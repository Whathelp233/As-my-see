#!/bin/bash
# doc_quality_analyzer.sh - 文档质量分析器

DOCS_DIR="/root/.openclaw/workspace/As-my-see/docs"
REPORT_FILE="/root/.openclaw/workspace/As-my-see/document_quality_report_$(date +%Y%m%d_%H%M%S).md"

echo "# 📊 文档质量分析报告" > "$REPORT_FILE"
echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 初始化统计
total_files=0
shallow_files=0
good_files=0
duplicate_files=0
shallow_list=()
duplicate_list=()

# 查找所有文档
echo "正在分析文档..." >&2

# 按目录分析
for category_dir in "$DOCS_DIR"/*/; do
    category=$(basename "$category_dir")
    
    if [ -d "$category_dir" ]; then
        echo "## 📁 $category" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "| 文档 | 行数 | 状态 | 建议 |" >> "$REPORT_FILE"
        echo "|------|------|------|------|" >> "$REPORT_FILE"
        
        category_files=0
        category_shallow=0
        
        # 按文件名排序，便于发现重复
        find "$category_dir" -name "*.md" -type f | sort | while read doc; do
            total_files=$((total_files + 1))
            category_files=$((category_files + 1))
            
            filename=$(basename "$doc")
            rel_path=${doc#$DOCS_DIR/}
            
            # 检查是否重复（带 _1, _2 等后缀）
            base_name="${filename%.md}"
            if [[ "$base_name" =~ _[0-9]+$ ]]; then
                original_name="${base_name%_*}.md"
                duplicate_files=$((duplicate_files + 1))
                duplicate_list+=("$rel_path (重复于: $original_name)")
                status="🟡 重复"
                suggestion="考虑删除或合并"
            else
                # 分析内容
                lines=$(wc -l < "$doc" 2>/dev/null || echo "0")
                has_titles=$(grep -c "^#" "$doc" 2>/dev/null || echo "0")
                has_code=$(grep -c "^```" "$doc" 2>/dev/null || echo "0")
                
                # 判断质量
                if [ "$lines" -lt 30 ]; then
                    status="🔴 过浅"
                    suggestion="需要大幅扩充"
                    shallow_files=$((shallow_files + 1))
                    category_shallow=$((category_shallow + 1))
                    shallow_list+=("$rel_path ($lines 行)")
                elif [ "$lines" -lt 100 ]; then
                    status="🟡 一般"
                    suggestion="建议补充内容"
                    shallow_files=$((shallow_files + 1))
                    category_shallow=$((category_shallow + 1))
                    shallow_list+=("$rel_path ($lines 行)")
                elif [ "$has_titles" -eq 0 ]; then
                    status="🟡 无结构"
                    suggestion="添加标题结构"
                    shallow_files=$((shallow_files + 1))
                    category_shallow=$((category_shallow + 1))
                    shallow_list+=("$rel_path ($lines 行)")
                else
                    status="🟢 良好"
                    suggestion="保持"
                    good_files=$((good_files + 1))
                fi
            fi
            
            echo "| $rel_path | $lines | $status | $suggestion |" >> "$REPORT_FILE"
        done
        
        echo "" >> "$REPORT_FILE"
        echo "**统计**: $category_files 个文档，其中 $category_shallow 个需要优化" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
done

# 总结
echo "# 📈 总体统计" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "- **总文档数**: $total_files" >> "$REPORT_FILE"
echo "- **质量良好**: $good_files ($(echo "scale=1; $good_files * 100 / $total_files" | bc)%)" >> "$REPORT_FILE"
echo "- **需要优化**: $shallow_files ($(echo "scale=1; $shallow_files * 100 / $total_files" | bc)%)" >> "$REPORT_FILE"
echo "- **重复文档**: $duplicate_files ($(echo "scale=1; $duplicate_files * 100 / $total_files" | bc)%)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 需要优化的文档列表
if [ ${#shallow_list[@]} -gt 0 ]; then
    echo "# 🔧 需要优化的文档" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "以下 ${#shallow_list[@]} 个文档需要优化（行数少于100或结构简单）：" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    for doc in "${shallow_list[@]:0:20}"; do  # 只显示前20个
        echo "- $doc" >> "$REPORT_FILE"
    done
    if [ ${#shallow_list[@]} -gt 20 ]; then
        echo "- ... 还有 $((${#shallow_list[@]} - 20)) 个" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
fi

# 重复文档列表
if [ ${#duplicate_list[@]} -gt 0 ]; then
    echo "# 🔄 重复文档" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "以下 ${#duplicate_list[@]} 个文档可能是重复的：" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    for doc in "${duplicate_list[@]:0:10}"; do  # 只显示前10个
        echo "- $doc" >> "$REPORT_FILE"
    done
    if [ ${#duplicate_list[@]} -gt 10 ]; then
        echo "- ... 还有 $((${#duplicate_list[@]} - 10)) 个" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
fi

# 建议
echo "# 🎯 优化建议" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "## 立即行动" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "1. **优先优化核心文档**：选择3-5个最重要的技术文档进行深度优化" >> "$REPORT_FILE"
echo "2. **清理重复文档**：删除或合并带 `_1`, `_2` 等后缀的重复文档" >> "$REPORT_FILE"
echo "3. **建立文档标准**：参考质量良好的文档，制定文档编写规范" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "## 自动化建议" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "1. **设置定时分析**：每周自动运行文档质量分析" >> "$REPORT_FILE"
echo "2. **自动备份**：优化前自动备份原文档" >> "$REPORT_FILE"
echo "3. **质量监控**：设置文档质量阈值，自动提醒" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "## 长期维护" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "1. **定期审查**：每月审查文档质量，持续优化" >> "$REPORT_FILE"
echo "2. **版本控制**：使用Git管理文档版本" >> "$REPORT_FILE"
echo "3. **协作规范**：建立团队文档协作流程" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 显示到控制台
echo "=== 文档质量分析完成 ==="
echo "报告文件: $REPORT_FILE"
echo ""
echo "📊 总体统计:"
echo "  总文档数: $total_files"
echo "  质量良好: $good_files ($(echo "scale=1; $good_files * 100 / $total_files" | bc)%)"
echo "  需要优化: $shallow_files ($(echo "scale=1; $shallow_files * 100 / $total_files" | bc)%)"
echo "  重复文档: $duplicate_files ($(echo "scale=1; $duplicate_files * 100 / $total_files" | bc)%)"
echo ""
if [ ${#shallow_list[@]} -gt 0 ]; then
    echo "🔧 需要优化的文档（前10个）:"
    for doc in "${shallow_list[@]:0:10}"; do
        echo "  - $doc"
    done
fi