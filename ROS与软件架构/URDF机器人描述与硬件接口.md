# URDF 机器人描述与硬件接口

URDF 用树结构表达机器人刚体、关节、几何外形和惯性属性；`robot_state_publisher` 等工具读取该模型后，根据关节状态发布模型中的坐标关系。URDF 是描述模型的格式，不是驱动程序、仿真插件或控制算法。

## 1. Link 与 Joint

- **link** 表示刚性部件及其局部属性，可包含 visual、collision、inertial。
- **joint** 将一个 parent link 与一个 child link 相连，给出关节类型、轴、限位和两侧坐标关系。
- 整个 URDF 是一棵树：每个非根 link 只能有一个 parent，不能存在闭环。闭链机构要由其他建模方式或控制约束补充，不能在 URDF 树中直接连出环。
- 常见类型有 `fixed`、`revolute`、`continuous`、`prismatic`、`floating`、`planar`。具体解析器/工具对类型的支持需按目标版本确认。

`visual` 用于渲染，可配材质名、颜色或纹理；`collision` 用于碰撞检查，二者不要求使用同一网格。碰撞网格常采用简单几何以提高仿真或规划效率。`inertial` 描述质量、质心和惯性张量，SI 单位通常是 kg、m、kg·m²；惯性原点描述质心和惯性张量所在坐标关系。坐标原点、质量和惯性错误会让仿真动力学严重失真。网格外观正确并不代表惯性和碰撞模型正确。

关节 `origin` 描述 joint frame 相对 parent link 的位置和姿态；`axis` 在关节坐标系中给出转轴/运动方向。角度单位为 rad，平移单位为 m。排查模型时逐个检查关节名称、父子连接、原点、轴方向、限位和零位，并在可视化中验证正方向。坐标变换推导归[坐标变换与传感器标定](../坐标变换与传感器标定/坐标系、刚体变换与TF.md)，此处不展开 SE(3)/TF 数学。

一个不完整的关节片段（需补充 link、robot 根节点等才能组成完整 URDF）：

```xml
<joint name="shoulder_joint" type="revolute">
  <parent link="base_link"/>
  <child link="upper_arm_link"/>
  <origin xyz="0 0 0.20" rpy="0 0 0"/>
  <axis xyz="0 1 0"/>
  <limit lower="-1.2" upper="1.2" effort="8.0" velocity="1.5"/>
</joint>
```

数字仅为格式示例，不代表任何通用机器人规格。`effort`/`velocity` 是模型约束的一部分，不替代设备安全限制。

## 2. Xacro 与从 CAD 到 URDF

Xacro 是生成 URDF 的宏/参数化描述工具，可用属性、宏、条件和包含文件减少重复结构。Xacro 文件不是解析器最终消费的 URDF；应展开生成结果，再对生成模型做语法和结构检查。宏能减少重复，却也会隐藏实际 link/joint 名称和参数值，因此需要检查展开后的文件。

从 CAD 导出时，应将机械装配拆成固定部件和真实自由度：合并无独立运动的小零件，移除螺纹、倒角和小孔等非必要视觉细节，单独生成轻量 collision 几何。确定机器人根 link、关节父子关系和每个部件坐标原点，检查质量/质心/惯性矩阵，最后统一长度单位与 mesh 路径。CAD 导出成功只说明文件生成，不能证明关节方向、零位、惯性或碰撞正确。

常见验证：

- 展开 Xacro，确认没有未知宏、缺失参数或重复名称；
- 用 `check_urdf` 或目标解析器加载，发现 XML/树结构错误；
- 用 `urdf_to_graphiz` 等生成树图，确认根 link 和父子结构；
- 在 RViz/RViz2 中检查模型姿态、joint axis 和 mesh 尺寸；
- 给关节状态输入有代表性的边界值，确认可动范围和碰撞几何；
- 在目标物理仿真器中验证 inertial、joint limit 和接触行为。

这些工具的可用性、参数名和支持范围依 ROS、URDF parser、仿真器版本变化，按照目标环境官方文档执行。

## 3. 关节状态与 robot_state_publisher

`sensor_msgs/JointState` 按关节名称提供位置、速度和 effort 数组；数组应按 name 对齐，时间戳应表示采样/状态更新时间。`effort` 对转动关节通常表示力矩，对平移关节表示力。数组长度不匹配、重复关节名、单位错误、过期状态会造成模型显示错误或下游误判。只有确实提供的字段才填写；不能用零值伪装未知读数。

ROS 2 `robot_state_publisher` 从 `robot_description` 获取 URDF，接收 JointState 并发布活动关节的变换；固定关节变换通过 `/tf_static`，可动关节变换通过 `/tf` 发布（具体 QoS 和参数可按版本核对）。它转换的是模型关系与关节测量，不会估计机器人在世界中的定位，也不会驱动关节。坐标树与标定由[坐标变换与传感器标定](../坐标变换与传感器标定/坐标系、刚体变换与TF.md)主讲。

## 4. ROS 1 `transmission` 与 ROS 2 `ros2_control`

“URDF 里写了硬件”并不表示驱动已实现。模型、传动关系、硬件接口、控制器和仿真器插件是不同层：

| 层 | 职责 |
| --- | --- |
| URDF link/joint | 几何、连接拓扑、关节运动类型与约束 |
| Transmission/控制资源声明 | 描述执行器/关节之间的映射或可用 command/state interface；具体语义依 ROS 控制栈版本 |
| 硬件接口插件 | 连接实际设备或模拟硬件，读取测量并写入命令 |
| Controller Manager | 管理控制器生命周期、资源借用与控制更新调度 |
| Controller | 根据输入状态和目标计算接口命令；控制律归机器人运动学与控制模块 |
| Simulator plugin | 将仿真器传感器/执行器接到 ROS；与 URDF 核心格式分开维护 |

ROS 1 的 `ros_control` 通常通过 `RobotHW` 向 `controller_manager` 注册 joint state/command interfaces；常见硬件循环为 read → controller update → write。旧式 `<transmission>` 常参与关节和执行器命令/状态资源映射，但不是通用 ROS 通信接口，也不负责实现驱动。ROS 1 的 Gazebo Classic 插件需要对应 ROS 1/Gazebo 插件版本。

下面是 ROS 1 `ros_control` 传输声明的缩略片段，不能作为 ROS 2 配置直接使用：

```xml
<transmission name="joint_transmission">
  <type>transmission_interface/SimpleTransmission</type>
  <joint name="shoulder_joint">
    <hardwareInterface>hardware_interface/PositionJointInterface</hardwareInterface>
  </joint>
  <actuator name="shoulder_motor">
    <hardwareInterface>hardware_interface/PositionJointInterface</hardwareInterface>
    <mechanicalReduction>1</mechanicalReduction>
  </actuator>
</transmission>
```

`mechanicalReduction` 表示旧传动插件约定中的机械映射参数。具体是电机侧/关节侧的传动比方向、正负号和单位换算，应以所用 Transmission 类型实现为准；不要仅凭字段名套用比值公式。旧版 URDF 可能还出现 `<safety_controller>` 扩展，它不等于硬件安全回路，也不能取代 ros_control 控制器或设备限位。

ROS 2 `ros2_control` 使用 `<ros2_control>` 描述硬件组件及 state/command interface，硬件插件实现 `hardware_interface` 接口，由 resource manager/controller manager 加载并管理。此配置与 URDF 的 link/joint 模型关联但职责不同。不要把 ROS 1 `<transmission>` 片段直接移植成 ROS 2 硬件组件；按选定的 ros2_control 和仿真器版本编写对应声明/插件。

一个示意性 ROS 2 硬件声明片段（插件名、接口和参数需由实际驱动定义）：

```xml
<ros2_control name="RobotHardware" type="system">
  <hardware>
    <plugin>example_hardware/RobotSystem</plugin>
  </hardware>
  <joint name="shoulder_joint">
    <command_interface name="position"/>
    <state_interface name="position"/>
    <state_interface name="velocity"/>
  </joint>
</ros2_control>
```

该代码只适用于 ROS 2 `ros2_control` 概念，不是 ROS 1 `transmission` 例子。位置/速度/力矩接口的选择、单位、限幅、更新频率和驱动反馈质量必须由硬件和控制器共同约定。硬实时要求、总线采样、编码器/IMU 原理和闭环控制设计分别见[传感器与硬件通信](../传感器与硬件通信/传感器测量与时间戳.md)与[机器人运动学与控制](../机器人运动学与控制/ROS控制器与实时数据流.md)。

## 5. 仿真和问题定位

Gazebo Classic、现代 Gazebo、Webots、Unity 等仿真器使用各自插件和桥接机制。URDF 可作为模型输入，但传感器参数、插件标签、话题名、控制器加载和仿真时间配置不能跨仿真器照搬。插件不被解析、依赖缺失、QoS 不匹配、时间源错误都可能导致“模型能显示但状态不更新”。

按数据路径分层诊断：模型是否解析 → 关节和 root link 是否正确 → 插件是否加载 → 硬件接口是否激活 → joint state 是否发布且新鲜 → `robot_state_publisher` 是否收到了正确关节名 → RViz/RViz2 的 frame 与固定坐标是否匹配。若机械结构正确而控制轨迹不正确，转到[机器人运动学与控制](../机器人运动学与控制/ROS控制器与实时数据流.md)。

## 参考资料

- [ROS 2 URDF tutorial source](https://github.com/ros2/ros2_documentation/tree/rolling/source/Tutorials/Intermediate/URDF)
- [robot_state_publisher](https://github.com/ros/robot_state_publisher)
- [sensor_msgs/JointState definition](https://github.com/ros2/common_interfaces/blob/rolling/sensor_msgs/msg/JointState.msg)
- [URDFDOM](https://github.com/ros/urdfdom)
- [ros2_control Jazzy documentation](https://control.ros.org/jazzy/)
- [ros2_control hardware components](https://control.ros.org/jazzy/doc/ros2_control/hardware_interface/doc/hardware_components_userdoc.html)
- [ros2_control controller manager](https://control.ros.org/jazzy/doc/ros2_control/controller_manager/doc/userdoc.html)
- [ROS 1 ros_control](https://wiki.ros.org/ros_control)
- [ROS 1 ros_control transmission tutorial](https://github.com/osrf/gazebo_tutorials/blob/master/ros_control/tutorial.md)
