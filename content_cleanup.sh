#!/bin/bash

# 内容清理与优化脚本
# 1. 移除重复内容
# 2. 合并相似文档
# 3. 标记浅显内容

set -e

REPO_DIR="/root/.openclaw/workspace/As-my-see"
LOG_FILE="$REPO_DIR/content_cleanup.log"
BACKUP_DIR="$REPO_DIR/backup_$(date +%Y%m%d_%H%M%S)"

# 创建备份
mkdir -p "$BACKUP_DIR"
cp -r "$REPO_DIR/docs" "$BACKUP_DIR/"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 查找并标记重复内容
find_duplicates() {
    log "查找重复内容..."
    
    # 创建文档指纹（前100个非空行）
    declare -A fingerprints
    declare -A file_map
    
    for file in $(find "$REPO_DIR/docs" -name "*.md"); do
        local fingerprint=$(head -100 "$file" | grep -v "^#" | grep -v "^$" | grep -v "^---" | md5sum | cut -d' ' -f1)
        local filename=$(basename "$file")
        
        if [ -n "${fingerprints[$fingerprint]}" ]; then
            log "发现重复: $filename 与 ${file_map[$fingerprint]}"
            echo "# ⚠️ 注意: 此文档内容与 ${file_map[$fingerprint]} 相似" >> "$file"
        else
            fingerprints[$fingerprint]=1
            file_map[$fingerprint]="$filename"
        fi
    done
}

# 评估文档深度
assess_document_depth() {
    local file="$1"
    local content=$(cat "$file")
    
    # 计算指标
    local total_lines=$(echo "$content" | wc -l)
    local code_blocks=$(echo "$content" | grep -c "^```")
    local headings=$(echo "$content" | grep -c "^#")
    local links=$(echo "$content" | grep -c "\[.*\](.*)")
    
    # 深度评分
    local score=$((code_blocks * 10 + headings * 5 + links * 3))
    
    if [ $total_lines -lt 30 ]; then
        echo "shallow"
    elif [ $score -lt 50 ]; then
        echo "medium"
    else
        echo "deep"
    fi
}

# 标记浅显文档
mark_shallow_documents() {
    log "标记浅显文档..."
    
    for file in $(find "$REPO_DIR/docs" -name "*.md"); do
        local depth=$(assess_document_depth "$file")
        
        if [ "$depth" = "shallow" ]; then
            local title=$(head -1 "$file" | sed 's/^# //')
            log "标记浅显文档: $title"
            
            # 添加标记
            if ! grep -q "## 内容深度评估" "$file"; then
                echo -e "\n## 内容深度评估\n\n⚠️ **此文档内容较浅，建议补充以下内容**:\n\n1. 更多代码示例\n2. 实际应用场景\n3. 性能考虑\n4. 最佳实践\n5. 相关资源链接\n\n*最后评估时间: $(date '+%Y-%m-%d %H:%M:%S')*" >> "$file"
            fi
        fi
    done
}

# 合并相似文档
merge_similar_documents() {
    log "分析相似文档进行合并..."
    
    # 按类别处理
    for category_dir in "$REPO_DIR/docs"/*/; do
        if [ -d "$category_dir" ]; then
            local category=$(basename "$category_dir")
            log "处理类别: $category"
            
            # 这里可以添加具体的合并逻辑
            # 例如：查找标题相似的文档
            find "$category_dir" -name "*.md" -exec basename {} \; | sort | uniq -c | grep -v "^\s*1"
        fi
    done
}

# 添加网络搜索建议
add_web_search_suggestions() {
    log "为浅显文档添加网络搜索建议..."
    
    for file in $(find "$REPO_DIR/docs" -name "*.md"); do
        if grep -q "内容较浅" "$file"; then
            local title=$(head -1 "$file" | sed 's/^# //')
            local category=$(basename $(dirname "$file"))
            
            # 添加搜索建议
            if ! grep -q "## 扩展学习建议" "$file"; then
                cat >> "$file" << EOF

## 扩展学习建议

### 推荐搜索关键词
1. "$title 高级教程"
2. "$title 实战案例"
3. "$title 最佳实践"
4. "$title 常见问题"

### 优质学习资源
- **官方文档**: 搜索 "$title official documentation"
- **视频教程**: 搜索 "$title tutorial 2024"
- **开源项目**: GitHub 搜索 "$title example"
- **技术社区**: Stack Overflow, Reddit r/$category

### 实践项目建议
1. 实现一个简单的 $title 应用
2. 阅读相关开源项目源码
3. 参与技术社区讨论
4. 撰写技术博客分享心得

*提示: 使用英文关键词通常能找到更多最新资源*
EOF
            fi
        fi
    done
}

# 生成优化报告
generate_report() {
    log "生成优化报告..."
    
    local report_file="$REPO_DIR/优化报告_$(date +%Y%m%d).md"
    
    cat > "$report_file" << EOF
# 文档内容优化报告

**生成时间**: $(date '+%Y-%m-%d %H:%M:%S')
**分析目录**: $REPO_DIR/docs

## 📊 统计概览

### 文档深度分布
EOF
    
    # 统计深度分布
    local shallow=0
    local medium=0
    local deep=0
    
    for file in $(find "$REPO_DIR/docs" -name "*.md"); do
        local depth=$(assess_document_depth "$file")
        case $depth in
            "shallow") ((shallow++)) ;;
            "medium") ((medium++)) ;;
            "deep") ((deep++)) ;;
        esac
    done
    
    local total=$((shallow + medium + deep))
    
    cat >> "$report_file" << EOF
- **浅显文档**: $shallow 个 ($(echo "scale=1; $shallow*100/$total" | bc)%)
- **中等深度**: $medium 个 ($(echo "scale=1; $medium*100/$total" | bc)%)
- **深度文档**: $deep 个 ($(echo "scale=1; $deep*100/$total" | bc)%)

### 类别分布
EOF
    
    # 按类别统计
    for category_dir in "$REPO_DIR/docs"/*/; do
        if [ -d "$category_dir" ]; then
            local category=$(basename "$category_dir")
            local count=$(find "$category_dir" -name "*.md" | wc -l)
            echo "- **$category**: $count 个文档" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << EOF

## 🔧 优化措施

### 已执行
1. ✅ 标记重复内容文档
2. ✅ 评估并标记浅显文档
3. ✅ 添加网络搜索建议
4. ✅ 创建文档备份

### 建议后续操作
1. **内容深化**: 为 $shallow 个浅显文档补充深度内容
2. **重复处理**: 合并或重写重复内容
3. **结构优化**: 统一文档格式标准
4. **知识更新**: 检查技术时效性

## 📁 浅显文档列表

以下文档被标记为内容较浅，建议优先补充：
EOF
    
    # 列出浅显文档
    for file in $(find "$REPO_DIR/docs" -name "*.md"); do
        if grep -q "内容较浅" "$file"; then
            local title=$(head -1 "$file" | sed 's/^# //')
            local path=$(echo "$file" | sed "s|$REPO_DIR/||")
            echo "- [$title]($path)" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << EOF

## 📈 改进建议

### 短期目标（1周内）
1. 选择5-10个关键文档进行深度优化
2. 建立文档质量评估标准
3. 制定内容更新计划

### 中期目标（1个月内）
1. 完成所有浅显文档的优化
2. 建立知识关联网络
3. 引入自动化质量检查

### 长期目标（3个月内）
1. 形成完整的技术知识体系
2. 建立社区贡献机制
3. 定期发布技术更新

## 🔗 相关资源

- [备份目录]($(basename "$BACKUP_DIR"))
- [优化日志]($(basename "$LOG_FILE"))
- [GitHub仓库](https://github.com/Whathelp233/As-my-see)

---

*报告生成于 $(date '+%Y年%m月%d日 %H:%M')，下次建议评估时间: $(date -d "+7 days" '+%Y-%m-%d')*
EOF
    
    log "优化报告已生成: $report_file"
}

# 主函数
main() {
    log "开始文档内容优化..."
    
    # 执行优化步骤
    find_duplicates
    mark_shallow_documents
    add_web_search_suggestions
    generate_report
    
    log "文档内容优化完成！"
    log "备份保存在: $BACKUP_DIR"
    log "优化报告: $REPO_DIR/优化报告_$(date +%Y%m%d).md"
    log "详细日志: $LOG_FILE"
}

# 运行主函数
main "$@"