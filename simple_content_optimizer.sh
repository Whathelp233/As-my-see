#!/bin/bash

# 简单内容优化器
# 1. 标记短文档
# 2. 添加改进建议
# 3. 生成分析报告

REPO_DIR="/root/.openclaw/workspace/As-my-see"
REPORT_FILE="$REPO_DIR/文档质量分析_$(date +%Y%m%d).md"

echo "# 文档质量分析报告" > "$REPORT_FILE"
echo "**生成时间**: $(date '+%Y-%m-%d %H:%M:%S')" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "## 📊 文档统计" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 统计总数
total_files=$(find "$REPO_DIR/docs" -name "*.md" | wc -l)
echo "- **总文档数**: $total_files" >> "$REPORT_FILE"

# 按类别统计
echo "" >> "$REPORT_FILE"
echo "### 按类别统计" >> "$REPORT_FILE"
for dir in "$REPO_DIR/docs"/*/; do
    if [ -d "$dir" ]; then
        category=$(basename "$dir")
        count=$(find "$dir" -name "*.md" | wc -l)
        echo "- **$category**: $count 个" >> "$REPORT_FILE"
    fi
done

echo "" >> "$REPORT_FILE"
echo "## ⚠️ 需要优化的文档" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 分析每个文档
shallow_count=0
for file in $(find "$REPO_DIR/docs" -name "*.md"); do
    lines=$(wc -l < "$file")
    title=$(head -1 "$file" | sed 's/^# //')
    
    # 如果文档很短（少于40行）
    if [ $lines -lt 40 ]; then
        ((shallow_count++))
        echo "### $title" >> "$REPORT_FILE"
        echo "- **文件**: $(basename "$file")" >> "$REPORT_FILE"
        echo "- **行数**: $lines 行" >> "$REPORT_FILE"
        echo "- **分类**: $(basename $(dirname "$file"))" >> "$REPORT_FILE"
        echo "- **状态**: 内容较浅，建议扩展" >> "$REPORT_FILE"
        
        # 添加改进建议
        echo "" >> "$REPORT_FILE"
        echo "#### 改进建议" >> "$REPORT_FILE"
        echo "1. 添加更多代码示例" >> "$REPORT_FILE"
        echo "2. 补充实际应用场景" >> "$REPORT_FILE"
        echo "3. 添加相关资源链接" >> "$REPORT_FILE"
        echo "4. 扩展理论知识" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        
        # 在文档中添加标记
        if ! grep -q "## 内容优化建议" "$file"; then
            echo "" >> "$file"
            echo "## 内容优化建议" >> "$file"
            echo "" >> "$file"
            echo "> 此文档内容较为简略，建议补充以下内容：" >> "$file"
            echo "" >> "$file"
            echo "1. **代码示例**: 添加实际可运行的代码" >> "$file"
            echo "2. **应用场景**: 说明在实际项目中的用途" >> "$file"
            echo "3. **最佳实践**: 分享经验教训和技巧" >> "$file"
            echo "4. **扩展阅读**: 链接到相关学习资源" >> "$file"
            echo "" >> "$file"
            echo "*最后检查: $(date '+%Y-%m-%d %H:%M:%S')*" >> "$file"
        fi
    fi
done

echo "" >> "$REPORT_FILE"
echo "## 📈 分析总结" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

percentage=$(echo "scale=1; $shallow_count * 100 / $total_files" | bc)
echo "- **需要优化的文档**: $shallow_count 个 ($percentage%)" >> "$REPORT_FILE"
echo "- **状态良好的文档**: $((total_files - shallow_count)) 个" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "### 优化优先级" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "1. **高优先级**: 核心技术文档（C++、Qt、Linux）" >> "$REPORT_FILE"
echo "2. **中优先级**: 专业领域文档（机器人、ROS、视觉）" >> "$REPORT_FILE"
echo "3. **低优先级**: 通用技术文档" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "### 行动建议" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "1. **立即行动**: 选择3-5个核心文档进行深度优化" >> "$REPORT_FILE"
echo "2. **短期计划**: 每周优化10-15个文档" >> "$REPORT_FILE"
echo "3. **长期维护**: 建立文档质量标准和更新机制" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "## 🔍 网络搜索建议" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "对于需要优化的文档，建议搜索以下关键词获取更多内容：" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "- **技术文档**: \"[主题] 高级教程 2024\"" >> "$REPORT_FILE"
echo "- **实践案例**: \"[主题] 实战项目 github\"" >> "$REPORT_FILE"
echo "- **官方资源**: \"[主题] official documentation\"" >> "$REPORT_FILE"
echo "- **社区讨论**: \"[主题] stackoverflow reddit\"" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "---" >> "$REPORT_FILE"
echo "*报告生成完成，建议定期（每月）重新分析文档质量*" >> "$REPORT_FILE"

echo "✅ 文档分析完成！"
echo "📊 分析报告: $REPORT_FILE"
echo "📝 共分析 $total_files 个文档，其中 $shallow_count 个需要优化"
echo "🔧 已在需要优化的文档中添加改进建议"