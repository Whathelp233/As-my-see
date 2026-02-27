# Shell脚本编程全面指南
> 文档状态: 深度优化版本
> 更新时间: 2026年02月27日
> 涵盖Bash脚本编程最佳实践

## 📖 概述

Shell脚本是Linux系统管理和自动化的核心工具。本文从基础语法到高级技巧，全面介绍现代Shell脚本编程。

## 🚀 快速开始

### 1. 脚本基础结构
```bash
#!/bin/bash
# 脚本说明: 这是一个示例脚本
# 作者: [你的名字]
# 版本: 1.0.0

set -euo pipefail  # 严格模式: 错误退出、未定义变量报错、管道错误

# 配置
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${SCRIPT_DIR}/script.log"

# 函数定义
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG_FILE" >&2
}

# 主函数
main() {
    log_info "脚本启动"
    
    # 脚本逻辑
    process_files
    
    log_info "脚本完成"
}

# 错误处理
trap 'handle_error $LINENO' ERR
trap 'cleanup_on_exit' EXIT

# 运行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## 🔧 核心语法详解

### 1. 变量和参数
```bash
#!/bin/bash

# 变量定义
name="John"
readonly PI=3.14159  # 只读变量
declare -i count=0    # 整数变量
declare -a files      # 数组变量

# 特殊变量
echo "脚本名: $0"
echo "参数个数: $#"
echo "所有参数: $@"
echo "第一个参数: ${1:-default}"  # 默认值

# 数组操作
files=("file1.txt" "file2.txt" "file3.txt")
files+=("file4.txt")  # 追加元素
echo "数组长度: ${#files[@]}"
echo "第一个元素: ${files[0]}"

# 关联数组 (Bash 4+)
declare -A config
config["host"]="localhost"
config["port"]="8080"
echo "主机: ${config[host]}"
```

### 2. 条件判断
```bash
#!/bin/bash

# 文件测试
if [[ -f "file.txt" ]]; then
    echo "文件存在"
elif [[ -d "directory" ]]; then
    echo "目录存在"
else
    echo "都不存在"
fi

# 字符串比较
name="Alice"
if [[ "$name" == "Alice" ]]; then
    echo "Hello Alice"
fi

if [[ -z "$name" ]]; then
    echo "姓名为空"
fi

# 数值比较
count=10
if (( count > 5 )); then
    echo "计数大于5"
fi

# 模式匹配
filename="document.pdf"
if [[ "$filename" =~ \.pdf$ ]]; then
    echo "PDF文件"
fi

# case语句
case "$1" in
    start)
        echo "启动服务"
        ;;
    stop)
        echo "停止服务"
        ;;
    restart)
        echo "重启服务"
        ;;
    *)
        echo "用法: $0 {start|stop|restart}"
        exit 1
        ;;
esac
```

### 3. 循环控制
```bash
#!/bin/bash

# for循环
for i in {1..5}; do
    echo "数字: $i"
done

for file in *.txt; do
    echo "处理文件: $file"
done

# C风格for循环
for ((i=0; i<10; i++)); do
    echo "迭代: $i"
done

# while循环
count=0
while (( count < 5 )); do
    echo "计数: $count"
    ((count++))
done

# 读取文件行
while IFS= read -r line; do
    echo "行: $line"
done < "input.txt"

# until循环
attempt=0
until ping -c1 example.com &>/dev/null || (( attempt++ >= 3 )); do
    echo "等待连接..."
    sleep 1
done
```

## 🛠️ 高级文本处理

### 1. 字符串操作
```bash
#!/bin/bash

str="Hello World"

# 长度
echo "长度: ${#str}"

# 子字符串
echo "前5个字符: ${str:0:5}"
echo "从第6个开始: ${str:6}"
echo "最后5个字符: ${str: -5}"

# 替换
echo "替换: ${str/World/Shell}"
echo "全局替换: ${str//l/L}"
echo "前缀匹配: ${str#Hello}"
echo "后缀匹配: ${str%World}"

# 大小写转换
echo "大写: ${str^^}"
echo "小写: ${str,,}"
echo "首字母大写: ${str^}"
```

### 2. 正则表达式
```bash
#!/bin/bash

# 使用 =~ 操作符
email="user@example.com"
if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "有效邮箱"
fi

# 提取匹配组
text="Date: 2024-01-15"
if [[ "$text" =~ ([0-9]{4})-([0-9]{2})-([0-9]{2}) ]]; then
    echo "年: ${BASH_REMATCH[1]}"
    echo "月: ${BASH_REMATCH[2]}"
    echo "日: ${BASH_REMATCH[3]}"
fi
```

### 3. AWK高级用法
```bash
#!/bin/bash

# 统计文件信息
analyze_logs() {
    local log_file="$1"
    
    awk '
    BEGIN {
        total_errors = 0
        total_warnings = 0
        printf "%-20s %-10s %s\n", "时间戳", "级别", "消息"
        printf "%-20s %-10s %s\n", "---", "---", "---"
    }
    /ERROR/ {
        total_errors++
        timestamp = $1 " " $2
        message = substr($0, index($0, $5))
        printf "%-20s %-10s %s\n", timestamp, "ERROR", message
    }
    /WARNING/ {
        total_warnings++
        timestamp = $1 " " $2
        message = substr($0, index($0, $5))
        printf "%-20s %-10s %s\n", timestamp, "WARNING", message
    }
    END {
        printf "\n统计报告:\n"
        printf "总错误数: %d\n", total_errors
        printf "总警告数: %d\n", total_warnings
        printf "总计: %d\n", total_errors + total_warnings
    }
    ' "$log_file"
}

# CSV处理
process_csv() {
    local csv_file="$1"
    
    awk -F',' '
    NR == 1 {
        # 读取表头
        for (i = 1; i <= NF; i++) {
            headers[i] = $i
        }
        next
    }
    {
        # 计算每行总和
        row_sum = 0
        for (i = 2; i <= NF; i++) {
            if ($i ~ /^[0-9]+(\.[0-9]+)?$/) {
                row_sum += $i
            }
        }
        
        # 输出结果
        printf "%-20s: %8.2f\n", $1, row_sum
        
        # 累加总计
        total_sum += row_sum
    }
    END {
        printf "\n%-20s: %8.2f\n", "总计", total_sum
    }
    ' "$csv_file"
}
```

### 4. Sed流编辑
```bash
#!/bin/bash

# 批量文件处理
batch_replace() {
    local pattern="$1"
    local replacement="$2"
    local directory="${3:-.}"
    
    find "$directory" -type f -name "*.txt" -print0 | while IFS= read -r -d '' file; do
        # 创建备份
        cp "$file" "${file}.bak"
        
        # 执行替换
        sed -i "s/$pattern/$replacement/g" "$file"
        
        echo "已处理: $file"
    done
}

# 配置文件管理
update_config() {
    local config_file="$1"
    local key="$2"
    local value="$3"
    
    # 检查键是否存在
    if grep -q "^$key=" "$config_file"; then
        # 更新现有键
        sed -i "s/^$key=.*/$key=$value/" "$config_file"
        echo "更新配置: $key=$value"
    else
        # 添加新键
        echo "$key=$value" >> "$config_file"
        echo "添加配置: $key=$value"
    fi
}

# 提取特定行
extract_section() {
    local file="$1"
    local start_pattern="$2"
    local end_pattern="$3"
    
    sed -n "/$start_pattern/,/$end_pattern/p" "$file" | sed '1d;$d'
}
```

## ⚡ 进程管理和并发

### 1. 后台任务
```bash
#!/bin/bash

# 启动后台任务
start_background_job() {
    local job_name="$1"
    local command="$2"
    
    # 启动后台进程
    eval "$command" &
    local pid=$!
    
    # 记录PID
    echo "$pid" > "/tmp/${job_name}.pid"
    echo "后台任务 '$job_name' 已启动 (PID: $pid)"
}

# 管理后台任务
manage_jobs() {
    case "$1" in
        list)
            jobs -l
            ;;
        stop)
            local job_name="$2"
            local pid_file="/tmp/${job_name}.pid"
            
            if [[ -f "$pid_file" ]]; then
                local pid=$(cat "$pid_file")
                kill "$pid" 2>/dev/null && echo "已停止任务: $job_name"
                rm -f "$pid_file"
            else
                echo "任务不存在: $job_name"
            fi
            ;;
        *)
            echo "用法: manage_jobs {list|stop <name>}"
            ;;
    esac
}
```

### 2. 并行处理
```bash
#!/bin/bash

# 使用xargs并行处理
parallel_process_files() {
    local input_dir="$1"
    local output_dir="$2"
    local max_processes="${3:-4}"
    
    find "$input_dir" -type f -name "*.txt" | \
        xargs -P "$max_processes" -I {} bash -c '
            input_file="$1"
            output_file="$2/$(basename "$input_file").processed"
            
            echo "处理: $input_file -> $output_file"
            process_single_file "$input_file" "$output_file"
        ' _ {} "$output_dir"
}

# 使用GNU Parallel (更强大)
parallel_process_with_gnu_parallel() {
    local input_dir="$1"
    local output_dir="$2"
    
    # 需要安装: apt-get install parallel
    find "$input_dir" -type f -name "*.txt" | \
        parallel --progress --jobs 4 '
            input={}
            output='$output_dir'/$(basename {}).processed
            process_single_file "$input" "$output"
        '
}

# 自定义并行控制
custom_parallel() {
    local tasks=("$@")
    local max_workers=4
    local current_jobs=0
    
    for task in "${tasks[@]}"; do
        # 等待有空闲worker
        while (( current_jobs >= max_workers )); do
            wait -n
            ((current_jobs--))
        done
        
        # 启动新任务
        (
            eval "$task"
        ) &
        
        ((current_jobs++))
    done
    
    # 等待所有任务完成
    wait
}
```

### 3. 信号处理
```bash
#!/bin/bash

# 信号处理函数
cleanup() {
    echo "收到中断信号，正在清理..."
    
    # 停止所有子进程
    pkill -P $$ 2>/dev/null
    
    # 清理临时文件
    rm -f /tmp/temp_*.$$
    
    echo "清理完成"
    exit 1
}

# 注册信号处理
trap cleanup INT TERM HUP

# 长时间运行的任务
long_running_task() {
    local duration="$1"
    
    echo "任务开始，将持续 ${duration}秒"
    
    for ((i=1; i<=duration; i++)); do
        echo "运行中... $i/$duration"
        sleep 1
        
        # 检查是否收到中断信号
        if [[ -f "/tmp/stop_signal" ]]; then
            echo "收到停止信号"
            rm -f "/tmp/stop_signal"
            break
        fi
    done
    
    echo "任务完成"
}
```

## 🏗️ 脚本架构设计

### 1. 模块化脚本
```bash
#!/bin/bash
# 主脚本: app.sh

# 加载配置
source "$(dirname "$0")/config.sh"

# 加载模块
for module in "$(dirname "$0")/modules"/*.sh; do
    source "$module"
done

# 初始化
init_app() {
    create_directories
    setup_logging
    load_configuration
}

# 主流程
main() {
    local command="${1:-help}"
    
    case "$command" in
        start)
            start_service
            ;;
        stop)
            stop_service
            ;;
        status)
            check_status
            ;;
        backup)
            create_backup
            ;;
        restore)
            restore_backup "$2"
            ;;
        help|*)
            show_help
            ;;
    esac
}

# 错误处理
handle_error() {
    local line="$1"
    local message="${2:-未知错误}"
    
    log_error "错误发生在第 $line 行: $message"
    send_alert "脚本错误: $message"
    exit 1
}

trap 'handle_error $LINENO' ERR

# 运行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_app
    main "$@"
fi
```

### 2. 配置文件示例
```bash
#!/bin/bash
# config.sh

# 应用配置
readonly APP_NAME="MyApplication"
readonly APP_VERSION="1.0.0"
readonly APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 目录配置
readonly LOG_DIR="${APP_DIR}/logs"
readonly DATA_DIR="${APP_DIR}/data"
readonly BACKUP_DIR="${APP_DIR}/backups"
readonly TEMP_DIR="${APP_DIR}/temp"

# 网络配置
readonly API_HOST="api.example.com"
readonly API_PORT="443"
readonly API_TIMEOUT=30

# 数据库配置
readonly DB_HOST="localhost"
readonly DB_PORT="3306"
readonly DB_NAME="app_db"
readonly DB_USER="app_user"

# 功能开关
readonly ENABLE_LOGGING=true
readonly ENABLE_BACKUP=true
readonly ENABLE_NOTIFICATIONS=false
readonly DEBUG_MODE="${DEBUG:-false}"

# 日志级别
if [[ "$DEBUG_MODE" == "true" ]]; then
    readonly LOG_LEVEL="DEBUG"
else
    readonly LOG_LEVEL="INFO"
fi
```

### 3. 日志模块
```bash
#!/bin/bash
# modules/logging.sh

# 日志初始化
init_logging() {
    mkdir -p "$LOG_DIR"
    
    local log_file="${LOG_DIR}/app_$(date '+%Y%m%d').log"
    exec 3>&1 4>&2
    exec > >(tee -a "$log_file") 2>&1
}

# 日志函数
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" | tee -a "${LOG_DIR}/app.log"
}

log_info() {
    log "INFO" "$*"
}

log_warning() {
    log "WARNING" "$*"
}

log_error() {
    log "ERROR" "$*"
}

log_debug() {
    if [[ "$DEBUG_MODE" == "true" ]]; then
        log "DEBUG" "$*"
    fi
}

# 日志轮转
rotate_logs() {
    local keep_days=30
    
    find "$LOG_DIR" -name "app_*.log" -mtime +$keep_days -delete
    find "$LOG_DIR" -name "app.log" -size +10M -exec mv {} "${LOG_DIR}/app_$(date '+%Y%m%d_%H%M%S').log" \;
}
```

## 🔒 安全最佳实践

### 1. 输入验证
```bash
#!/bin/bash

# 验证文件名
validate_filename() {
    local filename="$1"
    
    # 检查是否包含路径遍历
    if [[ "$filename" =~ \.\. ]]; then
        log_error "无效文件名: 包含路径遍历"
        return 1
    fi
    
    # 检查特殊字符
    if [[ "$filename" =~ [\"\'\`\$\\] ]]; then