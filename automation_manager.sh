#!/bin/bash
# automation_manager.sh
# 自动化系统管理器
# 统一管理文档质量监控和Git自动维护

set -euo pipefail

# 配置
REPO_DIR="/root/.openclaw/workspace/As-my-see"
LOG_DIR="$REPO_DIR/logs/automation"
CONFIG_FILE="$REPO_DIR/automation_config.json"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

echo_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# 创建目录
mkdir -p "$LOG_DIR"

# 加载配置
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source <(jq -r 'to_entries|map("\(.key)=\(.value|tostring)")|.[]' "$CONFIG_FILE" 2>/dev/null || echo "")
    else
        # 默认配置
        cat > "$CONFIG_FILE" << EOF
{
    "document_monitor_enabled": true,
    "git_maintainer_enabled": true,
    "document_monitor_schedule": "0 3 * * *",
    "git_maintainer_schedule": "0 4 * * *",
    "notification_enabled": false,
    "max_backups": 30,
    "quality_threshold": 50
}
EOF
        echo_color "$YELLOW" "创建默认配置文件: $CONFIG_FILE"
    fi
}

# 显示菜单
show_menu() {
    clear
    echo_color "$BLUE" "╔════════════════════════════════════════════════╗"
    echo_color "$BLUE" "║         自动化系统管理器 v1.0                 ║"
    echo_color "$BLUE" "╠════════════════════════════════════════════════╣"
    echo_color "$BLUE" "║ 文档质量监控: $(if [ "$document_monitor_enabled" = "true" ]; then echo -e "${GREEN}✅ 启用${NC}"; else echo -e "${RED}❌ 禁用${NC}"; fi)"
    echo_color "$BLUE" "║ Git自动维护:  $(if [ "$git_maintainer_enabled" = "true" ]; then echo -e "${GREEN}✅ 启用${NC}"; else echo -e "${RED}❌ 禁用${NC}"; fi)"
    echo_color "$BLUE" "╠════════════════════════════════════════════════╣"
    echo_color "$BLUE" "║ 1. 运行文档质量监控                          ║"
    echo_color "$BLUE" "║ 2. 运行Git自动维护                          ║"
    echo_color "$BLUE" "║ 3. 运行完整自动化流程                        ║"
    echo_color "$BLUE" "║ 4. 设置定时任务                              ║"
    echo_color "$BLUE" "║ 5. 查看状态报告                              ║"
    echo_color "$BLUE" "║ 6. 配置管理                                  ║"
    echo_color "$BLUE" "║ 7. 测试所有功能                              ║"
    echo_color "$BLUE" "║ 8. 退出                                      ║"
    echo_color "$BLUE" "╚════════════════════════════════════════════════╝"
    echo ""
    echo -n "请选择操作 [1-8]: "
}

# 运行文档质量监控
run_document_monitor() {
    echo_color "$YELLOW" "开始运行文档质量监控..."
    
    local log_file="$LOG_DIR/document_monitor_$(date '+%Y%m%d_%H%M%S').log"
    
    if ./auto_document_monitor.sh 2>&1 | tee "$log_file"; then
        echo_color "$GREEN" "文档质量监控完成"
        echo_color "$BLUE" "日志文件: $log_file"
    else
        echo_color "$RED" "文档质量监控失败"
    fi
}

# 运行Git自动维护
run_git_maintainer() {
    echo_color "$YELLOW" "开始运行Git自动维护..."
    
    local log_file="$LOG_DIR/git_maintainer_$(date '+%Y%m%d_%H%M%S').log"
    
    if ./auto_git_maintainer.sh run 2>&1 | tee "$log_file"; then
        echo_color "$GREEN" "Git自动维护完成"
        echo_color "$BLUE" "日志文件: $log_file"
    else
        echo_color "$RED" "Git自动维护失败"
    fi
}

# 运行完整自动化流程
run_full_automation() {
    echo_color "$YELLOW" "开始运行完整自动化流程..."
    
    local start_time=$(date +%s)
    local log_file="$LOG_DIR/full_automation_$(date '+%Y%m%d_%H%M%S').log"
    
    echo "=== 完整自动化流程开始 ===" > "$log_file"
    echo "开始时间: $(date)" >> "$log_file"
    
    # 1. 文档质量监控
    echo "" >> "$log_file"
    echo "=== 步骤1: 文档质量监控 ===" >> "$log_file"
    if ./auto_document_monitor.sh 2>&1 | tee -a "$log_file"; then
        echo "✅ 文档质量监控成功" >> "$log_file"
    else
        echo "❌ 文档质量监控失败" >> "$log_file"
    fi
    
    # 2. Git自动维护
    echo "" >> "$log_file"
    echo "=== 步骤2: Git自动维护 ===" >> "$log_file"
    if ./auto_git_maintainer.sh run 2>&1 | tee -a "$log_file"; then
        echo "✅ Git自动维护成功" >> "$log_file"
    else
        echo "❌ Git自动维护失败" >> "$log_file"
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo "" >> "$log_file"
    echo "=== 自动化流程完成 ===" >> "$log_file"
    echo "结束时间: $(date)" >> "$log_file"
    echo "总耗时: ${duration}秒" >> "$log_file"
    
    echo_color "$GREEN" "完整自动化流程完成 (耗时: ${duration}秒)"
    echo_color "$BLUE" "详细日志: $log_file"
}

# 设置定时任务
setup_cron_jobs() {
    echo_color "$YELLOW" "设置定时任务..."
    
    # 文档质量监控定时任务
    if [ "$document_monitor_enabled" = "true" ]; then
        echo_color "$BLUE" "设置文档质量监控: $document_monitor_schedule"
        ./auto_git_maintainer.sh setup-cron "$document_monitor_schedule" > /dev/null 2>&1 || true
    fi
    
    # Git自动维护定时任务
    if [ "$git_maintainer_enabled" = "true" ]; then
        echo_color "$BLUE" "设置Git自动维护: $git_maintainer_schedule"
        ./auto_git_maintainer.sh setup-cron "$git_maintainer_schedule" > /dev/null 2>&1 || true
    fi
    
    echo_color "$GREEN" "定时任务设置完成"
    
    # 显示当前cron任务
    echo_color "$YELLOW" "当前cron任务:"
    crontab -l 2>/dev/null | grep -E "(auto_document_monitor|auto_git_maintainer)" || echo "暂无相关任务"
}

# 查看状态报告
show_status_report() {
    echo_color "$YELLOW" "生成状态报告..."
    
    local report_file="$LOG_DIR/status_report_$(date '+%Y%m%d_%H%M%S').md"
    
    cat > "$report_file" << EOF
# 自动化系统状态报告
生成时间: $(date '+%Y-%m-%d %H:%M:%S')

## 系统配置
- 文档质量监控: $document_monitor_enabled
- Git自动维护: $git_maintainer_enabled
- 文档监控计划: $document_monitor_schedule
- Git维护计划: $git_maintainer_schedule

## 存储状态
EOF
    
    # 添加存储信息
    echo "" >> "$report_file"
    echo "### 存储使用情况" >> "$report_file"
    echo '```bash' >> "$report_file"
    du -sh "$REPO_DIR"/* 2>/dev/null | grep -E "(docs|logs|backups|reports)" >> "$report_file"
    echo '```' >> "$report_file"
    
    # 添加Git状态
    echo "" >> "$report_file"
    echo "### Git仓库状态" >> "$report_file"
    echo '```bash' >> "$report_file"
    cd "$REPO_DIR" && git status --short 2>/dev/null >> "$report_file"
    echo '```' >> "$report_file"
    
    # 添加文档统计
    echo "" >> "$report_file"
    echo "### 文档统计" >> "$report_file"
    echo '```bash' >> "$report_file"
    echo "文档总数: $(find "$REPO_DIR/docs" -name "*.md" -type f 2>/dev/null | wc -l)" >> "$report_file"
    echo "最近修改: $(find "$REPO_DIR/docs" -name "*.md" -type f -exec stat -c %y {} \; 2>/dev/null | sort -r | head -1)" >> "$report_file"
    echo '```' >> "$report_file"
    
    # 添加日志信息
    echo "" >> "$report_file"
    echo "### 最近日志" >> "$report_file"
    echo '```' >> "$report_file"
    find "$LOG_DIR" -name "*.log" -type f -exec tail -5 {} \; 2>/dev/null | head -20 >> "$report_file"
    echo '```' >> "$report_file"
    
    echo_color "$GREEN" "状态报告生成: $report_file"
    
    # 显示摘要
    echo_color "$BLUE" "=== 状态摘要 ==="
    echo "文档总数: $(find "$REPO_DIR/docs" -name "*.md" -type f 2>/dev/null | wc -l)"
    echo "Git状态: $(cd "$REPO_DIR" && git status --short 2>/dev/null | wc -l) 个更改"
    echo "日志文件: $(find "$LOG_DIR" -name "*.log" -type f 2>/dev/null | wc -l) 个"
    echo "备份文件: $(find "$REPO_DIR/backups" -name "*.tar.gz" -type f 2>/dev/null | wc -l) 个"
}

# 配置管理
manage_config() {
    echo_color "$YELLOW" "配置管理"
    echo ""
    
    while true; do
        echo "当前配置:"
        echo "1. 文档质量监控: $document_monitor_enabled"
        echo "2. Git自动维护: $git_maintainer_enabled"
        echo "3. 文档监控计划: $document_monitor_schedule"
        echo "4. Git维护计划: $git_maintainer_schedule"
        echo "5. 返回主菜单"
        echo ""
        echo -n "选择要修改的配置 [1-5]: "
        
        read -r choice
        case $choice in
            1)
                echo -n "启用文档质量监控? (y/n): "
                read -r enable
                if [ "$enable" = "y" ] || [ "$enable" = "Y" ]; then
                    document_monitor_enabled="true"
                else
                    document_monitor_enabled="false"
                fi
                ;;
            2)
                echo -n "启用Git自动维护? (y/n): "
                read -r enable
                if [ "$enable" = "y" ] || [ "$enable" = "Y" ]; then
                    git_maintainer_enabled="true"
                else
                    git_maintainer_enabled="false"
                fi
                ;;
            3)
                echo -n "输入文档监控计划 (cron格式): "
                read -r schedule
                document_monitor_schedule="$schedule"
                ;;
            4)
                echo -n "输入Git维护计划 (cron格式): "
                read -r schedule
                git_maintainer_schedule="$schedule"
                ;;
            5)
                # 保存配置
                jq --arg dm_enabled "$document_monitor_enabled" \
                   --arg gm_enabled "$git_maintainer_enabled" \
                   --arg dm_schedule "$document_monitor_schedule" \
                   --arg gm_schedule "$git_maintainer_schedule" \
                   '.document_monitor_enabled = ($dm_enabled == "true") |
                    .git_maintainer_enabled = ($gm_enabled == "true") |
                    .document_monitor_schedule = $dm_schedule |
                    .git_maintainer_schedule = $gm_schedule' \
                   "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
                echo_color "$GREEN" "配置已保存"
                break
                ;;
            *)
                echo_color "$RED" "无效选择"
                ;;
        esac
    done
}

# 测试所有功能
test_all_features() {
    echo_color "$YELLOW" "开始测试所有功能..."
    
    local test_log="$LOG_DIR/test_all_$(date '+%Y%m%d_%H%M%S').log"
    
    echo "=== 自动化系统功能测试 ===" > "$test_log"
    echo "测试时间: $(date)" >> "$test_log"
    
    # 测试1: 脚本权限
    echo "" >> "$test_log"
    echo "=== 测试1: 脚本权限 ===" >> "$test_log"
    for script in auto_document_monitor.sh auto_git_maintainer.sh automation_manager.sh; do
        if [ -x "$REPO_DIR/$script" ]; then
            echo "✅ $script 可执行" >> "$test_log"
        else
            echo "❌ $script 不可执行" >> "$test_log"
        fi
    done
    
    # 测试2: 目录结构
    echo "" >> "$test_log"
    echo "=== 测试2: 目录结构 ===" >> "$test_log"
    for dir in docs logs backups reports; do
        if [ -d "$REPO_DIR/$dir" ]; then
            echo "✅ $dir 目录存在" >> "$test_log"
        else
            echo "❌ $dir 目录不存在" >> "$test_log"
        fi
    done
    
    # 测试3: Git仓库
    echo "" >> "$test_log"
    echo "=== 测试3: Git仓库 ===" >> "$test_log"
    if [ -d "$REPO_DIR/.git" ]; then
        echo "✅ Git仓库存在" >> "$test_log"
        cd "$REPO_DIR" && git status --short >> "$test_log" 2>&1
    else
        echo "❌ Git仓库不存在" >> "$test_log"
    fi
    
    # 测试4: 快速运行文档监控（简化版）
    echo "" >> "$test_log"
    echo "=== 测试4: 文档监控快速测试 ===" >> "$test_log"
    if ./auto_document_monitor.sh --help 2>&1 | head -5 >> "$test_log"; then
        echo "✅ 文档监控脚本可运行" >> "$test_log"
    else
        echo "❌ 文档监控脚本运行失败" >> "$test_log"
    fi
    
    # 测试5: Git维护快速测试
    echo "" >> "$test_log"
    echo "=== 测试5: Git维护快速测试 ===" >> "$test_log"
    if ./auto_git_maintainer.sh help 2>&1 | head -5 >> "$test_log"; then
        echo "✅ Git维护脚本可运行" >> "$test_log"
    else
        echo "❌ Git维护脚本运行失败" >> "$test_log"
    fi
    
    echo_color "$GREEN" "功能测试完成"
    echo_color "$BLUE" "测试日志: $test_log"
}

# 主循环
main() {
    load_config
    
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1)
                run_document_monitor
                ;;
            2)
                run_git_maintainer
                ;;
            3)
                run_full_automation
                ;;
            4)
                setup_cron_jobs
                ;;
            5)
                show_status_report
                ;;
            6)
                manage_config
                ;;
            7)
                test_all_features
                ;;
            8)
                echo_color "$GREEN" "退出自动化系统管理器"
                exit 0
                ;;
            *)
                echo_color "$RED" "无效选择，请重新输入"
                ;;
        esac
        
        echo ""
        echo -n "按回车键继续..."
        read -r
    done
}

# 运行主函数
main "$@"