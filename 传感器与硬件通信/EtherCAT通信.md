# EtherCAT 通信

EtherCAT 是一种工业以太网现场总线，通常由主设备发起周期通信，从设备在经过的以太网帧中读取或写入映射到自己的数据。与逐个设备建立独立 TCP/IP 会话不同，主站可在一个周期帧中与多个从站交换过程数据；典型设备通过 EtherCAT 从站控制器实现帧转发和局部数据处理。实际网络拓扑、性能与可用服务取决于主站、从站和所选协议配置。

## 周期帧、PDO 与 SDO

EtherCAT 设备往往同时提供周期过程数据和非周期配置通道。若设备使用 CoE（CAN application protocol over EtherCAT），常见概念包括对象字典（OD）、过程数据对象（PDO）和服务数据对象（SDO）：

| 对象 | 主要用途 | 典型传输方式 |
| --- | --- | --- |
| PDO | 按周期交换控制量、状态量和测量值 | 周期过程数据，映射关系在配置阶段确定 |
| SDO | 读取或写入对象字典中的参数和状态 | 邮箱服务，按需发起的非周期读写 |
| OD | 用索引和子索引组织设备参数与状态对象 | CoE 对象访问的逻辑数据模型 |

`RxPDO` 与 `TxPDO` 是从站视角的方向：RxPDO 由从站接收，TxPDO 由从站发送。不同从站可以有固定映射，也可以允许主站在启动配置阶段选择变量和位宽。只有设备支持 CoE 时，才应将 PDO/SDO/OD 这一组 CANopen 概念用于它；EtherCAT 还可以承载 SoE、EoE、FoE 等其他通信 profile。[EtherCAT Technology Group：CoE](https://www.ethercat.org/en/technology.html)

典型数据流是：根据设备描述文件及制造商文档检查从站能力 → 配置通信状态和 PDO 映射 → 将周期缓冲区解释为有明确偏移、宽度、符号和单位的字段 → 在控制周期内读取状态并写出命令。改变 PDO 内容会改变过程映像布局，不能只改一个解析偏移后就假设协议仍兼容。

## 工作计数器和故障检查

每个 EtherCAT datagram 都有 Working Counter（WKC）。按 datagram 所指向的地址和操作类型，从站在成功完成相应内存读写时增加计数；主站将返回值与该 datagram 的预期 WKC 比较，以发现部分从站没有按预期处理该操作。WKC 是过程数据交换是否经过预期内存交互的诊断证据，**不是应用层命令已执行、动作安全或传感器值正确的证明**。[ETG：Working Counter 说明](https://www.ethercat.org/forms/france2016/download/03_EtherCAT_Installation_Troubleshooting_1609.pdf)

当 WKC 不符时，逐层检查从站是否进入预期状态、PDO 映射是否一致、数据长度与方向是否匹配、线路与设备是否稳定，以及主循环是否按时收发。不要把某一帧缺失简单解释为“EtherCAT 通信不可靠”，也不要仅凭 WKC 正常就略过数据范围、时间戳和设备状态检查。

## EtherCAT 状态机与驱动生命周期

EtherCAT 从站常见状态包括 `INIT`、`PRE-OP`、`SAFE-OP` 和 `OP`。通常，`PRE-OP` 可用于邮箱访问与配置，`SAFE-OP` 可开始提供输入过程数据但仍限制输出，`OP` 才允许正常交换输入与输出过程数据；具体可用服务、状态转换和安全输出行为应核对对应从站文档。该总线状态机与 ROS 节点或 `ros2_control` 硬件组件的 lifecycle 是不同层级。

主站或硬件组件在 configure 阶段发现设备并建立通信、配置状态机与 PDO；激活时才允许正常控制输出；停用时先让输出进入安全状态，再关闭周期任务和通信。错误恢复应明确指出设备未发现、状态转换超时、PDO 尺寸不匹配、WKC 异常或过程数据超时中的哪一类。`ros2_control` 硬件组件的生命周期 API 随 ROS 发行版变化，版本细节见目标发行版的[官方硬件生命周期文档](https://control.ros.org/rolling/doc/ros2_control/hardware_interface/doc/lifecycle_of_a_hardware_component.html)。

总线主循环、硬件驱动线程和 ROS executor 回调也不能互相替代。周期任务需要有可预期的调度、明确缓冲所有权和有界工作量；不可控的日志、磁盘操作、阻塞服务和耗时序列化不应无评估地进入实时周期。[ROS 与软件架构](../ROS与软件架构/节点执行与组件化架构.md)介绍 ROS 执行模型，[机器人运动学与控制](../机器人运动学与控制/ROS控制器与实时数据流.md)介绍控制循环及执行器接口。

## 分布式时钟

EtherCAT Distributed Clocks（DC）利用从站控制器中的本地时钟和参考时钟，使支持 DC 的设备在硬件时间轴上对齐，并补偿传播时延。同步精度来自设备时钟和网络配置，不意味着主机时钟天然与 UTC 或 ROS 时间相同，也不意味着传感器在同一触发相位曝光或采样。采样时刻、DC 时钟、主机接收时刻和 ROS 时间仍要显式建立映射。[ETG：Distributed Clocks](https://prelive.ethercat.org/technology/knowledge-base/dc-distributed-clocks/)

## CAN、EtherCAT 与上层协议的边界

CAN 与 EtherCAT 都可用于实时工业通信，但帧格式、仲裁、拓扑、数据映射和错误报告机制不同。不能把 CAN ID 直接套成 EtherCAT 从站地址，也不能因为 CoE 复用了 CANopen 的 OD/PDO/SDO 概念，就认为底层 EtherCAT 等同于 CAN 总线。异步配置流、周期过程映像和应用命令响应各自有自己的边界。

## 参考资料

- [EtherCAT Technology Group：EtherCAT 技术概览](https://www.ethercat.org/en/technology.html)
- [ETG：PDO 映射与配置](https://prelive.ethercat.org/technology/knowledge-base/pdo-mapping-and-configuration/)
- [ETG：SDO 服务](https://prelive.ethercat.org/technology/knowledge-base/sdo/)
- [ETG：分布式时钟](https://prelive.ethercat.org/technology/knowledge-base/dc-distributed-clocks/)
- [ETG：Working Counter 与安装诊断](https://www.ethercat.org/forms/france2016/download/03_EtherCAT_Installation_Troubleshooting_1609.pdf)
- [ros2_control：硬件组件生命周期（Rolling）](https://control.ros.org/rolling/doc/ros2_control/hardware_interface/doc/lifecycle_of_a_hardware_component.html)
