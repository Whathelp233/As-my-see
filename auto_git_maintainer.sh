#!/bin/bash
# auto_git_maintainer.sh
# Git自动维护系统
# 功能：自动提交、推送、备份、清理Git仓库

set -euo pipefail

# 配置
REPO_DIR="/root/.openclaw/workspace/As-my-see"
GIT_USER="OpenClaw Bot"
GIT_EMAIL="bot@openclaw.ai"
BACKUP_DIR="$REPO_DIR/backups/git"
LOG_DIR="$REPO_DIR/logs/git"
MAX_BACKUPS=30  # 保留最近30个备份

# 创建目录
mkdir -p "$BACKUP_DIR" "$LOG_DIR"

# 日志函数
log_git() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="$LOG_DIR/git_maintainer_$(date '+%Y%m%d').log"
    
    echo "[$timestamp] [$level] $message" | tee -a "$log_file"
}

log_info() { log_git "INFO" "$*"; }
log_warning() { log_git "WARNING" "$*"; }
log_error() { log_git "ERROR" "$*"; }

# 检查Git状态
check_git_status() {
    cd "$REPO_DIR"
    
    if [ ! -d ".git" ]; then
        log_error "不是Git仓库: $REPO_DIR"
        return 1
    fi
    
    # 检查是否有未提交的更改
    if git status --porcelain | grep -q "."; then
        log_info "检测到未提交的更改"
        return 0
    else
        log_info "没有未提交的更改"
        return 2
    fi
}

# 自动提交更改
auto_commit_changes() {
    cd "$REPO_DIR"
    
    log_info "开始自动提交更改..."
    
    # 配置Git用户
    git config user.name "$GIT_USER"
    git config user.email "$GIT_EMAIL"
    
    # 添加所有更改
    git add .
    
    # 生成提交信息
    local commit_message="自动提交: $(date '+%Y-%m-%d %H:%M:%S')
    
更新内容:
- 文档优化与维护
- 自动生成的更改
- 系统维护更新"
    
    # 提交
    if git commit -m "$commit_message" > /dev/null 2>&1; then
        local commit_hash=$(git rev-parse --short HEAD)
        log_info "提交成功: $commit_hash"
        echo "$commit_hash"
    else
        log_warning "没有需要提交的更改"
        echo ""
    fi
}

# 自动推送到远程仓库
auto_push_to_remote() {
    cd "$REPO_DIR"
    
    log_info "开始推送到远程仓库..."
    
    # 检查远程仓库配置
    if ! git remote | grep -q "origin"; then
        log_error "未配置远程仓库 'origin'"
        return 1
    fi
    
    # 获取当前分支
    local current_branch=$(git branch --show-current)
    
    # 推送
    if git push origin "$current_branch" 2>&1 | tee -a "$LOG_DIR/git_push.log"; then
        log_info "推送成功: $current_branch -> origin"
        return 0
    else
        log_error "推送失败"
        return 1
    fi
}

# 创建Git备份
create_git_backup() {
    local backup_name="git_backup_$(date '+%Y%m%d_%H%M%S').tar.gz"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    log_info "创建Git备份: $backup_name"
    
    cd "$REPO_DIR"
    
    # 备份整个.git目录
    tar -czf "$backup_path" .git/
    
    local backup_size=$(du -h "$backup_path" | cut -f1)
    log_info "Git备份完成: $backup_path ($backup_size)"
    
    echo "$backup_path"
}

# 清理旧备份
cleanup_old_backups() {
    log_info "清理旧备份文件..."
    
    # 按时间排序，保留最新的MAX_BACKUPS个
    local backups=($(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null || true))
    local total=${#backups[@]}
    
    if [ "$total" -le "$MAX_BACKUPS" ]; then
        log_info "备份文件数量正常 ($total/$MAX_BACKUPS)"
        return 0
    fi
    
    local to_delete=$((total - MAX_BACKUPS))
    log_info "需要删除 $to_delete 个旧备份"
    
    for ((i=MAX_BACKUPS; i<total; i++)); do
        local backup_to_delete="${backups[i]}"
        log_info "删除旧备份: $(basename "$backup_to_delete")"
        rm -f "$backup_to_delete"
    done
    
    log_info "备份清理完成"
}

# 检查Git仓库健康状态
check_git_health() {
    cd "$REPO_DIR"
    
    log_info "检查Git仓库健康状态..."
    
    local health_report="$LOG_DIR/git_health_$(date '+%Y%m%d').md"
    
    echo "# Git仓库健康检查报告" > "$health_report"
    echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$health_report"
    echo "" >> "$health_report"
    
    # 1. 检查分支状态
    echo "## 分支状态" >> "$health_report"
    echo '```bash' >> "$health_report"
    git branch -avv >> "$health_report" 2>&1
    echo '```' >> "$health_report"
    echo "" >> "$health_report"
    
    # 2. 检查远程状态
    echo "## 远程仓库状态" >> "$health_report"
    echo '```bash' >> "$health_report"
    git remote -v >> "$health_report" 2>&1
    echo '```' >> "$health_report"
    echo "" >> "$health_report"
    
    # 3. 检查最近提交
    echo "## 最近提交" >> "$health_report"
    echo '```bash' >> "$health_report"
    git log --oneline -10 >> "$health_report" 2>&1
    echo '```' >> "$health_report"
    echo "" >> "$health_report"
    
    # 4. 检查存储库大小
    echo "## 存储库统计" >> "$health_report"
    echo '```bash' >> "$health_report"
    echo "文件总数: $(find . -type f | wc -l)" >> "$health_report"
    echo "Git对象数: $(git count-objects -v | grep count | cut -d: -f2)" >> "$health_report"
    echo "存储库大小: $(du -sh .git | cut -f1)" >> "$health_report"
    echo '```' >> "$health_report"
    echo "" >> "$health_report"
    
    # 5. 检查问题
    echo "## 问题检查" >> "$health_report"
    
    local issues_found=0
    
    # 检查是否有悬空对象
    if git fsck --full 2>&1 | grep -q "dangling"; then
        echo "⚠️ 发现悬空对象" >> "$health_report"
        issues_found=$((issues_found + 1))
    fi
    
    # 检查是否需要垃圾回收
    local pack_size=$(git count-objects -v | grep size-pack | cut -d: -f2 | tr -d ' ')
    if [ "$pack_size" -gt 100000 ]; then  # 大于100MB
        echo "⚠️ Git包文件较大 ($((pack_size/1024))MB)，建议运行 git gc" >> "$health_report"
        issues_found=$((issues_found + 1))
    fi
    
    if [ "$issues_found" -eq 0 ]; then
        echo "✅ Git仓库健康状态良好" >> "$health_report"
    fi
    
    log_info "健康检查完成: $health_report"
}

# 自动运行Git垃圾回收
run_git_garbage_collection() {
    cd "$REPO_DIR"
    
    log_info "运行Git垃圾回收..."
    
    # 检查是否需要垃圾回收
    local loose_objects=$(git count-objects -v | grep count | cut -d: -f2 | tr -d ' ')
    
    if [ "$loose_objects" -gt 100 ]; then
        log_info "执行垃圾回收 (松散对象: $loose_objects)"
        
        # 运行垃圾回收
        git gc --auto --prune=now
        
        log_info "垃圾回收完成"
        
        # 检查回收效果
        local new_loose_objects=$(git count-objects -v | grep count | cut -d: -f2 | tr -d ' ')
        log_info "回收后松散对象: $new_loose_objects (减少 $((loose_objects - new_loose_objects)))"
    else
        log_info "不需要垃圾回收 (松散对象: $loose_objects)"
    fi
}

# 自动同步远程更改
auto_sync_from_remote() {
    cd "$REPO_DIR"
    
    log_info "开始从远程同步..."
    
    # 获取当前分支
    local current_branch=$(git branch --show-current)
    
    # 获取远程更新
    if git fetch origin 2>&1 | tee -a "$LOG_DIR/git_fetch.log"; then
        log_info "远程更新获取成功"
        
        # 检查是否有远程更新
        local behind_count=$(git rev-list --count HEAD..origin/"$current_branch" 2>/dev/null || echo "0")
        
        if [ "$behind_count" -gt 0 ]; then
            log_info "发现 $behind_count 个远程更新，正在合并..."
            
            # 尝试合并
            if git merge --ff-only "origin/$current_branch" 2>&1 | tee -a "$LOG_DIR/git_merge.log"; then
                log_info "快速合并成功"
            else
                log_warning "快速合并失败，尝试变基..."
                
                if git rebase "origin/$current_branch" 2>&1 | tee -a "$LOG_DIR/git_rebase.log"; then
                    log_info "变基成功"
                else
                    log_error "合并冲突，需要手动解决"
                    git rebase --abort 2>/dev/null || true
                    return 1
                fi
            fi
        else
            log_info "本地已是最新，无需同步"
        fi
    else
        log_error "获取远程更新失败"
        return 1
    fi
    
    return 0
}

# 生成Git维护报告
generate_git_report() {
    local report_file="$LOG_DIR/git_maintenance_report_$(date '+%Y%m%d').md"
    
    echo "# Git自动维护报告" > "$report_file"
    echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$report_file"
    echo "" >> "$report_file"
    
    cd "$REPO_DIR"
    
    # 基本状态
    echo "## 基本状态" >> "$report_file"
    echo "" >> "$report_file"
    echo "- 仓库位置: $REPO_DIR" >> "$report_file"
    echo "- 当前分支: $(git branch --show-current)" >> "$report_file"
    echo "- 最新提交: $(git log --oneline -1)" >> "$report_file"
    echo "" >> "$report_file"
    
    # 维护操作记录
    echo "## 本次维护操作" >> "$report_file"
    echo "" >> "$report_file"
    
    local log_content=$(tail -50 "$LOG_DIR/git_maintainer_$(date '+%Y%m%d').log" 2>/dev/null || echo "无日志")
    echo '```' >> "$report_file"
    echo "$log_content" >> "$report_file"
    echo '```' >> "$report_file"
    
    # 建议
    echo "" >> "$report_file"
    echo "## 维护建议" >> "$report_file"
    echo "" >> "$report_file"
    echo "1. 定期运行本维护脚本" >> "$report_file"
    echo "2. 监控Git仓库大小" >> "$report_file"
    echo "3. 及时解决合并冲突" >> "$report_file"
    echo "4. 定期清理旧分支" >> "$report_file"
    
    log_info "维护报告生成: $report_file"
}

# 主维护流程
main_git_maintenance() {
    log_info "=== 开始Git自动维护 ==="
    
    # 1. 检查Git状态
    if ! check_git_status; then
        if [ $? -eq 1 ]; then
            log_error "Git仓库检查失败，退出维护"
            return 1
        fi
    fi
    
    # 2. 从远程同步
    auto_sync_from_remote || log_warning "远程同步失败，继续本地维护"
    
    # 3. 自动提交更改
    local commit_hash=$(auto_commit_changes)
    
    # 4. 如果有新提交，推送到远程
    if [ -n "$commit_hash" ]; then
        auto_push_to_remote || log_error "推送失败"
    fi
    
    # 5. 创建备份
    local backup_file=$(create_git_backup)
    
    # 6. 运行垃圾回收
    run_git_garbage_collection
    
    # 7. 检查健康状态
    check_git_health
    
    # 8. 清理旧备份
    cleanup_old_backups
    
    # 9. 生成报告
    generate_git_report
    
    log_info "=== Git自动维护完成 ==="
    
    # 返回结果
    echo "{
        \"status\": \"success\",
        \"commit\": \"$commit_hash\",
        \"backup\": \"$(basename "$backup_file" 2>/dev/null || echo \"none\")\",
        \"timestamp\": \"$(date '+%Y-%m-%d %H:%M:%S')\"
    }"
}

# 设置定时任务
setup_cron_job() {
    local cron_schedule="$1"
    local script_path="$REPO_DIR/auto_git_maintainer.sh"
    
    log_info "设置定时任务: $cron_schedule"
    
    # 创建cron任务文件
    local cron_file="/etc/cron.d/auto_git_maintainer"
    
    echo "# Git自动维护定时任务" > "$cron_file"
    echo "# 由OpenClaw Bot自动生成" >> "$cron_file"
    echo "$cron_schedule root $script_path >> $LOG_DIR/cron.log 2>&1" >> "$cron_file"
    echo "" >> "$cron_file"
    
    # 设置权限
    chmod 0644 "$cron_file"
    
    # 重新加载cron
    systemctl reload cron 2>/dev/null || service cron reload 2>/dev/null || true
    
    log_info "定时任务设置完成: $cron_schedule"
}

# 主函数
main() {
    local action="${1:-run}"
    
    case "$action" in
        "run")
            # 运行维护
            main_git_maintenance
            ;;
        "setup-cron")
            # 设置定时任务
            local schedule="${2:-0 2 * * *}"  # 默认每天凌晨2点
            setup_cron_job "$schedule"
            ;;
        "check-health")
            # 只检查健康状态
            check_git_health
            ;;
        "create-backup")
            # 只创建备份
            create_git_backup
            ;;
        "cleanup")
            # 只清理
            cleanup_old_backups
            ;;
        "help")
            echo "用法: $0 [命令]"
            echo ""
            echo "命令:"
            echo "  run             运行完整维护流程"
            echo "  setup-cron [schedule]  设置定时任务"
            echo "  check-health    只检查健康状态"
            echo "  create-backup   只创建备份"
            echo "  cleanup         只清理旧备份"
            echo "  help            显示帮助"
            echo ""
            echo "示例:"
            echo "  $0 run"
            echo "  $0 setup-cron \"0 2 * * *\""
            ;;
        *)
            echo "未知命令: $action"
            echo "使用 '$0 help' 查看帮助"
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"