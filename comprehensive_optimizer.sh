#!/bin/bash

# 综合优化脚本：修复图片路径 + 深度内容优化

set -e

REPO_DIR="/root/.openclaw/workspace/As-my-see"
LOG_FILE="$REPO_DIR/optimization_iteration_$(date +%Y%m%d_%H%M%S).log"
ITERATION=1
MAX_ITERATIONS=3

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# 修复图片路径
fix_image_paths() {
    local file="$1"
    local fixed=0
    
    # 检查并修复图片路径
    while IFS= read -r line; do
        # 查找图片引用
        if [[ "$line" =~ \!\[.*\]\(.*\.(png|jpg|jpeg|gif|svg)\) ]]; then
            local img_path=$(echo "$line" | sed -n 's/.*](\(.*\))/\1/p')
            local filename=$(basename "$file")
            local dirname=$(dirname "$file")
            local doc_name=$(basename "$file" .md)
            
            # 如果图片路径是相对路径且包含文档名
            if [[ "$img_path" == *"$doc_name"* ]] && [[ "$img_path" != /* ]]; then
                # 创建正确的assets目录
                local assets_dir="$dirname/${doc_name}.assets"
                mkdir -p "$assets_dir"
                
                # 尝试查找并移动图片
                local img_name=$(basename "$img_path")
                local possible_locations=(
                    "$dirname/$img_name"
                    "$dirname/$img_path"
                    "$REPO_DIR/$img_path"
                    "$dirname/${doc_name}_files/$img_name"
                )
                
                for location in "${possible_locations[@]}"; do
                    if [ -f "$location" ]; then
                        cp "$location" "$assets_dir/"
                        local new_path="./${doc_name}.assets/$img_name"
                        sed -i "s|$img_path|$new_path|g" "$file"
                        ((fixed++))
                        log "修复图片路径: $img_path -> $new_path"
                        break
                    fi
                done
            fi
        fi
    done < "$file"
    
    if [ $fixed -gt 0 ]; then
        success "修复了 $fixed 个图片路径"
    fi
}

# 评估文档质量
assess_quality() {
    local file="$1"
    
    local lines=$(wc -l < "$file")
    local code_blocks=$(grep -c "^```" "$file")
    local headings=$(grep -c "^#" "$file")
    local images=$(grep -c "!\[.*\](" "$file")
    local links=$(grep -c "\[.*\](http" "$file")
    
    # 质量评分
    local score=$((lines + code_blocks*20 + headings*5 + images*10 + links*5))
    
    if [ $lines -lt 50 ]; then
        echo "poor"
    elif [ $score -lt 100 ]; then
        echo "fair"
    elif [ $score -lt 200 ]; then
        echo "good"
    else
        echo "excellent"
    fi
}

# 为文档添加深度内容
enhance_document() {
    local file="$1"
    local category="$2"
    local title="$3"
    
    log "深度优化文档: $title"
    
    # 读取当前内容
    local content=$(cat "$file")
    
    # 1. 确保有清晰的标题
    if ! echo "$content" | head -1 | grep -q "^# "; then
        sed -i "1s/^/# $title\n\n/" "$file"
    fi
    
    # 2. 添加更新时间
    if ! grep -q "> 更新时间:" "$file"; then
        sed -i "2s/^/> 更新时间: $(date '+%Y年%m月%d日')\n\n/" "$file"
    fi
    
    # 3. 根据类别添加专业内容
    add_technical_content "$file" "$category" "$title"
    
    # 4. 添加代码示例（如果缺少）
    if [ $(grep -c "^```" "$file") -lt 2 ]; then
        add_code_examples "$file" "$category" "$title"
    fi
    
    # 5. 添加实践应用部分
    if ! grep -q "## 实践应用" "$file"; then
        add_practical_applications "$file" "$category" "$title"
    fi
    
    # 6. 添加常见问题
    if ! grep -q "## 常见问题" "$file"; then
        add_faq "$file" "$category" "$title"
    fi
    
    # 7. 添加扩展资源
    if ! grep -q "## 扩展资源" "$file"; then
        add_resources "$file" "$category" "$title"
    fi
    
    success "文档深度优化完成: $title"
}

# 添加技术内容
add_technical_content() {
    local file="$1"
    local category="$2"
    local title="$3"
    
    case "$category" in
        "qt")
            cat >> "$file" << 'EOF'

## 技术原理

### Qt 对象模型
Qt 使用独特的对象模型，核心特性包括：

1. **元对象系统 (Meta-Object System)**
   - 提供运行时类型信息 (RTTI)
   - 支持信号与槽机制
   - 实现属性系统

2. **内存管理**
   - 父子对象关系自动管理内存
   - QObject 派生类的自动清理
   - 智能指针的使用

3. **事件系统**
   - 事件循环 (Event Loop)
   - 事件过滤器 (Event Filter)
   - 自定义事件处理

### 架构设计
Qt 采用模块化设计，主要模块包括：
- **QtCore**: 核心非 GUI 功能
- **QtGui**: 基础 GUI 组件
- **QtWidgets**: 扩展的 GUI 组件
- **QtQuick**: 声明式 UI 框架
- **QtNetwork**: 网络编程支持
EOF
            ;;
        "cpp")
            cat >> "$file" << 'EOF'

## 技术原理

### 内存模型
C++ 内存管理涉及多个层次：

1. **存储期 (Storage Duration)**
   - 自动存储期 (栈内存)
   - 静态存储期 (全局/静态变量)
   - 动态存储期 (堆内存)
   - 线程存储期 (thread_local)

2. **内存对齐**
   ```cpp
   struct alignas(16) AlignedData {
       int x;
       double y;
       char z;
   };
   ```

3. **智能指针体系**
   - `std::unique_ptr`: 独占所有权
   - `std::shared_ptr`: 共享所有权
   - `std::weak_ptr`: 弱引用，打破循环

### 模板元编程
```cpp
// 编译时计算斐波那契数列
template<int N>
struct Fibonacci {
    static const int value = Fibonacci<N-1>::value + Fibonacci<N-2>::value;
};

template<>
struct Fibonacci<0> {
    static const int value = 0;
};

template<>
struct Fibonacci<1> {
    static const int value = 1;
};

// 使用
static_assert(Fibonacci<10>::value == 55, "Fibonacci test");
```
EOF
            ;;
        "linux")
            cat >> "$file" << 'EOF'

## 技术原理

### Linux 内核架构
```
用户空间 (User Space)
    ↓
系统调用接口 (System Call Interface)
    ↓
内核空间 (Kernel Space)
├── 进程管理 (Process Management)
├── 内存管理 (Memory Management)
├── 文件系统 (File Systems)
├── 设备驱动 (Device Drivers)
├── 网络协议栈 (Network Stack)
└── 虚拟文件系统 (Virtual File System)
```

### 进程管理
1. **进程描述符 (task_struct)**
   - 包含进程所有信息
   - 通过双向链表组织
   - 支持进程状态转换

2. **调度器 (Scheduler)**
   - CFS (完全公平调度器)
   - 实时调度类
   - 调度策略和优先级

### 内存管理
1. **虚拟内存系统**
   - 分页机制
   - 页面缓存
   - 交换空间

2. **内存分配器**
   - 伙伴系统 (Buddy System)
   - SLAB 分配器
   - kmalloc/vmalloc
EOF
            ;;
        *)
            cat >> "$file" << 'EOF'

## 技术原理

### 核心概念
深入理解技术的基本原理和设计思想：

1. **架构设计**
   - 模块划分与职责分离
   - 接口定义与实现
   - 扩展性与维护性考虑

2. **算法复杂度**
   - 时间复杂度和空间复杂度分析
   - 最优解与近似解
   - 实际性能考量

3. **设计模式应用**
   - 创建型模式：工厂、单例、建造者
   - 结构型模式：适配器、装饰器、代理
   - 行为型模式：观察者、策略、模板方法

### 实现细节
关注技术实现的关键细节和最佳实践。
EOF
            ;;
    esac
}

# 添加代码示例
add_code_examples() {
    local file="$1"
    local category="$2"
    local title="$3"
    
    cat >> "$file" << 'EOF'

## 代码示例

### 基础示例
EOF
    
    case "$category" in
        "qt")
            cat >> "$file" << 'EOF'
```cpp
// 简单的 Qt 窗口应用
#include <QApplication>
#include <QWidget>
#include <QPushButton>
#include <QVBoxLayout>
#include <QMessageBox>

class MainWindow : public QWidget {
    Q_OBJECT
public:
    MainWindow(QWidget *parent = nullptr) : QWidget(parent) {
        // 创建界面组件
        QPushButton *button = new QPushButton("点击我", this);
        QLabel *label = new QLabel("Hello Qt!", this);
        
        // 设置布局
        QVBoxLayout *layout = new QVBoxLayout(this);
        layout->addWidget(label);
        layout->addWidget(button);
        
        // 连接信号与槽
        connect(button, &QPushButton::clicked, this, &MainWindow::onButtonClicked);
        
        setWindowTitle("Qt 示例应用");
        resize(400, 300);
    }

private slots:
    void onButtonClicked() {
        QMessageBox::information(this, "提示", "按钮被点击了！");
    }
};

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    MainWindow window;
    window.show();
    return app.exec();
}
```
EOF
            ;;
        "cpp")
            cat >> "$file" << 'EOF'
```cpp
// 现代 C++ 特性示例
#include <iostream>
#include <vector>
#include <algorithm>
#include <memory>
#include <thread>
#include <future>

// 使用 auto 和范围 for 循环
void modern_loop_example() {
    std::vector<int> numbers = {1, 2, 3, 4, 5};
    
    // C++11 范围 for 循环
    for (const auto& num : numbers) {
        std::cout << num << " ";
    }
    std::cout << std::endl;
    
    // 使用 lambda 表达式
    auto is_even = [](int n) { return n % 2 == 0; };
    auto count = std::count_if(numbers.begin(), numbers.end(), is_even);
    std::cout << "偶数个数: " << count << std::endl;
}

// 智能指针示例
class Resource {
public:
    Resource() { std::cout << "Resource acquired\n"; }
    ~Resource() { std::cout << "Resource released\n"; }
    void use() { std::cout << "Using resource\n"; }
};

void smart_pointer_demo() {
    // 独占所有权
    std::unique_ptr<Resource> ptr1 = std::make_unique<Resource>();
    ptr1->use();
    
    // 共享所有权
    std::shared_ptr<Resource> ptr2 = std::make_shared<Resource>();
    {
        std::shared_ptr<Resource> ptr3 = ptr2;  // 引用计数增加
        ptr3->use();
    }  // ptr3 销毁，引用计数减少
    
    ptr2->use();
}  // ptr1 和 ptr2 自动释放资源

int main() {
    modern_loop_example();
    smart_pointer_demo();
    return 0;
}
```
EOF
            ;;
        *)
            cat >> "$file" << 'EOF'
```python
# Python 示例代码
def example_function():
    """这是一个示例函数"""
    # 基础操作
    numbers = [1, 2, 3, 4, 5]
    squared = [x**2 for x in numbers]
    
    # 使用内置函数
    total = sum(numbers)
    average = total / len(numbers)
    
    return {
        'numbers': numbers,
        'squared': squared,
        'total': total,
        'average': average
    }

# 类定义示例
class ExampleClass:
    def __init__(self, name):
        self.name = name
        self.data = []
    
    def add_data(self, value):
        """添加数据"""
        self.data.append(value)
        return self
    
    def get_summary(self):
        """获取摘要信息"""
        return {
            'name': self.name,
            'data_count': len(self.data),
            'data_sum': sum(self.data) if self.data else 0
        }

# 使用示例
if __name__ == "__main__":
    result = example_function()
    print(f"计算结果: {result}")
    
    obj = ExampleClass("测试对象")
    obj.add_data(10).add_data(20).add_data(30)
    print(f"对象摘要: {obj.get_summary()}")
```
EOF
            ;;
    esac
}

# 添加实践应用
add_practical_applications() {
    local file="$1"
    local category="$2"
    local title="$3"
    
    cat >> "$file" << 'EOF'

## 实践应用

### 实际项目中的应用
EOF
    
    case "$category" in
        "qt")
            cat >> "$file" << 'EOF'
1. **桌面应用开发**
   - 跨平台办公软件
   - 数据可视化工具
   - 系统监控面板

2. **嵌入式界面**
   - 工业控制面板
   - 医疗设备界面
   - 车载信息娱乐系统

3. **移动应用**
   - 使用 Qt for Android/iOS
   - 跨平台移动解决方案

### 开发工作流
1. **项目结构**
   ```
   project/
   ├── src/           # 源代码
   ├── include/       # 头文件
   ├── resources/     # 资源文件
   ├── tests/         # 测试代码
   └── CMakeLists.txt # 构建配置
   ```

2. **调试技巧**
   - 使用 Qt Creator 的调试器
   - 信号与槽连接检查
   - 内存泄漏检测
EOF
            ;;
        "cpp")
            cat >> "$file" << 'EOF'
1. **高性能计算**
   - 科学计算模拟
   - 实时数据处理
   - 游戏引擎开发

2. **系统编程**
   - 操作系统开发
   - 设备驱动程序
   - 嵌入式系统

3. **金融科技**
   - 高频交易系统
   - 风险分析引擎
   - 量化交易平台

### 性能优化实践
1. **基准测试**
   ```cpp
   #include <chrono>
   #include <iostream>
   
   auto start = std::chrono::high_resolution_clock::now();
   // 测试代码
   auto end = std::chrono::high_resolution_clock::now();
   auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
   std::cout << "执行时间: " << duration.count() << "微秒" << std::endl;
   ```

2. **内存分析**
   - 使用 Valgrind 检测内存泄漏
   - 使用 perf 进行性能分析
   - 使用 gprof 生成调用图
EOF
            ;;
        *)
            cat >> "$file" << 'EOF'
1. **实际应用场景**
   - 企业级系统开发
   - 数据处理与分析
   - 自动化脚本编写

2. **项目实践建议**
   - 从简单原型开始
   - 逐步添加功能
   - 持续测试和重构

3. **团队协作**
   - 代码规范统一
   - 版本控制流程
   - 代码审查机制
EOF
            ;;
    esac
}

# 添加常见问题
add_faq() {
    local file="$1"
    local category="$2"
    local title="$3"
    
    cat >> "$file" << 'EOF'

## 常见问题

### Q1: 初学者常见问题
EOF
    
    case "$category" in
        "qt")
            cat