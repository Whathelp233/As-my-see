#!/bin/bash
# simple_automation_manager.sh
# 简单的自动化系统管理器

set -e

WORKSPACE_DIR="/root/.openclaw/workspace"
AS_MY_SEE_DIR="$WORKSPACE_DIR/As-my-see"
CONFIG_FILE="$AS_MY_SEE_DIR/automation_config.json"
LOG_DIR="$AS_MY_SEE_DIR/logs/automation"

mkdir -p "$LOG_DIR"

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

# 加载配置
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        echo "配置已加载: $CONFIG_FILE"
    else
        # 创建默认配置
        cat > "$CONFIG_FILE" << EOF
{
    "document_monitor": {
        "enabled": true,
        "schedule": "0 3 * * *",
        "threshold_lines": 50
    },
    "git_maintainer": {
        "enabled": true,
        "schedule": "0 4 * * *",
        "auto_push": true
    }
}
EOF
        echo_color "$YELLOW" "创建默认配置文件: $CONFIG_FILE"
    fi
}

# 显示状态
show_status() {
    echo_color "$BLUE" "=== 自动化系统状态 ==="
    echo "工作目录: $WORKSPACE_DIR"
    echo "配置文件: $CONFIG_FILE"
    echo "日志目录: $LOG_DIR"
    echo ""
    
    echo_color "$GREEN" "📊 文档质量监控:"
    echo "  脚本: analyze_docs.py"
    echo "  功能: 分析文档质量，生成报告"
    echo ""
    
    echo_color "$GREEN" "🔧 Git自动维护:"
    echo "  脚本: git_auto_maintain.py"
    echo "  功能: 自动提交、推送、备份"
    echo ""
    
    # 检查脚本状态
    echo_color "$YELLOW" "📋 脚本状态:"
    
    if [ -f "$AS_MY_SEE_DIR/analyze_docs.py" ]; then
        echo "  ✅ analyze_docs.py - 存在"
    else
        echo "  ❌ analyze_docs.py - 不存在"
    fi
    
    if [ -f "$AS_MY_SEE_DIR/git_auto_maintain.py" ]; then
        echo "  ✅ git_auto_maintain.py - 存在"
    else
        echo "  ❌ git_auto_maintain.py - 不存在"
    fi
    
    # 检查目录
    echo ""
    echo_color "$YELLOW" "📁 目录状态:"
    
    if [ -d "$AS_MY_SEE_DIR/docs" ]; then
        doc_count=$(find "$AS_MY_SEE_DIR/docs" -name "*.md" -type f | wc -l)
        echo "  ✅ docs/ - $doc_count 个文档"
    else
        echo "  ❌ docs/ - 不存在"
    fi
    
    if [ -d "$AS_MY_SEE_DIR/logs" ]; then
        log_count=$(find "$AS_MY_SEE_DIR/logs" -name "*.log" -type f | wc -l)
        echo "  ✅ logs/ - $log_count 个日志文件"
    else
        echo "  ❌ logs/ - 不存在"
    fi
    
    if [ -d "$AS_MY_SEE_DIR/backups" ]; then
        backup_count=$(find "$AS_MY_SEE_DIR/backups" -name "*.tar.gz" -type f | wc -l)
        echo "  ✅ backups/ - $backup_count 个备份文件"
    else
        echo "  ❌ backups/ - 不存在"
    fi
}

# 运行文档质量监控
run_document_monitor() {
    echo_color "$YELLOW" "运行文档质量监控..."
    
    local log_file="$LOG_DIR/document_monitor_$(date +%Y%m%d_%H%M%S).log"
    
    cd "$AS_MY_SEE_DIR"
    
    if python3 analyze_docs.py 2>&1 | tee "$log_file"; then
        echo_color "$GREEN" "文档质量监控完成"
        echo_color "$BLUE" "日志文件: $log_file"
        
        # 查找最新报告
        latest_report=$(ls -t "$AS_MY_SEE_DIR"/document_analysis_*.md 2>/dev/null | head -1)
        if [ -n "$latest_report" ]; then
            echo_color "$BLUE" "报告文件: $latest_report"
            
            # 显示统计摘要
            echo ""
            echo_color "$YELLOW" "📊 统计摘要:"
            grep -E "(总文档数|质量良好|需要优化|重复文档)" "$latest_report" | head -4
        fi
    else
        echo_color "$RED" "文档质量监控失败"
    fi
}

# 运行Git自动维护
run_git_maintainer() {
    echo_color "$YELLOW" "运行Git自动维护..."
    
    local log_file="$LOG_DIR/git_maintainer_$(date +%Y%m%d_%H%M%S).log"
    
    cd "$AS_MY_SEE_DIR"
    
    if python3 git_auto_maintain.py 2>&1 | tee "$log_file"; then
        echo_color "$GREEN" "Git自动维护完成"
        echo_color "$BLUE" "日志文件: $log_file"
    else
        echo_color "$RED" "Git自动维护失败"
    fi
}

# 运行完整维护
run_full_maintenance() {
    echo_color "$YELLOW" "=== 开始完整自动化维护 ==="
    
    local start_time=$(date +%s)
    local log_file="$LOG_DIR/full_maintenance_$(date +%Y%m%d_%H%M%S).log"
    
    echo "开始时间: $(date)" > "$log_file"
    echo "" >> "$log_file"
    
    # 1. 文档质量监控
    echo "=== 步骤1: 文档质量监控 ===" >> "$log_file"
    run_document_monitor >> "$log_file" 2>&1
    
    # 2. Git自动维护
    echo "" >> "$log_file"
    echo "=== 步骤2: Git自动维护 ===" >> "$log_file"
    run_git_maintainer >> "$log_file" 2>&1
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo "" >> "$log_file"
    echo "=== 维护完成 ===" >> "$log_file"
    echo "结束时间: $(date)" >> "$log_file"
    echo "总耗时: ${duration}秒" >> "$log_file"
    
    echo_color "$GREEN" "=== 完整自动化维护完成，耗时: ${duration}秒 ==="
    echo_color "$BLUE" "详细日志: $log_file"
}

# 设置cron任务
setup_cron_tasks() {
    echo_color "$YELLOW" "设置cron定时任务..."
    
    local cron_file="/etc/cron.d/as_my_see_automation"
    
    # 读取配置中的计划
    local doc_schedule="0 3 * * *"  # 默认
    local git_schedule="0 4 * * *"  # 默认
    
    if [ -f "$CONFIG_FILE" ]; then
        # 简单解析JSON获取计划
        doc_schedule=$(grep -A1 '"schedule"' "$CONFIG_FILE" | grep -v '"schedule"' | tr -d ' ,"' | head -1)
        git_schedule=$(grep -A1 '"schedule"' "$CONFIG_FILE" | grep -v '"schedule"' | tr -d ' ,"' | tail -1)
    fi
    
    # 创建cron文件
    cat > "$cron_file" << EOF
# 自动化系统定时任务
# 文档质量监控 - $doc_schedule
$doc_schedule root cd "$AS_MY_SEE_DIR" && python3 analyze_docs.py >> "$LOG_DIR/cron_document.log" 2>&1

# Git自动维护 - $git_schedule
$git_schedule root cd "$AS_MY_SEE_DIR" && python3 git_auto_maintain.py >> "$LOG_DIR/cron_git.log" 2>&1

# 每周日完整维护 - 凌晨5点
0 5 * * 0 root cd "$AS_MY_SEE_DIR" && bash "$AS_MY_SEE_DIR/simple_automation_manager.sh" --run-full >> "$LOG_DIR/cron_full.log" 2>&1
EOF
    
    echo_color "$GREEN" "cron任务设置完成"
    echo_color "$BLUE" "cron文件: $cron_file"
    echo ""
    echo "计划任务:"
    echo "  文档质量监控: $doc_schedule"
    echo "  Git自动维护: $git_schedule"
    echo "  完整维护: 每周日 5:00"
}

# 显示菜单
show_menu() {
    clear
    echo_color "$BLUE" "╔════════════════════════════════════════════════╗"
    echo_color "$BLUE" "║         自动化系统管理器 v1.0                 ║"
    echo_color "$BLUE" "╠════════════════════════════════════════════════╣"
    echo_color "$BLUE" "║ 1. 显示系统状态                              ║"
    echo_color "$BLUE" "║ 2. 运行文档质量监控                          ║"
    echo_color "$BLUE" "║ 3. 运行Git自动维护                          ║"
    echo_color "$BLUE" "║ 4. 运行完整维护流程                          ║"
    echo_color "$BLUE" "║ 5. 设置定时任务                              ║"
    echo_color "$BLUE" "║ 6. 测试所有功能                              ║"
    echo_color "$BLUE" "║ 7. 退出                                      ║"
    echo_color "$BLUE" "╚════════════════════════════════════════════════╝"
    echo ""
    echo -n "请选择操作 [1-7]: "
}

# 测试所有功能
test_all_functions() {
    echo_color "$YELLOW" "测试所有功能..."
    
    local test_log="$LOG_DIR/test_all_$(date +%Y%m%d_%H%M%S).log"
    
    echo "=== 功能测试开始 ===" > "$test_log"
    echo "测试时间: $(date)" >> "$test_log"
    echo "" >> "$test_log"
    
    # 测试1: Python脚本
    echo "=== 测试1: Python脚本 ===" >> "$test_log"
    cd "$AS_MY_SEE_DIR"
    
    if python3 --version >> "$test_log" 2>&1; then
        echo "✅ Python可用" >> "$test_log"
    else
        echo "❌ Python不可用" >> "$test_log"
    fi
    
    # 测试2: 文档分析脚本
    echo "" >> "$test_log"
    echo "=== 测试2: 文档分析脚本 ===" >> "$test_log"
    if python3 analyze_docs.py --help >> "$test_log" 2>&1; then
        echo "✅ 文档分析脚本可用" >> "$test_log"
    else
        echo "❌ 文档分析脚本不可用" >> "$test_log"
    fi
    
    # 测试3: Git维护脚本
    echo "" >> "$test_log"
    echo "=== 测试3: Git维护脚本 ===" >> "$test_log"
    if python3 git_auto_maintain.py --help >> "$test_log" 2>&1; then
        echo "✅ Git维护脚本可用" >> "$test_log"
    else
        echo "❌ Git维护脚本不可用" >> "$test_log"
    fi
    
    # 测试4: 目录结构
    echo "" >> "$test_log"
    echo "=== 测试4: 目录结构 ===" >> "$test_log"
    for dir in docs logs backups; do
        if [ -d "$AS_MY_SEE_DIR/$dir" ]; then
            echo "✅ $dir/ 目录存在" >> "$test_log"
        else
            echo "❌ $dir/ 目录不存在" >> "$test_log"
        fi
    done
    
    # 测试5: Git仓库
    echo "" >> "$test_log"
    echo "=== 测试5: Git仓库 ===" >> "$test_log"
    if [ -d "$AS_MY_SEE_DIR/.git" ]; then
        echo "✅ Git仓库存在" >> "$test_log"
        cd "$AS_MY_SEE_DIR" && git status --short >> "$test_log" 2>&1
    else
        echo "❌ Git仓库不存在" >> "$test_log"
    fi
    
    echo_color "$GREEN" "功能测试完成"
    echo_color "$BLUE" "测试日志: $test_log"
}

# 主函数
main() {
    load_config
    
    local action="${1:-}"
    
    case "$action" in
        "--status")
            show_status
            ;;
        "--run-document-monitor")
            run_document_monitor
            ;;
        "--run-git-maintainer")
            run_git_maintainer
            ;;
        "--run-full")
            run_full_maintenance
            ;;
        "--setup-cron")
            setup_cron_tasks
            ;;
        "--test")
            test_all_functions
            ;;
        "--help"|"")
            # 显示菜单
            while true; do
                show_menu
                read -r choice
                
                case $choice in
                    1)
                        show_status
                        ;;
                    2)
                        run_document_monitor
                        ;;
                    3)
                        run_git_maintainer
                        ;;
                    4)
                        run_full_maintenance
                        ;;
                    5)
                        setup_cron_tasks
                        ;;
                    6)
                        test_all_functions
                        ;;
                    7)
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
            ;;
        *)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --status                 显示系统状态"
            echo "  --run-document-monitor   运行文档质量监控"
            echo "  --run-git-maintainer     运行Git自动维护"
            echo "  --run-full               运行完整维护流程"
            echo "  --setup-cron             设置定时任务"
            echo "  --test                   测试所有功能"
            echo "  --help                   显示帮助"
            echo ""
            echo "示例:"
            echo "  $0 --status"
            echo "  $0 --run-full"
            echo "  $0 --setup-cron"
            ;;
    esac
}

# 运行主函数
main "$@"