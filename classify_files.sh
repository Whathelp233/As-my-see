#!/bin/bash

# 文档分类脚本

echo "📁 开始文档分类整理..."
echo "时间: $(date)"
echo ""

BASE_DIR="/root/.openclaw/workspace/As-my-see"
LOG_FILE="$BASE_DIR/classification.log"

# 创建标准目录
create_directories() {
    echo "创建标准目录结构..."
    
    # 主目录
    mkdir -p "$BASE_DIR"/{docs,notes,projects,resources,templates,daily_reports,domain_guides}
    
    # 子目录
    mkdir -p "$BASE_DIR"/docs/{qt,cpp,linux,robotics,ros,vision,embedded,general}
    mkdir -p "$BASE_DIR"/notes/{signals,systems,programming,learning,math,electronics}
    mkdir -p "$BASE_DIR"/projects/{ros-projects,vision-projects,slam-projects,embedded-projects,qt-projects}
    mkdir -p "$BASE_DIR"/resources/{tools,tutorials,books,images,links,configs}
    
    echo "✅ 目录结构创建完成"
}

# 分类函数
classify_file() {
    local file="$1"
    local filename=$(basename "$file")
    
    # 基于文件名和内容的分类
    case "$filename" in
        # Qt相关 -> docs/qt
        *[Qq]t*|*控件*|*对话框*|*菜单栏*|*Lambda*|*对象树*)
            echo "docs/qt"
            ;;
        # C++相关 -> docs/cpp
        *[Cc]++*|*游戏编程*|*多线程*)
            echo "docs/cpp"
            ;;
        # Linux相关 -> docs/linux
        *[Ll]inux*|*Shell*|*脚本*|*SSH*|*ubuntu*)
            echo "docs/linux"
            ;;
        # ROS相关 -> docs/ros
        *[Rr][Oo][Ss]*|*URDF*|*TF*|*激光雷达*)
            echo "docs/ros"
            ;;
        # 机器人学 -> docs/robotics
        *机器人*|*SLAM*|*运动学*|*动力学*|*控制*|*传感器*|*电机*)
            echo "docs/robotics"
            ;;
        # 视觉相关 -> docs/vision
        *视觉*|*图像*|*色彩*|*形态学*)
            echo "docs/vision"
            ;;
        # 嵌入式 -> docs/embedded
        *[Cc][Aa][Nn]*|*STM32*|*Arduino*|*嵌入式*|*EtherCAT*)
            echo "docs/embedded"
            ;;
        # 信号处理 -> notes/signals
        *信号*|*系统*|*阶跃*|*冲激*)
            echo "notes/signals"
            ;;
        # 数学 -> notes/math
        *数学*|*线性代数*|*拉格朗日*|*易经*)
            echo "notes/math"
            ;;
        # 电子 -> notes/electronics
        *电子*|*电路*|*第三章*)
            echo "notes/electronics"
            ;;
        # 学习笔记 -> notes/learning
        *学习*|*笔记*|*总结*|*心得*)
            echo "notes/learning"
            ;;
        # 项目记录 -> projects
        *项目*|*案例*|*建立*|*部署*)
            # 进一步细分
            if [[ "$filename" =~ [Rr][Oo][Ss] ]]; then
                echo "projects/ros-projects"
            elif [[ "$filename" =~ [Ss][Ll][Aa][Mm] ]]; then
                echo "projects/slam-projects"
            elif [[ "$filename" =~ [Vv]ision ]]; then
                echo "projects/vision-projects"
            else
                echo "projects"
            fi
            ;;
        # 资源文件 -> resources
        *资源*|*工具*|*教程*|*配置*|*样式*|*Markdown*|*Python*|*Latex*)
            echo "resources"
            ;;
        # 默认 -> docs/general
        *)
            echo "docs/general"
            ;;
    esac
}

# 处理单个文件
process_file() {
    local file="$1"
    local target_dir="$2"
    
    local filename=$(basename "$file")
    local target_path="$target_dir/$filename"
    
    # 处理重名文件
    if [ -f "$target_path" ]; then
        local counter=1
        local name="${filename%.*}"
        local ext="${filename##*.}"
        
        while [ -f "$target_path" ]; do
            target_path="$target_dir/${name}_${counter}.${ext}"
            counter=$((counter + 1))
        done
    fi
    
    # 移动文件
    mv "$file" "$target_path"
    echo "  📄 $filename → $(basename "$target_dir")/"
}

# 主分类函数
classify_all_files() {
    echo "开始分类所有文档..."
    echo ""
    
    local total_files=0
    local moved_files=0
    
    # 查找所有markdown文件（排除已分类目录）
    find "$BASE_DIR" -name "*.md" -type f | grep -v "/docs/\|/notes/\|/projects/\|/resources/" | while read file; do
        total_files=$((total_files + 1))
        
        # 获取分类
        local category=$(classify_file "$file")
        local target_dir="$BASE_DIR/$category"
        
        # 确保目标目录存在
        mkdir -p "$target_dir"
        
        # 处理文件
        process_file "$file" "$target_dir"
        moved_files=$((moved_files + 1))
        
        # 每处理10个文件显示进度
        if [ $((moved_files % 10)) -eq 0 ]; then
            echo "  已处理: $moved_files/$total_files"
        fi
    done
    
    echo ""
    echo "✅ 分类完成!"
    echo "📊 统计: 处理了 $moved_files 个文件"
}

# 处理子目录
process_subdirectories() {
    echo "处理现有子目录..."
    echo ""
    
    # 需要处理的子目录列表
    local subdirs=("Linux" "ROS" "vision" "基础概念" "机器人学" "激光SLAM" "ros2" "Markdown" "杂项（特殊需要）")
    
    for subdir in "${subdirs[@]}"; do
        if [ -d "$BASE_DIR/$subdir" ]; then
            echo "处理目录: $subdir"
            
            # 移动目录中的文件到相应分类
            find "$BASE_DIR/$subdir" -name "*.md" -type f 2>/dev/null | while read file; do
                local category=$(classify_file "$file")
                local target_dir="$BASE_DIR/$category"
                
                mkdir -p "$target_dir"
                process_file "$file" "$target_dir"
            done
            
            # 删除空目录
            rmdir "$BASE_DIR/$subdir" 2>/dev/null && echo "  删除空目录: $subdir"
        fi
    done
}

# 生成分类报告
generate_report() {
    echo ""
    echo "📊 分类完成报告"
    echo "──────────────"
    echo "生成时间: $(date)"
    echo ""
    
    echo "📁 各分类文档数量:"
    for category in docs notes projects resources; do
        local count=$(find "$BASE_DIR/$category" -name "*.md" -type f 2>/dev/null | wc -l)
        if [ $count -gt 0 ]; then
            echo "  $category/: $count 个文档"
            
            # 显示子分类
            if [ -d "$BASE_DIR/$category" ]; then
                find "$BASE_DIR/$category" -maxdepth 1 -type d | grep -v "^$BASE_DIR/$category$" | while read subdir; do
                    local subcount=$(find "$subdir" -name "*.md" -type f 2>/dev/null | wc -l)
                    if [ $subcount -gt 0 ]; then
                        echo "    $(basename "$subdir"): $subcount"
                    fi
                done
            fi
        fi
    done
    
    # 总文件数
    local total=$(find "$BASE_DIR" -name "*.md" -type f 2>/dev/null | wc -l)
    echo ""
    echo "📈 总计: $total 个Markdown文档"
    
    # 未分类文件
    local uncategorized=$(find "$BASE_DIR" -name "*.md" -type f -path "*/docs/general/*" 2>/dev/null | wc -l)
    if [ $uncategorized -gt 0 ]; then
        echo "⚠️  未分类文件: $uncategorized 个 (在 docs/general/)"
    fi
}

# 主函数
main() {
    echo "🚀 文档分类系统启动"
    echo "=================="
    
    # 创建目录
    create_directories
    
    # 处理子目录
    process_subdirectories
    
    # 分类所有文件
    classify_all_files
    
    # 生成报告
    generate_report
    
    echo ""
    echo "🎉 分类整理完成!"
    echo "下一步: 开始内容优化和知识扩展"
}

# 执行主函数
main 2>&1 | tee "$LOG_FILE"