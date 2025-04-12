# What is rm2_controls?
本代码基于rm_controls，是它的ros2适配版本，旨在扩展原项目适用的ubuntu版本(support with 22.04+)，以及，为未来可能的比赛方案变化作出预备(如半自动化，集群化等等等等)
~~当然还有防止未来的电脑完全不支持安装20.04的情况（比如我的电脑）~~
# Diffference between ROS & ROS2
详情见 Note(ROS->ROS2).md
# 硬件规格
CAN-ECat,USB2Can
GPIO
#待补充 
# 软件规格 #待审阅
## ==rm_bringup==
包含一系列自启相关脚本
## ==rm_config==
包含所有机器人的可更改参数
## ==rm2_control==
### rm2_msgs
包含自定义ROS2 topic/server/action
~~(受制于ROS2对于msgs的大幅改变，该文件可能会被大改)~~
### rm_common
包含常用算法及函数
### rm_hw
包含所有队内使用的硬件接口
### rm_gazebo
包含gazebo中仿真所需的接口
### rm_dbus
包含遥控器的连接接口
### rm_referee
包含裁判端的连接接口

## ==rm_controllers==
包含所有控制器
含有:
```
gpio_controller ##gpio控制
mimic_joint     ##工程特定控制
calibration     ##校准控制
chassis         ##底盘控制
gimbal          ##云台控制
orientation     ##方向控制
shooter         ##发射器控制
robot_state     ##姿态控制
tof_radar       ##雷达
```
## ==rm_description==
包含所有兵种的urdf及xacro文件
## ==rm_ecat==
包含 Ether-cat 通信相关
### rm_ecat_example
ecat相关例程
### rm_ecat_manager
ecat从站管理层
### rm_ecat_msgs
ecat相关的ros msgs
### rm_ecat_ros
ecat的ros接口
### rm_ecat_standard_slave/rm_ecat_mit_slave
ecat从站实现层，分为两种协议，无刷/关节电机
## ==rm_forecast==
包含视觉相关，如打符，自瞄等视觉预测函数
## ==rm_manual==
包含键位定义相关，用于键盘或遥控操作机器人
## ==rm_vision==
视觉加载
## ==rm_visplugin==
视觉组件
# 开发指南 #待审阅 
* 这一系列项目开发中，将仍然使用 [ROS C++ Style guide](https://wiki.ros.org/CppStyleGuide) 以及 [ROS Python Style guide](https://wiki.ros.org/CppStyleGuide) 这些代码规范，你也可以参照ros2_best_practices~~(还没写)~~ 来作为模板参考，我们也建议你在IDE中使用带有ROS配置的```clang-format```以方便开发
* 除此之外，rm2_control(等)项目还有一些额外的开发要求：
  1：ROS2 强制要求 C++14 以上，建议：C++17
  2：（ #待补充 ）
# ROS2 编写控制器和插件
#待补充
# 其他： #待补充 
