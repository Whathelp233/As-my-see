# CUDA 执行模型与数据通路

CUDA 是 NVIDIA GPU 的并行编程平台。典型程序由 CPU 负责准备输入、管理资源和提交工作，GPU 负责适合并行执行的数值计算。安装 GPU 不会自动让普通 C++ 或 ROS 节点获得加速；应用必须把计算与数据显式交给 CUDA 或使用基于 CUDA 的库。

矩阵乘法、FFT 和深度学习等常见运算通常先评估 cuBLAS、cuFFT、cuDNN 或成熟推理框架；自写 kernel 适合用来实现尚未覆盖的热点或专用融合路径。矩阵、FFT 和网络运算的算法正确性不由本篇展开。

本篇用每点独立的二维坐标变换说明从 CPU 循环迁移到 GPU 的思路。例中坐标单位为米，教学参数不代表传感器外参。

刚体变换的先后次序会改变结果。以教学点 $p=(2.0,1.0)$、平移 $t=(0.3,0)$ 和逆时针 90° 旋转矩阵 $R$ 为例，$R(p+t)=(-1.0,2.3)$，而 $Rp+t=(-0.7,2.0)$。必须依据算法定义确定次序，不能把平移和旋转随意调换。

## 从循环到 kernel

若每个输入点只影响对应输出点，可以为每个点分配一个 GPU 线程。线程在 grid 中的全局索引为：

$$
i = \text{blockIdx.x} \times \text{blockDim.x} + \text{threadIdx.x}
$$

其中 thread 是执行单元，block 是可在块内协作的一组线程，grid 是一次启动的全部 block。坐标变量 `x` 与线程组织中的维度 `threadIdx.x` 是两个不同概念。

**CUDA 代码片段：展示索引和边界判断；省略错误检查、资源所有权与完整程序，不可直接作为生产实现。**

```cpp
__global__ void translatePoints(
    const float2* input, float2* output, int count, float offset_x) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < count) {
        output[i].x = input[i].x + offset_x;
        output[i].y = input[i].y;
    }
}

// count 为正时，覆盖所有元素并为向上取整的尾部线程保留边界检查。
const int threads = 256;
const int blocks = (count + threads - 1) / threads;
if (count > 0) {
    translatePoints<<<blocks, threads>>>(input, output, count, 0.3F);
}
```

块大小 256 只是示例。一个 block 里的线程数通常要是 warp 宽度的倍数，但合适的配置取决于寄存器、共享内存、访存和每个 block 的工作量。点数为 0 时应跳过 kernel 启动；线程索引需要使用足以容纳最大元素数的整数类型。不能假设 block 会按编号顺序执行。

同一个 warp 的相邻线程若访问相邻或紧邻的地址，硬件较容易合并访存请求。`if` 本身不表示低效；同一 warp 的线程若走不同分支，才可能因分支分歧而串行执行不同路径。正确的越界检查优先于删除一个必要分支。

## 内存层级和协作边界

| 资源 | 可用范围与注意点 |
| --- | --- |
| Register | 每线程私有、延迟低、容量有限；寄存器压力过高可能降低同时驻留的 warp 数，甚至溢出到更慢的本地存储。 |
| Shared memory | 同一 block 的线程可协作访问的片上存储；需显式管理加载、同步和 bank 访问。 |
| Global memory | 可由设备各线程访问的大容量内存；跨 kernel 保留的数据通常放这里，访问仍受带宽和缓存影响。 |
| Constant memory | 面向只读、适合广播访问等特定模式的缓存路径，不是所有只读数组的默认最佳选择。 |
| Local memory | 名称不表示片上高速；通常是线程私有的地址空间抽象，可能落在设备内存。 |

`__syncthreads()` 只在一个 block 内建立协作屏障，不能让整个 grid 停在同一全局阶段。`atomicAdd` 能保护特定共享更新免于丢失，但不提供全局阶段屏障；reduction（归约）则需把多个局部结果按定义的规则合并。跨 block 的全局依赖通常要拆成多个 kernel 或使用其他显式同步机制。

## AoS、SoA 与实际访存

AoS（结构体数组）将每点字段放在一起，例如 `x0,y0,x1,y1,...`；SoA（数组结构体）将同一字段放在一起，例如 `x0,x1,...` 和 `y0,y1,...`。一个 warp 只读 `x` 时，SoA 的地址通常更连续；AoS 也可以合并访存，缓存还可能复用同一结构体中邻近字段。

如果每个 `float` 为 4 字节、每个点恰有两个连续 `float`，32 个线程分别读取 AoS 中的 `x`，地址步长是 8 字节；SoA 中读取 `x[i]` 的步长是 4 字节。基地址、访问宽度、对齐、编译器指令和缓存都会影响实际事务，不能由地址步长直接推导 kernel 快多少。

布局转换也有成本。外部接口是 AoS 时，改用 SoA 可能增加 CPU 拆分/组装、复制调用次数和暂存内存。若上下游本来就能接受 SoA，成本结构才会不同。比较时要计入真实接口要求的转换和拷贝，而不是只计 GPU 内一段访问。

## 先减少搬运，再优化计算

常见的完整数据流是：

```text
CPU 输入 → 设备内存分配 → H2D 上传 → kernel → D2H 下载 → CPU 使用结果
```

H2D 是 host-to-device，D2H 是 device-to-host。`cudaMalloc` 只分配设备内存；它不会上传数据。复制 API 的字节数应按 `count * sizeof(element)` 计算，并检查整数溢出。设备指针只是地址；缓冲区的所有者必须保证它在所有异步使用结束前都有效。

GPU 计算单元的吞吐可能很高，但主机与设备间的传输通常比设备内部访存更慢。优先考虑减少传输次数、合并小块传输、复用设备中间结果。若某个中间数组仍留在设备上由后续 kernel 使用，就可以避免回传再上传。具体收益取决于硬件互连、数据规模、同步和主机端处理成本。

连续的坐标变换、阈值和标记等逐点操作可以考虑融合：每个线程读取本点，在寄存器中依次计算，只写最终结果。这样可能减少 kernel 启动和中间读写；按 4 字节 `float` 的教学布局，三个独立 kernel 可能有更多逻辑读写，而一个融合 kernel 可复用线程局部值。源代码估算的逻辑字节数不等于 DRAM 实际流量，缓存和编译器会改变真实行为。

融合也可能增加寄存器压力、导致寄存器溢出，或让原本可并发的工作失去并行机会。高 occupancy 不是独立目标：它描述硬件上可同时驻留的 warp 比例，不能单独证明性能更好。需要依算法依赖决定是否融合；邻域滤波、全局归约和跨 block 的阶段不能仅通过拼接函数体来消除同步。

## 同步与错误检查

同一 stream 中的操作按提交顺序执行，因此同一帧的 H2D、kernel、D2H 可以用队列顺序表达依赖，而不必每步都让 CPU 等待。跨 stream 没有默认的先后顺序；需要显式 event 依赖。过早调用 `cudaDeviceSynchronize()` 会把 CPU 等待插入流水线，限制重叠机会。

**API 片段：说明 kernel 启动错误检查与异步执行错误的区别；省略错误处理封装。**

```cpp
kernel<<<blocks, threads, 0, stream>>>(...);
cudaError_t launch_error = cudaGetLastError();
// 检查 launch_error。执行期错误通常要在 stream/event 同步时检查。
cudaError_t execution_error = cudaStreamSynchronize(stream);
```

kernel 启动语法不直接返回错误码。紧接启动检查可以发现部分同步的启动错误；非法访问等执行错误可能直到 stream 或 event 同步才报告。`cudaGetLastError()` 返回并清除同一 CUDA Runtime 库实例中、当前主机线程的最近错误状态；静态链接的库可能带来多个 Runtime 实例。它不表示工作已经完成。每个 CUDA API 的返回值都应处理；一次全设备同步不应代替对资源生命周期和 stream 依赖的正确设计。

## 何时由 CPU 做更合适

状态机、串口协议解析、少量分支控制和消息调度通常需要大量顺序决策，却没有足够数据并行度。对小任务，kernel 启动、传输、格式转换和同步可能比计算本身更贵。应先测端到端成本，再决定是否把单个算子或整条数据管线放到 GPU。

涉及坐标变换的真实系统应使用定义明确的刚体变换和坐标系约定，见[坐标变换与传感器标定](../坐标变换与传感器标定/坐标系、刚体变换与TF.md)。本篇中的点坐标例只用来展示并行映射，不替代外参定义。

## 参考资料

- [CUDA C++ Programming Guide：编程模型与并行执行](https://docs.nvidia.com/cuda/cuda-programming-guide/index.html)：线程、block、grid、同步和异步执行。
- [CUDA Runtime API：Error Handling](https://docs.nvidia.com/cuda/cuda-runtime-api/cuda_runtime_api/group__CUDART__ERROR.html)：last-error 状态的线程和 Runtime 实例范围。
- [CUDA C++ Best Practices Guide：内存优化](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/index.html)：数据传输、pinned memory、访存布局与减少搬运。
