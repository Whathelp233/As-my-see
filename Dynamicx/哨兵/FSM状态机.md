# FSM状态机

> 事件触发器，我们所写的控制器本质为插件，它们的特点之一是没有main函数，而状态机的任务就在于触发控制器的事件





## data.h

> 从结构上来看，rm_fsm的data.h文件内容与rm_referee相似
>
> 获取最基本的数据，准备好serial与publisher



### 结构

#### 订阅者们

> /dbus_data
>
> /controllers/upper_gimbal_controller/track
>
> /controllers/lower_gimbal_controller/track
>
> /controllers/upper_gimbal_controller/error_des
>
> /controllers/lower_gimbal_controller/error_des

```c++
  ros::Subscriber joint_state_sub_;
  ros::Subscriber dbus_sub_;
  ros::Subscriber upper_track_sub_, lower_track_sub_;
  ros::Subscriber upper_gimbal_des_error_sub_, lower_gimbal_des_error_sub_;
```



### 发布者

> 都在referee.h中实现
>
> /referee

```c++
ros::Publisher referee_pub_;
ros::Publisher super_capacitor_pub_;
```



### 更新

> 更新的数据：joint_state_（position，effort）    odom2baselink 

```c++
void update(const ros::Time &time)
    
sum_effort_ += joint_state_.effort[0];//累加力

try { odom2baselink = tf_buffer_.lookupTransform("odom", "base_link", ros::Time(0)); }//获取坐标转换
```



### 命令发布者

> 对应于command_sender.h，派生而出的类
>
> 录入track_data，获取pitch，yaw的数据



> class SideCommandSender自身集成了云台发布与发射发布
>
> 由它实例的类是*upper_cmd_sender_, *lower_cmd_sender_

```c++
  rm_common::GimbalCommandSender *gimbal_cmd_sender_;
  rm_common::ShooterCommandSender *shooter_cmd_sender_;

  rm_msgs::TrackDataArray &track_data_;
  rm_msgs::GimbalDesError &gimbal_des_error_;
  double pitch_min_{}, pitch_max_{}, yaw_min_{}, 
  double &pos_yaw_, &pos_pitch_;
  double yaw_direct_{1.}, pitch_direct_{1.};
```





## fsm_common.h

> 拥有StateBase类与FsmBase类

### 结构

#### class StateBase

> 包含 run()，getname(), sendCommand(),等函数，作用在于获取目标状态和发布命令

```c++
  StateBase(ros::NodeHandle &nh, Data *data, std::string state_name);//构造函数

  std::string getName() { return state_name_; }//获取状态名


  virtual void setGimbal(SideCommandSender *side_cmd_sender) {
    side_cmd_sender->gimbal_cmd_sender_->setMode(rm_msgs::GimbalCmd::RATE);
  }
  virtual void setShooter(SideCommandSender *side_cmd_sender) {
    side_cmd_sender->shooter_cmd_sender_->setMode(rm_msgs::ShootCmd::STOP);
  }//分别对应云台，发射，


  Data *data_;
  std::string state_name_;
  rm_common::ChassisCommandSender *chassis_cmd_sender_;
  rm_common::Vel2DCommandSender *vel_2d_cmd_sender_;
  SideCommandSender *upper_cmd_sender_, *lower_cmd_sender_;
```



#### class FsmBase

> 包含run(), getNextState(), checkSwich/Referee(),和一系列referee发布开关，远程控制开关

```c++
  //当前状态
  StateBase *current_state_;
  Data data_;

  //需要使用controller manager
  rm_common::ControllerManager controller_manager_;
  rm_common::SwitchDetectionCaller *upper_switch_detection_srv_{}, *lower_switch_detection_srv_{};
  rm_common::CalibrationQueue *upper_trigger_calibration_{}, *upper_gimbal_calibration_{},
*lower_trigger_calibration_{}, *lower_gimbal_calibration_{};
  std::map<std::string, StateBase *> string2state_;

  bool remote_is_open_{};
  bool chassis_output_{}, gimbal_output_{}, shooter_output_{};
```





# 实现

## Fsm_common.cpp

> 定义了StateBase与FsmBase的子函数

### StateBase

#### 构造函数

> 联系到命名空间 /chassis /vel /upper /lower
>
> 调用函数commandSender()



#### run()

> 初始化，更新

```c++
  try 
    if (data_->serial_.available())
    //尝试联系serial
        
  setChassis();
  setGimbal(upper_cmd_sender_);
  setGimbal(lower_cmd_sender_);
  setShooter(upper_cmd_sender_);
  setShooter(lower_cmd_sender_);
  sendCommand(ros::Time::now());
  //设置命令发布者
  //都来自于side_cmd_sender

  try {
    data_->serial_.write(data_->referee_.tx_buffer_, data_->referee_.tx_len_);
  }//设置完后尝试写入线程
```



#### sendCommand()

> 依次调用commandSender的发布函数

```c++
  chassis_cmd_sender_->sendCommand(time);
  vel_2d_cmd_sender_->sendCommand(time);
  upper_cmd_sender_->gimbal_cmd_sender_->sendCommand(time);
  lower_cmd_sender_->gimbal_cmd_sender_->sendCommand(time);
  upper_cmd_sender_->shooter_cmd_sender_->sendCommand(time);
  lower_cmd_sender_->shooter_cmd_sender_->sendCommand(time);
```





### FsmBase

#### 构造函数

```c++
  ros::NodeHandle upper_nh(nh, "upper");
  ros::NodeHandle upper_detection_switch_nh(upper_nh, "detection_switch");
  upper_switch_detection_srv_ = new rm_common::SwitchDetectionCaller(upper_detection_switch_nh);
  //上升开关句柄？

  controller_manager_.startStateControllers();
  
  string2state_.insert(std::make_pair("INVALID", nullptr));
  //是map类型，内部是string和stateBase
  current_state_ = string2state_["INVALID"];
```



#### run()

> 更新time，data；检查referee，switch；设置目标颜色，装甲板，服务；状态名（state_name）；
>
> 检查最新状态是否改变，改变则更新map：string2state_和stateBase类current_state_
>
> 未改变则执行 current_state的run()

```c++
  ros::Time time = ros::Time::now();
  data_.update(time);
  checkReferee(time);
  checkSwitch(time);
  controller_manager_.update();

  upper_switch_detection_srv_->setEnemyColor(data_.referee_.referee_data_);
  upper_switch_detection_srv_->setArmorTargetType(rm_msgs::StatusChangeRequest::ARMOR_WITHOUT_OUTPOST_BASE);
  upper_switch_detection_srv_->callService();
  lower_switch_detection_srv_->setEnemyColor(data_.referee_.referee_data_);
  lower_switch_detection_srv_->setArmorTargetType(rm_msgs::StatusChangeRequest::ARMOR_WITHOUT_OUTPOST_BASE);
  lower_switch_detection_srv_->callService();


  std::string next_state_name = getNextState();
  if (next_state_name != current_state_->getName()) {
    current_state_ = string2state_[next_state_name];
    current_state_->onEnter();
    current_state_->run();
  } else current_state_->run();
```



#### checkSwitch()

> 检查远程是否可用和dbus的stamp后设置远程状态为ON/OFF，用于检查是否和远程断开连接

```c++
  if (remote_is_open_ && (time - data_.dbus_data_.stamp).toSec() > 0.1) {
    ROS_INFO("Remote controller OFF");
    remoteControlTurnOff();
    remote_is_open_ = false;
  }
  //使用stamp连接时间检查远程，当断连大于0.1s后判断连接已断开

  if (!remote_is_open_ && (time - data_.dbus_data_.stamp).toSec() < 0.1) {
    ROS_INFO("Remote controller ON");
    remoteControlTurnOn();
    remote_is_open_ = true;
```



#### checkReferee()

> 关于底盘，云台，发射的输出

```c++
  if (data_.referee_.referee_data_.game_robot_status_.mains_power_chassis_output_ && !chassis_output_) {
    ROS_INFO("Chassis output ON");
    chassisOutputOn();
    //rosinfo
  }
  if (data_.referee_.referee_data_.game_robot_status_.mains_power_gimbal_output_ && !gimbal_output_) {
    ROS_INFO("Gimbal output ON");
    gimbalOutputOn();
  }
  if (data_.referee_.referee_data_.game_robot_status_.mains_power_shooter_output_ && !shooter_output_) {
    ROS_INFO("Shooter output ON");
    shooterOutputOn();
  }
  //之前见到的提示
  //在protocol.h中赋值为1，即为打开

  if (data_.referee_.referee_data_.game_robot_status_.mains_power_chassis_output_) chassis_output_ = true;
  else chassis_output_ = false;
  if (data_.referee_.referee_data_.game_robot_status_.mains_power_gimbal_output_) gimbal_output_ = true;
  else gimbal_output_ = false;
  if (data_.referee_.referee_data_.game_robot_status_.mains_power_shooter_output_) shooter_output_ = true;
  else shooter_output_ = false;
```





#### remoteControl开关

```c++
void FsmBase::remoteControlTurnOff() {
  controller_manager_.stopMainControllers();
  controller_manager_.stopCalibrationControllers();
}

void FsmBase::remoteControlTurnOn() {
  controller_manager_.startMainControllers();
}
```

