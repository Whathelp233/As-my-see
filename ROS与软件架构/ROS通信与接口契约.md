# ROS 通信与接口契约

机器人软件由多个独立节点组成。通信接口要让发布方、订阅方和运维工具对“数据代表什么、何时有效、失败如何表达”形成一致理解。ROS 会处理序列化、发现和传输，但不会替应用定义单位、时效性、错误恢复和安全边界。

## 1. 节点图与命名

节点是可独立运行或组合运行的计算单元。节点通过名称加入图，名称通常由命名空间、节点名和重映射规则共同决定。主题、服务、动作和参数也有名称；相同短名称在不同命名空间中可能指向不同资源。诊断时要确认解析后的完整名称、消息类型和发布者/订阅者数量，而不是只凭源码里的字符串判断。

ROS 1 中，ROS Master 提供注册和发现入口。节点登记其 XML-RPC 地址，节点间根据协商结果建立数据连接；Master 不转发每条消息。Master 不可用会影响新节点发现和图更新，但已经建立的数据连接可能继续工作一段时间。在常见 ROS 2 DDS RMW 实现中，DDS/RTPS 提供发现与数据交换；RMW 层也支持非 DDS 中间件实现，例如 Zenoh。ROS 2 节点图发现通常不需要中心 Master。发现成功仍取决于域、网络接口、防火墙、中间件实现和 QoS 等条件，不能据此断言端到端应用已就绪。

## 2. 选对通信语义

| 机制 | 数据模型 | 适用场景 | 设计重点 |
| --- | --- | --- | --- |
| Topic | 发布/订阅的连续数据流，发布者和订阅者可多对多 | 传感器测量、状态、命令流 | 时间戳、坐标系、队列长度/QoS、过期数据和过载策略 |
| Service | 一次请求对应一次响应 | 查询、短时配置和确定性的读写操作 | 超时、可重复请求、副作用、明确的错误结果；长耗时工作不应假装是同步服务 |
| Action | 一个带目标的异步任务，具有接受/拒绝、反馈、最终结果和取消过程 | 路径跟踪、抓取、标定等可观察且可能取消的任务 | 目标所有权、抢占/取消语义、进度、终态、失败和超时 |

Action 不是“能持续发反馈的 Service”这么简单：它需要定义目标被拒绝时如何响应、取消是立即停还是进入受控停止、结果何时成为终态，以及同一服务器同时接受多个目标时的仲裁。ROS 1 `actionlib` 和 ROS 2 Action API 名称与消息类型不同，概念可以迁移，代码不能直接互换。

Topic 通常用于持续状态而非“必须被执行一次”的命令。若消费方短暂离线也不能丢失任务，应由 Action、持久化队列或上层确认协议表达，而不是仅提高 topic 队列长度。Service 适合较短且边界清晰的请求；调用者需要设置等待策略，不能在实时循环或必须继续处理回调的线程上无限等待。

## 3. 接口契约要写全

一个可用的消息定义不仅是字段列表。每个字段应说明：

- 语义和单位，例如角度是 rad 还是 deg，长度是 m 还是 mm；
- 坐标系，以及该坐标系标识来自哪个字段；
- 时间戳代表采样时刻、发送时刻还是处理完成时刻；
- 有效范围、未知/无效值的表达方式和数据是否允许为空；
- 序列号、来源标识或版本信息是否用于去重和乱序检测；
- 协方差、置信度、状态码等字段的含义和约定；
- 请求的权限、前置条件、超时、重试安全性和终止条件。

若消息携带位姿或速度，仅字段名不足以确定 frame。上游需提供明确 frame_id 和时间基准，下游需检查变换可用性与数据年龄。数学定义和坐标变换细节见[坐标变换与传感器标定](../坐标变换与传感器标定/坐标系、刚体变换与TF.md)。

错误码应属于稳定、可记录和可测试的接口契约。建议区分：输入无效、资源忙、前置条件未满足、暂不可用/超时、执行失败、取消和内部故障。不要把错误码直接暴露成硬件寄存器或私有业务状态，也不要只返回布尔值而让调用方猜测原因。若错误导致安全降级，结果应同时说明“动作是否已经开始、是否有副作用、是否还在运行”。

接口演进不能假定“新增字段就是向后兼容”。ROS 1 消息定义参与 MD5 类型标识，字段变化通常要求发布/订阅两端使用一致定义并重新生成、编译；ROS 2 的接口定义也会影响类型描述与类型 hash，但不同 ROS 发行版、RMW 和传输实现对类型兼容/演进的支持不同，也不能把 `.msg` 字段当成普遍可选字段。对会破坏既有消费者的语义或结构变化，优先定义显式版本类型，并在边界节点提供适配器；若采用原类型更新，则要按目标版本验证协同升级和 rosbag 等记录数据的可读性。重命名、改单位、改时间语义或改变终态都应作为接口变更评审。对 topic 消费者、service/action 客户端和记录工具都要检查迁移影响。

## 4. ROS 2 QoS：传输策略是契约的一部分

ROS 2 QoS 常涉及历史缓存策略、深度、可靠性、持久性、deadline、liveliness 和 lifespan。QoS 兼容性由发布端与订阅端的请求/提供策略共同决定；端点能发现但策略不兼容时，仍可能收不到数据。

- `reliable` 尽量重传以提高交付可靠性，但带来额外状态与开销，不表示应用已经及时处理消息。
- `best_effort` 不做可靠重传，允许丢失，常适合高频且新值覆盖旧值的测量流。
- `volatile` 不为后来加入的订阅者保留历史样本；`transient_local` 可在发布者仍存活时向新订阅者提供保留样本，常用于低频静态配置或状态快照。
- `keep_last(depth)` 只保留最近有限样本；深度不足或回调处理过慢会导致旧样本被丢弃。
- `deadline`、`liveliness`、`lifespan` 可帮助发现更新间隔、发布者存活和消息时效问题，但应用仍需处理超时与安全状态。

QoS 要按数据用途选择，而不是统一使用可靠、高深度。传感器数据过时后价值往往低于丢包；任务状态或配置快照通常更重视可靠性和后来加入的观察者可见性。检查 QoS 的方法是同时查看两端 profile、发现状态、回调频率和处理耗时。

ROS 1 的 `queue_size` 不是 ROS 2 QoS 的同义词。TCPROS/UDPROS、队列长度、latching 等 ROS 1 行为应按 ROS 1 工具链单独诊断，不要拿 ROS 2 DDS 参数解释 ROS 1 连接。

## 5. 录包、回放与故障定位

录包应连同消息类型定义、QoS/连接信息、仿真时间设置和软件版本记录。ROS 1 `rosbag` 与 ROS 2 `rosbag2` 是不同工具，CLI 与存储格式不可混用。回放用于重现数据流，不等同于完整仿真：时钟、外部服务、动作服务器、硬件副作用和启动顺序可能与实时系统不同。

排障按层检查：

1. 节点是否存在，名字是否按命名空间和 remap 解析为预期值？
2. 发布者/订阅者的类型、接口版本、QoS 或 ROS 1 传输协议是否匹配？
3. 数据是否真的发布、时间戳是否推进、回调是否被执行？
4. 消费者处理速度是否低于输入速率，是否发生队列覆盖、延迟增长或阻塞？
5. 调用方是否等待在不可重入的回调上，服务端是否忙或生命周期不允许处理？
6. 错误是否被映射到稳定的状态码，重试是否造成重复副作用？

ROS 2 C++ API 片段，展示 QoS 作为端点配置的一部分；这是非独立运行示例：

```cpp
auto qos = rclcpp::QoS(rclcpp::KeepLast(5)).best_effort();
auto sub = node->create_subscription<sensor_msgs::msg::LaserScan>(
  "scan", qos,
  [](sensor_msgs::msg::LaserScan::ConstSharedPtr msg) {
    // 检查时间戳、frame_id 和数据有效性后再处理。
  });
```

ROS 1 `roscpp` API 片段，与上方 ROS 2 代码不可混编：

```cpp
ros::NodeHandle nh;
ros::Subscriber sub = nh.subscribe<sensor_msgs::LaserScan>(
  "scan", 5,
  [](const sensor_msgs::LaserScan::ConstPtr& msg) {
    // ROS 1 队列长度；不是 ROS 2 QoS 配置。
  });
```

## 参考资料

- [ROS 2 Topics, Services, and Actions](https://github.com/ros2/ros2_documentation/blob/rolling/source/ROS-Framework/interfaces/Topics-Services-Actions.rst)
- [ROS 2 Quality of Service settings](https://github.com/ros2/ros2_documentation/blob/rolling/source/ROS-Framework/interfaces/topics/About-Quality-of-Service-Settings.rst)
- [ROS 2 middleware implementations](https://github.com/ros2/ros2_documentation/blob/rolling/source/ROS-Framework/client-libraries/About-Middleware-Implementations.rst)
- [ROS 2 interface type descriptions (REP-2011)](https://www.ros.org/reps/rep-2011.html)
- [ROS 2 Recording and playing back data](https://github.com/ros2/ros2_documentation/blob/rolling/source/ROS-Framework/interfaces/Working-with-interfaces/Recording-And-Playing-Back-Data/Recording-And-Playing-Back-Data.rst)
- [ROS 1 Concepts: ROS graph](https://wiki.ros.org/ROS/Concepts)
- [ROS 1 message serialization and MD5 sums](https://wiki.ros.org/ROS/Technical%20Overview#Message_serialization_and_msg_MD5_sums)
- [ROS 1 actionlib](https://wiki.ros.org/actionlib)
