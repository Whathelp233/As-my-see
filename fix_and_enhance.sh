#!/bin/bash

# 修复和增强脚本

REPO_DIR="/root/.openclaw/workspace/As-my-see"
echo "开始修复图片路径和增强文档内容..."

# 1. 首先修复图片路径
echo "=== 修复图片路径 ==="
for file in $(find "$REPO_DIR/docs" -name "*.md"); do
    filename=$(basename "$file")
    docname=$(basename "$file" .md)
    dirname=$(dirname "$file")
    
    echo "处理: $filename"
    
    # 创建assets目录
    assets_dir="$dirname/${docname}.assets"
    mkdir -p "$assets_dir"
    
    # 修复图片引用
    sed -i "s|(${docname}_files/|(./${docname}.assets/|g" "$file"
    sed -i "s|(${docname}.assets/|(./${docname}.assets/|g" "$file"
    
    # 查找图片文件
    find "$dirname" -name "${docname}*.png" -o -name "${docname}*.jpg" -o -name "${docname}*.jpeg" -o -name "${docname}*.gif" -o -name "${docname}*.svg" | while read img_file; do
        if [ -f "$img_file" ]; then
            img_name=$(basename "$img_file")
            cp "$img_file" "$assets_dir/"
            echo "  复制图片: $img_name"
        fi
    done
    
    # 检查_files目录
    if [ -d "$dirname/${docname}_files" ]; then
        cp "$dirname/${docname}_files"/* "$assets_dir/" 2>/dev/null
        echo "  复制_files目录内容"
    fi
done

echo "图片路径修复完成"
echo ""

# 2. 增强核心文档内容
echo "=== 增强文档内容 ==="

# 定义要增强的核心文档
CORE_DOCS=(
    "docs/cpp/C++多线程.md"
    "docs/qt/1_Qt.md"
    "docs/linux/Shell脚本.md"
    "docs/robotics/SLAM的基本知识.md"
    "docs/ros/ROS编程.md"
)

for doc_path in "${CORE_DOCS[@]}"; do
    full_path="$REPO_DIR/$doc_path"
    if [ -f "$full_path" ]; then
        echo "增强: $(basename "$full_path")"
        enhance_document "$full_path"
    else
        echo "未找到: $doc_path"
    fi
done

echo "文档增强完成"

# 增强单个文档
enhance_document() {
    local file="$1"
    local title=$(head -1 "$file" | sed 's/^# //')
    local category=$(basename $(dirname "$file"))
    
    echo "  正在增强: $title ($category)"
    
    # 添加技术原理部分
    if ! grep -q "## 技术原理" "$file"; then
        echo "" >> "$file"
        echo "## 技术原理" >> "$file"
        echo "" >> "$file"
        
        case "$category" in
            "cpp")
                echo "C++多线程编程基于操作系统提供的线程API，通过标准库进行抽象封装。" >> "$file"
                echo "核心概念包括线程创建、同步机制、内存模型和原子操作。" >> "$file"
                ;;
            "qt")
                echo "Qt是一个跨平台的C++应用程序框架，采用元对象系统实现信号槽机制。" >> "$file"
                echo "核心特性包括图形界面、网络通信、数据库访问和多线程支持。" >> "$file"
                ;;
            "linux")
                echo "Shell是Linux系统的命令解释器，提供用户与内核交互的接口。" >> "$file"
                echo "Shell脚本通过组合系统命令和编程结构实现自动化任务。" >> "$file"
                ;;
            *)
                echo "深入理解技术的基本原理和设计思想是掌握该技术的关键。" >> "$file"
                ;;
        esac
    fi
    
    # 添加代码示例
    if [ $(grep -c "^```" "$file") -lt 2 ]; then
        echo "" >> "$file"
        echo "## 代码示例" >> "$file"
        echo "" >> "$file"
        
        case "$category" in
            "cpp")
                echo '```cpp' >> "$file"
                echo '// C++多线程示例' >> "$file"
                echo '#include <iostream>' >> "$file"
                echo '#include <thread>' >> "$file"
                echo '' >> "$file"
                echo 'void hello() {' >> "$file"
                echo '    std::cout << "Hello from thread!" << std::endl;' >> "$file"
                echo '}' >> "$file"
                echo '' >> "$file"
                echo 'int main() {' >> "$file"
                echo '    std::thread t(hello);' >> "$file"
                echo '    t.join();' >> "$file"
                echo '    return 0;' >> "$file"
                echo '}' >> "$file"
                echo '```' >> "$file"
                ;;
            "qt")
                echo '```cpp' >> "$file"
                echo '// Qt简单示例' >> "$file"
                echo '#include <QApplication>' >> "$file"
                echo '#include <QLabel>' >> "$file"
                echo '' >> "$file"
                echo 'int main(int argc, char *argv[]) {' >> "$file"
                echo '    QApplication app(argc, argv);' >> "$file"
                echo '    QLabel label("Hello Qt!");' >> "$file"
                echo '    label.show();' >> "$file"
                echo '    return app.exec();' >> "$file"
                echo '}' >> "$file"
                echo '```' >> "$file"
                ;;
            *)
                echo '```bash' >> "$file"
                echo '# Shell脚本示例' >> "$file"
                echo '#!/bin/bash' >> "$file"
                echo '' >> "$file"
                echo 'echo "当前目录: $(pwd)"' >> "$file"
                echo 'echo "文件列表:"' >> "$file"
                echo 'ls -la' >> "$file"
                echo '```' >> "$file"
                ;;
        esac
    fi
    
    # 添加实践应用
    if ! grep -q "## 实践应用" "$file"; then
        echo "" >> "$file"
        echo "## 实践应用" >> "$file"
        echo "" >> "$file"
        echo "1. **学习建议**: 从简单示例开始，逐步增加复杂度" >> "$file"
        echo "2. **项目实践**: 将知识应用到实际项目中" >> "$file"
        echo "3. **调试技巧**: 使用调试工具分析问题" >> "$file"
        echo "4. **性能优化**: 关注代码效率和资源使用" >> "$file"
    fi
    
    # 添加学习资源
    if ! grep -q "## 学习资源" "$file"; then
        echo "" >> "$file"
        echo "## 学习资源" >> "$file"
        echo "" >> "$file"
        echo "### 推荐资料" >> "$file"
        echo "1. 官方文档和教程" >> "$file"
        echo "2. 相关技术书籍" >> "$file"
        echo "3. 在线课程和视频" >> "$file"
        echo "4. 开源项目源码" >> "$file"
        echo "" >> "$file"
        echo "### 社区支持" >> "$file"
        echo "- Stack Overflow" >> "$file"
        echo "- GitHub Discussions" >> "$file"
        echo "- 技术论坛和博客" >> "$file"
    fi
    
    echo "  增强完成"
}

echo ""
echo "=== 完成 ==="
echo "已修复图片路径并增强核心文档"
echo "建议: 查看增强后的文档，根据需要进行进一步优化"