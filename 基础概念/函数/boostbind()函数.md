# boost::bind()函数

太扯蛋了这个函数，每次报错一错就是一大堆



如果有问题尝试以下形式修改



## input event

```c++
 d_event_.setDelayTriggered(boost::bind(&BalanceManual::stateNormalizeDelay, this), 0.5, true);

void setDelayTriggered(boost::function<void()> delay_handler, double duration, bool rising_trigger = false,
                         bool falling_trigger = false)
  {
    ros::NodeHandle nh;
    triggered_timer_ = nh.createTimer(ros::Duration(duration), std::bind(delay_handler), true, false); //参数没有this
    if (rising_trigger)
      rising_handler_ = boost::bind(&InputEvent::startTimer, this); //参数后面跟着一个this
    if (falling_trigger)
      falling_handler_ = boost::bind(&InputEvent::startTimer, this);
  }


  left_switch_up_event_.setActiveHigh(boost::bind(&ChassisGimbalShooterManual::leftSwitchUpOn, this, _1));//有占位符
这种占位符生成的函数对象：参数类型是：
   void setActiveHigh(boost::function<void(ros::Duration)> handler)
  {
    active_high_handler_ = std::move(handler);//boost::function<void(ros::Duration)> active_high_handler_;
  }
//调用：
active_high_handler_(ros::Time::now() - last_change_);
```



## two_wheel_robot_action

回调函数本来是这样的：

```c++
void
actionDoneCallback(const actionlib::SimpleClientGoalState &state,
                   const two_wheel_robot_msg::MoveActionResultConstPtr &result);
void actionActiveCallback();
void
actionFeedbackCallback(const two_wheel_robot_msg::MoveActionFeedbackConstPtr &feed);
```

但是一到发送就不正确：

```c++
client_.sendGoal(
    goal, boost::bind(&ChassisManual::actionDoneCallback, this, _1, _2),
    boost::bind(&ChassisManual::actionActiveCallback, this),
    boost::bind(&ChassisManual::actionFeedbackCallback, this, _1));
```

> Done和Feedback会报无法匹配参数的错误，但是比对enginee manual的action后，参数没什么问题

最后是修改参数类型为：

```c++
void
actionDoneCallback(const actionlib::SimpleClientGoalState &state,
                   const two_wheel_robot_msg::MoveResultConstPtr &result); //MoveAction变成了ResultConstPtrMoveResultConstPtr
void actionActiveCallback();
void
actionFeedbackCallback(const two_wheel_robot_msg::MoveFeedbackConstPtr &feed);
```

不明白为什么要在中间删去“Action”部分