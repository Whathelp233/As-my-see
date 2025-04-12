# ros_control

>  一组包，包括控制器接口、控制器管理器、传输和硬件接口

> [github_wiki](https://github.com/ros-controls/ros_control/wiki)



## hardware_interface

本质上是一些变量(电机数据和电机命令)通过interface传来传去，以Handle为单位被Controller修改

> [官方文档：配置一个机器人](http://docs.ros.org/en/noetic/api/hardware_interface/html/c++/)
>
> 通常需要：
>
> 1. 重写init() read() write()，实现硬件获取/发送数据功能
> 2. 注册interface handle， 将变量和joint联系，封装成Handle注册进interface
> 3. 设置transmission，在模型有执行器时需要，配置执行器和关节的传动关系
> 4. 设置jointlimit，可选
> 4. 加载controller， controller通过关节名在interface匹配该关节的handle

### 串口案例

> 一个基础的案例，电脑通过串口获取舵机信息再处理后将命令通过串口发给电机



#### 派生hw

> hw将硬件与电脑相沟通，从硬件读取的信息会保存在成员变量里。它的结构如下

```c++
#include <ros/ros.h>
#include <controller_manager/controller_manager.h>
#include <hardware_interface/robot_hw.h>

// 舵机驱动程序
class MyRobotHW : public hardware_interface::RobotHW
{
public:
    MyRobotHW() {}

    void read()
    {
        // 读取舵机状态
        // ......
    }

    void write()
    {
        // 发送命令到舵机
        // ......
    }

private:
    // 舵机状态变量
    double position_;
    double velocity_;
    double effort_;
};

int main(int argc, char** argv)
{
    ros::init(argc, argv, "my_robot_controller");
    ros::NodeHandle nh;

    MyRobotHW robot_hw;
    controller_manager::ControllerManager cm(&robot_hw);

    ros::Time previous_time = ros::Time::now();
    ros::Rate rate(50); // 50Hz
    while (ros::ok())
    {
        ros::Time current_time = ros::Time::now();
        ros::Duration dt = current_time - previous_time;
        cm.update(current_time, dt);

        previous_time = current_time;
		rate.sleep();
	}
    return 0；
}
```

> ```c
> 上面的代码中，MyRobotHW 类是舵机驱动程序，它继承自 hardware_interface::RobotHW。 read() 和 write() 方法分别用于读取舵机状态和发送命令到舵机。
> 
> 在主程序中，首先创建一个 ros::NodeHandle 对象，然后创建一个 MyRobotHW 类的实例并传递给 controller_manager。在 while 循环中调用 cm.update() 方法来更新控制器的状态。
> 
> 实际上还需要根据你的舵机型号来实现自己的驱动程序，如读取舵机状态，发送命令，以及配置舵机的参数等。
> ```



##### 以USART方式通讯

> https://blog.csdn.net/qq_52785580/article/details/122877511



#### 联系joint

> 由于ros还不知道我们之前保存的变量是什么意思，也不知道是什么关节，所以向ros注册一些interface

##### 从电机获得的数据

通过在 MyRobotHW 类中注册相应的状态变量来知道相应的舵机状态，使用gazebo时启动的节点`joint_state_publisher`就是从仿真的interface中获取到关节数据后把它发布在/joint_state话题上。

如果是仿真，配置变量与关节的联系的通常步骤是：

- 定义hardware_interface::JointStateHandle对象，说明关节名字和相应变量
- 把该对象注册进hardware_interface::JointStateInterface对象里

对于实际电机，配置变量与关节的联系的通常步骤是：

- 定义hardware_interface::ActuatorStateHandle对象，说明关节名字和相应变量
- 把该对象注册进hardware_interface::ActuatorStateInterface对象里

```c
二者区别在于前者的环境是虚拟的，gazebo会直接生成JointStateHandle来对应joints，后者还需要通过transmission建立actor与joint的联系，所以需要ActuatorStateHandle
```





例如，注册状态Handle：

```c++

MyRobotHW::MyRobotHW()
{
    // Register position variable
    hardware_interface::JointStateHandle state_handle("joint_name", &pos_, &vel_, &eff_);
    jnt_state_interface.registerHandle(state_handle);
}
```

controller_manager 会在启动时调用 MyRobotHW 类中的 registerInterfaces() 方法，来注册所有的状态变量。

这样 controller_manager 就知道了"joint_name"是对应的电机信息了，并且它会根据该舵机状态来更新控制器。





##### 发给电机的指令

hardware_interface/EffortJointInterface

上面是基于力矩控制的控制器所使用的interface，我们把力矩指令以指针传给JointHandle后注册，之后控制器可以调用这些Handle并修改力矩指令。我们要做的是把指令通过write()发给电机

**控制器本质上也是先获取Handle，再通过Handle里的`setCommand()`函数修改指令而是实现的！我们自己的controller因而需要先获取那些Handle**

如果是仿真，配置变量与关节的命令联系的通常步骤是：

- 定义hardware_interface::JointStateHandle对象，说明关节名字和相应变量
- 把该对象注册进hardware_interface::JointStateInterface对象里

对于实际电机，配置变量与关节的命令联系的通常步骤是：

- 定义hardware_interface::ActuatorStateHandle对象，说明关节名字和相应变量
- 把该对象注册进hardware_interface::ActuatorStateInterface对象里



以`effort_controllers/JointPositionController`为例，这是一个基于力控制的位置控制器。我们从电机获取位置，发布期望的位置，再经过控制器处理后控制器返回我们要发给电机的力的大小。

基于力控制那就要准备`hardware_interface::EffortJointInterface effort_joint_interface_;`上面的代码已经说了位置(&pos)和期望(&cmd)部分，对于力部分

```cpp
hardware_interface::JointHandle jointEffortHandle(jointStateHandle, &joint_effort_command_);
//joint_effort_command_就是控制器返回给我们的指令
	effort_joint_interface_.registerHandle(jointEffortHandle);

registerInterface(&effort_joint_interface_);
```

与rm自定义的GpioInterface类似，它就是基于gpio控制的控制器所使用的interface



##### 设置Offset

> `<offset>` 元素用于表示关节初始位置的偏移量。对于旋转关节，这个值表示关节的初始旋转角度偏移量，对于平移关节，这个值表示关节的初始位置偏移量。

消除位置偏移的影响，可以在建模时手动对齐，或在代码中对数据进行处理

- 电机的offset

> 电机自己认为的零位(电机角度为0时所对应的位置，每次重启电机该值可能会变换)可能和我们期待的零位不一样，这时我们需要添加offset来让读取的数据和期望的零位对齐

hw中的can读取就是一个例子，pos是电机读取数据，offset可以理解为补偿量。offset的值需要通过其他手段获取，例如撞击对位等

```c
// Converter raw CAN data to position velocity and effort.
   act_data.pos =
            act_coeff.act2pos * static_cast<double>(act_data.q_raw + 8191 * act_data.q_circle) + act_data.offset;
```

**撞击对位**

在电机的移动路径的原点位置上设置障碍物，向电机发送速度指令，当电机撞击到障碍物会停止，读取此时位置值，该值取反即offset。

之后将读取的位置与offset相加



- link的offset

在transmission中有一个属性offset：

```html
<transmission name="trans_yaw_joint">
    <type>transmission_interface/SimpleTransmission</type>
    <actuator name="yaw_joint_motor">
        <mechanicalReduction>1</mechanicalReduction>
    </actuator>
    <joint name="yaw_joint">
        <offset>-0.502</offset>
        <hardwareInterface>hardware_interface/EffortJointInterface</hardwareInterface>
    </joint>
</transmission>
```

这是输出轴使用的offset







#### 使用controller

> 使用控制器之前需要我们在配置文件里面注册控制器，并向控制器加载interface

```c++
//代码里面的控制器
effort_controllers::JointVelocityController ctrl_friction_l_, ctrl_friction_r_;
effort_controllers::JointPositionController ctrl_trigger_;

//“ ”内是配置文件里面定义的控制器名字
ros::NodeHandle nh_friction_l = ros::NodeHandle(controller_nh, "friction_left");
ros::NodeHandle nh_friction_r = ros::NodeHandle(controller_nh, "friction_right");
ros::NodeHandle nh_trigger = ros::NodeHandle(controller_nh, "trigger");

//从hw获取一个interface
effort_joint_interface_ = robot_hw->get<hardware_interface::EffortJointInterface>();

//初始化控制器
return ctrl_friction_l_.init(effort_joint_interface_, nh_friction_l) &&
       ctrl_friction_r_.init(effort_joint_interface_, nh_friction_r) &&
       ctrl_trigger_.init(effort_joint_interface_, nh_trigger);
```



yaml文件的控制器参数

```yaml
  friction_left:
    joint: "left_friction_wheel_joint"
    pid: { p: 0.0007, i: 0.005, d: 0.0, i_clamp_max: 0.01, i_clamp_min: -0.01, antiwindup: true, publish_state: true }
  friction_right:
    joint: "right_friction_wheel_joint"
    pid: { p: 0.0007, i: 0.005, d: 0.0, i_clamp_max: 0.01, i_clamp_min: -0.01, antiwindup: true, publish_state: true }
  trigger:
    joint: "trigger_joint"
    pid: { p: 50.0, i: 0.0, d: 1.3, i_clamp_max: 0.0, i_clamp_min: 0.0, antiwindup: true, publish_state: true }
```





### IMU案例

> imu需要使用hardware interface的imuHandle，向handle传入线加速度，角速度，姿态数据。
>
> 其中线加速度和角速度由imu模块给出，姿态数据需要自己解算并更新

使用代码分析：

#### 姿态解算器

> [ros接口](https://zhuanlan.zhihu.com/p/143097152)
>
> [代码分析](https://zhuanlan.zhihu.com/p/143214677)

姿态数据更新需要以下头文件

```c++
#include <imu_complementary_filter/complementary_filter.h>
```

- 在CMakeLists.txt文件中添加对imu_complementary_filter库的依赖。

```
find_package(catkin REQUIRED COMPONENTS
  roscpp
  sensor_msgs
  imu_complementary_filter
)
```

- 在源代码中包含<imu_complementary_filter/complementary_filter.h>头文件。

```c
#include <ros/ros.h>
#include <sensor_msgs/Imu.h>
#include <imu_complementary_filter/complementary_filter.h>
```

- 创建一个ComplementaryFilter对象，并设置滤波参数。

```c
imu_complementary_filter::ComplementaryFilter filter;

//设置初始角度
  filter->setOrientation(double q0, double q1, double q2, double q3);//rm没用这个

/*setDoBiasEstimation(do_bias_estimation_)函数用于设置是否进行偏置估计，当参数do_bias_estimation_为true时，会进行偏置估计，否则不会。偏置估计是用于校正陀螺仪和加速度计的漂移，使得姿态估计更准确。
setDoAdaptiveGain(do_adaptive_gain_)函数用于设置是否使用自适应增益，当参数do_adaptive_gain_为true时，会使用自适应增益，否则不会。自适应增益可以使滤波器更加鲁棒，适应不同的环境和运动状态，提高姿态估计的准确性。*/
  filter_->setDoBiasEstimation(do_bias_estimation_);//rm为false
  filter_->setDoAdaptiveGain(do_adaptive_gain_);//rm为true

//ComplementaryFilter类中的 setGainAcc() 函数和 setGainMag() 函数用于设置加速度计和磁力计的增益值，这些增益值是用于滤波器的参数。通过设置不同的增益值，可以调整滤波器的响应特性，以适应不同的应用场景和要求。具体来说，加速度计的增益值用于计算重力加速度的参考值，而磁力计的增益值用于计算地磁场的参考值。
	filter_->setGainAcc(gain_acc_)；//rm为0.0003
    if (use_mag_)
  	  filter_->setGainMag(gain_mag_)；
        
/*setBiasAlpha(double bias_alpha)函数是ComplementaryFilter类中的一个函数，用于设置补偿滤波器中的偏差alpha值，该值用于控制陀螺仪测量值的影响程度。
具体来说，在补偿滤波器中，陀螺仪测量值和加速度计测量值是同时用于计算姿态的。然而，陀螺仪存在漂移和噪声等问题，而加速度计则存在震动和重力误差等问题，因此需要对两个传感器测量值进行加权平均，以得到更加稳定和准确的姿态估计值。
而偏差alpha值则用于控制陀螺仪测量值的权重，即alpha越小，则加速度计测量值的影响越大，而陀螺仪测量值的影响越小；反之，alpha越大，则陀螺仪测量值的影响越大，而加速度计测量值的影响越小。*/
    filter_->setBiasAlpha(bias_alpha_)；
```

- 获取IMU数据，并将数据传递给ComplementaryFilter对象。

```c
 filter_->update(ax, ay, az, wx, wy, wz, dt);
```

- 发布数据。

```c
  filter_->getOrientation(q0, q1, q2, q3);
  
  ****
  /*赋值操作*/
  ****
      
  imu_filtered_pub = nh.advertise<sensor_msgs::Imu>("imu/data_filtered", 10);
```



- 参数orientation_covariance

> `orientation_covariance`是滤波器中的一个参数，它用于设置滤波后的姿态（orientation）的协方差矩阵。协方差矩阵描述了姿态估计的精度和不确定性，其中对角线上的元素表示对应姿态分量的方差，越小表示估计的姿态越精确，反之越大表示不确定性越高。

在ROS中，IMU消息中的`orientation_covariance`字段是一个长度为9的一维数组，表示一个3x3的协方差矩阵。其中，前三个元素表示x轴分量的方差，中间三个元素表示y轴分量的方差，后三个元素表示z轴分量的方差。

在使用滤波器进行姿态估计时，可以将`orientation_covariance`设置为适当的值，以描述估计的姿态的精度和不确定性。通常情况下，可以将协方差矩阵初始化为较大的值，然后随着滤波器的工作，根据估计的精度和不确定性进行动态调整。如果滤波器的姿态估计越来越准确，可以逐渐减小协方差矩阵中的值，反之则可以逐渐增大。

`orientation_covariance`参数用于描述姿态估计的精度和不确定性，可以根据实际情况进行动态调整，以获得更好的姿态估计结果



- Hamilton四元数到ROS四元数

```c
#include <tf/LinearMath/Quaternion.h>
#include <tf/transform_datatypes.h>


// get orientation
double q0, q1, q2, q3;
imu_filter_.getOrientation(q0, q1, q2, q3);
	//ROS使用的Hamilton四元数约定q0是标量。然而ROS四元数的形式为[x，y，z，w]，其中w为标量。所以顺序不一样
tf::Quaternion q = tf::Quaternion(q1, q2, q3, q0);

// Create and publish fitlered IMU message.
tf::quaternionTFToMsg(q, imu_pub_data.orientation);
```

- ROS四元数到欧拉角

```c
// Create and publish roll, pitch, yaw angles
geometry_msgs::Vector3Stamped rpy;
rpy.header = imu_msg_raw->header;

tf::Matrix3x3 M;
M.setRotation(q);
M.getRPY(rpy.vector.x, rpy.vector.y, rpy.vector.z);
```



#### 零漂

> 和rm调试中调零漂的参数一样，我们需要读取并填入相关的offset

```yaml
two_wheel_hardware:
  imus:
    base_imu:
      angle_offset: [ 0., 0., 0. ]
```



#### 联合标定

> https://www.bbsmax.com/A/kvJ3gP8nJg/



#### 节点滤波

> 上面的姿态解算器用起来有些问题，现在使用一下这个包的封装形式，它可以生成一个node来读取imu话题和发布滤波后的imu数据
>
> [wiki](http://wiki.ros.org/imu_complementary_filter)
>
> [使用 ](https://cloud.tencent.com/developer/article/2098138) [2](https://blog.csdn.net/learning_tortosie/article/details/103189118/)

```bash
sudo apt-get install ros-noetic-imu-tools
//
git clone https://github.com/CCNYRoboticsLab/imu_tools.git
```

打开文件：
 `~/imu_tools_ws/src/imu_tools/imu_complementary_filter/src/complementary_filter_ros.cpp`，有如下代码：

```c
// Register IMU raw data subscriber.
imu_subscriber_.reset(new ImuSubscriber(nh_, ros::names::resolve("imu") + "/data_raw", queue_size));
12
```

可以看出，`imu_tools`订阅的topic为`imu/data_raw`，而IMU发布的topic为`/mynteye/imu/data_raw`，因此需要修改代码，使topic一致：

```c
// Register IMU raw data subscriber.
imu_subscriber_.reset(new ImuSubscriber(nh_, "/mynteye/imu/data_raw", queue_size));
12
```

打开launch文件：`~/imu_tools_ws/src/imu_tools/imu_complementary_filter/launch/complementary_filter.launch`，进行一些修改：

```c
<!-- ComplementaryFilter launch file -->
<launch>
  #### Complementary filter
  <node pkg="imu_complementary_filter" type="complementary_filter_node"
      name="complementary_filter_gain_node" output="screen">
    <param name="do_bias_estimation" value="true"/>
    <param name="do_adaptive_gain" value="true"/>
    <param name="use_mag" value="false"/>
    <param name="gain_acc" value="0.01"/>
    <param name="gain_mag" value="0.01"/>
    <param name="publish_debug_topics" value="false"/>
    <param name="publish_tf" value="true"/>
  </node>
</launch>
```





#### 线/角速度匹配

> 通过imu数据获取小车在liner0.2或angular0.5系数时的速度和角速度，将其与cmd匹配变成实际速度。
>
> 之后将速度命令发布，如果有速度和加速度之间的偏差，则在上位机修正cmd_vel下的系数直到其达到目标值



## 两个节点发布器

`robot_state_publisher` 和 `joint_state_publisher` 的主要区别在于它们所发布的信息类型不同。

`robot_state_publisher` 是一个 ROS 节点，用于发布机器人的全局状态，例如位置和姿态。它通常发布在 TF 树中，这样所有关于机器人位置和姿态的信息就能在整个 ROS 系统中被共享和使用。

`joint_state_publisher` 是一个 ROS 节点，用于发布机器人的关节状态。它发布的信息主要是关于关节的位置，速度和力，并且通常被其他 ROS 控制器使用。

总的来说，如果需要发布关于机器人的全局状态信息，应该使用 `robot_state_publisher` ；如果需要发布关于机器人的关节状态信息，应该使用 `joint_state_publisher`。



### joint_state_publisher

> 注册joint state handle，并将它们关联到对应的关节状态变量

```c
    // Register position variable
    hardware_interface::JointStateHandle state_handle("joint_name", &pos_, &vel_, &eff_);
    jnt_state_interface.registerHandle(state_handle);

   //register interface
   registerInterface(&jnt_state_interface);
```



### robot_state_publisher

> 创建一个robot_state_publisher对象并在代码中调用它的update函数，使用自己派生的hardware interface里面的数据来更新关节信息





## 两个控制器管理器

`controller_manager::ControllerManager`是`controller_manager`包中定义的一个类，它封装了所有控制器管理的功能，例如加载控制器，让控制器启动或停止。

`node controller manager`是ROS系统中的一个节点，它通过ROS消息和服务来管理控制器。

实际上为了更加灵活，通常使用的是`controller_manager::ControllerManager`类来管理控制器，而不是使用`node controller manager`节点



### ControllerManager类

> 使用controller_manager::ControllerManager类管理控制器可以分为以下几步：
>
> 1. 创建一个controller_manager::ControllerManager对象。
> 2. 在循环中调用ControllerManager对象的loadControllers方法，用于加载控制器。
> 3. 调用ControllerManager对象的update方法，根据控制周期更新控制器的状态。
> 4. 如果需要，调用ControllerManager对象的unloadControllers方法卸载不再使用的控制器。

```c
#include <controller_manager/controller_manager.h>

int main(int argc, char** argv)
{
  ros::init(argc, argv, "my_robot_hardware_interface");
  ros::NodeHandle nh;

  // 创建一个MyRobotHW对象，表示机器人的硬件接口
  MyRobotHW robot;

  // 创建一个ControllerManager对象
  controller_manager::ControllerManager cm(&robot, nh);

  ros::Rate rate(100.0);
  while (ros::ok())
  {
    robot.read();
    cm.update(robot.getTime(), robot.getPeriod());
    robot.write();
    rate.sleep();
  }

  return 0;
}
```



### Controller manager节点

在launch文件中配置的controller manager

<!-- controller manager -->
<node name="controller_manager" pkg="controller_manager"  type="controller_manager" output="screen"
      args="load
 sg90_mechanical_arm_controller/joint_state_controller
 sg90_mechanical_arm_controller/middle_rotation_joint_position_controller
 sg90_mechanical_arm_controller/rotation_baselink_joint_position_controller
 sg90_mechanical_arm_controller/left3_middle_joint_position_controller
 	"/>





### 一些问题

- controller manager包里面的controller manager正常运行，但是spawner则会提示

```c
[main]: Controler Spawner couldn't find the expected controller_manager ROS interface
```

可能原因：代码中没有注册正确的interface和transmission



- controller manager没有任何输出，也不载入控制器

1. 可能是代码写错了，检查launch文件

<!-- controller manager -->
<node name="controller_manager" pkg="controller_manager"  type="controller_manager" output="screen"
      args="load
 sg90_mechanical_arm_controller/joint_state_controller
 sg90_mechanical_arm_controller/middle_rotation_joint_position_controller
 sg90_mechanical_arm_controller/rotation_baselink_joint_position_controller
 sg90_mechanical_arm_controller/left3_middle_joint_position_controller
 	"/>

2. interface配置错误

   没有载入transmission文件或没有在代码中载入transmission





## Gazebo与实际电机的硬件接口

> 在 Gazebo 中加载 URDF 和操作实际电机时，需要使用的硬件接口不同。
>
> Gazebo 模拟的环境可以通过使用 hardware_interface::PositionJointInterface 来实现，但是操作实际电机可能需要使用更高级的硬件接口，如 hardware_interface::PositionActuatorInterface。
>
> 这样的原因是gazebo是简单的关节控制，而现实可能会用更复杂的方式驱动关节

因此，需要确保在 URDF 文件中描述的 transmission 中包含适当的硬件接口，并在加载 transmission 时使用相应的硬件接口。





## URDF

### jointLimitInterface

> [wiki](https://github.com/ros-controls/ros_control/wiki/joint_limits_interface)

### Transmission

> [wiki](https://github.com/ros-controls/ros_control/wiki/transmission_interface)
>
> 告诉控制器机器人执行器的类型以及与执行器对应的joint，==注意handle参数里的名字和urdf的joint名字是强对应的，因为tranmission构建时会去寻找对应关节，所以二者的名字填的一样==
>
> <type>硬件接口的类型：说明执行器的性质。例如`hardware_interface/PositionJointInterface`说明是一种基于位置控制的执行器，而这个执行器需要注册positionJoinitInterface
>
> <joint name>：URDF定义的joint的名字。
>
> <mechanicalReduction>减速比：通过注册interface，我们知道轮子转一圈相应的joint的值也会改变。而transmission则是表示轮子转一圈时电机要转多少圈。

在配置完hardware_interface后，我们已经获得了电机的数据，现在我们需要建立起电机数据与joint的传动关系

#### InterfaceManager，HandleManger(ResourceManager)，Handle

```c
hardware_interface::XXXXInterface实际上是一个资源管理器，因为它们派生于基类HardwareResourceManager<T>,而T描述的的就是一个Handle，是派生于ActuatorStateHandle的类。一个Handle储存电机信息的引用。
transmission_interface::XXXXeInterface实际上也是一个资源管理器，因为它们也派生于基类HardwareResourceManager<T>，此时T是一个派生于TransmissionHandle的类。储存电机信息和关节信息的引用，执行器名以及传动关系Transmission的指针。
 
传动关系Transmission是一个记录电机数据<->关节数据转换关系的类，这些转换关系以函数形式被封装。在HardwareResourceManager<T>的派生类执行propagate()函数时会循环调用内部TransmissionHandle的propagate()函数，而这些函数会调用Transmission内部的转换函数,从而更新电机和关节指令。通过urdf和代码载入的方式可以自动生成该类，如果需要复杂传动可以自定义派生该类。例如rm仓库的MultiActuatorTransmission。
HardwareResourceManager<T>是一个资源管理类，虽然ActuatorStateHandle与TransmissionHandle是两个基类，但它们都能被管理类注册,在它内部的p函数会循环执行所有Handle的转化关系函数。


TransmissionInterfaceLoader是一个通过参数或文件生成transmission_interface::XXXXeInterface对象和TransmissionHandle对象的类，生成Handle时在其中会调用插件 pluginlib::ClassLoader<TransmissionLoader>用于收集转换信息并生成Transmission对象。我们可以重写一个这样的插件来实现无法单靠Offset和减速比来描述的复杂转换关系，例如rm仓库的MultiActuatorTransmissionLoader。建立一个TransmissionInterfaceLoader对象需要在构造函数填入一个RobotTransmissions对象的引用以传入最终生成的transmission_interface::XXXXeInterface对象。
    //TransmissionInterfaceLoader与TransmissionLoader通常是绑定的，因为前者通过读取参数或文件为后者提供生成Transmission所需要的信息。目前没有找到读取参数或文件这部分的源码。
RobotTransmissions派生自Hardware_interface::InterfaceManager类，InterfaceManager是一个管理Interface的类，不同的Interface表示不同类型的执行器，例如速度，位置和力执行器。TransmissionInterfaceLoader在载入URDF后会把生成的transmission_interface::不同的XXXXeInterface来执行传入RobotTransmissions，这对应上文的 “通过urdf和代码载入的方式可以自动生成该类”。之后可以从中获取不同的XXXXeInterface来执行propagat函数以更新转换
    
RobotHW也派生自InterfaceManager
```

> **transmission和interface如何建立联系？**
> 或者说，我们先注册了电机的hardware_interface，之后我们又注册了tranmission，而如果我们不调用propagate()的话，hardware_interface下的要发给电机的命令是不更新的。
> 在[官方源码](https://github.com/ros-controls/ros_control/blob/noetic-devel/transmission_interface/src/transmission_interface_loader.cpp)第89行的
>
> ```c
> TransmissionInterfaceLoader::TransmissionInterfaceLoader(hardware_interface::RobotHW* robot_hw,
>                                                          RobotTransmissions*          robot_transmissions)
> ```
>
> 说明TransmissionInterfaceLoader需要提供一个hw和RobotTransmissions指针。在这之后，Loader会从hw下寻找我们已经注册了的Handle，在获取转换关系后会自动生成相应的jointHandle，这样最终展现在controller面前的是transmission准备的好了的jointHandle，它对jointHandle下达的命令也在tranmision的propagate()之后转换到对电机的命令上，而这些命令就是我们手动注册ActutorHandle时填入的命令变量。
>
> 再扩展到gazebo仿真，gazebo是直接生成jointHandle并注册进interface里，不需要tranmission来建立一层与执行器的联系。
>
> 这样来看，如果我们已经有单片机下位机，所有传动关系由单片机负责，我们只需要向电机发目标命令的话，那就只需要注册hardware_interface::JointStateHandle和hardware_interface::JointHandle并注册进hardware_interface::PositionJointInterface(或velocity)，不需要载入transmission，而控制器也可以直接获取jointHandle并发布命令







我们可以通过launch或代码的方式来载入transmission

#### URDF载入

- [urdf载入](http://docs.ros.org/en/melodic/api/transmission_interface/html/c++/classtransmission__interface_1_1TransmissionInterfaceLoader.html#details)

注册hardware interface -> RobotTransmissions.load(urdf) -> 从RobotTransmissions获取转换得到的act_joint transmission interface -> propagate()

```c
<?xml version="1.0" ?>
<robot name="sg90_mechanical_arm" xmlns:xacro="http://www.ros.org/wiki/xacro" >

<transmission name="middle_rotation_joint_tran">
  <type>transmission_interface/SimpleTransmission</type>
  <joint name="middle_rotation_joint">
    <hardwareInterface>hardware_interface/PositionJointInterface</hardwareInterface>
  </joint>
  <actuator name="middle_rotation_joint_actr">
    <hardwareInterface>hardware_interface/PositionJointInterface</hardwareInterface>
    <mechanicalReduction>1</mechanicalReduction>
  </actuator>
</transmission>
```

1. 注册hardware interface

只需要注册ActuatorInterface部分，positionJointInterface会自动生成，之后从nh里面拿就行了。硬要注册的话会报错

```
hardware_interface::PositionActuatorInterface position_act_interface_;
hardware_interface::ActuatorStateInterface act_state_interface_;
```



2. 从RobotTransmissions获取转换得到的act_joint transmission interface

```c
  transmission_interface::ActuatorToJointStateInterface *act_to_jnt_state_{};
  transmission_interface::JointToActuatorPositionInterface
      *jnt_to_act_effort_{};//这里的类型是joint-》positon，执行器类型是位置(舵机)，如果是力控执行器那就是effort

//转换关系已经完成了，但是我们需要手动获取
  act_to_jnt_state_ =
      robot_transmissions_
          .get<transmission_interface::ActuatorToJointStateInterface>();
  jnt_to_act_effort_ =
      robot_transmissions_
          .get<transmission_interface::JointToActuatorPositionInterface>();
```

3. propagate()

**最重要的一步，将转换关系广播到interface中，没有它controller manager就无法载入相应控制器**

```c++
  void read()
  {
    // Read actuator state from hardware
    // ...

    // Propagate current actuator state to joints
    act_to_jnt_state.propagate();//执行器数据转joint
  }

  void write()
  {
    // Porpagate joint commands to actuators
    jnt_to_act_pos.propagate();//joint转执行器数据

    // Send actuator command to hardware
    // ...
  }
```

> `act_to_jnt_state.propagate();`将电机给的数据(read()中获取的值)通过设定的transmissioin转换为joint的值
>
> `jnt_to_act_pos.propagate();` 控制器通过Handle设置了给joint的命令，现在通过设定的transmission将命令转化为给电机的命令，再通过write()发送





#### 代码载入

- [代码载入](https://github.com/ros-controls/ros_control/wiki/transmission_interface)

设置type对象，执行器对象 -> 注册act_joint transmission interface -> propagate()

```c++
#include <transmission_interface/simple_transmission.h>
#include <transmission_interface/transmission_interface.h>

int main(int argc, char** argv)
{
  using namespace transmission_interface;

  // Raw data
  double a_pos;
  double j_pos;

  // Transmission
  SimpleTransmission trans(10.0); // 10x reducer

  // Wrap raw data
  ActuatorData a_data;
  a_data.position.push_back(&a_pos);

  JointData j_data;
  j_data.position.push_back(&j_pos);

  // Transmission interface
  ActuatorToJointPositionInterface act_to_jnt_pos;
  act_to_jnt_pos.registerHandle(ActuatorToJointPositionHandle("trans", &trans, a_data, j_data));

  // Propagate actuator position to joint space
  act_to_jnt_pos.propagate();
}
```



在代码中注册position_joint_interface

```c++
hardware_interface::JointStateHandle rotation_baselink_joint_state_handle(
    "rotation_baselink_joint", &angle_[0], &vel_[1], &effort_[1]);

joint_state_interface_.registerHandle(rotation_baselink_joint_state_handle);
hardware_interface::JointHandle joint_state_handle(
    joint_state_interface_.getHandle("rotation_baselink_joint"), &cmd_[1]);

position_joint_interface_.registerHandle(joint_state_handle);

registerInterface(&position_joint_interface_);
```

```c++
    std::string robot_description;
    // ...load URDF from parameter server or file
    // Perform actual transmission loading
    if (!transmission_loader_->load(robot_description)) {return false;}
```



#### TransmissionInterfaceLoader与TransmissionLoader

> ```
> #include <transmission_interface/transmission_interface_loader.h>
> #include <transmission_interface/transmission_loader.h>
> ```

`TransmissionInterfaceLoader`和`TransmissionLoader`是ROS控制框架中的两个类，用于加载和实例化机器人控制系统中的传输器（`transmission`）。

`TransmissionLoader`类用于从URDF中加载传输器的参数，并创建一个传输器实例。它的主要任务是从URDF参数中提取传输器的参数，并使用这些参数创建一个传输器实例，同时还将控制器和机器人硬件接口绑定到传输器中。

`TransmissionInterfaceLoader`类继承自`TransmissionLoader`，并添加了一个新的功能，即使用硬件接口从机器人硬件中获取传输器参数。具体而言，它通过调用硬件接口中的`configure()`方法来获取传输器参数，然后将这些参数传递给`TransmissionLoader`以创建传输器实例。因此，`TransmissionInterfaceLoader`可以根据机器人硬件的实际状态，动态地调整传输器的参数。

因此，`TransmissionInterfaceLoader`比`TransmissionLoader`更加灵活，可以根据硬件接口动态调整传输器的参数。但是，这种灵活性的代价是`TransmissionInterfaceLoader`的实现和使用也更加复杂



- 抽象类TransmissionLoader

这是一个抽象类，我们对它的派生





### 注意

- ROS似乎会载入URDF中注释掉的link joint和transimission，请完全删除它们

- hardware_interface::ActuatorStateInterface会自动生成一个hardware_interface::PositionJointInterface，这个interface给controller用的。controller生成指令后还需要通过transmission生成最终电机命令，这就是`jnt_to_act_pos.propagate();`的工作之一



### 报错

#### Does not expose the required hardware

>  		Actuator 'middle_rotation_joint_motor'does not expose the required hardware interface 'hardware_interface::ActuatorStateInterface'.

除了joint，还需要注册一下acutor。类型可以是

`hardware_interface::ActuatorStateHandle`的作用类似于JointStateHandle，是获取电机数据层

```c
  hardware_interface::ActuatorStateHandle middle_rotation_act_state(
      "middle_rotation_joint_motor", &angle_[2], &vel_[2], &effort_[2]);
  act_state_interface_.registerHandle(middle_rotation_act_state);
```

`hardware_interface::ActuatorHandle`的作用类似于JointHandle，是电机命令层

```c++
  hardware_interface::ActuatorHandle middle_rotation_act_handle(
      act_state_interface_.getHandle("middle_rotation_joint_motor"), &cmd_[2]);
  position_act_interface_.registerHandle(middle_rotation_act_handle);
```

`hardware_interface::PositionActuatorInterface`的作用类似PositionJointInterface，用于注册

```c++
hardware_interface::PositionActuatorInterface position_act_interface_;
//其他类型还有EffortActuatorInterface等，与urdf中的transmission对应

registerInterface(&act_state_interface_);
registerInterface(&position_act_interface_);
```



#### Failed to load transmission

> ```c
>     /st_hardware: [TransmissionInterfaceLoader::load]: Failed to load transmission 'middle_rotation_joint_tran'. It contains no valid hardware interfaces.
> ```

这个报错和上面上面的那个“not expose the required hardware“的报错一起出现的，解决上面后发现这个报错还在。

可能是两个handle操控同一个关节是不允许的，所以注释掉了一个后正常了

**补充解释：PositionJointInterface会自动生成，之后从nh里面拿Handle就行了**

```c++
/*注释掉的PositionJointInterface部分*/
//  hardware_interface::JointStateHandle rotation_baselink_joint_state_handle(
//      "rotation_baselink_joint", &angle_[0], &vel_[1], &effort_[1]);
//  joint_state_interface_.registerHandle(rotation_baselink_joint_state_handle);
//  hardware_interface::JointHandle joint_state_handle(
//      joint_state_interface_.getHandle("rotation_baselink_joint"),
//      &cmd_[1]);
//  position_joint_interface_.registerHandle(joint_state_handle);
hardware_interface::ActuatorStateHandle rotation_baselink_act_state(
    "rotation_baselink_joint_motor", &angle_[0], &vel_[1], &effort_[1]);
act_state_interface_.registerHandle(rotation_baselink_act_state);
hardware_interface::ActuatorHandle rotation_baselink_act_handle(
    act_state_interface_.getHandle("rotation_baselink_joint_motor"),
    &cmd_[1]);
position_act_interface_.registerHandle(rotation_baselink_act_handle);
```

拿handle的部分：

```c++
auto effort_joint_interface = this->get<hardware_interface::EffortJointInterface>();
std::vector<std::string> names = effort_joint_interface->getNames();
for (const auto& name : names)
  effort_joint_handles_.push_back(effort_joint_interface->getHandle(name));
 //之后通过这些handles可以去设置joint limit
```





#### Replacing previously registered handle

>```c=+
>[ResourceManager<ResourceHandle>::registerHandle]: Replacing previously registered handle 'rotation_baselink_joint_motor' in 'hardware_interface::PositionActuatorInterface'.
>```

发生了重复注册，在代码中

```c
  hardware_interface::ActuatorStateHandle middle_rotation_act_state(
      "middle_rotation_joint_motor", &angle_[2], &vel_[2], &effort_[2]);
  act_state_interface_.registerHandle(middle_rotation_act_state);
  hardware_interface::ActuatorHandle middle_rotation_act_handle(
      act_state_interface_.getHandle("middle_rotation_joint_motor"), &cmd_[2]);
  position_act_interface_.registerHandle(middle_rotation_act_handle);
```

hardware_interface::ActuatorHandle注册时应该从act_state_interface_使用`getHandle()`，而不是直接：

```c
  hardware_interface::ActuatorHandle middle_rotation_act_handle(
      middle_rotation_act_state, &cmd_[2]); //重复注册
```



#### Gazebo: This controller requires a hardware interface of type 'hardware_interface::ImuSensorInterface', but is not exposed by the robot. Available interfaces in robot

自定义控制器需要获取imu sensor interface，在gazebo总默认的插件只能注册acutor，不能注册imu，需要使用二次开发的插件



其他插件：https://zhuanlan.zhihu.com/p/368033345



## Controller

> 在ROS控制器的生命周期中，在控制器被实例化时会调用init()。
>
> init()函数的主要目的是初始化控制器，包括读取参数、订阅/发布话题等等。在init()函数调用完成后，ROS控制器管理器将调用update()函数开始控制器的运行。因此，init()函数通常用于初始化控制器所需的所有内容，并在控制器启动前执行一些必要的设置。

我们需要一个控制器管理器，this传入了RobotHW，也就是控制器init()里的第一个参数

```c
controller_manager_.reset(new controller_manager::ControllerManager(this));
```

在update()函数执行时会更新所有的控制器

```c
 controller_manager_->update(time, dt);
```



rm的controller manager并不是库里的controller_manager::ControllerManager，前者本质还还是通过调用服务请求后者操控控制器







## Clock

> [wiki](http://wiki.ros.org/Clock)
>
> [同步两台机器的时钟](https://www.shuzhiduo.com/A/l1dyElaAde/)

- 模拟时钟与挂壁时钟

launch设置这个参数使得ros::Time::now()读取模拟时钟

```c
<arg name="use_sim_time" value="true"/>
```

- 启动roscore后/clock话题上就会发布时间了吗？

不一定。启动 roscore 后，如果其他节点（如模拟节点）需要使用 /clock 话题，则会在发布 /clock 话题的数据。因此，启动 roscore 仅仅创建了 ROS 系统的核心服务器，但不会生成 /clock 话题。如果需要 /clock 话题，请启动需要的节点。

- 谁在往这个话题发消息？

某些特定的节点

- 怎么启动这些节点？

启动动一个ROS时钟节点。常见的时钟节点是 ros::WallTimer 和 ros::Rate。您可以使用 ros::WallTimer 设置一个定时器，以在一个固定的频率发布 /clock 话题，或者使用 ros::Rate 限制另一个节点的频率





### 一些问题

- while(ros::ok())语句只执行一次

首先重启roscore，但是我是在终端里启动roscore后才正常。如果在X-terminal里启动就会这样。

但是之后在X-terminal里启动后又没事了

```
之后我发现启动rm_gazebo empty_world.launch后再启动我的start.launch就会这样，盲猜是两个的clock冲突了才导致这样
```





## TF

> [wiki](https://wiki.ros.org/tf2/Tutorials/Introduction%20to%20tf2)
>
> 在ROS中，tf（transform）库用于维护各个坐标系（frame）之间的关系，包括位置和方向。如果需要跟踪机器人或其他对象的位置，姿态和运动，发布tf将是非常有用的。

一种常见的应用是机器人定位，其中机器人在环境中移动并使用传感器（例如激光雷达，摄像头）来感知周围环境。发布机器人的tf帧可以帮助其他节点将机器人传感器数据与环境坐标系（例如地图）对齐，从而进行定位。

**robot_state_publisher有发布/tf的能力，不过为了实时性还是要准备一个新的controller**

不发布/tf的话，rviz就看不到东西，模型是一团白色，也无法选择fixed frame



### tf与tf_static

`tf`是一个动态的坐标系变换库，可以发布变换信息，随着时间变化。例如，它可以用于将机器人的姿态信息转换为相机坐标系。`tf`发布的变换关系在时间上是连续变化的，因此需要频繁的发布变换信息。

`tf_static`是一个静态的坐标系变换库，它发布的变换关系不随时间变化，通常是**在机器人启动时就确定好的**。例如，在机器人运行期间，机器人的基座坐标系和相机坐标系之间的关系是不会变化的。因此，发布这种静态的变换关系就可以使用`tf_static`



### KDL::Tree

> robot_state_pub的过程中需要约定父子参考系，tf wiki给的例子是自己输入参考线的frame_id，显然不利于代码复用，所以使用KDL::Tree

> KDL（Kinematics and Dynamics Library）是一个开源的C++库，用于求解机器人的正运动学、逆运动学、雅可比矩阵、动力学等问题。KDL库提供了对机器人建模、求解机器人运动学和动力学等方面的支持，是一个广泛应用于机器人领域的库。

KDL::Tree是KDL库中的一种数据结构，用于描述机器人的运动学结构，它是一种基于树形结构的描述方法，用于描述机器人关节之间的父子关系。KDL::Tree中包含多个KDL::Segment，每个Segment描述一个机器人关节的运动学信息。KDL::Tree是求解机器人运动学和动力学问题的重要基础。

通过载入urdf可以定义一个tree对象

```c++
#include <kdl/tree.hpp>

if (!urdf_model_.initParam("robot_description"))
{
  ROS_ERROR("Failed to init URDF from robot description");
  return false;
}
KDL::Tree tree;
if (!kdl_parser::treeFromUrdfModel(urdf_model_, tree))
{
  ROS_ERROR("Failed to extract kdl tree from xml robot description");
  return false;
}
```

定义一个类方便储存segment

```c++
class SegmentPair {
public:
  SegmentPair(const KDL::Segment &p_segment, std::string p_root,
              std::string p_tip)
      : segment(p_segment), root(std::move(p_root)), tip(std::move(p_tip)) {}

  KDL::Segment segment{};
  std::string root, tip;
};
```

之后函数获取所有关节



#### float segment和fixed segment

> 在ROS的URDF中，一个joint定义了两个link之间的运动关系。在这个关系中，link可以是固定的（fixed link）或者可以运动的（movable link）。Fixed link是静止的，不会随着joint的运动而移动，而movable link则随着joint的运动而移动。

Segment是由一个link和连接到它的joint组成的，因此可以理解为一个运动的部分。Fixed segment是一个没有运动的部分，因为它所连接的link是fixed link。Movable segment是一个可以运动的部分，因为它所连接的link是movable link。

在URDF中，一个joint可以有多个子segment，每个子segment连接到一个movable link。如果一个joint没有子segment，则它连接到一个fixed link。







## realtime_tools

> realtime_tools是ROS中的一个软件包，主要提供了一些实时控制相关的工具和函数。它的主要作用是提供一些在实时控制中常用的函数和类，以方便ROS节点的实时控制。

其中，常用的函数包括：

- `RealtimePublisher`: 一个用于实时发布数据的类。该类会自动对发布数据的频率进行限制，以确保数据发布的实时性。
- `RealtimeBuffer`: 一个用于存储实时数据的类。该类提供了多种数据类型的实时缓存，可以在实时线程和非实时线程之间传递数据。
- `RealtimeBox`: 一个用于存储实时数据的类。该类类似于`RealtimeBuffer`，但只支持单个数据类型的实时缓存。

另外，realtime_tools还提供了一些实时控制相关的函数，包括：

- `nonRealtime`: 一个宏定义，用于将一个函数声明为非实时函数。这可以确保该函数不会影响实时控制的执行。
- `rate`: 一个函数，用于限制函数的执行频率。该函数可以确保函数不会过于频繁地执行，从而保证实时控制的稳定性。





### TF循环检测订阅

> 在tf发布中为了保证tf缓冲区的转换是最新的，有一步是循环检测订阅；

```c++
//设置好转换
for (const auto& tran : tf_transforms)
    tf_buffer_->setTransform(tran, "robot_state_controller", false);

//在代码中执行一次发布
tf_broadcaster_.sendTransform(tf_transforms);

//实时订阅/tf
for (const auto& item : tf_msg_.readFromRT()->transforms)
{
    try
    {
      //检查话题上的时间戳是否与缓冲区的相同，如果不同则以话题缓冲区为准
      if (item.header.stamp !=
          tf_buffer_->lookupTransform(item.child_frame_id, item.header.frame_id, item.header.stamp).header.stamp)
        tf_transforms.push_back(item);
    }
    catch (tf2::TransformException& ex)
    {
      tf_transforms.push_back(item);
    }
}
```







## Move it!

> [CSDN][https://blog.csdn.net/zxxxiazai/article/details/108368231?spm=1001.2014.3001.5506]







# 代码优化

## 循环注册Handle

我是一个个按关节注册的，但是下面的是用循环替代

```c++
  auto effort_joint_interface = this->get<hardware_interface::EffortJointInterface>();
  std::vector<std::string> names = effort_joint_interface->getNames();
  for (const auto& name : names)
    effort_joint_handles_.push_back(effort_joint_interface->getHandle(name));
```





## 主循环回调化

[来源](https://blog.csdn.net/AFATAR/article/details/107453318?spm=1001.2014.3001.5506)

通过一个类里面的周期定时器调用update()函数，而在代码主循环里面改为：

```c++
{
    ros::init(argc, argv, "single_joint_hardware_interface");
    ros::NodeHandle nh;
    //ros::AsyncSpinner spinner(4);  
    ros::MultiThreadedSpinner spinner(2); // Multiple threads for controller service callback and for the Service client callback used to get the feedback from ardiuno
    ROBOTHardwareInterface ROBOT(nh);
    //spinner.start();
    spinner.spin();
    //ros::spin();
    return 0;
```

不再是while(ros::ok())  ros::spinOnce()  loop_rate.sleep();的形式



## 异常和错误处理

一些函数通常会返回表示是否处理成功的bool值，用if()判断进行鉴别和抛出异常

```c++
if (!buffer)
  throw hardware_interface::HardwareInterfaceException("Cannot create handle '" + name +
                                                       "'. Tf Buffer data pointer is null.");
```



## 容器差值前查重

> 容器插入新元素前检查是否有重复对象

```c++
#include <hardware_interface/internal/interface_manager.h>中的：


if (interfaces_.find(iface_name) != interfaces_.end())
{
  ROS_WARN_STREAM("Replacing previously registered interface '" << iface_name << "'.");
}
interfaces_[iface_name] = iface;
internal::CheckIsResourceManager<T>::callGetResources(resources_[iface_name], iface);
```





# 报错

## 编译时

### /usr/bin/ld: CMakeFiles

```c
/usr/bin/ld: CMakeFiles/st_hardware.dir/src/common/hardware_interface.cpp.o: in function `steering_engine_hw::StRobotHW::loadUrdf(ros::NodeHandle&)':

hardware_interface.cpp:(.text+0x11d6): undefined reference to `urdf::Model::initString(std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > const&)'
```

这种报错的原因是CMakelist文件里面没有包含一些库，例如上面的就是缺少“urdf".

这个报错在写代码时发现不了，只有编译时才会出现



### Clion与终端冲突

这并不会报错，当你在clion编译一次后再修改代码在终端编译，此时修改的代码不会生效还是原来的包。

catkin clean一下即可





## 运行时

### ros::ok()为false

> 程序跑着跑着停了，debug后发现是main函数里的while(ros::ok())过不去

发现是`ros::Rate loop_rate(50);`和我read()和write()的频率没对上，改对后正常



### effort_actutor_cmd[0]显示nan

经过`nt_to_act_effort_interface_->propagate();`的转换后，存储命令的数组报nan

原因不知道，可能是在转换前没有在控制器里给jont efoort设置命令，也可能和注册actuator handle和effort actutar  handle顺序有关？