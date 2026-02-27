#!/bin/bash
# simple_document_analyzer.sh
# 简单的文档质量分析器

set -e

# 配置
DOCS_DIR="/root/.openclaw/workspace/As-my-see/docs"
REPORT_FILE="/root/.openclaw/workspace/As-my-see/document_analysis_$(date +%Y%m%d).md"
BACKUP_DIR="/root/.openclaw/workspace/As-my-see/backups"

# 创建目录
mkdir -p "$BACKUP_DIR"

echo "# 文档质量分析报告" > "$REPORT_FILE"
echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 备份当前状态
echo "## 1. 备份当前状态" >> "$REPORT_FILE"
backup_file="$BACKUP_DIR/docs_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
cd "/root/.openclaw/workspace/As-my-see"
tar -czf "$backup_file" docs/ 2>/dev/null || true
echo "- 备份文件: $(basename "$backup_file") ($(du -h "$backup_file" | cut -f1))" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 统计文档
echo "## 2. 文档统计" >> "$REPORT_FILE"
total_files=$(find "$DOCS_DIR" -name "*.md" -type f | wc -l)
echo "- 文档总数: $total_files" >> "$REPORT_FILE"

# 按目录统计
echo "- 按目录统计:" >> "$REPORT_FILE"
find "$DOCS_DIR" -type d | while read dir; do
    count=$(find "$dir" -maxdepth 1 -name "*.md" -type f | wc -l)
    if [ "$count" -gt 0 ]; then
        rel_dir=${dir#$DOCS_DIR/}
        echo "  - $rel_dir: $count 个文档" >> "$REPORT_FILE"
    fi
done
echo "" >> "$REPORT_FILE"

# 分析文档质量
echo "## 3. 文档质量分析" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "| 文档 | 行数 | 状态 | 建议 |" >> "$REPORT_FILE"
echo "|------|------|------|------|" >> "$REPORT_FILE"

shallow_docs=()
good_docs=()

for doc in $(find "$DOCS_DIR" -name "*.md" -type f); do
    filename=$(basename "$doc")
    rel_path=${doc#$DOCS_DIR/}
    
    # 计算行数
    line_count=$(wc -l < "$doc" 2>/dev/null || echo "0")
    
    # 分析内容
    has_titles=$(grep -c "^#" "$doc" 2>/dev/null || echo "0")
    has_code=$(grep -c "^```" "$doc" 2>/dev/null || echo "0")
    has_lists=$(grep -c "^- " "$doc" 2>/dev/null || echo "0")
    
    # 判断质量
    if [ "$line_count" -lt 30 ]; then
        status="🔴 过浅"
        suggestion="需要大幅扩充"
        shallow_docs+=("$rel_path")
    elif [ "$line_count" -lt 100 ]; then
        status="🟡 一般"
        suggestion="建议补充内容"
        shallow_docs+=("$rel_path")
    elif [ "$has_titles" -eq 0 ]; then
        status="🟡 无结构"
        suggestion="添加标题结构"
        shallow_docs+=("$rel_path")
    else
        status="🟢 良好"
        suggestion="保持"
        good_docs+=("$rel_path")
    fi
    
    echo "| $rel_path | $line_count | $status | $suggestion |" >> "$REPORT_FILE"
done

echo "" >> "$REPORT_FILE"

# 总结
echo "## 4. 总结与建议" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [ ${#shallow_docs[@]} -gt 0 ]; then
    echo "### 需要优化的文档 (${#shallow_docs[@]}个):" >> "$REPORT_FILE"
    for doc in "${shallow_docs[@]}"; do
        echo "- $doc" >> "$REPORT_FILE"
    done
    echo "" >> "$REPORT_FILE"
    echo "**建议**: 优先优化这些文档，增加技术深度和实用性。" >> "$REPORT_FILE"
else
    echo "✅ 所有文档质量良好！" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"
echo "### 质量良好的文档 (${#good_docs[@]}个):" >> "$REPORT_FILE"
echo "这些文档可以作为其他文档的参考标准。" >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"
echo "## 5. 下一步行动" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "1. **立即优化**: 选择3-5个最重要的浅层文档进行深度优化" >> "$REPORT_FILE"
echo "2. **定期检查**: 每周运行一次本分析脚本" >> "$REPORT_FILE"
echo "3. **建立标准**: 参考质量良好的文档，建立文档编写标准" >> "$REPORT_FILE"
echo "4. **自动化**: 设置定时任务，自动监控文档质量" >> "$REPORT_FILE"

# 输出到控制台
echo "=== 文档质量分析完成 ==="
echo "报告文件: $REPORT_FILE"
echo "备份文件: $backup_file"
echo ""
echo "文档统计:"
echo "- 总计: $total_files 个文档"
echo "- 需要优化: ${#shallow_docs[@]} 个"
echo "- 质量良好: ${#good_docs[@]} 个"
echo ""
if [ ${#shallow_docs[@]} -gt 0 ]; then
    echo "需要优化的文档:"
    for doc in "${shallow_docs[@]:0:10}"; do  # 只显示前10个
        echo "  - $doc"
    done
    if [ ${#shallow_docs[@]} -gt 10 ]; then
        echo "  ... 还有 $((${#shallow_docs[@]} - 10)) 个"
    fi
fi