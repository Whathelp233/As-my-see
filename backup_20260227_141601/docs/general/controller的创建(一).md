# controller的创建(一)
> 更新时间: 2026年02月27日

创建一个controller通常的方法是利用已定义好的插件

例：

``` c++
#include <velocity_controllers/joint_position_controller>
```

默认的设置提供了以下的ros_control接口：

- hardware_interface::JointStateInterface

- hardware_interface::EffortJointInterface

- hardware_interface::VelocityJointInterface -不完全应用

  

[JointCommandInterface](http://docs.ros.org/en/melodic/api/hardware_interface/html/c++/classhardware__interface_1_1JointCommandInterface.html) 硬件接口支持命令关节阵列。

```
#include <joint_command_interface.h>
```

![Inheritance graph](http://docs.ros.org/en/melodic/api/hardware_interface/html/c++/classhardware__interface_1_1JointCommandInterface__inherit__graph.png)

[Effort Joint Interface](https://link.zhihu.com/?target=http%3A//docs.ros.org/en/melodic/api/hardware_interface/html/c%2B%2B/classhardware__interface_1_1EffortJointInterface.html)：用于指挥基于力的关节

[Velocity Joint Interface](https://link.zhihu.com/?target=http%3A//docs.ros.org/en/melodic/api/hardware_interface/html/c%2B%2B/classhardware__interface_1_1VelocityJointInterface.html)：用于指挥基于速度的关节

[Position Joint Interface](https://link.zhihu.com/?target=http%3A//docs.ros.org/en/melodic/api/hardware_interface/html/c%2B%2B/classhardware__interface_1_1PositionJointInterface.html)：用于指挥基于位置的关节



# joint_position_controller.h的解析

> 工作：接受上一个位置数据并发送目标数据

``` c++
#include <control_msgs/JointControllerState.h>
#include <control_toolbox/pid.h>
#include <controller_interface/controller.h>
#include <hardware_interface/joint_command_interface.h>
#include <memory>
#include <realtime_tools/realtime_buffer.h>
#include <realtime_tools/realtime_publisher.h>
#include <ros/node_handle.h>
#include <std_msgs/Float64.h>
#include <urdf/model.h>

namespace effort_controllers                          //定义命名空间
{

class JointPositionController: public controller_interface::Controller<hardware_interface::EffortJointInterface>
{
public:

  //存储position和velocity命令，以便更轻松地使用实时缓冲区
  struct Commands
  {
    double position_; // Last commanded position
    double velocity_; // Last commanded velocity
    bool has_velocity_; // false if no velocity command has been specified
  };

  JointPositionController();
  ~JointPositionController();


  //init将会用于初始化指向硬件接口线程的指针，接口类型（eFFortJointInterface），以及所在的节点句柄
  bool init(hardware_interface::EffortJointInterface *robot, ros::NodeHandle &n);

  //输入下一次更新时的目标数据：旋转（角度）和棱柱（位置）
  void setCommand(double pos_target);

  //也可以包括目标速度的数据
  void setCommand(double pos_target, double vel_target);

   /*This is called from within the realtime thread just before the
    first call to \ref update
    \param time The current time
    实时调用一次时间*/
  void starting(const ros::Time& time);

   //创建定时器，设置时间间隔
  void update(const ros::Time& time, const ros::Duration& period);

   //获取PID各项系数
  void getGains(double &p, double &i, double &d, double &i_max, double &i_min);

   //Get the PID parameters
  void getGains(double &p, double &i, double &d, double &i_max, double &i_min, bool &antiwindup);

  //打印调试信息到控制台
  void printDebug();

  // Set the PID parameters
  void setGains(const double &p, const double &i, const double &d, const double &i_max, const double &i_min, const bool &antiwindup = false);

  //获取操纵关节的名字
  std::string getJointName();

  //获取关节位置
  double getPosition();

  //重新设置实时缓冲区的预分配内存 (pre-allocated memory that is re-used to set the realtime buffe)
  hardware_interface::JointHandle joint_;
  urdf::JointConstSharedPtr joint_urdf_;
  realtime_tools::RealtimeBuffer<Commands> command_;
  Commands command_struct_; 
    
private:
  int loop_count_;
  control_toolbox::Pid pid_controller_;       /**< Internal PID controller. */

  std::unique_ptr<
    realtime_tools::RealtimePublisher<
      control_msgs::JointControllerState> > controller_state_publisher_ ;

  ros::Subscriber sub_command_;

  /**
   * \brief Callback from /command subscriber for setpoint
   */
  void setCommandCB(const std_msgs::Float64ConstPtr& msg);

  //检查关节限制，判断目标数据是否超限
  void enforceJointLimits(double &command);

};

} // namespace
```





# joint_group_position_controller.h的解析

> 工作：一次设置多个关节位置





























在创建包后，将PID系数与控制器的配置写入包内的$$.yaml$$（package_name/config/robot_control.yaml)文件中;接着创建一个launch文件(package_name/launch/robot_control.launch)用于读取编写的yaml文件并启动控制器。编写完成后控制台运行roslaunch命令，加载控制器
