#!/bin/bash

# 文档优化脚本

echo "📝 开始文档内容优化..."
echo "时间: $(date)"
echo ""

BASE_DIR="/root/.openclaw/workspace/As-my-see"
LOG_FILE="$BASE_DIR/optimization.log"

# 优化单个文档
optimize_document() {
    local file="$1"
    local temp_file="${file}.tmp"
    
    echo "优化: $(basename "$file")"
    
    # 1. 读取文件内容
    local content=$(cat "$file")
    
    # 2. 确保有标题
    if ! echo "$content" | head -1 | grep -q "^# "; then
        # 从文件名生成标题
        local filename=$(basename "$file" .md)
        local title=$(echo "$filename" | sed 's/_/ /g' | sed 's/-/ /g')
        content="# $title"$'\n\n'"$content"
    fi
    
    # 3. 标准化标题格式
    content=$(echo "$content" | sed 's/^#\+ /# /g')
    
    # 4. 添加更新时间（如果还没有）
    if ! echo "$content" | grep -q "更新时间:"; then
        # 在标题后添加更新时间
        local update_line="> 更新时间: $(date '+%Y年%m月%d日')"
        content=$(echo "$content" | sed "1a\\$update_line")
    fi
    
    # 5. 添加目录（如果文档较长）
    local line_count=$(echo "$content" | wc -l)
    if [ $line_count -gt 50 ]; then
        # 简单目录生成
        local toc=""
        echo "$content" | grep "^## " | head -5 | while read heading; do
            local clean_heading=$(echo "$heading" | sed 's/^## //')
            local anchor=$(echo "$clean_heading" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
            toc+="- [$clean_heading](#$anchor)"$'\n'
        done
        
        if [ -n "$toc" ]; then
            # 在标题后插入目录
            content=$(echo "$content" | sed "2a\\"$'\n'"## 目录"$'\n'"$toc")
        fi
    fi
    
    # 6. 保存优化后的内容
    echo "$content" > "$temp_file"
    
    # 7. 检查文件大小变化
    local original_size=$(wc -c < "$file")
    local new_size=$(wc -c < "$temp_file")
    
    if [ $new_size -gt 0 ]; then
        mv "$temp_file" "$file"
        echo "  ✅ 优化完成 (+$((new_size - original_size)) 字节)"
    else
        rm -f "$temp_file"
        echo "  ⚠️  优化失败，保留原文件"
    fi
}

# 批量优化目录
optimize_directory() {
    local dir="$1"
    local pattern="${2:-*.md}"
    
    echo ""
    echo "优化目录: $dir"
    echo "────────────"
    
    local total_files=0
    local optimized_files=0
    
    find "$dir" -name "$pattern" -type f | while read file; do
        total_files=$((total_files + 1))
        
        # 优化文档
        optimize_document "$file"
        
        if [ $? -eq 0 ]; then
            optimized_files=$((optimized_files + 1))
        fi
        
        # 每处理10个文件显示进度
        if [ $((total_files % 10)) -eq 0 ]; then
            echo "  进度: $total_files 个文件"
        fi
    done
    
    echo ""
    echo "📊 完成: $optimized_files/$total_files 个文件已优化"
}

# 为文档添加标准结构
add_standard_structure() {
    local file="$1"
    local category="$2"
    
    echo "增强: $(basename "$file")"
    
    # 读取文件内容
    local content=$(cat "$file")
    local temp_file="${file}.enhanced"
    
    # 根据类别添加标准章节
    case "$category" in
        */qt|*/cpp|*/ros|*/robotics)
            # 技术文档结构
            local enhanced_content="$content"$'\n\n'"---"$'\n\n'
            enhanced_content+="## 📚 扩展阅读"$'\n\n'
            enhanced_content+="### 官方文档"$'\n'
            enhanced_content+="- [相关官方文档链接]()"$'\n\n'
            enhanced_content+="### 学习资源"$'\n'
            enhanced_content+="- [推荐教程]()"$'\n'
            enhanced_content+="- [示例代码]()"$'\n\n'
            enhanced_content+="### 常见问题"$'\n'
            enhanced_content+="1. **问题描述**"$'\n'
            enhanced_content+="   解决方案"$'\n\n'
            enhanced_content+="## 🛠️ 实践建议"$'\n\n'
            enhanced_content+="1. **学习路径**"$'\n'
            enhanced_content+="2. **实践项目**"$'\n'
            enhanced_content+="3. **调试技巧**"$'\n\n'
            enhanced_content+="> 最后更新: $(date '+%Y-%m-%d') | 由OpenClaw优化"
            ;;
        
        */notes/*)
            # 学习笔记结构
            local enhanced_content="$content"$'\n\n'"---"$'\n\n'
            enhanced_content+="## 💡 学习总结"$'\n\n'
            enhanced_content+="### 核心要点"$'\n'
            enhanced_content+="1. " $'\n'
            enhanced_content+="2. " $'\n'
            enhanced_content+="3. " $'\n\n'
            enhanced_content+="### 疑问与思考"$'\n'
            enhanced_content+="- " $'\n\n'
            enhanced_content+="### 下一步计划"$'\n'
            enhanced_content+="1. " $'\n'
            enhanced_content+="2. " $'\n\n'
            enhanced_content+="## 🔗 相关资源"$'\n\n'
            enhanced_content+="> 学习时间: $(date '+%Y-%m-%d') | 笔记优化"
            ;;
        
        */projects/*)
            # 项目记录结构
            local enhanced_content="$content"$'\n\n'"---"$'\n\n'
            enhanced_content+="## 📊 项目状态"$'\n\n'
            enhanced_content+="### 当前进展"$'\n'
            enhanced_content+="- [ ] 阶段1: " $'\n'
            enhanced_content+="- [ ] 阶段2: " $'\n'
            enhanced_content+="- [ ] 阶段3: " $'\n\n'
            enhanced_content+="### 遇到的问题"$'\n'
            enhanced_content+="1. " $'\n'
            enhanced_content+="2. " $'\n\n'
            enhanced_content+="### 解决方案"$'\n'
            enhanced_content+="1. " $'\n'
            enhanced_content+="2. " $'\n\n'
            enhanced_content+="## 🎯 下一步行动"$'\n\n'
            enhanced_content+="> 项目记录: $(date '+%Y-%m-%d') | 持续更新"
            ;;
        
        *)
            # 通用结构
            local enhanced_content="$content"$'\n\n'"---"$'\n\n'
            enhanced_content+="## 📝 文档信息"$'\n\n'
            enhanced_content+="- **创建时间**: [请补充]"$'\n'
            enhanced_content+="- **最后更新**: $(date '+%Y-%m-%d')"$'\n'
            enhanced_content+="- **文档类型**: $(basename $(dirname "$file"))"$'\n'
            enhanced_content+="- **优化状态**: ✅ 已标准化"$'\n\n'
            enhanced_content+="## 🔍 内容概述"$'\n\n'
            enhanced_content+="> 本文档已由OpenClaw文档优化系统处理，结构已标准化。"$'\n\n'
            enhanced_content+="## 💡 使用建议"$'\n\n'
            enhanced_content+="1. 定期回顾和更新内容"$'\n'
            enhanced_content+="2. 补充实际案例和代码"$'\n'
            enhanced_content+="3. 添加相关资源链接"$'\n'
            ;;
    esac
    
    # 保存增强版
    echo "$enhanced_content" > "$temp_file"
    mv "$temp_file" "$file"
    
    echo "  ✅ 结构增强完成"
}

# 批量增强文档结构
enhance_structures() {
    echo ""
    echo "🚀 开始增强文档结构..."
    echo "────────────────────"
    
    # 优化技术文档
    echo "处理技术文档..."
    for subdir in qt cpp linux robotics ros vision embedded; do
        if [ -d "$BASE_DIR/docs/$subdir" ]; then
            find "$BASE_DIR/docs/$subdir" -name "*.md" -type f | head -5 | while read file; do
                add_standard_structure "$file" "docs/$subdir"
            done
        fi
    done
    
    # 优化学习笔记
    echo ""
    echo "处理学习笔记..."
    for subdir in signals learning math electronics; do
        if [ -d "$BASE_DIR/notes/$subdir" ]; then
            find "$BASE_DIR/notes/$subdir" -name "*.md" -type f | head -3 | while read file; do
                add_standard_structure "$file" "notes/$subdir"
            done
        fi
    done
    
    echo ""
    echo "✅ 文档结构增强完成"
}

# 生成优化报告
generate_optimization_report() {
    echo ""
    echo "📊 优化完成报告"
    echo "──────────────"
    echo "报告时间: $(date)"
    echo ""
    
    # 统计各目录文件数
    echo "📁 文档分布统计:"
    for category in docs notes projects resources; do
        local count=$(find "$BASE_DIR/$category" -name "*.md" -type f 2>/dev/null | wc -l)
        if [ $count -gt 0 ]; then
            echo "  $category/: $count 个文档"
        fi
    done
    
    # 显示示例文件
    echo ""
    echo "📋 优化示例:"
    find "$BASE_DIR" -name "*.md" -type f -newer "$LOG_FILE" 2>/dev/null | head -3 | while read file; do
        local filename=$(basename "$file")
        local size=$(wc -l < "$file")
        echo "  • $filename ($size 行)"
    done
    
    local total_files=$(find "$BASE_DIR" -name "*.md" -type f 2>/dev/null | wc -l)
    echo ""
    echo "📈 总计: $total 个文档已就绪"
    echo "🎉 优化阶段完成!"
}

# 主函数
main() {
    echo "🚀 文档优化系统启动"
    echo "=================="
    
    # 1. 优化docs目录
    optimize_directory "$BASE_DIR/docs"
    
    # 2. 优化notes目录
    optimize_directory "$BASE_DIR/notes"
    
    # 3. 优化projects目录
    optimize_directory "$BASE_DIR/projects"
    
    # 4. 优化resources目录
    optimize_directory "$BASE_DIR/resources"
    
    # 5. 增强文档结构
    enhance_structures
    
    # 6. 生成报告
    generate_optimization_report
    
    echo ""
    echo "✅ 文档内容优化完成!"
    echo "下一步: 知识扩展和网络搜索补充"
}

# 执行主函数
main 2>&1 | tee -a "$LOG_FILE"