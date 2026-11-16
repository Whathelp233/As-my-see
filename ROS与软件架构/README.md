# ROS 与软件架构

本模块介绍 ROS 如何组织机器人软件：节点之间怎样约定并传输数据，回调由谁执行，复杂任务怎样表达生命周期与状态，以及 URDF 和硬件接口怎样把模型接到运行系统。重点是可迁移的架构和接口语义；具体机器人运动学、传感器驱动算法、定位导航算法和界面线程实现由相邻模块主讲。

## 前置知识

- 能读基本的 C++ 或 Python，理解进程、线程、函数回调和配置文件。
- 熟悉 Linux 文件、环境变量和终端的基础操作。
- 了解机器人由刚性部件和关节构成；坐标变换的数学推导见[坐标变换与传感器标定](../坐标变换与传感器标定/README.md)，本模块仅说明 URDF 中坐标关系的接口用途。

## 建议阅读顺序

1. [ROS 通信与接口契约](ROS通信与接口契约.md)：从节点图、Topic、Service、Action 和 QoS 建立通信模型。
2. [节点执行与组件化架构](节点执行与组件化架构.md)：理解包、命名空间、参数、Launch、执行器、插件与组件。
3. [软件模块与异步任务](软件模块与异步任务.md)：设计模块边界、任务队列、错误传播、日志背压与退出过程。
4. [生命周期、状态机与行为树](生命周期、状态机与行为树.md)：将单节点生命周期、业务状态机和跨模块任务编排区分开。
5. [URDF 机器人描述与硬件接口](URDF机器人描述与硬件接口.md)：从 link/joint 模型继续到关节状态、控制器和硬件插件。

## ROS 1 与 ROS 2

二者共享节点、消息、主题、服务、动作、机器人描述等核心概念，但运行时、构建工具和若干 API 不兼容。读代码或迁移时，先确认目标发行版和客户端库，不能把下面的 API 混用。

| 主题 | ROS 1（常见发行版如 Noetic） | ROS 2（例如 Jazzy） |
| --- | --- | --- |
| 通信发现 | ROS Master 协助注册和查找；节点间再建立连接 | 常见 DDS RMW 实现采用 DDS/RTPS 发现和传输；RMW 也可适配其他中间件，例如 Zenoh |
| 构建与包 | catkin、`roscpp`/`rospy` | ament、`rclcpp`/`rclpy` |
| 参数 | 常见模式是中心参数服务器、命名空间和 `dynamic_reconfigure` | 参数属于节点，可由 YAML/参数服务设置；参数回调负责校验和副作用 |
| 可靠性设置 | 主题队列长度、TCPROS/UDPROS 等传输选择；没有 ROS 2 的通用 QoS 配置模型 | 每个端点配置 QoS，发布/订阅策略必须兼容 |
| 组件 | nodelet 在一个进程内运行，依赖 ROS 1 插件机制 | composable node 在容器进程内运行；可选进程内通信，但不自动保证零拷贝 |
| 生命周期 | 常见节点由进程启停管理，具体状态通常由应用定义 | 有标准 managed-node 生命周期接口，也可继续使用应用自己的 FSM |
| 动作 | 常用 `actionlib` | 内建 ROS 2 Action 接口和客户端库 |

版本边界：文中 ROS 1 例子只使用 `roscpp`/catkin/ROS 1 消息和命名约定；ROS 2 例子只使用 `rclcpp`/ament/ROS 2 消息和参数写法。URDF 本体可跨版本复用，Gazebo 插件、传输配置、控制器和启动文件则应按目标仿真器及 ROS 发行版核实。

## 相邻模块

- [数学与信号基础](../数学与信号基础/README.md)：向量、矩阵、概率、最小二乘、滤波和信号处理。
- [SLAM 与定位](../SLAM与定位/README.md)：状态估计、地图和定位算法；本模块只说明这些能力如何封装成 ROS 节点与接口。
- [点云处理与障碍检测](../点云处理与障碍检测/README.md)：点云几何、障碍识别与融合。
- [坐标变换与传感器标定](../坐标变换与传感器标定/README.md)：TF/SE(3)、内外参与标定；本模块不重复变换推导。
- [导航规划与代价地图](../导航规划与代价地图/README.md)：规划、代价地图和 Nav2 算法；此处仅讨论任务编排接口。
- [传感器与硬件通信](../传感器与硬件通信/README.md)：编码器、IMU、总线、驱动和采样原理。
- [CUDA 与性能分析](../CUDA与性能分析/README.md)：测量、吞吐和性能优化方法。
- [机器人运动学与控制](../机器人运动学与控制/README.md)：运动学、底层控制、执行器限位与控制器设计。
- [Linux 与软件开发](../Linux与软件开发/README.md)：进程、线程、文件描述符、构建和调试基础。
- [Qt 与界面开发](../Qt与界面开发/README.md)：RViz/Qt 插件、GUI 主线程和跨线程界面更新。

## 官方资料

- [ROS 2 Concepts: Topics, Services and Actions](https://github.com/ros2/ros2_documentation/blob/rolling/source/ROS-Framework/interfaces/Topics-Services-Actions.rst)
- [ROS 2 QoS settings](https://github.com/ros2/ros2_documentation/blob/rolling/source/ROS-Framework/interfaces/topics/About-Quality-of-Service-Settings.rst)
- [ROS 2 managed nodes design](https://design.ros2.org/articles/node_lifecycle.html)
- [ROS 2 composition](https://github.com/ros2/ros2_documentation/blob/rolling/source/ROS-Framework/nodes/About-Composition.rst)
- [ROS 2 parameters](https://github.com/ros2/ros2_documentation/blob/rolling/source/ROS-Framework/parameters/Working-with-parameters/Understanding-ROS2-Parameters/Understanding-ROS2-Parameters.rst)
- [ROS 2 middleware implementations](https://github.com/ros2/ros2_documentation/blob/rolling/source/ROS-Framework/client-libraries/About-Middleware-Implementations.rst)
- [ros2_control Jazzy documentation](https://control.ros.org/jazzy/)
- [robot_state_publisher](https://github.com/ros/robot_state_publisher)
