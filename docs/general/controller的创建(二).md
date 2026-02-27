# controller的创建(二)
> 更新时间: 2026年02月27日



# 利用joint_position_controller.h创建一个控制器

``` c++
#include <effort_controllers/joint_position_controller.h>  //载入头文件
#include <angles/angles.h>
#include <pluginlib/class_list_macros.hpp>

namespace effort_controllers {

JointPositionController::JointPositionController()
  : loop_count_(0)                                         
{}

JointPositionController::~JointPositionController()
{
   //.h中的ros::Subscriber sub_command_;
  sub_command_.shutdown();                              
}

    ============================================================================
     //初始化控制器
bool JointPositionController::init(hardware_interface::EffortJointInterface *robot, ros::NodeHandle &n)
{
  // Get joint name from parameter server(参数服务器)
  std::string joint_name;
  if (!n.getParam("joint", joint_name))
  {
    ROS_ERROR("No joint given (namespace: %s)", n.getNamespace().c_str());
    return false;
  }

  // Load PID Controller using gains set on parameter server
    //.h中的  control_toolbox::Pid pid_controller_; 
  if (!pid_controller_.init(ros::NodeHandle(n, "pid")))
    return false;
 
  // Start realtime state publisher 重置Unique_ptr指针，设置位置更新
    /*.h中的std::unique_ptr<realtime_tools::RealtimePublisher<control_msgs::JointControllerState>> controller_state_publisher_ ;*/
  controller_state_publisher_.reset(
    new realtime_tools::RealtimePublisher<control_msgs::JointControllerState>(n, "state", 1));

  // Start command subscriber 设置订阅者
	 //.h中的ros::Subscriber sub_command_;
  sub_command_ = n.subscribe<std_msgs::Float64>("command", 1, &JointPositionController::setCommandCB, this);

   //hardware_interface::JointHandle joint_;
  // Get joint handle from hardware interface 从硬件接口获取联合句柄
  joint_ = robot->getHandle(joint_name);

  // Get URDF info about joint 载入URDF
  urdf::Model urdf;
  if (!urdf.initParamWithNodeHandle("robot_description", n))
  {
    ROS_ERROR("Failed to parse urdf file");
    return false;
  }
    //.h中的 urdf::JointConstSharedPtr joint_urdf_;
  joint_urdf_ = urdf.getJoint(joint_name);
  if (!joint_urdf_)
  {
    ROS_ERROR("Could not find joint '%s' in urdf", joint_name.c_str());
    return false;
  }

  return true;
}

    ================================================================
     //将获得的PID系数利用 （control_toolbox::Pid） pid_controller_.setGains 载入机器人
void JointPositionController::setGains(const double &p, const double &i, const double &d, const double &i_max, const double &i_min, const bool &antiwindup)
{
  pid_controller_.setGains(p,i,d,i_max,i_min,antiwindup);
}

void JointPositionController::getGains(double &p, double &i, double &d, double &i_max, double &i_min, bool &antiwindup)
{
  pid_controller_.getGains(p,i,d,i_max,i_min,antiwindup);
}

void JointPositionController::getGains(double &p, double &i, double &d, double &i_max, double &i_min)
{
  bool dummy;
  pid_controller_.getGains(p,i,d,i_max,i_min,dummy);
}
    
  ==================================================================
    //定义头文件的函数:打印调试，关节名，位置
void JointPositionController::printDebug()
{
      //control_toolbox::Pid pid_controller_; 
  pid_controller_.printValues();
}

std::string JointPositionController::getJointName()
{
  return joint_.getName();
}

double JointPositionController::getPosition()
{
  return joint_.getPosition();
}

 =============================================================
// 设置要执行的命令,下列对应两个重载函数对应有不同的参数需求
void JointPositionController::setCommand(double pos_command)
{
    //.h中的 Commands command_struct_; 一个.h中自定义的commands结构体变量command_struct_
  command_struct_.position_ = pos_command;// double position_; 
  command_struct_.has_velocity_ = false;  // bool has_velocity_; 判断是否需要速度数据
    // Flag to ignore the velocity command since our setCommand method did not include it

  // the writeFromNonRT can be used in RT, if you have the guarantee that
  //  * no non-rt thread is calling the same function (we're not subscribing to ros callbacks)
  //  * there is only one single rt thread
  command_.writeFromNonRT(command_struct_);
}

// Set the joint position command with a velocity command as well
void JointPositionController::setCommand(double pos_command, double vel_command)
{
  command_struct_.position_ = pos_command;
  command_struct_.velocity_ = vel_command;
  command_struct_.has_velocity_ = true;

  command_.writeFromNonRT(command_struct_);
}
  ==========================================================
      
void JointPositionController::starting(const ros::Time& time)
{
    // .h中的hardware_interface::JointHandle joint_;
  double pos_command = joint_.getPosition();

  // Make sure joint is within limits if applicable 检查关节限制
  enforceJointLimits(pos_command);

  command_struct_.position_ = pos_command;
  command_struct_.has_velocity_ = false;

  command_.initRT(command_struct_);

  pid_controller_.reset();
}

void JointPositionController::update(const ros::Time& time, const ros::Duration& period)
{
    //获取定义好的sommand_struct_
  command_struct_ = *(command_.readFromRT());
  double command_position = command_struct_.position_;
  double command_velocity = command_struct_.velocity_;
  bool has_velocity_ =  command_struct_.has_velocity_;

  double error, vel_error;
  double commanded_effort;

  double current_position = joint_.getPosition();

  // Make sure joint is within limits if applicable
  enforceJointLimits(command_position);

  // Compute position error 输出误差
  if (joint_urdf_->type == urdf::Joint::REVOLUTE)//revolute - 可以绕着一个轴旋转的铰链关节，有最大值和最小值限制。
  {
    angles::shortest_angular_distance_with_large_limits(
      current_position,
      command_position,
      joint_urdf_->limits->lower,
      joint_urdf_->limits->upper,
      error);
  }
  else if (joint_urdf_->type == urdf::Joint::CONTINUOUS)//continuous - 连续型的铰链关节，可以绕一个轴旋转，没有最大值和最小值限制
  {
    error = angles::shortest_angular_distance(current_position, command_position);
  }
  else //prismatic - 滑动关节，可以沿着一个轴滑动，有最大值和最小值限制
  {
    error = command_position - current_position;
  }

   ================================================================
  //决定调用两个PID computeCommand（）方法中的哪一个
  if (has_velocity_)
  {
    // 如果给出非零速度指令，则计算速度误差
    vel_error = command_velocity - joint_.getVelocity();

    //设置PID误差，计算非均匀PID指令
    //时间步长。这还允许用户传入预计算的衍生错误。
    commanded_effort = pid_controller_.computeCommand(error, vel_error, period);
  }
  else
  {
    // Set the PID error and compute the PID command with nonuniform
    // time step size.
    commanded_effort = pid_controller_.computeCommand(error, period);
  }

  joint_.setCommand(commanded_effort);//硬件接口

    =================================================================
  // 发送数据
  if (loop_count_ % 10 == 0)
  {
    if(controller_state_publisher_ && controller_state_publisher_->trylock())//当发布者存在且线程空闲未锁定时
    { //开始输入要传输的数据
      controller_state_publisher_->msg_.header.stamp = time;                 //msg_是Msg类型变量，存储要发送的信息
      controller_state_publisher_->msg_.set_point = command_position;        /
      controller_state_publisher_->msg_.process_value = current_position;
      controller_state_publisher_->msg_.process_value_dot = joint_.getVelocity();
      controller_state_publisher_->msg_.error = error;
      controller_state_publisher_->msg_.time_step = period.toSec();
      controller_state_publisher_->msg_.command = commanded_effort;

      double dummy;
      bool antiwindup;
      getGains(controller_state_publisher_->msg_.p,
        controller_state_publisher_->msg_.i,
        controller_state_publisher_->msg_.d,
        controller_state_publisher_->msg_.i_clamp,
        dummy,
        antiwindup);
      controller_state_publisher_->msg_.antiwindup = static_cast<char>(antiwindup);
      controller_state_publisher_->unlockAndPublish();
    }
  }
  loop_count_++;
}

void JointPositionController::setCommandCB(const std_msgs::Float64ConstPtr& msg)
{
  setCommand(msg->data);
}

// Note: we may want to remove this function once issue https://github.com/ros/angles/issues/2 is resolved
    //对上面用到的关节限制检查函数进行定义
void JointPositionController::enforceJointLimits(double &command)
{
  // Check that this joint has applicable limits
  if (joint_urdf_->type == urdf::Joint::REVOLUTE || joint_urdf_->type == urdf::Joint::PRISMATIC)
  {
    if( command > joint_urdf_->limits->upper ) // above upper limnit
    {
      command = joint_urdf_->limits->upper;
    }
    else if( command < joint_urdf_->limits->lower ) // below lower limit
    {
      command = joint_urdf_->limits->lower;
    }
  }
}

} // namespace

PLUGINLIB_EXPORT_CLASS( effort_controllers::JointPositionController, controller_interface::ControllerBase)
```
