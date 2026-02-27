#!/bin/bash

# 优化选定的核心文档

REPO_DIR="/root/.openclaw/workspace/As-my-see"
echo "开始优化选定的核心文档..."

# 优化C++多线程文档
optimize_cpp_threading() {
    local file="$REPO_DIR/docs/cpp/C++多线程.md"
    echo "优化: C++多线程.md"
    
    # 创建备份
    cp "$file" "$file.backup_$(date +%Y%m%d)"
    
    # 构建优化内容
    cat > "$file" << 'EOF'
# C++多线程编程
> 文档状态: 深度优化版本
> 优化时间: 2026年02月27日
> 基于网络搜索最新内容补充

## 📖 概述

C++多线程是现代C++编程的核心技术，用于提高程序性能和响应能力。本文涵盖从基础到高级的多线程编程知识。

## 🔍 最新发展 (2024-2025)

### C++20/23 新特性
1. **std::jthread**: 自动join的线程，避免资源泄漏
2. **std::stop_token**: 线程停止机制，优雅终止
3. **std::latch & std::barrier**: 新的同步原语
4. **协程支持**: std::coroutine框架

### 性能优化趋势
- 无锁数据结构广泛应用
- 线程池模式标准化
- 硬件感知并发编程
- 内存模型深入优化

## 🛠️ 深度技术解析

### 1. 线程管理
#### 线程创建
```cpp
// 传统方式
std::thread t1([](){
    std::cout << "Thread 1 running" << std::endl;
});

// C++20新方式
std::jthread t2([](std::stop_token stoken){
    while (!stoken.stop_requested()) {
        std::cout << "Thread 2 working..." << std::endl;
        std::this_thread::sleep_for(100ms);
    }
});
```

#### 线程同步
- **互斥锁**: std::mutex, std::shared_mutex
- **条件变量**: std::condition_variable
- **原子操作**: std::atomic, 内存顺序
- **信号量**: C++20引入

### 2. 并发模式

#### 线程池实现
```cpp
#include <thread>
#include <vector>
#include <queue>
#include <functional>
#include <condition_variable>

class ThreadPool {
    std::vector<std::thread> workers;
    std::queue<std::function<void()>> tasks;
    std::mutex queue_mutex;
    std::condition_variable condition;
    bool stop = false;
    
public:
    ThreadPool(size_t threads = std::thread::hardware_concurrency()) {
        for (size_t i = 0; i < threads; ++i) {
            workers.emplace_back([this] {
                while (true) {
                    std::function<void()> task;
                    {
                        std::unique_lock<std::mutex> lock(this->queue_mutex);
                        this->condition.wait(lock, [this] {
                            return this->stop || !this->tasks.empty();
                        });
                        if (this->stop && this->tasks.empty()) return;
                        task = std::move(this->tasks.front());
                        this->tasks.pop();
                    }
                    task();
                }
            });
        }
    }
    
    template<class F>
    void enqueue(F&& f) {
        {
            std::unique_lock<std::mutex> lock(queue_mutex);
            tasks.emplace(std::forward<F>(f));
        }
        condition.notify_one();
    }
    
    ~ThreadPool() {
        {
            std::unique_lock<std::mutex> lock(queue_mutex);
            stop = true;
        }
        condition.notify_all();
        for (std::thread &worker : workers)
            worker.join();
    }
};
```

#### 无锁编程
```cpp
#include <atomic>

template<typename T>
class LockFreeQueue {
private:
    struct Node {
        T data;
        std::atomic<Node*> next;
        Node(const T& data) : data(data), next(nullptr) {}
    };
    
    std::atomic<Node*> head;
    std::atomic<Node*> tail;
    
public:
    LockFreeQueue() {
        Node* dummy = new Node(T());
        head.store(dummy);
        tail.store(dummy);
    }
    
    void enqueue(const T& value) {
        Node* new_node = new Node(value);
        Node* old_tail = tail.load();
        
        while (true) {
            Node* next = old_tail->next.load();
            if (next == nullptr) {
                if (old_tail->next.compare_exchange_weak(next, new_node)) {
                    tail.compare_exchange_strong(old_tail, new_node);
                    return;
                }
            } else {
                tail.compare_exchange_strong(old_tail, next);
            }
        }
    }
    
    bool dequeue(T& result) {
        Node* old_head = head.load();
        while (true) {
            Node* next = old_head->next.load();
            if (next == nullptr) return false;
            
            if (head.compare_exchange_weak(old_head, next)) {
                result = next->data;
                delete old_head;
                return true;
            }
        }
    }
};
```

### 3. 性能优化技巧

#### 避免虚假共享 (False Sharing)
```cpp
// 错误示例：多个线程访问同一缓存行
struct Data {
    int x;  // 线程1频繁访问
    int y;  // 线程2频繁访问
};

// 正确示例：缓存行对齐
struct alignas(64) AlignedData {  // 64字节对齐
    int x;
    char padding[60];  // 填充
};

struct ThreadData {
    alignas(64) int local_counter;
    // 其他线程局部数据...
};
```

#### 内存顺序选择
```cpp
std::atomic<int> data{0};
std::atomic<bool> ready{false};

// 生产者
void producer() {
    data.store(42, std::memory_order_relaxed);
    ready.store(true, std::memory_order_release);
}

// 消费者
void consumer() {
    while (!ready.load(std::memory_order_acquire)) {
        std::this_thread::yield();
    }
    int value = data.load(std::memory_order_relaxed);
    // 保证看到 data = 42
}
```

## 💻 实际应用案例

### 案例1：并行数据处理
```cpp
template<typename InputIt, typename OutputIt, typename Func>
void parallel_transform(InputIt first, InputIt last, OutputIt d_first, 
                       Func f, size_t num_threads) {
    auto length = std::distance(first, last);
    if (length == 0) return;
    
    size_t block_size = (length + num_threads - 1) / num_threads;
    std::vector<std::thread> threads;
    
    for (size_t i = 0; i < num_threads; ++i) {
        InputIt start = first + i * block_size;
        InputIt end = first + std::min((i + 1) * block_size, static_cast<size_t>(length));
        OutputIt dest = d_first + i * block_size;
        
        if (start < end) {
            threads.emplace_back([start, end, dest, &f]() {
                std::transform(start, end, dest, f);
            });
        }
    }
    
    for (auto& t : threads) {
        t.join();
    }
}

// 使用示例：并行图像处理
void parallel_image_filter(const std::vector<Pixel>& input, 
                          std::vector<Pixel>& output) {
    auto filter = [](Pixel p) {
        // 应用滤镜
        p.r = 255 - p.r;  // 反色
        p.g = 255 - p.g;
        p.b = 255 - p.b;
        return p;
    };
    
    unsigned int num_threads = std::thread::hardware_concurrency();
    parallel_transform(input.begin(), input.end(), output.begin(), 
                      filter, num_threads);
}
```

### 案例2：高性能服务器
```cpp
class AsyncServer {
    ThreadPool pool;
    std::atomic<int> connection_count{0};
    
public:
    AsyncServer() : pool(16) {}  // 16个工作者线程
    
    void handle_connection(int socket) {
        pool.enqueue([this, socket]() {
            connection_count.fetch_add(1);
            
            // 处理请求
            char buffer[1024];
            ssize_t bytes = recv(socket, buffer, sizeof(buffer), 0);
            
            if (bytes > 0) {
                // 处理数据
                std::string response = process_request(buffer, bytes);
                send(socket, response.c_str(), response.size(), 0);
            }
            
            close(socket);
            connection_count.fetch_sub(1);
        });
    }
    
    int get_connection_count() const {
        return connection_count.load();
    }
};
```

## 🚀 最佳实践

### 1. 设计原则
- **单一职责**: 每个线程专注单一任务
- **资源管理**: 使用RAII管理线程资源
- **错误处理**: 完善的异常安全保证
- **可测试性**: 设计可测试的并发组件

### 2. 调试技巧
```cpp
#include <chrono>
#include <iostream>

class ThreadProfiler {
    std::chrono::high_resolution_clock::time_point start;
    std::string thread_name;
    
public:
    ThreadProfiler(const std::string& name) : thread_name(name) {
        start = std::chrono::high_resolution_clock::now();
    }
    
    ~ThreadProfiler() {
        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
        std::cout << thread_name << " took " << duration.count() << " μs" << std::endl;
    }
};

// 使用
void expensive_operation() {
    ThreadProfiler profiler("expensive_operation");
    // 耗时操作
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
}
```

### 3. 性能监控
- 使用perf分析CPU缓存命中率
- 使用Valgrind检测线程错误
- 使用gprof生成调用图
- 自定义性能计数器

## 📚 学习资源

### 官方文档
- [C++ Concurrency](https://en.cppreference.com/w/cpp/thread)
- [C++ Memory Model](https://en.cppreference.com/w/cpp/atomic/memory_order)
- [C++20 Concurrency Features](https://en.cppreference.com/w/cpp/thread/jthread)

### 推荐书籍
1. **《C++ Concurrency in Action》** (2nd Edition) - Anthony Williams
2. **《The Art of Multiprocessor Programming》** - Maurice Herlihy
3. **《Effective Modern C++》** - Scott Meyers

### 在线资源
- [LearnCpp Concurrency](https://www.learncpp.com/cpp-tutorial/multithreading/)
- [CppCon Talks](https://www.youtube.com/results?search_query=cppcon+concurrency)
- [并发编程网](http://ifeve.com/)

### 工具推荐
- **ThreadSanitizer**: 数据竞争检测
- **Helgrind**: Valgrind的线程错误检测工具
- **perf**: Linux性能分析工具
- **Intel VTune**: 专业性能分析

## ⚠️ 常见问题

### Q1: 如何避免死锁？
**A**: 使用std::lock同时锁定多个互斥锁，或使用std::scoped_lock。

### Q2: 何时使用原子操作？
**A**: 简单计数器使用原子，复杂数据结构考虑锁或无锁结构。

### Q3: 如何选择线程数量？
**A**: 通常为CPU核心数，I/O密集型可适当增加。

### Q4: 线程局部存储的性能影响？
**A**: 访问速度快，但初始化成本需考虑。

---

*本文档持续更新，建议定期查看最新C++标准和技术发展。*
EOF
    
    echo "  C++多线程文档优化完成"
}

# 优化Shell脚本文档
optimize_shell_script() {
    local file="$REPO_DIR/docs/linux/Shell脚本.md"
    echo "优化: Shell脚本.md"
    
    cp "$file" "$file.backup_$(date +%Y%m%d)"
    
    cat > "$file" << 'EOF'
# Shell脚本编程
> 文档状态: 深度优化版本  
> 优化时间: 2026年02月27日
> 基于现代Shell编程最佳实践

## 📖 概述

Shell脚本是Linux系统管理和自动化的重要工具。本文涵盖Bash脚本编程从基础到高级的所有知识。

## 🔍 现代Shell实践 (2024)

### Bash 5.x 新特性
1. **关联数组增强**: 更好的键值对支持
2. **wait -n**: 等待任意子进程完成
3. **mapfile改进**: 更灵活的文件读取
4. **命名引用**: 间接变量引用

### 安全最佳实践
- **严格模式**: `set -euo pipefail`
- **输入验证**: 防止命令注入
- **权限控制**: 最小权限原则
- **敏感信息**: 使用环境变量或密钥管理

## 🛠️ 深度技术解析

### 1. 脚本架构设计

#### 模块化脚本
```bash
#!/bin/bash
# 主脚本: main.sh

set -euo pipefail  # 严格模式

# 加载配置
source "$(dirname "$0")/config.sh"
# 加载工具函数
source "$(dirname "$0")/lib/utils.sh"
# 加载日志模块
source "$(dirname "$0")/lib/logging.sh"

# 主函数
main() {
    log_info "脚本启动"
    
    # 参数解析
    parse_args "$@"
    
    # 初始化
    initialize
    
    # 主逻辑
    process_data
    
    # 清理
    cleanup
    
    log_info "脚本完成"
}

# 错误处理
trap 'error_handler $LINENO' ERR
trap 'cleanup_on_exit' EXIT

# 运行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

#### 配置文件
```bash
# config.sh
#!/bin/bash

# 应用配置
readonly APP_NAME="MyApp"
readonly APP_VERSION="1.0.0"
readonly APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 路径配置
readonly LOG_DIR="${APP_DIR}/logs"
readonly DATA_DIR="${APP_DIR}/data"
readonly BACKUP_DIR="${APP_DIR}/backups"

# 网络配置
readonly API_URL="https://api.example.com"
readonly TIMEOUT=30

# 功能开关
readonly ENABLE_LOGGING=true
readonly ENABLE_BACKUP=true
readonly DEBUG_MODE=false
```

### 2. 高级文本处理

#### AWK高级用法
```bash
#!/bin/bash

# 复杂数据提取
process_logs() {
    local log_file="$1"
    
    # 提取错误信息并统计
    awk '
    BEGIN {
        error_count = 0
        warning_count = 0
        printf "%-20s %-10s %s\n", "时间", "级别", "消息"
        printf "%-20s %-10s %s\n", "---", "---", "---"
    }
    /ERROR/ {
        error_count++
        printf "%-20s %-10s %s\n", $1, "ERROR", substr($0, index($0, $5))
    }
    /WARNING/ {
        warning_count++
        printf "%-20s %-10s %s\n", $1, "WARNING", substr($0, index($0, $5))
    }
    END {
        printf "\n统计:\n"
        printf "错误数: %d\n", error_count
        printf "警告数: %d\n", warning_count
    }
    ' "$log_file"
}

# CSV文件处理
process_csv() {
    local csv_file="$1"
    
    awk -F',' '
    NR == 1 {
        # 读取表头
        for (i = 1; i <= NF; i++) headers[i] = $i
        next
    }
    {
        # 处理每一行
        total = 0
        for (i = 2; i <= NF; i++) {
            if ($i ~ /^[0-9]+(\.[0-9]+)?$/) {
                total += $i
            }
        }
        printf "%s: %.2f\n", $1, total
    }
    ' "$csv_file"
}
```

#### Sed流编辑
```bash
#!/bin/bash

# 批量文件处理
batch_rename() {
    local pattern="$1"
    local replacement="$2"
    local directory="${3:-.}"
    
    find "$directory" -type f -name "*.txt" | while read -r file; do
        # 备份原文件
        cp "$file" "${file}.bak"
        
        # 使用sed进行替换
        sed -i "s/$pattern/$replacement/g" "$file"
        
        echo "处理: $file"
    done
}

# 配置文件修改
update_config() {
    local config_file="$1"
    local key="$2"
    local value="$3"
    
    # 如果键存在则更新，否则追加
    if grep -q "^$key=" "$config_file"; then
        sed -i "s/^$key=.*/$key=$value/" "$config_file"
    else
        echo "$key=$value" >> "$config_file"
    fi
}
```

### 3. 进程管理和并发

#### 并行处理
```bash
#!/bin/bash

# 使用xargs并行处理
parallel_process() {
    local input_dir="$1"
    local output_dir="$2"
