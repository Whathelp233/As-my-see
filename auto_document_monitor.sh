#!/bin/bash
# auto_document_monitor_fixed.sh
# 自动文档质量监控系统（修复版）
# 功能：每天自动检查文档质量，生成报告

set -euo pipefail

# 配置
WORKSPACE_DIR="/root/.openclaw/workspace"
AS_MY_SEE_DIR="$WORKSPACE_DIR/As-my-see"
DOCS_DIR="$AS_MY_SEE_DIR/docs"
LOG_DIR="$AS_MY_SEE_DIR/logs"
REPORT_DIR="$AS_MY_SEE_DIR/reports"
BACKUP_DIR="$AS_MY_SEE_DIR/backups"

# 创建目录
mkdir -p "$LOG_DIR" "$REPORT_DIR" "$BACKUP_DIR"

# 日志函数
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="$LOG_DIR/document_monitor_$(date '+%Y%m%d').log"
    
    echo "[$timestamp] [$level] $message" | tee -a "$log_file"
}

log_info() { log "INFO" "$*"; }
log_warning() { log "WARNING" "$*"; }
log_error() { log "ERROR" "$*"; }

# 备份当前状态
backup_current_state() {
    local backup_name="backup_$(date '+%Y%m%d_%H%M%S').tar.gz"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    log_info "开始备份当前状态..."
    
    cd "$AS_MY_SEE_DIR"
    tar -czf "$backup_path" \
        --exclude="*.tar.gz" \
        --exclude="*.log" \
        --exclude="*.report" \
        .
    
    log_info "备份完成: $backup_path ($(du -h "$backup_path" | cut -f1))"
}

# 分析文档质量
analyze_document_quality() {
    local report_file="$REPORT_DIR/quality_report_$(date '+%Y%m%d').md"
    
    log_info "开始文档质量分析..."
    
    echo "# 文档质量分析报告" > "$report_file"
    echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$report_file"
    echo "文档总数: $(find "$DOCS_DIR" -name "*.md" -type f | wc -l)" >> "$report_file"
    echo "" >> "$report_file"
    
    # 分析每个文档
    echo "## 文档详细分析" >> "$report_file"
    echo "" >> "$report_file"
    echo "| 文档 | 行数 | 深度评分 | 状态 | 建议 |" >> "$report_file"
    echo "|------|------|----------|------|------|" >> "$report_file"
    
    local shallow_docs=()
    
    for doc in $(find "$DOCS_DIR" -name "*.md" -type f); do
        local filename=$(basename "$doc")
        local relative_path=${doc#$DOCS_DIR/}
        
        # 计算行数
        local line_count=$(wc -l < "$doc" || echo "0")
        
        # 分析文档深度
        local depth_score=$(analyze_document_depth "$doc")
        
        # 确定状态
        local status="🟢 良好"
        local suggestion="保持"
        
        if [ "$line_count" -lt 50 ]; then
            status="🔴 过浅"
            suggestion="需要大幅扩充内容"
            shallow_docs+=("$relative_path")
        elif [ "$line_count" -lt 100 ]; then
            status="🟡 一般"
            suggestion="建议补充更多细节"
        fi
        
        if [ "$depth_score" -lt 3 ]; then
            status="🟡 结构简单"
            suggestion="建议增加章节层次"
        fi
        
        echo "| $relative_path | $line_count | $depth_score/5 | $status | $suggestion |" >> "$report_file"
    done
    
    # 总结
    echo "" >> "$report_file"
    echo "## 总结与建议" >> "$report_file"
    echo "" >> "$report_file"
    
    if [ ${#shallow_docs[@]} -gt 0 ]; then
        echo "### 需要优化的文档 (${#shallow_docs[@]}个):" >> "$report_file"
        for doc in "${shallow_docs[@]}"; do
            echo "- $doc" >> "$report_file"
        done
        echo "" >> "$report_file"
        echo "建议优先优化这些文档，增加技术深度和实用性。" >> "$report_file"
    else
        echo "所有文档质量良好，继续保持！" >> "$report_file"
    fi
    
    log_info "质量分析完成: $report_file"
    
    # 返回浅层文档列表
    for doc in "${shallow_docs[@]}"; do
        echo "$doc"
    done
}

# 分析文档深度
analyze_document_depth() {
    local doc="$1"
    local depth_score=0
    
    # 检查是否有标题结构
    if grep -q "^#" "$doc"; then
        depth_score=$((depth_score + 1))
    fi
    
    # 检查是否有二级标题
    if grep -q "^## " "$doc"; then
        depth_score=$((depth_score + 1))
    fi
    
    # 检查是否有三级标题
    if grep -q "^### " "$doc"; then
        depth_score=$((depth_score + 1))
    fi
    
    # 检查是否有代码块
    if grep -q "^```" "$doc"; then
        depth_score=$((depth_score + 1))
    fi
    
    # 检查是否有列表
    if grep -q "^- " "$doc" || grep -q "^[0-9]\+\. " "$doc"; then
        depth_score=$((depth_score + 1))
    fi
    
    echo "$depth_score"
}

# 生成总结报告
generate_summary_report() {
    local summary_file="$REPORT_DIR/summary_$(date '+%Y%m%d').md"
    
    echo "# 自动化文档优化总结" > "$summary_file"
    echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$summary_file"
    echo "" >> "$summary_file"
    
    echo "## 执行结果" >> "$summary_file"
    echo "" >> "$summary_file"
    echo "- ✅ 备份完成" >> "$summary_file"
    echo "- 📊 质量分析完成" >> "$summary_file"
    echo "- 📝 报告生成完成" >> "$summary_file"
    echo "" >> "$summary_file"
    
    echo "## 下一步建议" >> "$summary_file"
    echo "" >> "$summary_file"
    echo "1. 审查分析报告，识别需要优化的文档" >> "$summary_file"
    echo "2. 手动优化浅层文档，增加技术深度" >> "$summary_file"
    echo "3. 定期运行本监控脚本，保持文档质量" >> "$summary_file"
    
    log_info "总结报告生成: $summary_file"
}

# 显示帮助
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --help     显示此帮助信息"
    echo "  --version  显示版本信息"
    echo "  --analyze  只进行分析，不进行优化"
    echo ""
    echo "功能:"
    echo "  自动分析文档质量，生成报告，识别需要优化的文档"
    echo ""
    echo "输出:"
    echo "  - 质量分析报告: reports/quality_report_YYYYMMDD.md"
    echo "  - 总结报告: reports/summary_YYYYMMDD.md"
    echo "  - 日志文件: logs/document_monitor_YYYYMMDD.log"
    echo "  - 备份文件: backups/backup_YYYYMMDD_HHMMSS.tar.gz"
}

# 主函数
main() {
    local action="full"
    
    # 解析参数
    for arg in "$@"; do
        case "$arg" in
            --help)
                show_help
                exit 0
                ;;
            --analyze)
                action="analyze"
                ;;
            --version)
                echo "文档质量监控系统 v1.0"
                exit 0
                ;;
        esac
    done
    
    log_info "=== 开始文档质量监控 ==="
    
    # 1. 备份当前状态
    backup_current_state
    
    # 2. 分析文档质量
    shallow_docs=$(analyze_document_quality)
    
    # 3. 显示分析结果
    if [ -n "$shallow_docs" ]; then
        log_warning "发现 $(echo "$shallow_docs" | wc -l) 个浅层文档需要优化"
        echo "需要优化的文档:"
        echo "$shallow_docs"
    else
        log_info "没有发现浅层文档，所有文档质量良好"
    fi
    
    # 4. 生成总结报告
    generate_summary_report
    
    log_info "=== 文档质量监控完成 ==="
}

# 运行主函数
main "$@"