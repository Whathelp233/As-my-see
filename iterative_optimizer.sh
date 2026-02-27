#!/bin/bash

# 迭代优化脚本 - 修复图片路径并深度优化内容

REPO_DIR="/root/.openclaw/workspace/As-my-see"
LOG_FILE="$REPO_DIR/iteration_$(date +%Y%m%d_%H%M%S).log"
OPTIMIZED_COUNT=0

echo "=== 开始迭代优化 ===" | tee "$LOG_FILE"
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
echo "目录: $REPO_DIR" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# 第一步：修复所有文档的图片路径
echo "1. 修复图片路径..." | tee -a "$LOG_FILE"

for file in $(find "$REPO_DIR/docs" -name "*.md"); do
    echo "处理: $(basename "$file")" | tee -a "$LOG_FILE"
    
    # 获取文档基本信息
    filename=$(basename "$file")
    docname=$(basename "$file" .md)
    dirname=$(dirname "$file")
    
    # 创建对应的assets目录
    assets_dir="$dirname/${docname}.assets"
    mkdir -p "$assets_dir"
    
    # 修复图片引用
    sed -i "s|(${docname}_files/|(./${docname}.assets/|g" "$file"
    sed -i "s|(${docname}.assets/|(./${docname}.assets/|g" "$file"
    
    # 查找并移动图片文件
    for img_file in "$dirname/${docname}"*.{png,jpg,jpeg,gif,svg} "$dirname/${docname}_files/"*.{png,jpg,jpeg,gif,svg} 2>/dev/null; do
        if [ -f "$img_file" ]; then
            img_name=$(basename "$img_file")
            cp "$img_file" "$assets_dir/"
            echo "  移动图片: $img_name -> ${docname}.assets/" | tee -a "$LOG_FILE"
        fi
    done
done

echo "图片路径修复完成" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# 第二步：深度优化内容（按优先级）
echo "2. 深度优化文档内容..." | tee -a "$LOG_FILE"

# 定义优化优先级（核心技术优先）
PRIORITY_CATEGORIES=("cpp" "qt" "linux" "robotics" "ros")

for category in "${PRIORITY_CATEGORIES[@]}"; do
    category_dir="$REPO_DIR/docs/$category"
    if [ -d "$category_dir" ]; then
        echo "优化类别: $category" | tee -a "$LOG_FILE"
        
        # 每个类别优化前5个文档
        for file in $(find "$category_dir" -name "*.md" | head -5); do
            optimize_single_document "$file" "$category"
            ((OPTIMIZED_COUNT++))
        done
    fi
done

# 优化函数
optimize_single_document() {
    local file="$1"
    local category="$2"
    local title=$(head -1 "$file" | sed 's/^# //')
    
    echo "  优化: $title" | tee -a "$LOG_FILE"
    
    # 1. 确保有完整的基本结构
    ensure_basic_structure "$file" "$title"
    
    # 2. 添加技术深度内容
    add_technical_depth "$file" "$category" "$title"
    
    # 3. 添加实用代码示例
    add_practical_examples "$file" "$category"
    
    # 4. 添加学习资源
    add_learning_resources "$file" "$category" "$title"
    
    echo "  完成优化: $title" | tee -a "$LOG_FILE"
}

# 确保基本结构
ensure_basic_structure() {
    local file="$1"
    local title="$2"
    
    # 确保有标题
    if ! head -1 "$file" | grep -q "^# "; then
        sed -i "1i# $title" "$file"
    fi
    
    # 添加更新时间
    if ! grep -q "> 更新时间:" "$file"; then
        sed -i "2i> 更新时间: $(date '+%Y年%m月%d日')" "$file"
        echo "" >> "$file"
    fi
    
    # 添加目录（如果文档较长）
    local line_count=$(wc -l < "$file")
    if [ $line_count -gt 100 ] && ! grep -q "## 目录" "$file"; then
        sed -i "3i## 目录" "$file"
        sed -i "4i" "$file"
        # 这里可以添加自动生成目录的逻辑
    fi
}

# 添加技术深度内容
add_technical_depth() {
    local file="$1"
    local category="$2"
    local title="$3"
    
    # 检查是否已有技术内容
    if grep -q "## 技术原理\|## 实现细节\|## 架构设计" "$file"; then
        return
    fi
    
    echo "## 技术深度" >> "$file"
    echo "" >> "$file"
    
    case "$category" in
        "cpp")
            cat >> "$file" << 'EOF'
### 内存管理
现代C++提供了多种内存管理方式：

1. **智能指针**
   - `std::unique_ptr`: 独占所有权，不可复制
   - `std::shared_ptr`: 共享所有权，引用计数
   - `std::weak_ptr`: 弱引用，避免循环引用

2. **移动语义**
   ```cpp
   class Resource {
       std::vector<int> data;
   public:
       // 移动构造函数
       Resource(Resource&& other) noexcept 
           : data(std::move(other.data)) {}
       
       // 移动赋值运算符
       Resource& operator=(Resource&& other) noexcept {
           if (this != &other) {
               data = std::move(other.data);
           }
           return *this;
       }
   };
   ```

3. **RAII (Resource Acquisition Is Initialization)**
   资源获取即初始化，确保资源自动释放。

### 模板编程
C++模板提供了强大的泛型编程能力：
- 函数模板
- 类模板
- 可变参数模板
- 模板特化
EOF
            ;;
        "qt")
            cat >> "$file" << 'EOF'
### 信号与槽机制
Qt的信号与槽是其核心特性：

1. **连接方式**
   ```cpp
   // 传统方式（需要元对象系统）
   connect(sender, SIGNAL(valueChanged(int)), receiver, SLOT(updateValue(int)));
   
   // 新式语法（编译时检查）
   connect(sender, &Sender::valueChanged, receiver, &Receiver::updateValue);
   
   // Lambda表达式
   connect(button, &QPushButton::clicked, []() {
       qDebug() << "Button clicked!";
   });
   ```

2. **线程间通信**
   ```cpp
   // 跨线程信号槽连接（自动排队）
   connect(worker, &Worker::resultReady, guiThreadObject, &GuiObject::handleResult, Qt::QueuedConnection);
   ```

### 图形渲染
Qt支持多种渲染后端：
- 软件渲染
- OpenGL
- Vulkan
- Direct3D
EOF
            ;;
        "linux")
            cat >> "$file" << 'EOF'
### 进程管理
Linux进程管理的核心概念：

1. **进程状态**
   ```
   R - 运行或可运行
   S - 可中断睡眠
   D - 不可中断睡眠
   T - 停止状态
   Z - 僵尸进程
   ```

2. **进程间通信**
   - 管道 (pipe)
   - 信号 (signal)
   - 消息队列 (message queue)
   - 共享内存 (shared memory)
   - 信号量 (semaphore)
   - 套接字 (socket)

### 文件系统
Linux支持多种文件系统：
- ext4: 最常用的Linux文件系统
- XFS: 高性能日志文件系统  
- Btrfs: 支持快照和压缩
- ZFS: 高级文件系统（需要额外模块）
EOF
            ;;
        *)
            cat >> "$file" << 'EOF'
### 核心概念
深入理解技术的基本原理：

1. **设计原则**
   - 单一职责原则
   - 开闭原则
   - 里氏替换原则
   - 接口隔离原则
   - 依赖倒置原则

2. **性能考量**
   - 时间复杂度分析
   - 空间复杂度优化
   - 缓存友好设计
   - 并发处理策略
EOF
            ;;
    esac
    
    echo "" >> "$file"
}

# 添加实用代码示例
add_practical_examples() {
    local file="$1"
    local category="$2"
    
    # 检查是否已有足够代码示例
    local code_count=$(grep -c "^```" "$file")
    if [ $code_count -ge 3 ]; then
        return
    fi
    
    echo "## 代码示例" >> "$file"
    echo "" >> "$file"
    
    case "$category" in
        "cpp")
            cat >> "$file" << 'EOF'
### 基础示例
```cpp
#include <iostream>
#include <vector>
#include <algorithm>

// 使用现代C++特性
void modern_cpp_example() {
    std::vector<int> numbers = {3, 1, 4, 1, 5, 9, 2, 6};
    
    // 使用auto和lambda
    auto print = [](int n) { std::cout << n << " "; };
    
    std::cout << "原始数据: ";
    std::for_each(numbers.begin(), numbers.end(), print);
    std::cout << std::endl;
    
    // 排序
    std::sort(numbers.begin(), numbers.end());
    
    std::cout << "排序后: ";
    std::for_each(numbers.begin(), numbers.end(), print);
    std::cout << std::endl;
    
    // 使用算法
    auto it = std::find(numbers.begin(), numbers.end(), 5);
    if (it != numbers.end()) {
        std::cout << "找到数字5" << std::endl;
    }
}

int main() {
    modern_cpp_example();
    return 0;
}
```
EOF
            ;;
        "qt")
            cat >> "$file" << 'EOF'
### 简单窗口应用
```cpp
#include <QApplication>
#include <QWidget>
#include <QLabel>
#include <QVBoxLayout>

class SimpleWindow : public QWidget {
public:
    SimpleWindow(QWidget *parent = nullptr) : QWidget(parent) {
        // 创建组件
        QLabel *titleLabel = new QLabel("Qt示例应用", this);
        titleLabel->setAlignment(Qt::AlignCenter);
        titleLabel->setStyleSheet("font-size: 20px; font-weight: bold;");
        
        QLabel *contentLabel = new QLabel(
            "这是一个简单的Qt应用程序示例。\n"
            "展示了基本的窗口创建和布局管理。", this);
        contentLabel->setAlignment(Qt::AlignCenter);
        
        // 设置布局
        QVBoxLayout *layout = new QVBoxLayout(this);
        layout->addWidget(titleLabel);
        layout->addWidget(contentLabel);
        layout->addStretch();
        
        // 窗口设置
        setWindowTitle("Qt示例");
        resize(400, 300);
        setStyleSheet("background-color: #f0f0f0;");
    }
};

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    SimpleWindow window;
    window.show();
    return app.exec();
}
```
EOF
            ;;
        *)
            cat >> "$file" << 'EOF'
### 基础示例
```python
def comprehensive_example():
    """综合示例函数"""
    # 数据结构示例
    data = {
        'numbers': [1, 2, 3, 4, 5],
        'names': ['Alice', 'Bob', 'Charlie'],
        'settings': {'debug': True, 'version': '1.0'}
    }
    
    # 数据处理
    processed = {
        'sum': sum(data['numbers']),
        'count': len(data['names']),
        'average': sum(data['numbers']) / len(data['numbers'])
    }
    
    # 输出结果
    print("原始数据:", data)
    print("处理结果:", processed)
    
    return processed

# 类示例
class ExampleProcessor:
    def __init__(self, data):
        self.data = data
        self.results = {}
    
    def process(self):
        """处理数据"""
        if 'numbers' in self.data:
            self.results['sum'] = sum(self.data['numbers'])
            self.results['average'] = self.results['sum'] / len(self.data['numbers'])
        
        return self.results
    
    def display(self):
        """显示结果"""
        print("处理完成:")
        for key, value in self.results.items():
            print(f"  {key}: {value}")

# 使用示例
if __name__ == "__main__":
    # 函数调用
    result = comprehensive_example()
    
    # 类使用
    processor = ExampleProcessor({'numbers': [10, 20, 30, 40, 50]})
    processor.process()
    processor.display()
```
EOF
            ;;
    esac
    
    echo "" >> "$file"
}

# 添加学习资源
add_learning_resources() {
    local file="$1"
    local category="$2"
    local title="$3"
    
    echo "## 学习资源" >> "$file"
    echo "" >> "$file"
    
    case "$category" in
        "cpp")
            cat >> "$file" << 'EOF'
### 官方文档
- [C++ Reference](https://en.cppreference.com/) - 最全面的C++参考
- [isocpp.org](https://isocpp.org/) - C++标准委员会官网
- [C++ Core Guidelines](https://github.com/isocpp/CppCoreGuidelines) - C++核心指南

### 推荐书籍
1. **《C++ Primer》** - 经典入门书籍
2. **《Effective Modern C++》** - 现代C++最佳实践
3. **《The C++ Programming Language》** - Bjarne Stroustrup 著作

### 在线课程
- [Coursera: C++专项课程](https://www.coursera.org/specializations/coding-cpp)
- [Udemy: C++完整课程](https://www.udemy.com/topic/c-plus-plus/)
- [LearnCpp.com](https://www.learncpp.com/) - 免费教程

### 实践项目
1. 实现一个简单的文本编辑器
2. 编写一个多线程网络服务器
3. 创建一个小型游戏引擎
EOF
            ;;
        "qt")
            cat >> "$file" << 'EOF'
### 官方资源
- [Qt官方文档](https://doc.qt.io/) - 完整API文档和教程
- [Qt示例](https://doc.qt.io/qt-6/examples.html) - 官方示例代码
- [Qt论坛](https://forum.qt.io/) - 开发者社区

### 学习路径
1. **基础阶段**: Qt Widgets编程
2. **进阶阶段**: QML和Qt Quick
3. **高级阶段**: 多线程、网络、数据库

### 中文资源
- [Qt中文网](http://www.qtcn.org/) - 中文社区和资源
- [鱼香ROS的Qt教程](https://fishros.com/#/docs/tutorials/advanced/qt_basic/) - 实践导向教程

### 项目实践
1. 开发一个简单的计算器
2. 创建一个文件管理器
3. 实现一个聊天应用
EOF
            ;;
        *)
            cat >> "$file" << 'EOF'
### 学习建议
1. **官方文档优先**: 总是先查阅官方文档
2. **实践驱动学习**: 通过项目实践加深理解
3. **社区参与**: 参与相关技术社区讨论

### 资源推荐
- [Stack Overflow](https://stackoverflow.com/) - 技术问答社区
- [GitHub](https://github.com/) - 开源项目学习
- [MDN Web Docs](https://developer.mozilla.org/) - Web技术文档

### 持续学习
1. 关注技术博客和新闻
2. 参加技术会议和研讨会
3. 阅读源代码和设计文档
EOF
            ;;
    esac
    
    echo "" >> "$file"
}

# 运行优化
for category in "${PRIORITY_CATEGORIES[@]}"; do
    category_dir="$REPO_DIR/docs/$category"
    if [ -d "$category_dir" ]; then
        echo "优化类别: $category" | tee -a "$LOG_FILE"
        
        for file in $(find "$category_dir" -name "*.md" | head -5); do
            optimize_single_document "$file" "$category"
            ((OPTIMIZED_COUNT++))
        done
    fi
done

echo "" | tee -a "$LOG_FILE"
echo "=== 优化完成 ===" | tee -a "$LOG_FILE"
echo "优化文档数: $OPTIMIZED_COUNT" | tee -a "$LOG_FILE"
echo "日志文件: $LOG_FILE" | tee -a "$LOG_FILE"
echo "建议: 查看优化后的文档，根据需要进一步调整内容" | tee -a "$LOG_FILE"