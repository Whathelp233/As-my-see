#!/bin/bash
# mini_doc_analyzer.sh - 极简文档分析器

DOCS_DIR="/root/.openclaw/workspace/As-my-see/docs"
REPORT_FILE="/root/.openclaw/workspace/As-my-see/doc_report_$(date +%Y%m%d).txt"

echo "文档质量分析报告 - $(date)" > "$REPORT_FILE"
echo "======================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 统计
echo "文档统计:" >> "$REPORT_FILE"
total=0
shallow=0

find "$DOCS_DIR" -name "*.md" -type f | while read doc; do
    total=$((total + 1))
    lines=$(wc -l < "$doc" 2>/dev/null || echo "0")
    
    if [ "$lines" -lt 50 ]; then
        shallow=$((shallow + 1))
        echo "[浅层] $doc ($lines 行)" >> "$REPORT_FILE"
    else
        echo "[良好] $doc ($lines 行)" >> "$REPORT_FILE"
    fi
done

echo "" >> "$REPORT_FILE"
echo "总结:" >> "$REPORT_FILE"
echo "总文档数: $total" >> "$REPORT_FILE"
echo "浅层文档: $shallow" >> "$REPORT_FILE"
echo "良好文档: $((total - shallow))" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [ "$shallow" -gt 0 ]; then
    echo "建议优化以下 $shallow 个浅层文档:" >> "$REPORT_FILE"
    find "$DOCS_DIR" -name "*.md" -type f -exec sh -c '
        lines=$(wc -l < "$1" 2>/dev/null || echo "0")
        if [ "$lines" -lt 50 ]; then
            echo "  - $1 ($lines 行)"
        fi
    ' _ {} \; >> "$REPORT_FILE"
fi

# 显示结果
cat "$REPORT_FILE"
echo ""
echo "报告已保存到: $REPORT_FILE"