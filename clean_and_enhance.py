#!/usr/bin/env python3
"""
文档清理和增强脚本
1. 清理格式问题
2. 修复图片路径
3. 添加深度内容
"""

import os
import re
import shutil
from pathlib import Path

REPO_DIR = Path("/root/.openclaw/workspace/As-my-see")

def clean_document(file_path):
    """清理文档格式"""
    print(f"清理: {file_path.name}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. 移除多余空行（保留最多2个连续空行）
    content = re.sub(r'\n\s*\n\s*\n+', '\n\n', content)
    
    # 2. 修复图片路径
    doc_name = file_path.stem
    assets_dir = file_path.parent / f"{doc_name}.assets"
    assets_dir.mkdir(exist_ok=True)
    
    # 查找并修复图片引用
    img_pattern = r'!\[.*?\]\((.*?)\)'
    for match in re.finditer(img_pattern, content):
        img_path = match.group(1)
        
        # 如果是相对路径且包含文档名
        if not img_path.startswith('http') and doc_name in img_path:
            img_name = Path(img_path).name
            
            # 尝试查找图片文件
            possible_locations = [
                file_path.parent / img_name,
                file_path.parent / img_path,
                file_path.parent / f"{doc_name}_files" / img_name,
            ]
            
            for loc in possible_locations:
                if loc.exists():
                    # 复制到assets目录
                    dest = assets_dir / img_name
                    shutil.copy2(loc, dest)
                    
                    # 更新引用
                    new_path = f"./{doc_name}.assets/{img_name}"
                    content = content.replace(img_path, new_path)
                    print(f"  修复图片: {img_path} -> {new_path}")
                    break
    
    # 3. 确保有标题
    if not content.startswith('# '):
        title = file_path.stem.replace('_', ' ').replace('-', ' ')
        content = f"# {title}\n\n{content}"
    
    # 4. 添加更新时间
    if "> 更新时间:" not in content:
        lines = content.split('\n')
        if len(lines) > 1 and lines[1].startswith('>'):
            # 第二行已有其他注释，在第三行插入
            lines.insert(2, f"> 更新时间: 2026年02月27日")
        else:
            # 在标题后插入
            lines.insert(1, f"> 更新时间: 2026年02月27日")
        content = '\n'.join(lines)
    
    # 5. 添加基本结构
    sections = [
        "## 概述",
        "## 技术原理", 
        "## 代码示例",
        "## 实践应用",
        "## 常见问题",
        "## 学习资源"
    ]
    
    for section in sections:
        if section not in content:
            content += f"\n\n{section}\n\n*（待补充）*"
    
    # 写回文件
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"  完成清理和增强")

def enhance_technical_content(file_path, category):
    """根据类别添加技术内容"""
    print(f"增强技术内容: {file_path.name} ({category})")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 技术原理部分
    if "## 技术原理" in content and "*（待补充）*" in content.split("## 技术原理")[1].split("##")[0]:
        tech_content = get_tech_content(category, file_path.stem)
        
        # 替换待补充标记
        parts = content.split("## 技术原理")
        before = parts[0]
        after = parts[1].split("##", 1)
        
        if len(after) > 1:
            new_content = f"{before}## 技术原理\n\n{tech_content}\n\n##{after[1]}"
        else:
            new_content = f"{before}## 技术原理\n\n{tech_content}"
        
        content = new_content
    
    # 代码示例部分
    if "## 代码示例" in content and "*（待补充）*" in content.split("## 代码示例")[1].split("##")[0]:
        code_example = get_code_example(category)
        
        parts = content.split("## 代码示例")
        before = parts[0]
        after = parts[1].split("##", 1)
        
        if len(after) > 1:
            new_content = f"{before}## 代码示例\n\n{code_example}\n\n##{after[1]}"
        else:
            new_content = f"{before}## 代码示例\n\n{code_example}"
        
        content = new_content
    
    # 写回文件
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"  技术内容增强完成")

def get_tech_content(category, title):
    """获取技术原理内容"""
    if category == "cpp":
        return """### 内存管理
C++提供了精细的内存控制能力：

1. **存储类别**
   - 自动存储期：局部变量，栈内存
   - 静态存储期：全局/静态变量，程序生命周期
   - 动态存储期：堆内存，手动管理
   - 线程存储期：thread_local变量

2. **智能指针体系**
   - `std::unique_ptr`: 独占所有权，不可复制
   - `std::shared_ptr`: 共享所有权，引用计数
   - `std::weak_ptr`: 弱引用，避免循环引用

3. **移动语义 (C++11)**
   - 右值引用：`T&&`
   - 移动构造函数和移动赋值运算符
   - 完美转发：`std::forward`

### 模板编程
C++模板提供了强大的泛型编程能力：
- 函数模板：参数化函数
- 类模板：参数化类
- 可变参数模板：接受任意数量参数
- 模板特化：为特定类型提供特殊实现"""
    
    elif category == "qt":
        return """### 元对象系统 (Meta-Object System)
Qt的核心特性，提供：
1. **运行时类型信息 (RTTI)**
   - `Q_OBJECT`宏启用
   - 支持动态类型转换
   - 反射能力

2. **信号与槽机制**
   - 类型安全的回调机制
   - 支持跨线程通信
   - 自动连接管理

3. **属性系统**
   - 声明式属性定义
   - 属性变化通知
   - 序列化支持

### 图形架构
Qt支持多种渲染后端：
- 软件渲染：QPainter
- OpenGL：硬件加速
- Vulkan：现代图形API
- Direct3D：Windows平台"""
    
    elif category == "linux":
        return """### 内核架构
Linux采用单内核设计：
```
用户空间
    ↓
系统调用接口
    ↓
内核空间
├── 进程管理
├── 内存管理  
├── 文件系统
├── 设备驱动
├── 网络协议栈
└── 虚拟文件系统
```

### 进程管理
1. **进程描述符 (task_struct)**
   - 包含进程所有状态信息
   - 通过双向链表组织
   - 支持进程状态转换

2. **调度器**
   - CFS (完全公平调度器)
   - 实时调度类
   - 调度策略和优先级"""
    
    else:
        return f"""### 核心概念
{title}涉及以下核心概念：

1. **基本原理**
   - 理解技术背后的设计思想
   - 掌握核心算法和数据结构
   - 了解性能特性和限制

2. **架构设计**
   - 模块化设计原则
   - 接口定义和实现分离
   - 扩展性和维护性考虑

3. **最佳实践**
   - 代码组织和结构
   - 错误处理和调试
   - 性能优化策略"""

def get_code_example(category):
    """获取代码示例"""
    if category == "cpp":
        return """```cpp
// 现代C++多线程示例
#include <iostream>
#include <thread>
#include <vector>
#include <atomic>
#include <chrono>

std::atomic<int> counter{0};

void worker(int id) {
    for (int i = 0; i < 1000; ++i) {
        counter.fetch_add(1, std::memory_order_relaxed);
        std::this_thread::sleep_for(std::chrono::microseconds(10));
    }
    std::cout << "Worker " << id << " finished" << std::endl;
}

int main() {
    std::vector<std::thread> threads;
    const int num_threads = 4;
    
    std::cout << "Starting " << num_threads << " threads..." << std::endl;
    
    // 创建线程
    for (int i = 0; i < num_threads; ++i) {
        threads.emplace_back(worker, i);
    }
    
    // 等待所有线程完成
    for (auto& t : threads) {
        t.join();
    }
    
    std::cout << "Final counter value: " << counter.load() << std::endl;
    std::cout << "Expected value: " << num_threads * 1000 << std::endl;
    
    return 0;
}
```"""
    
    elif category == "qt":
        return """```cpp
// Qt多线程示例
#include <QApplication>
#include <QWidget>
#include <QLabel>
#include <QPushButton>
#include <QVBoxLayout>
#include <QThread>
#include <QDebug>

class Worker : public QObject {
    Q_OBJECT
public slots:
    void doWork() {
        qDebug() << "Worker thread:" << QThread::currentThread();
        for (int i = 0; i < 5; ++i) {
            QThread::sleep(1);
            emit progress(i + 1);
        }
        emit finished();
    }
    
signals:
    void progress(int value);
    void finished();
};

class MainWindow : public QWidget {
    Q_OBJECT
public:
    MainWindow(QWidget *parent = nullptr) : QWidget(parent) {
        // 创建界面
        QLabel *label = new QLabel("Qt多线程示例", this);
        QPushButton *startButton = new QPushButton("开始工作", this);
        QLabel *statusLabel = new QLabel("就绪", this);
        
        QVBoxLayout *layout = new QVBoxLayout(this);
        layout->addWidget(label);
        layout->addWidget(startButton);
        layout->addWidget(statusLabel);
        
        // 创建工作线程
        QThread *workerThread = new QThread(this);
        Worker *worker = new Worker();
        worker->moveToThread(workerThread);
        
        // 连接信号槽
        connect(startButton, &QPushButton::clicked, worker, &Worker::doWork);
        connect(worker, &Worker::progress, statusLabel, &QLabel::setText);
        connect(worker, &Worker::finished, [statusLabel]() {
            statusLabel->setText("完成");
        });
        connect(workerThread, &QThread::finished, worker, &QObject::deleteLater);
        
        // 启动线程
        workerThread->start();
        
        setWindowTitle("Qt多线程");
        resize(300, 200);
    }
};

// 注意：实际使用时需要添加对应的头文件和元对象编译
```"""
    
    elif category == "linux":
        return """```bash
#!/bin/bash
# 高级Shell脚本示例

set -euo pipefail  # 严格模式

# 配置
CONFIG_FILE="config.ini"
LOG_FILE="app.log"
BACKUP_DIR="backups"

# 函数定义
setup_environment() {
    echo "设置环境..."
    mkdir -p "$BACKUP_DIR"
    
    # 检查依赖
    local deps=("curl" "jq" "git")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo "错误: 缺少依赖 $dep"
            exit 1
        fi
    done
}

backup_files() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="backup_${timestamp}.tar.gz"
    
    echo "创建备份: $backup_name"
    tar -czf "$BACKUP_DIR/$backup_name" "$CONFIG_FILE" "$LOG_FILE" 2>/dev/null || true
    
    # 清理旧备份（保留最近7天）
    find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +7 -delete
}

process_data() {
    echo "处理数据..."
    
    # 使用管道处理数据
    cat "$CONFIG_FILE" | grep -v "^#" | grep -v "^$" | while IFS='=' read -r key value; do
        if [[ -n "$key" ]]; then
            echo "配置项: $key = $value"
        fi
    done
    
    # 数组操作
    local files=("file1.txt" "file2.txt" "file3.txt")
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            echo "处理文件: $file"
            # 实际处理逻辑
        fi
    done
}

main() {
    echo "脚本开始: $(date)"
    
    setup_environment
    backup_files
    process_data
    
    echo "脚本完成: $(date)"
}

# 主程序入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```"""
    
    else:
        return """```python
# Python示例代码
import os
import sys
import json
from datetime import datetime
from typing import Dict, List, Optional

class ConfigManager:
    """配置管理器"""
    
    def __init__(self, config_file: str = "config.json"):
        self.config_file = config_file
        self.config = self.load_config()
    
    def load_config(self) -> Dict:
        """加载配置"""
        if os.path.exists(self.config_file):
            with open(self.config_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        return {}
    
    def save_config(self) -> bool:
        """保存配置"""
        try:
            with open(self.config_file, 'w', encoding='utf-8') as f:
                json.dump(self.config, f, indent=2, ensure_ascii=False)
            return True
        except Exception as e:
            print(f"保存配置失败: {e}")
            return False
    
    def get_value(self, key: str, default=None):
        """获取配置值"""
        return self.config.get(key, default)
    
    def set_value(self, key: str, value):
        """设置配置值"""
        self.config[key] = value
        return self.save_config()

def process_files(file_pattern: str) -> List[str]:
    """处理文件"""
    import glob
    
    files = glob.glob(file_pattern)
    results = []
    
    for file_path in files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                # 处理内容
                processed = content.upper()  # 示例处理
                results.append(processed)
        except Exception as e:
            print(f"处理文件失败 {file_path}: {e}")
    
    return results

def main():
    """主函数"""
    print(f"程序启动: {datetime.now()}")
    
    # 配置管理
    config = ConfigManager()
    config.set_value("last_run", datetime.now().isoformat())
    
    # 文件处理
    files = process_files("*.txt")
    print(f"处理了 {len(files)} 个文件")
    
    print(f"程序结束: {datetime.now()}")

if __name__ == "__main__":
    main()
```"""

def main():
    """主函数"""
    print("开始文档优化...")
    
    # 处理核心文档
    core_docs = [
        ("docs/cpp/C++多线程.md", "cpp"),
        ("docs/qt/1_Qt.md", "qt"),
        ("docs/linux/Shell脚本.md", "linux"),
        ("docs/robotics/SLAM的基本知识.md", "robotics"),
        ("docs/ros/ROS编程.md", "ros"),
    ]
    
    for doc_path, category in core_docs:
        full_path = REPO_DIR / doc_path
        if full_path.exists():
            clean_document(full_path)
            enhance_technical_content(full_path, category)
        else:
            print(f"文件不存在: {doc_path}")
    
    print("\n文档优化完成！")
    print("建议：")
    print("1. 检查图片是否正确显示")
    print("2. 补充实践应用和常见问题部分")
    print("3. 根据需要进一步细化技术内容")

if __name__ == "__main__":
    main()