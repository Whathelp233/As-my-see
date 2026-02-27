# Bullet发射装置
> 更新时间: 2026年02月27日

# bullet_slove

# 配置子弹

```c++
BulletSolver::BulletSolver(ros::NodeHandle& controller_nh)
    //BulletSolver 类是所有模型以及算法的基类，定义了实现求解子弹发射角度的算法函数接口，和空气阻力系数、重力加速度、发射延时、子弹速度等成员变量。
    //获取publish_rate,缺省50
    //配置resistance_coff_qd_（？）
    //设置目标的颜色，坐标，帧id等数据
    //设置实时工具对目标进行监听
```



# 获取子弹发射速度&&阻力系数

```c++
double BulletSolver::getResistanceCoefficient(double bullet_speed) const
    // 子弹速度有5个输出值:10,15,16,18,30
    //用if根据获取的速度判断子弹对应哪个速度发射值，因为速度存在误差所以if判读的值稍大。
    //不同发射速度的阻力系数不同
```



# 发射解算

```c++
bool BulletSolver::solve(geometry_msgs::Point pos, geometry_msgs::Vector3 vel, double bullet_speed)
    //赋值目标的坐标，子弹的发射速度
    //根据获得的发射速度，设置阻力系数，缺省0.001
    //误差值赋999，当误差大于0.001进行一次解算。解算次数大于20次或有非法字符时返回错误
```



# 发射指令发布

```c++
void BulletSolver::bulletModelPub(const geometry_msgs::TransformStamped& map2pitch, const ros::Time& time)
    //发布前先清空目标位置和实际位置
    //四元数转欧拉角
    //循环获取数据，同时计算子弹的预期位置
    //循环获取数据，同时计算子弹的实际位置
    //实时工具对数据进行发布
```



# 云台误差

```c++
double BulletSolver::getGimbalError(geometry_msgs::Point pos, geometry_msgs::Vector3 vel, double yaw_real,
                                    double pitch_real, double bullet_speed)
    //？
```



# 更新参数

```c++
void BulletSolver::reconfigCB(rm_gimbal_controllers::BulletSolverConfig& config, uint32_t /*unused*/)
    //不同速度下的阻力系数
    //重力加速度g
    //发射间隔delay
    //迭代时间dt
    //最长的飞行时间timeout
    //数据写入非实时区
    //实时工具写入非实时数据
```



# shooter

> 设置一系列发射模式，完成对弹丸进行发射的一系列流程
>
> qd：角加速度
>
> block_effort：设置判断阻塞力，若扳机力大于该力说明阻塞
>
> anti_block_：如果阻塞，该参数将让扳机倒转

**初始化设置**

```c
bool Controller::init(hardware_interface::RobotHW* robot_hw, ros::NodeHandle& root_nh, ros::NodeHandle& controller_nh)
    //阻塞力，阻塞速度，持续时间，范围时间
    //发射速度qd_10\15\16\18\30
    //定义轮速rotation，拨弹轮threshlod
    //订阅command话题获取命令
    //定义左右摩擦轮friction，及扳机trigger
    //如果对摩擦轮，扳机的初始化全部成功，返回true
```



**更新指令**

```c
void Controller::update(const ros::Time& time, const ros::Duration& period)
    //更新发射状态state
    //如果state不等于当前模式且不为阻塞BLOCK，执行更新
    //非阻塞状态，向目标发送命令cmd
    //匹配state READY，PUSH，STOP，BLOCK
    //向摩擦轮，扳机发送更新指令
```



**一系列指令**

```c
void Controller::ready(const ros::Duration& period)
    //预备状态
    //如果state发生改变，执行标准化normalize（）
```

```c
void Controller::push(const ros::Time& time, const ros::Duration& period)
    //发射状态
    //设置好发射参数，摩擦轮进行旋转
    //发射设置有时间间隔(hz)等限制条件，无法满足则显示提示
    
    /*利用比较力的大小检查阻塞，设置可能阻塞maybe_block，并设置好阻塞时间
       如果阻塞时间开始仍未发射，将当前状态设置为阻塞，并返回exit*/
```

```c
void Controller::block(const ros::Time& time, const ros::Duration& period)
    //阻塞状态
    //如果扳机的位置发生适度改变或当前时间与上一次阻塞超出了一定时间，返回退出阻塞
```



**设置发射速度**

```c
void Controller::setSpeed(const rm_msgs::ShootCmd& cmd)
    //发射速度
    //依次匹配命令设置的速度大小，缺省0
    //向摩擦轮发送参数
```



**标准化**

```c
void Controller::normalize()
    //设置标准参数命令，参数来自yaml
    /*包括阻塞：力，速度，持续时间，超出时间，阻塞反转
         速度：10，15，16，18，30
         等
      以及一个非实时命令区，读取实时的函数
    */
    
```
