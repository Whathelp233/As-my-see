# Gimbal云台装置

> 发射解算文档位于”bullet发射装置“



## gimbal_controller

> 配置有一系列云台的运动模式，通过订阅参数，通过实时工具更新云台运动模式



### 初始化配置

```c++
bool Controller::init(hardware_interface::RobotHW* robot_hw, ros::NodeHandle& root_nh, ros::NodeHandle& controller_nh)、
    //xml_rpc_value(?)
    //获取正反馈参数（feedforward）,下辖重力加速度，质心，是否开启加速度补偿
    //链接到发射解算，订阅yaw（摇头），pitch（点头）命令
    //获取imu_name参数，连接惯性传感器
    //准备坐标发布
    //创建订阅者，订阅command话题，同时获取publish_rate参数
    //重置实时工具发布误差
```



## 云台进入开始状态

```c++
void Controller::starting(const ros::Time& /*unused*/)
    //设置运动模式为RATE
```



## 云台更新

```c++
void Controller::update(const ros::Time& time, const ros::Duration& period)
    //尝试实时工具获取命令
    //尝试tf2坐标转化，失败报错
    //检查参数mode是否改变以申明state的状态
    //向运动模式匹配state，获取云台期望的运动模式
    //moveJoint()
```



## 云台运动目标点

每个模式最终都会调用该函数以配置运动

```c++
void Controller::setDes(const ros::Time& time, double yaw_des, double pitch_des)
    //获取yaw，pitch期望位置
    //向tf数配置坐标转化，四元数生成欧拉角
    //检查转化后的坐标是否超出关节限制setDesIntoLimit()
    //目标yaw及pitch生成目标四元数tf::createQuaternionMsgFromRollPitchYaw()
    //标记好当前时间，向rm_gimbal_controllers配置数据
```



### 云台运动模式

#### 普通运动模式

```c++
void Controller::rate(const ros::Time& time, const ros::Duration& period)
    //首先检查state是否改变，再设置将要执行的命令数据
    //跟随配置的pitch和yaw数据运动
```



#### 跟踪模式

```c++
void Controller::track(const ros::Time& time)
    //首先检查state是否改变，再设置将要执行的命令数据
    //设置有地图上目标的坐标，如果目标的位置，速度有数据则录入，无则报错
    //调用发射解算函数，判断是否解算成功
    //如果publish_rate大于0且距离上一次发布的时间已大于限制的发布时间，则依靠实时工具发布运动误差，接着发布枪管解算，更新上一次发布的时间
    //如果解算成功，命令枪管解算更新数据，若失败转换rm_gimbal_controllers调取命(?)    
```



##