# 控制器们

rm_controllers

> 欧拉角
>
> yaw：偏航     pitch：倾斜，坠落     roll：转动

![image-20220305171721827](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220305171721827.png)





*****

### rm_chassis_controllers

底盘控制器们，用于操纵机器人底盘




#### chassis_base

> 基本底盘操纵，涉及参数获取及初始化，坐标显示，实时发布者，功率限制
>
> ``` c++
> bool init(hardware_interface::RobotHW* robot_hw, ros::NodeHandle& root_nh, ros::NodeHandle& controller_nh) override;
> //初始化，获取各项参数
> ```
>
> ```c++
> void ChassisBase<T...>::update(const ros::Time& time, const ros::Duration& period);
> //更新数据，检查新命令，包含一个模式控制和防止错乱机制
> ```
>
> ``` c++
> void recovery();
> //速度置零
> ```
>
> ``` c++
> void updateOdom(const ros::Time& time, const ros::Duration& period);
> // tf2::doTransform：将收到的map系下全局路径点变换到odom系下
> //odom进行积分，根据计算得到的坐标和真实坐标做出坐标系
> ```
>
> ```c++
> tf2::doTransform(const T& data_in, T& data_out, const geometry_msgs::TransformStamped& transform);
> //功能：模板化函数进行转换,date_out转移到odom系.
> /* 参数 data_in要转换的数据。
> \ 参数 data_out对输出数据的引用。
> \ 参数 transform应用于data_in以填充data_out的变换。*/
> ```
>
> ```c++
>  void tfVelToBase(const std::string& from);
> //tf速度转换到base_link上
> ```
>
> ``` c++
> void update(const ros::Time& time, const ros::Duration& period);
> //获取新的底盘命令并更新命令，j
> ```
>
> ```c++
> void ChassisBase<T...>::cmdChassisCallback(const rm_msgs::ChassisCmdConstPtr& msg);
> void ChassisBase<T...>::cmdVelCallback(const geometry_msgs::Twist::ConstPtr& msg);
> //已发布的命令储存在非实时数据中
> ```
>
> 
>
> 运动模式选择
>
> ``` c++
> void raw();            //初始
> 控制逻辑：检查模式的改变。若改变则调用底下的recovery，reset修改并发布状态。判断跟随方式并计算命令
> void follow();         //不跟随万向轮，自由运动
> 	检查模式是否改变，reset更新里程计，判断命令（功率限制tfVelToBase）后尝试把位置矩阵转化为欧拉角，然后计算并输出命令
> void twist(）          //扭腰模式
> 检查模式是否改变，reset更新里程计,设置转动方式为偏航（陀螺），然后计算并输出命令
> void gyro()            //小陀螺模式
> 
> 
> switch (state_)        //匹配raw，follow，gyro，twist模式
> 0：RAW模式，初始状态，此模式下底盘无法运动。
> 1：FOLLOW模式，底盘跟随设定坐标系移动，底盘正面（即底盘坐标的x轴方向）与设定坐标系的x轴同向（默认跟随map轴）。
> 2：GYRO模式，小陀螺模式下，底盘的直线运动会跟随设置的坐标系运动，同时自身能够旋转。
> T3：TWIST模式，扭腰状态下，底盘正面将以特殊角度面对敌方机器人，并且底盘不断小幅度旋转。
> ```
>
> ``` c++                           
> tf2:doTransform()      //转换自定义数据类型
> ```
>
> **操纵样例**
>
> rostopic pub /controllers/chassis_controller/command rm_msgs/ChassisCmd "mode: 2
> accel:
> linear: {x: 3.0, y: 3.0, z: 0.0}
> angular: {x: 0.0, y: 0.0, z: 3.0}
> power_limit: 200.0
> follow_source_frame: 'map'
> stamp: {secs: 0, nsecs: 0}" 





#### balance

> 获取机器人当前的运动数据，是一个状态反馈控制器。
>
> ``` c++
> void getK(XmlRpc::XmlRpcValue a, XmlRpc::XmlRpcValue b, XmlRpc::XmlRpcValue q, XmlRpc::XmlRpcValue r);
> //接收ab（状态空间表达）qr（权重矩阵），分别检查各项数据是否有效，获得K值（计算功率限制）
> ```
>
> ``` c++
> void moveJoint(const ros::Time& time, const ros::Duration& period) override;
> //接受最新的命令并把它转化为关节命令
> ```
>
> ``` c++
> void BalanceController::update(const ros::Time& time, const ros::Duration& period);
> //更新并发布当前速度数据
> ```
>
> ``` c++
> geometry_msgs::Twist BalanceController::forwardKinematics();
> //获取速度数据（包含线速度，角速度）
> ```
>
> 





#### mecanum

> 麦克拉姆轮
>
> ```c++
> void moveJoint(const ros::Time& time, const ros::Duration& period) override;
> //逆运动学：根据命令解算轮子角速度
> ```
>
> ```c++
>  geometry_msgs::Twist forwardKinematics() override;
> //正运动学：根据轮子速度计算车子整体的角速度，线速度。
> ```



#### omni

> 全向轮



#### sentry

> 哨兵底盘,因为只在x轴上运动所以只保有一个速度变量。



#### swerve

> 舵轮