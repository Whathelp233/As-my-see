# POSIX 文件 I/O、设备控制与套接字

Unix-like 系统把文件、管道、终端、设备和套接字暴露为可操作的对象。应用通过整数文件描述符（file descriptor, fd）引用这些对象，再调用 `read`、`write`、`ioctl` 或套接字接口。调用结果受对象类型、标志、缓冲区、权限与当前状态影响；一次系统调用不一定完成整个应用层操作。

## 文件描述符与 open

`open` 成功后返回一个非负整数 fd；失败返回 `-1` 并设置 `errno`。fd 是进程文件描述符表中的索引，不是指针，不是对象的固定内存地址，也不是权限本身。`close` 后该整数可被后续打开操作复用。Linux `open` 建立的 open file description 持有文件偏移和文件状态标志；复制 fd 可能让多个描述符引用同一 open file description。

打开时应先确定目的，再选择访问模式与标志。常见标志有 `O_RDONLY`、`O_WRONLY`、`O_RDWR`、`O_CREAT`、`O_TRUNC`、`O_APPEND` 和 `O_CLOEXEC`。其中 `O_TRUNC` 会清空已有文件；`O_CREAT` 允许创建文件且需要提供权限模式，最终权限还受进程 umask 影响。`O_CLOEXEC` 可避免 fd 意外泄漏给随后执行的子程序。注意任何会创建、覆盖、写入或改配置的命令与程序都需要明确授权的目标和目录。

## read 与 write 的返回值

`read(fd, buffer, count)` 和 `write(fd, buffer, count)` 操作的是最多 `count` 个字节。成功时返回实际传输字节数；这可能小于请求值。对普通文件和流套接字，`count > 0` 时 `read` 返回 0 通常表示文件结束或对端有序关闭；错误返回 `-1` 并设置 `errno`。终端和设备的含义由驱动及配置决定，例如终端的 `VMIN`/`VTIME` 组合可能让 `read` 在超时或暂时无数据时返回 0，不能把所有设备的 0 都解释为断连。对于非阻塞 fd，暂时没有数据或空间时可能报告 `EAGAIN`/`EWOULDBLOCK`；被信号打断时需要按返回值与 `errno` 判断是否重试。

**一次成功的 `write` 不保证写完全部字节；一次成功的 `read` 也不保证读满缓冲区。** 对普通文件、管道、终端、套接字，阻塞与短读短写的具体条件不同。对 `SOCK_STREAM`，读写还不保留发送端每次调用的消息边界。应用协议必须自己描述长度、分隔符或固定帧格式。

以下为**API 片段，说明控制流程，未作为独立程序运行**。真实代码还需处理边界、缓冲区生命周期、非阻塞 I/O 和资源释放：

```c
/* 发送恰好 length 个字节时，维护已发送偏移量。 */
size_t offset = 0;
while (offset < length) {
    ssize_t n = write(fd, data + offset, length - offset);
    if (n > 0) {
        offset += (size_t)n;
    } else if (n < 0 && errno == EINTR) {
        continue;
    } else {
        /* 按 errno 分类处理 EAGAIN、断连、权限或 I/O 错误。 */
        break;
    }
}
```

系统调用失败时检查调用返回值与 `errno`，而不是只看打印文本。写入错误有时会在稍后的 `fsync` 或 `close` 才报告；若需要确认数据交给存储层，应了解 `fsync`、`fdatasync` 和文件系统的持久化语义。仅调用 `close` 不代表数据已经物理持久化。

## O_DIRECT 与内存对齐

`O_DIRECT` 是 Linux 文件 I/O 的特定标志，可能绕过或减少页缓存参与，但它不等于同步持久化，也不保证任何工作负载都会更快。文件系统、内核版本和设备会决定约束；用户缓冲区地址、文件偏移和传输长度都可能有对齐要求。

`posix_memalign` 可申请满足指定字节对齐的内存。对齐参数必须是 2 的幂，且是 `sizeof(void *)` 的倍数；成功返回 0，失败返回错误码（不是通过 `errno` 报错）。不要把固定 4096 字节当成所有设备的通用对齐要求。较新的 Linux 可通过 `statx` 的 `STATX_DIOALIGN` 查询文件的直接 I/O 内存和偏移约束，但支持情况因内核和文件系统而异。若实际不需要直接 I/O，优先从普通缓存 I/O 开始，用测量结果决定是否引入这种复杂约束。

## ioctl：设备专用控制接口

`ioctl(fd, request, ...)` 用于读取或修改设备相关状态。`fd` 必须指向支持该请求的对象，`request` 与第三参数的结构及方向由具体接口定义。Linux 中许多 UAPI 请求会用宏编码操作方向和参数大小，但这不是一套对所有驱动都完全一致的通用协议。

编写或调用 `ioctl` 时应：

1. 查该设备或子系统的官方 API/UAPI 头文件和版本说明。
2. 使用对应结构体，不根据旧文章猜测指针布局或字段长度。
3. 检查 `fd`、请求码、输入范围与结构体生命周期。
4. 检查返回值、`errno`，并处理权限、设备不支持或内核版本差异。
5. 尽可能优先使用稳定的专用 API；网络接口信息通常可通过 `getifaddrs` 或标准网络配置工具获取，而不是依赖旧式私有 ioctl。

## 套接字与连接顺序

`socket(domain, type, protocol)` 创建通信端点并返回 fd。`domain` 指地址族，例如本地通信、IPv4 或 IPv6；`type` 定义数据语义；`protocol` 可明确协议，也可在组合唯一时使用 0。

- `SOCK_STREAM` 提供有序、可靠的双向字节流，但没有消息边界。
- `AF_INET`/`AF_INET6` 上的 `SOCK_DGRAM` 通常表示 UDP：保留报文边界，但不保证可靠或有序交付。数据报语义取决于地址族和协议；例如 Linux `AF_UNIX` 数据报在本机提供可靠传递且不重排，不能把 UDP 的性质推广到所有数据报套接字。

典型 TCP 服务端流程是：

```text
socket → bind → listen → accept → read/write 或 recv/send → close
```

客户端通常是：

```text
socket → connect → read/write 或 recv/send → close
```

`bind` 把本地地址绑定到套接字，`listen` 让连接套接字进入被动接收状态，`accept` 为一个新连接返回新的 fd；监听 fd 仍然可用于接收后续连接。客户端 `connect` 请求建立连接。`listen` 的 backlog 是内核排队边界之一，内核会结合系统配置进行限制。

IPv4 的地址结构和 IPv6 的地址结构不同。新代码通常使用 `getaddrinfo` 解析主机和服务名，并按其返回地址族创建、连接或绑定；不要硬编码只有 IPv4 的 `sockaddr_in` 假设。网络协议中的整数还要注意网络字节序，端口等 16 位值用 `htons`/`ntohs`，32 位值用 `htonl`/`ntohl` 转换。

## 资源与错误语义

fd 的生命周期必须和对象使用范围一致。普通 C++ 代码可用一个只拥有 fd 的 RAII 类型，在析构时关闭资源；复制对象时要么禁止复制，要么显式 `dup` 并定义共享语义。多个线程并发 `read/write/close` 同一个 fd 时需要规定所有权与关闭时序，避免 fd 被关闭后复用到别的对象。

I/O 错误需要按接口语义分类：EOF、暂时不可用、连接关闭、对端重置、权限拒绝、无效请求和资源耗尽含义不同。超时后不应假定远端没执行请求；带副作用的网络命令需有请求标识、幂等策略或状态查询。异步任务、取消和结果所有权由 [软件模块与异步任务](../ROS与软件架构/软件模块与异步任务.md) 主讲，本篇只覆盖操作系统接口层。

## 参考资料

- [open(2)](https://man7.org/linux/man-pages/man2/open.2.html)、[read(2)](https://man7.org/linux/man-pages/man2/read.2.html)、[write(2)](https://man7.org/linux/man-pages/man2/write.2.html)：fd、打开标志、短读短写和错误语义。
- [close(2)](https://man7.org/linux/man-pages/man2/close.2.html)：fd 关闭、复用与持久化注意事项。
- [ioctl(2)](https://man7.org/linux/man-pages/man2/ioctl.2.html)：设备相关请求的调用约定。
- [posix_memalign(3)](https://man7.org/linux/man-pages/man3/posix_memalign.3.html) 与 [statx(2)](https://www.man7.org/linux/man-pages/man2/statx.2.html)：内存对齐和按文件查询直接 I/O 对齐约束。
- [socket(2)](https://man7.org/linux/man-pages/man2/socket.2.html)、[listen(2)](https://man7.org/linux/man-pages/man2/listen.2.html)、[socket(7)](https://man7.org/linux/man-pages/man7/socket.7.html)、[unix(7)](https://man7.org/linux/man-pages/man7/unix.7.html)：套接字类型、连接流程、字节流与本地数据报语义。
- [byteorder(3)](https://man7.org/linux/man-pages/man3/byteorder.3.html)：主机字节序与网络字节序转换。
