#!/bin/bash

# 深度内容优化脚本
# 1. 清理重复内容
# 2. 深化浅显知识
# 3. 结构化重组

set -e

REPO_DIR="/root/.openclaw/workspace/As-my-see"
LOG_FILE="$REPO_DIR/deep_optimization.log"
TEMP_DIR="$REPO_DIR/temp_analysis"

# 创建临时目录
mkdir -p "$TEMP_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 分析文档内容重复度
analyze_duplicates() {
    log "分析文档内容重复度..."
    
    # 提取所有文档的核心内容（去除标题、代码块等）
    for file in $(find "$REPO_DIR/docs" -name "*.md"); do
        local filename=$(basename "$file")
        local clean_content=$(grep -v "^#" "$file" | grep -v "^```" | grep -v "^---" | head -100 | tr -d '[:punct:]' | tr '[:upper:]' '[:lower:]')
        echo "$filename: $clean_content" >> "$TEMP_DIR/all_contents.txt"
    done
    
    # 查找相似内容
    log "查找相似文档..."
    cat "$TEMP_DIR/all_contents.txt" | sort | uniq -c | sort -nr > "$TEMP_DIR/duplicate_analysis.txt"
    
    local duplicate_count=$(grep -c "^[2-9]" "$TEMP_DIR/duplicate_analysis.txt")
    log "发现 $duplicate_count 组可能重复的内容"
}

# 深化浅显知识
deepen_knowledge() {
    local file="$1"
    local category="$2"
    
    log "深化文档: $file"
    
    # 读取文档内容
    local content=$(cat "$file")
    local title=$(echo "$content" | head -n 1 | sed 's/^# //')
    
    # 分析文档深度
    local line_count=$(echo "$content" | wc -l)
    local code_blocks=$(echo "$content" | grep -c "^```")
    local headings=$(echo "$content" | grep -c "^#")
    
    # 如果文档太简单（少于50行且代码块少于2个）
    if [ $line_count -lt 50 ] && [ $code_blocks -lt 2 ]; then
        log "文档内容较浅，需要深化: $title"
        
        # 根据类别添加深度内容
        case "$category" in
            "cpp")
                add_cpp_depth "$file" "$title"
                ;;
            "qt")
                add_qt_depth "$file" "$title"
                ;;
            "linux")
                add_linux_depth "$file" "$title"
                ;;
            "robotics")
                add_robotics_depth "$file" "$title"
                ;;
            "ros")
                add_ros_depth "$file" "$title"
                ;;
            *)
                add_general_depth "$file" "$title" "$category"
                ;;
        esac
    fi
}

# 添加C++深度内容
add_cpp_depth() {
    local file="$1"
    local title="$2"
    
    local depth_content=""
    
    if [[ "$title" == *"多线程"* ]]; then
        depth_content="\n## 多线程编程深度解析\n\n### 1. 线程同步机制\n\n#### 互斥锁 (Mutex)\n```cpp\n#include <mutex>\n#include <iostream>\n\nstd::mutex mtx;\nint shared_data = 0;\n\nvoid increment() {\n    std::lock_guard<std::mutex> lock(mtx);\n    ++shared_data;\n    std::cout << \"Thread \" << std::this_thread::get_id() \n              << \" incremented to \" << shared_data << std::endl;\n}\n```\n\n#### 条件变量 (Condition Variable)\n```cpp\n#include <condition_variable>\n#include <queue>\n\nstd::mutex mtx;\nstd::condition_variable cv;\nstd::queue<int> data_queue;\nbool finished = false;\n\nvoid producer() {\n    for (int i = 0; i < 10; ++i) {\n        std::this_thread::sleep_for(std::chrono::milliseconds(100));\n        {\n            std::lock_guard<std::mutex> lock(mtx);\n            data_queue.push(i);\n        }\n        cv.notify_one();\n    }\n    {\n        std::lock_guard<std::mutex> lock(mtx);\n        finished = true;\n    }\n    cv.notify_all();\n}\n\nvoid consumer() {\n    while (true) {\n        std::unique_lock<std::mutex> lock(mtx);\n        cv.wait(lock, []{ return !data_queue.empty() || finished; });\n        \n        if (data_queue.empty() && finished) break;\n        \n        int value = data_queue.front();\n        data_queue.pop();\n        lock.unlock();\n        \n        std::cout << \"Consumed: \" << value << std::endl;\n    }\n}\n```\n\n### 2. 现代C++多线程特性\n\n#### std::async 与 std::future\n```cpp\n#include <future>\n#include <vector>\n#include <numeric>\n\n// 异步计算数组和\nstd::future<int> async_sum(const std::vector<int>& data) {\n    return std::async(std::launch::async, [&data]() {\n        return std::accumulate(data.begin(), data.end(), 0);\n    });\n}\n\n// 使用示例\nstd::vector<int> numbers(1000000, 1);\nauto future_result = async_sum(numbers);\n\n// 可以继续做其他工作...\n\n// 获取结果（如果还没完成会阻塞）\nint result = future_result.get();\nstd::cout << \"Sum: \" << result << std::endl;\n```\n\n#### 原子操作 (Atomic)\n```cpp\n#include <atomic>\n#include <thread>\n#include <vector>\n\nstd::atomic<int> counter{0};\n\nvoid increment_atomic(int n) {\n    for (int i = 0; i < n; ++i) {\n        counter.fetch_add(1, std::memory_order_relaxed);\n    }\n}\n\n// 性能对比：原子操作 vs 互斥锁\nvoid benchmark() {\n    const int iterations = 1000000;\n    const int thread_count = 4;\n    \n    std::vector<std::thread> threads;\n    \n    // 使用原子操作\n    auto start = std::chrono::high_resolution_clock::now();\n    for (int i = 0; i < thread_count; ++i) {\n        threads.emplace_back(increment_atomic, iterations);\n    }\n    for (auto& t : threads) t.join();\n    auto end = std::chrono::high_resolution_clock::now();\n    \n    auto atomic_time = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);\n    std::cout << \"Atomic time: \" << atomic_time.count() << \"ms\" << std::endl;\n}\n```\n\n### 3. 线程池实现\n\n```cpp\n#include <thread>\n#include <vector>\n#include <queue>\n#include <functional>\n#include <condition_variable>\n\nclass ThreadPool {\nprivate:\n    std::vector<std::thread> workers;\n    std::queue<std::function<void()>> tasks;\n    std::mutex queue_mutex;\n    std::condition_variable condition;\n    bool stop = false;\n    \npublic:\n    ThreadPool(size_t threads) {\n        for (size_t i = 0; i < threads; ++i) {\n            workers.emplace_back([this] {\n                while (true) {\n                    std::function<void()> task;\n                    {\n                        std::unique_lock<std::mutex> lock(this->queue_mutex);\n                        this->condition.wait(lock, [this] {\n                            return this->stop || !this->tasks.empty();\n                        });\n                        if (this->stop && this->tasks.empty()) return;\n                        task = std::move(this->tasks.front());\n                        this->tasks.pop();\n                    }\n                    task();\n                }\n            });\n        }\n    }\n    \n    template<class F>\n    void enqueue(F&& f) {\n        {\n            std::unique_lock<std::mutex> lock(queue_mutex);\n            tasks.emplace(std::forward<F>(f));\n        }\n        condition.notify_one();\n    }\n    \n    ~ThreadPool() {\n        {\n            std::unique_lock<std::mutex> lock(queue_mutex);\n            stop = true;\n        }\n        condition.notify_all();\n        for (std::thread &worker : workers) {\n            worker.join();\n        }\n    }\n};\n\n// 使用示例\nThreadPool pool(4);\nfor (int i = 0; i < 8; ++i) {\n    pool.enqueue([i] {\n        std::this_thread::sleep_for(std::chrono::seconds(1));\n        std::cout << \"Task \" << i << \" completed\" << std::endl;\n    });\n}\n```\n\n### 4. 性能优化与最佳实践\n\n#### 避免虚假共享 (False Sharing)\n```cpp\n// 错误示例：多个线程访问同一缓存行的不同变量\nstruct Data {\n    int x;  // 线程1频繁访问\n    int y;  // 线程2频繁访问\n};\n\n// 正确示例：使用缓存行对齐\nstruct alignas(64) AlignedData {  // 64字节对齐（典型缓存行大小）\n    int x;\n    char padding[60];  // 填充到64字节\n};\n\nstruct ThreadData {\n    alignas(64) int local_counter;\n};\n```\n\n#### 无锁数据结构示例\n```cpp\ntemplate<typename T>\nclass LockFreeQueue {\nprivate:\n    struct Node {\n        T data;\n        std::atomic<Node*> next;\n        Node(const T& value) : data(value), next(nullptr) {}\n    };\n    \n    std::atomic<Node*> head;\n    std::atomic<Node*> tail;\n    \npublic:\n    LockFreeQueue() {\n        Node* dummy = new Node(T());\n        head.store(dummy);\n        tail.store(dummy);\n    }\n    \n    void enqueue(const T& value) {\n        Node* new_node = new Node(value);\n        Node* old_tail = tail.load();\n        \n        while (true) {\n            Node* next = old_tail->next.load();\n            if (next == nullptr) {\n                if (old_tail->next.compare_exchange_weak(next, new_node)) {\n                    tail.compare_exchange_strong(old_tail, new_node);\n                    return;\n                }\n            } else {\n                tail.compare_exchange_strong(old_tail, next);\n            }\n        }\n    }\n    \n    bool dequeue(T& result) {\n        Node* old_head = head.load();\n        while (true) {\n            Node* next = old_head->next.load();\n            if (next == nullptr) return false;\n            \n            if (head.compare_exchange_weak(old_head, next)) {\n                result = next->data;\n                delete old_head;\n                return true;\n            }\n        }\n    }\n};\n```\n\n### 5. 调试与测试\n\n#### 线程安全测试\n```cpp\n#include <gtest/gtest.h>\n#include <thread>\n\nTEST(ThreadSafeTest, ConcurrentIncrement) {\n    const int num_threads = 10;\n    const int increments_per_thread = 1000;\n    \n    std::atomic<int> counter{0};\n    std::vector<std::thread> threads;\n    \n    for (int i = 0; i < num_threads; ++i) {\n        threads.emplace_back([&counter, increments_per_thread]() {\n            for (int j = 0; j < increments_per_thread; ++j) {\n                counter.fetch_add(1);\n            }\n        });\n    }\n    \n    for (auto& t : threads) {\n        t.join();\n    }\n    \n    EXPECT_EQ(counter.load(), num_threads * increments_per_thread);\n}\n```\n\n#### 死锁检测\n```cpp\n#include <mutex>\n#include <thread>\n\nstd::mutex mtx1, mtx2;\n\nvoid thread1() {\n    std::lock(mtx1, mtx2);  // 同时锁定两个互斥锁，避免死锁\n    std::lock_guard<std::mutex> lock1(mtx1, std::adopt_lock);\n    std::lock_guard<std::mutex> lock2(mtx2, std::adopt_lock);\n    // 安全访问共享资源\n}\n\nvoid thread2() {\n    std::lock(mtx1, mtx2);  // 相同的锁定顺序\n    std::lock_guard<std::mutex> lock1(mtx1, std::adopt_lock);\n    std::lock_guard<std::mutex> lock2(mtx2, std::adopt_lock);\n    // 安全访问共享资源\n}\n```\n\n### 6. 实际应用场景\n\n#### 并行数据处理\n```cpp\ntemplate<typename InputIt, typename OutputIt, typename Func>\nvoid parallel_transform(InputIt first, InputIt last, OutputIt d_first, Func f, size_t num_threads) {\n    auto length = std::distance(first, last);\n    if (length == 0) return;\n    \n    size_t block_size = (length + num_threads - 1) / num_threads;\n    std::vector<std::thread> threads;\n    \n    for (size_t i = 0; i < num_threads; ++i) {\n        InputIt start = first + i * block_size;\n        InputIt end = first + std::min((i + 1) * block_size, static_cast<size_t>(length));\n        OutputIt dest = d_first + i * block_size;\n        \n        if (start < end) {\n            threads.emplace_back([start, end, dest, &f]() {\n                std::transform(start, end, dest, f);\n            });\n        }\n    }\n    \n    for (auto& t : threads) {\n        t.join();\n    }\n}\n\n// 使用示例：并行图像处理\nvoid parallel_image_processing(const std::vector<Pixel>& input, std::vector<Pixel>& output) {\n    auto apply_filter = [](Pixel p) {\n        // 应用图像滤镜\n        p.r = 255 - p.r;  // 反色\n        p.g = 255 - p.g;\n        p.b = 255 - p.b;\n        return p;\n    };\n    \n    unsigned int num_threads = std::thread::hardware_concurrency();\n    parallel_transform(input.begin(), input.end(), output.begin(), apply_filter, num_threads);\n}\n```\n\n### 7. 性能监控与调优\n\n#### 线程性能分析\n```cpp\n#include <chrono>\n#include <iostream>\n\nclass ThreadProfiler {\nprivate:\n    std::chrono::high_resolution_clock::time_point start_time;\n    std::string thread_name;\n    \npublic:\n    ThreadProfiler(const std::string& name) : thread_name(name) {\n        start_time = std::chrono::high_resolution_clock::now();\n    }\n    \n    ~ThreadProfiler() {\n        auto end_time = std::chrono::high_resolution_clock::now();\n        auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end_time - start_time);\n        std::cout << thread_name << \" took \" << duration.count() << \" microseconds\" << std::endl;\n    }\n};\n\n// 使用示例\nvoid expensive_operation() {\n    ThreadProfiler profiler(\"expensive_operation\");\n    // 执行耗时操作\n    std::this_thread::sleep_for(std::chrono::milliseconds(100));\n}\n```\n\n---\n\n**总结**：现代C++多线程编程需要深入理解内存模型、原子操作、无锁数据结构等高级概念。在实际应用中，应根据具体场景选择合适的同步机制，并注意性能优化和线程安全。"
    fi
    
    # 将深度内容追加到文档
    if [ -n "$depth_content" ]; then
        echo -e "$depth_content" >> "$file"
        log "已为 $title 添加深度内容"
    fi
}

# 添加Qt深度内容（简化版）
add_qt_depth() {
    local file="$1"
    local title