#!/bin/bash

# 简单的清理和增强脚本

REPO_DIR="/root/.openclaw/workspace/As-my-see"
echo "开始清理和增强文档..."

# 处理核心文档
process_document() {
    local file="$1"
    local category="$2"
    
    echo "处理: $(basename "$file")"
    
    # 1. 清理空行
    sed -i '/^$/N;/^\n$/D' "$file"
    
    # 2. 确保有标题
    if ! head -1 "$file" | grep -q "^# "; then
        local title=$(basename "$file" .md | sed 's/_/ /g')
        sed -i "1i# $title" "$file"
    fi
    
    # 3. 添加更新时间
    if ! grep -q "> 更新时间:" "$file"; then
        sed -i "2i> 更新时间: 2026年02月27日" "$file"
    fi
    
    # 4. 添加基本结构
    add_document_structure "$file" "$category"
    
    echo "  完成"
}

add_document_structure() {
    local file="$1"
    local category="$2"
    
    # 添加概述
    if ! grep -q "## 概述" "$file"; then
        echo "" >> "$file"
        echo "## 概述" >> "$file"
        echo "" >> "$file"
        echo "本文档介绍$category相关技术的基本概念、原理和应用。" >> "$file"
    fi
    
    # 添加技术原理
    if ! grep -q "## 技术原理" "$file"; then
        echo "" >> "$file"
        echo "## 技术原理" >> "$file"
        echo "" >> "$file"
        add_tech_content "$file" "$category"
    fi
    
    # 添加代码示例
    if ! grep -q "## 代码示例" "$file"; then
        echo "" >> "$file"
        echo "## 代码示例" >> "$file"
        echo "" >> "$file"
        add_code_example "$file" "$category"
    fi
    
    # 添加实践应用
    if ! grep -q "## 实践应用" "$file"; then
        echo "" >> "$file"
        echo "## 实践应用" >> "$file"
        echo "" >> "$file"
        echo "1. **学习路径**: 从基础到进阶的系统学习" >> "$file"
        echo "2. **项目实践**: 实际项目中的应用案例" >> "$file"
        echo "3. **最佳实践**: 经验总结和技巧分享" >> "$file"
        echo "4. **性能优化**: 提升效率和性能的方法" >> "$file"
    fi
    
    # 添加学习资源
    if ! grep -q "## 学习资源" "$file"; then
        echo "" >> "$file"
        echo "## 学习资源" >> "$file"
        echo "" >> "$file"
        echo "### 推荐资料" >> "$file"
        echo "1. 官方文档和教程" >> "$file"
        echo "2. 经典技术书籍" >> "$file"
        echo "3. 在线课程和视频" >> "$file"
        echo "4. 开源项目源码" >> "$file"
        echo "" >> "$file"
        echo "### 社区支持" >> "$file"
        echo "- Stack Overflow: 技术问答社区" >> "$file"
        echo "- GitHub: 开源项目平台" >> "$file"
        echo "- 相关技术论坛和博客" >> "$file"
    fi
}

add_tech_content() {
    local file="$1"
    local category="$2"
    
    case "$category" in
        "cpp")
            echo "C++是一种高效的编程语言，支持多种编程范式：" >> "$file"
            echo "" >> "$file"
            echo "### 核心特性" >> "$file"
            echo "1. **面向对象编程**: 类、继承、多态" >> "$file"
            echo "2. **泛型编程**: 模板和STL" >> "$file"
            echo "3. **低级内存操作**: 指针和引用" >> "$file"
            echo "4. **现代特性**: 智能指针、lambda表达式" >> "$file"
            ;;
        "qt")
            echo "Qt是一个跨平台的C++应用程序开发框架：" >> "$file"
            echo "" >> "$file"
            echo "### 核心组件" >> "$file"
            echo "1. **Qt Core**: 核心非GUI功能" >> "$file"
            echo "2. **Qt GUI**: 图形用户界面组件" >> "$file"
            echo "3. **Qt Widgets**: 扩展的UI控件" >> "$file"
            echo "4. **Qt Quick**: 声明式UI框架" >> "$file"
            ;;
        "linux")
            echo "Linux是一个开源的操作系统内核：" >> "$file"
            echo "" >> "$file"
            echo "### 系统架构" >> "$file"
            echo "1. **内核空间**: 核心系统功能" >> "$file"
            echo "2. **用户空间**: 应用程序运行环境" >> "$file"
            echo "3. **系统调用**: 用户程序与内核的接口" >> "$file"
            echo "4. **文件系统**: 数据存储和管理" >> "$file"
            ;;
        *)
            echo "深入理解技术原理是掌握该技术的关键：" >> "$file"
            echo "" >> "$file"
            echo "### 学习要点" >> "$file"
            echo "1. **基本概念**: 核心术语和定义" >> "$file"
            echo "2. **工作原理**: 技术实现机制" >> "$file"
            echo "3. **应用场景**: 适用领域和限制" >> "$file"
            echo "4. **发展趋势**: 技术演进方向" >> "$file"
            ;;
    esac
}

add_code_example() {
    local file="$1"
    local category="$2"
    
    case "$category" in
        "cpp")
            echo '```cpp' >> "$file"
            echo '// C++基础示例' >> "$file"
            echo '#include <iostream>' >> "$file"
            echo '' >> "$file"
            echo 'int main() {' >> "$file"
            echo '    std::cout << "Hello, C++!" << std::endl;' >> "$file"
            echo '    ' >> "$file"
            echo '    // 变量和类型' >> "$file"
            echo '    int number = 42;' >> "$file"
            echo '    double pi = 3.14159;' >> "$file"
            echo '    std::string message = "Learning C++";' >> "$file"
            echo '    ' >> "$file"
            echo '    std::cout << "Number: " << number << std::endl;' >> "$file"
            echo '    std::cout << "Pi: " << pi << std::endl;' >> "$file"
            echo '    std::cout << "Message: " << message << std::endl;' >> "$file"
            echo '    ' >> "$file"
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
            echo '    ' >> "$file"
            echo '    QLabel *label = new QLabel("Hello Qt!");' >> "$file"
            echo '    label->setAlignment(Qt::AlignCenter);' >> "$file"
            echo '    label->setWindowTitle("Qt Application");' >> "$file"
            echo '    label->resize(400, 300);' >> "$file"
            echo '    label->show();' >> "$file"
            echo '    ' >> "$file"
            echo '    return app.exec();' >> "$file"
            echo '}' >> "$file"
            echo '```' >> "$file"
            ;;
        "linux")
            echo '```bash' >> "$file"
            echo '#!/bin/bash' >> "$file"
            echo '# Linux Shell脚本示例' >> "$file"
            echo '' >> "$file"
            echo 'echo "系统信息:"' >> "$file"
            echo 'echo "主机名: $(hostname)"' >> "$file"
            echo 'echo "内核版本: $(uname -r)"' >> "$file"
            echo 'echo "系统时间: $(date)"' >> "$file"
            echo '' >> "$file"
            echo '# 文件操作' >> "$file"
            echo 'echo "当前目录文件:"' >> "$file"
            echo 'ls -la' >> "$file"
            echo '' >> "$file"
            echo '# 进程检查' >> "$file"
            echo 'echo "运行中的进程:"' >> "$file"
            echo 'ps aux | head -10' >> "$file"
            echo '' >> "$file"
            echo 'echo "脚本执行完成"' >> "$file"
            echo '```' >> "$file"
            ;;
        *)
            echo '```python' >> "$file"
            echo '# Python示例代码' >> "$file"
            echo 'def main():' >> "$file"
            echo '    print("Hello, World!")' >> "$file"
            echo '    ' >> "$file"
            echo '    # 基本操作' >> "$file"
            echo '    numbers = [1, 2, 3, 4, 5]' >> "$file"
            echo '    total = sum(numbers)' >> "$file"
            echo '    average = total / len(numbers)' >> "$file"
            echo '    ' >> "$file"
            echo '    print(f"数字列表: {numbers}")' >> "$file"
            echo '    print(f"总和: {total}")' >> "$file"
            echo '    print(f"平均值: {average}")' >> "$file"
            echo '' >> "$file"
            echo 'if __name__ == "__main__":' >> "$file"
            echo '    main()' >> "$file"
            echo '```' >> "$file"
            ;;
    esac
}

# 处理核心文档
echo "=== 处理核心文档 ==="
process_document "$REPO_DIR/docs/cpp/C++多线程.md" "cpp"
process_document "$REPO_DIR/docs/qt/1_Qt.md" "qt"
process_document "$REPO_DIR/docs/linux/Shell脚本.md" "linux"
process_document "$REPO_DIR/docs/robotics/SLAM的基本知识.md" "robotics"
process_document "$REPO_DIR/docs/ros/ROS编程.md" "ros"

echo ""
echo "=== 完成 ==="
echo "文档清理和增强完成"
echo "建议下一步："
echo "1. 检查文档结构是否完整"
echo "2. 补充具体的技术细节"
echo "3. 添加更多实际应用案例"
echo "4. 更新图片和示例代码"