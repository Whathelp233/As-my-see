# CUDA 流、事件与异步流水线

CPU 调用 CUDA API 返回得快，不等于 GPU 已完成对应工作。正确使用异步能力，需要同时理解 stream 的排队顺序、主机缓冲区的生命周期、跨 stream 依赖和目标 GPU 的复制能力。

## Stream 表达的是队列顺序

一个 CUDA stream 是有序的设备工作队列。同一 stream 中先提交的操作在后续依赖操作之前完成；不同 stream 的工作可以交错，也可能并发，但其先后关系不会由 CPU 提交顺序自动建立。

```text
stream A：帧 0 的 H2D → 帧 0 的 kernel → 帧 0 的 D2H → 完成事件
stream B：帧 1 的 H2D → 帧 1 的 kernel → 帧 1 的 D2H → 完成事件
```

这是让不同帧有机会重叠的一种组织方式，不保证执行器一定并发。设备复制引擎数量、共享带宽、kernel 占用、任务粒度和运行时调度都会影响结果。查询 `cudaDeviceProp.asyncEngineCount` 能了解设备能力，不能证明某一次运行发生了重叠。

传统 legacy default stream 会与普通 blocking stream 产生隐式同步；`cudaStreamNonBlocking` 创建的 stream 不与 legacy default stream 进行那类同步。是否使用 per-thread default stream 也会改变默认队列语义。为避免隐式依赖，性能敏感路径应显式传入 stream，并确认编译和运行时采用的默认流模式。

**API 片段：展示在指定 stream 提交 kernel；未运行。**

```cpp
cudaStream_t stream;
cudaStreamCreateWithFlags(&stream, cudaStreamNonBlocking);

cudaMemcpyAsync(device_input, host_input, bytes,
                cudaMemcpyHostToDevice, stream);
kernel<<<blocks, threads, 0, stream>>>(device_input, device_output);
cudaMemcpyAsync(host_output, device_output, bytes,
                cudaMemcpyDeviceToHost, stream);
```

同一 stream 的操作顺序保证输入先到达，再执行 kernel，最后写回结果。片段省略错误检查、缓冲区分配和释放；真正使用时，`host_input`、`host_output`、设备内存及 stream 都要由明确的所有者管理。

## Pinned memory 与异步传输

普通 host 内存可能是 pageable（可分页）内存。运行时为了和设备传输，可能先把它暂存到页锁定内存；`cudaMemcpyAsync` 也可能在某些 pageable 用法中出现主机阻塞或暂存。因此，不能只凭函数名有 `Async` 就断言复制与 kernel 已异步重叠。

同步 API 的返回时机也取决于传输方向和主机内存类型：pageable H2D 的同步调用可能在数据复制到 staging buffer 后就返回，而 DMA 到设备最终地址仍未完成；设备到 pinned 或 pageable host memory 的同步 D2H 则返回前会等复制完成。要测 H2D 设备传输时间，应在目标 stream 上放置事件或等待该 stream；只测 CPU 函数调用时间不够。

要可靠地安排主机与设备传输重叠，常用 `cudaMallocHost` 或 `cudaHostAlloc` 分配 pinned memory，并在确认所有设备访问结束后通过 `cudaFreeHost` 释放。pinned memory 仍是主机内存，不是显存，也不是自动零拷贝。页锁定分配比较重，应预分配并重复使用；过多 pinned 页面会挤压操作系统管理内存的空间。CPU 拆分、整理、复制和组装本身也可能成为瓶颈。

把批量小传输合并为较大连续传输，通常比逐字段发起大量小复制更有效，但可能增加 CPU 打包/解包开销。应根据上游和下游接口测完整成本。

## 缓冲区槽位与复用规则

使用两个或更多槽位可以在某一帧尚未完成时为后续帧提交工作。一种常见设计是每个槽位独占该帧的主机输入、主机输出、设备输入和设备输出，并关联一个 stream 与完成事件；stream 可以按槽位分配，也可以由多个阶段或槽位共享。关键条件是缓冲区在所有使用它的工作完成前保持有效且不被覆盖，并通过同一队列顺序或 event 明确建立依赖。

```text
槽位 0：拆分帧 0 → 上传 → 计算 → 下载 → 等完成 → 组装帧 0 → 复用
槽位 1：拆分帧 1 → 上传 → 计算 → 下载 → 等完成 → 组装帧 1 → 复用
```

环形缓冲区常按 `slot = frame_id % slot_count` 选择槽位。槽位再次使用前，必须先确认其中上一帧的完成事件已经触发；该事件应排在该帧最后一次访问槽位资源的工作之后。H2D 完成前不能改写对应主机输入，D2H 完成前不能读取主机输出；设备缓冲区在所有引用它的 kernel 和复制操作完成前都不能释放或复用，不能只等待 kernel 而忽略仍在读取设备输出的 D2H。正常退出、异常退出和尾部排空都必须等待最后在途工作结束。

若不同阶段分布在不同 stream，使用 `cudaEventRecord` 记录一个阶段的完成，再由 `cudaStreamWaitEvent` 建立跨 stream 依赖。不要依赖“CPU 先调用了哪个 stream”推断 GPU 工作的先后顺序。

## CUDA Event 的计时范围

CUDA Event 在指定 stream 的队列中记录一个时间点。把开始和结束事件放在同一 stream、同步结束事件后调用 `cudaEventElapsedTime`，可以测量这两个事件在该 stream 上的间隔。返回单位是毫秒。

**API 片段：展示同一 stream 中的 Event 计时顺序；未运行。**

```cpp
cudaEvent_t start_event;
cudaEvent_t stop_event;
cudaEventCreate(&start_event);
cudaEventCreate(&stop_event);

cudaEventRecord(start_event, stream);
kernel<<<blocks, threads, 0, stream>>>(...);
cudaEventRecord(stop_event, stream);
cudaEventSynchronize(stop_event);

float elapsed_ms = 0.0F;
cudaEventElapsedTime(&elapsed_ms, start_event, stop_event);
```

Event 测的是设备队列时间线，不等于 CPU 调用开销、线程等待和应用总延迟。中间的队列空隙或干扰工作会影响区间；如果开始和结束事件记录在多个 stream 中，必须有依赖关系并理解它们实际记录的位置。跨多个 stream 时，分别测出的 event 区间可以互相重叠，不能求和当作整批墙钟时间。

如需测 kernel 单独用时，先预热，确保区间没有不相关工作，并将结果与 CPU 端到端计时同时报告。Event 对极短工作也有观测开销和分辨率限制；重复运行与较长的批次有助于稳定观察。

## 用 Nsight Systems 看真实重叠

Nsight Systems 展示 CPU CUDA API 调用、GPU 内存复制、kernel、stream 与 NVTX 标记之间的关系。NVTX range 表示 CPU 代码区间；它可帮助把提交的工作定位到 GPU 时间线上，但 range 本身不是 kernel 执行区间。

在 GPU 时间线上选择同一批工作的 H2D、kernel 和 D2H，核对它们所在 stream、起止时间及帧/批次关联。三者存在共同重叠，才可声称三阶段在该次运行中同时进行。两两重叠只支持对应的两类活动有交叉。显示上的细小像素交叉应放大并检查时间戳，避免把绘图分辨率当作设备证据。

**示意时间，不是实测值：**

```text
下一帧 H2D：   [100, 160] 微秒
当前帧 kernel：[120, 145] 微秒
上一帧 D2H：   [110, 150] 微秒
共同区间：     [120, 145] 微秒
```

可用区间交集判断：

$$
\max(t_{H2D}^{start}, t_K^{start}, t_{D2H}^{start})
<
\min(t_{H2D}^{end}, t_K^{end}, t_{D2H}^{end})
$$

使用 NVTX 给批次、帧号和槽位命名可以提高可读性。先用 profiler 确认活动结构，再退出 profiler 用未插桩版本测端到端成绩；采样与时间线采集会扰动短 kernel。Nsight Compute 则更适合检查单 kernel 的访存、吞吐和资源使用，不用于替代整条应用时间线。

**采集命令示例：需要安装匹配目标系统的 Nsight Systems，并在被分析程序中按需加入 NVTX 或 CUDA Profiler API 标记。各版本支持的选项可能不同，应先查本机 `nsys profile --help`。**

```bash
nsys profile --trace=cuda,nvtx --output=run_trace ./application arg1 arg2
```

若只采集程序中 `cudaProfilerStart()` 与 `cudaProfilerStop()` 之间的范围，可使用 Nsight Systems 的 CUDA Profiler API capture range 选项；程序必须实际调用对应 API，否则不会触发预期采集。`nsys stats` 的报告名称会随版本变化，应先用 `nsys stats --help-reports` 查询，再用汇总报告看调用次数与累计时间。汇总值适合发现异常热点，不取代 GPU 时间线上的区间交叉证据。

## 如何读“没有重叠”

| 时间线现象 | 首要检查 |
| --- | --- |
| 只有 CPU API，没有 GPU 工作 | GPU 是否可用、采集是否覆盖到执行区间、CUDA tracing 是否成功 |
| 帧仍按上传、计算、下载完全串行 | 是否每帧全设备同步、是否复用了单一槽位、是否误用默认 stream |
| 多个 stream 有工作但时间不交叉 | 设备复制引擎、任务粒度、提交间隔、流间依赖和共享带宽 |
| kernel 很短而复制很长 | 运算是否太轻、传输量是否可减少、是否能把中间数据留在设备 |
| GPU 等待而 CPU 拆分/组装很长 | 主机转换和内存带宽是否限制输入供给 |
| CPU 等槽位很久 | GPU 是否仍有工作；等待本身不等于设备空闲 |

时间线适合解释“何时发生什么”，不单独回答“哪个指标更重要”。最终仍需在代表性负载中比较同一输入、同一包含范围下的端到端延迟和吞吐。

## 参考资料

- [CUDA Programming Guide：异步执行、stream 与同步](https://docs.nvidia.com/cuda/cuda-programming-guide/02-basics/asynchronous-execution.html)：默认流、事件依赖和异步错误。
- [CUDA Runtime API：Event Management](https://docs.nvidia.com/cuda/cuda-runtime-api/cuda_runtime_api/group__CUDART__EVENT.html)：Event 创建、记录、同步和计时单位。
- [CUDA Runtime API：API Synchronization Behavior](https://docs.nvidia.com/cuda/cuda-runtime-api/api-sync-behavior.html)：pageable/pinned 内存与不同复制方向的同步语义。
- [Nsight Systems User Guide](https://docs.nvidia.com/nsight-systems/UserGuide/index.html)：CUDA 时间线、NVTX 关联与采集方法。
- [Nsight Compute Profiling Guide](https://docs.nvidia.com/nsight-compute/ProfilingGuide/index.html)：kernel 指标、资源吞吐与计数器解释。
- [CUDA C++ Best Practices Guide](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/index.html)：pinned memory 与传输计算重叠条件。
