# BUG 表（整合）

这里主要用来描述一些调车的时候可能出现的bug还有对应的解决方法

目录

[TOC]

## 系统

### NUC 14 PRO 掉网卡驱动 

带来的主要影响：连不上easywifi，不方便调车

主要解决方法：主要是上网去找对应的驱动，然后在本地编译后移到NUC的 /lib/firmware/ 目录下

一般来说队里的NUC是 intel的网卡，它的网卡驱动可以直接在官网上找到已经编译的版本

https://www.intel.cn/content/www/cn/zh/download/824804/intel-wireless-wi-fi-drivers-for-linux.html

（注意对应的内核版本，这里的内核最低好像都是6.11以上，如果需要低内核版本后面更新）



### 在换完内核后，时间戳出现异常
带来的主要影响：bag存储混乱
出现原因：未知，但是具体体现为系统获取时间失败就自动定位最近的同步时间
主要解决方法：关闭NUC上的时间同步服务器，并且手动调整时间

打开终端
```
sudo systemctl stop systemd-timesyncd
sudo systemctl disable systemd-timesyncd
sudo systemctl stop ntp
sudo systemctl disable ntp
sudo timedatectl set-time '20xx-xx-xx xx:xx:xx'
timedatectl #验证
```


### kex_exchange_identification: Connection closed by remote host

**solution**：

1. 

- (1)cd .ssh

- (2)chmod +600(+777) know_hosts

2. 重新生成ssh密钥

**cause：**know_hosts里面存放ssh密钥，ssh连不上并且出现这个信息是权限问题，chmod 600就行，或者重新生成一下



------



## 硬件调试（调车）

### 在开启校准之后电机仍然无法转动

前置知识：增量式编码器在初始位置时会产生随机地址值，需要设置一个固定的限位(通过开启校准控制器），使之撞击到该限位后进行调试再使用。

我们有一个校准控制器，当开启控制器后电机即会撞击一次，在此之间可能存在一些问题使电机无法转动

未显示校准，电机也未转动

- can掉线
- 未设置PID（P值太小或没定义P）
- 代码出现错误



当显示调试成功但电机未转动

- urdf中有一个指定元素firsthole(?)，当获取到的值小于该元素时才会判断成功，若该元素过小，会造成该问题

## 影响重复度（弹丸散布）的因素

### 1. 非控制部分

1. 摩擦轮磨损

- 这个会导致射速波动变大，因为磨损程度不同必然导致初速度波动变大

2. 摩擦轮电机

- 确保电机完好，碰到过电机轴承有问题

3. 弹丸姿态

- 观察弹丸发射前的位置，保证每次的位置都相同
- 根据发射的情况（比如是否双发、卡弹），可以通过改变trigger的offset来解决；或者说一定要调一个合适的offset来使弹丸不双发、不卡弹

4. 弹丸粗糙程度

- 弹丸粗糙程度不同，也可能导致弹丸初速度不同，因为摩擦轮转速和弹丸的速度是符合动量守恒的

5. 单发限位

- 单发限位太软，限不住弹丸，会导致发射前弹丸的位置有问题，从而导致双发
- 单发限位太硬，会导致弹丸被单发限位卡住，导致卡弹
- 单发限位左右偏而非竖直，会导致弹丸发射之后左右偏

6. 底盘移动

- 每次发射的后座力可能会让底盘后移，导致弹丸发射的起点改变，进而导致重复度降低
- 其他原因导致的底盘移动都会导致重复度降低，要观察底盘确定他是否移动
- 底盘移动可以通过把底盘架起来解决，但是一定要架稳

7. 云台移动

- 英雄一定要标定imu，其他兵种可以不用
- imu一定要做好零飘补偿（method：IMU零飘补偿.md）
- 可以通过把底盘架起来，然后关掉orientation controller，这样用的就是底盘的数据，follow的时候底盘不会动，然后云台会follow过去；如果开了这个控制器，那就是用imu的数据，云台yaw动了之后，是底盘会follow过去

8. 撞枪管

- 对于17mm小弹丸，可以直接听声音判断
- 对于42mm大弹丸，个人认为：在测速内壁贴一圈复写纸+白纸为较好的方法

9. 温度

- 一定要**预热！！！**
- 空转温度上升幅度有限且速度较慢，可以套管发射，当射速波动大概稳定在一个值时，可以认为预热完成

10. **机械安装问题**

- **一定**要保证安装没有问题，精细到一个**垫片！！！**
- 确保**定心**没有问题

### 2. 控制部分

1. 调整拨盘offset来改变弹丸初始位置，要求调到他不卡弹、不双发
1. 调拨盘pid，使其不超调，不过阻尼
1. 摩擦轮掉速

- 个人测试：
  - 单个摩擦轮每次掉速波动大约在**30rad/s**
  - 每次发射两个摩擦轮掉速大约差**10rad/s**

3. 经验

- **影响上下散布**：射速波动
  - 弹丸新旧、摩擦轮温度、机械安装

- **影响左右散布**：弹丸定位
  - 单发限位是否晃动/歪、弹丸定心

<mark>机械的安装、环境（温度、湿度）、（弹丸的新旧），这是影响重复度最大的因素</mark>

# 待整理


---

2. 运行manual.launch和rm_dbus

(1)出现报错：[rt_dbus] Unable to open dbus

(2)solution：通过在dbus.cpp中看代码可以知道，打不开dbus的串口时就会报这个错，串口之类的硬件问题直接找电路解决（一般就是线松了，自己重新插插）

---

3. 测试新拨弹method（减速比传动比都是（大比小）这样的形式，）

- 修改4处参数：

1. rm_config/config/rm_controller/${ROBOT_TYPE}.yaml：shooter_controller下的block_effort，改的比urdf中的jonit下面的<limit effort>小一点
2. shooter.transmission.urdf.xacro中actuator的减速比，如果是直驱就填电机减速器的减速比（例如3508+配套减速箱减速比是19.2032），如果有传动带（或者齿轮传动之类的）就要再乘上齿轮传动的传动比
3. shooter.urdf.xacro中joint标签下的limit标签中的effoet和 velocity，一个是关节的最大力矩，一个是关节的最大转速

（1）最大力矩要用执行器（eg:3508电机）的瞬时最大力矩乘传动比

（2）最大转速除电机减速比再除（eg:齿轮传动）传动比

- 开校准控制器看方向修改urdf里面减速比的正负
- rqt调pid，一般校准控制器给一个p就行，因为只需要他正常转动就可以
- 调shooter controller的pid，看电机曲线调，就是plotjuggler选congtroller/state，看setpoint跟process_value
- 如果对某个电机的pid没有概念（比如大概多少是大，多少是小），可以看配置文件中相同的电机的pid

---

4. 开gimbal_controller，云台会甩

- 正常情况下，开启orientation_controller、gimbal_controller，云台固定在开启控制前的位置，电机有力；因为初始的时候云台是rate模式，没有给pitch_rate跟yaw_rate的话那pitch跟yaw就必须保持静止，也就是停在当前这个位置
- **cause**：urdf中的imu的坐标系跟实际的不一样，那么假设tf中imu姿态是正的，但是实物yaw不正，
- **solution**：看实物，云台上的imu的坐标系；imu那块板上面画着他的坐标系，开rviz对比rviz里面的imu的坐标系，如果两个不一样就改urdf中的imu那个link的<interial>标签下的rpy

---

5. 开遥控器后，一直小陀螺，yaw不动

- cause：yaw线断了，导致yaw掉了，获取不到yaw跟baselink的转换，他就会一直修正那个位置

---

6. 使用网线进行调试

- 用网线连接nuc和自己的电脑
- 打开一个终端，输入命令（可以扫描出网线连接的设备的ip）：

```
nmap 10.42.0.1/24
```

- ssh连接nuc
- 如果要使用rqt、plotjuggler这些工具，要把ros_master_url改成nuc的ip

---

7. rviz看tf之类的东西，要开robot_state_controller，因为robot_state会高频维护tf；如果要看关节数据，就开joint state controller

---

8. 修改power_limit.h中的normal()，传到nuc上编译后，新代码并没有生效

- **cause**：单独编译rm_common，可以看到catkin build编译的时间很短(0.2s)，基本可以判断虽然显示编译成功，但是实际上并没有编译这个包
- **solution**：catkin clean再catkin build

---

9. 使用热点登陆nuc

- 将手机热点的ssid跟密码改成 dynamicX604_5G & dynamicx（因为配nuc的时候设置好了这个wifi，所以他会自动连接这个ssid的wifi，用存储的密码）
- 自己的电脑连接这个热点
- 在手机上看nuc的ip（有些手机不行，不行就换个手机）

---

10. 测试英雄发射重复度

problem

单发限位时歪的，会导致弹丸受力会偏，落点就会偏

---

11. hero测发射，为防止yaw移动方法

- 关闭orientation_controller，这样云台就是用底盘的位置数据来移动的，就是如果把底盘架起来，推云台的遥杆然后松开，云台会回到原来的位置，因为底盘没有动，
- 如果开启orientation_controller，那云台就是用imu的数据的，推摇杆之后，他会停在那个位置，然后让底盘follow过去
- 所以测发射的时候，把orientation_controller关了，然后把底盘架起来，他的yaw就肯定不会动，因为底盘不会动

---

12. 英雄imu一定要校准，但是步兵这些不用，因为英雄对这些东西的精度要求更高

---

13. 记住一定要确定校准成功，**终端显示校准成功也要看确保真的成功**；拨盘校准的时候放一颗弹丸就行，防止他是因为卡住弹丸而不是卡到机械限位停止反转

---

14. 左推云台遥杆然后松开，发现底盘一直缓慢follow

- 看yaw图像，松开遥杆后发现yaw的位置一直在类似正弦型的波动，猜测dbus有问题
- 查看dbus_data

15. 给电机发送指令后，电机正常运行一会后不受控制乱转

- eg：给拨盘发1hz，正常转一会后，乱转
- **cause**：电机id太靠后，导致丢包严重
- **solution**：将电机id改前

16. 代码中使用以下这句

```c++
tf_buffer_.transform(pos_yaw_.point, pos_odom_.point, "odom");
```

build 报错：

```
CMakeFiles/tf2_test_tf2_point.dir/src/tf2_test_tf2_point.cpp.o: In function `geometry_msgs::PointStamped_<std::allocator<void> >& tf2_ros::BufferInterface::transform<geometry_msgs::PointStamped_<std::allocator<void> > >(geometry_msgs::PointStamped_<std::allocator<void> > const&, geometry_msgs::PointStamped_<std::allocator<void> >&, std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > const&, ros::Duration) const':
tf2_test_tf2_point.cpp:(.text._ZNK7tf2_ros15BufferInterface9transformIN13geometry_msgs13PointStamped_ISaIvEEEEERT_RKS6_S7_RKNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEN3ros8DurationE[_ZNK7tf2_ros15BufferInterface9transformIN13geometry_msgs13PointStamped_ISaIvEEEEERT_RKS6_S7_RKNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEN3ros8DurationE]+0x69): undefined reference to `ros::Time const& tf2::getTimestamp<geometry_msgs::PointStamped_<std::allocator<void> > >(geometry_msgs::PointStamped_<std::allocator<void> > const&)'
tf2_test_tf2_point.cpp:(.text._ZNK7tf2_ros15BufferInterface9transformIN13geometry_msgs13PointStamped_ISaIvEEEEERT_RKS6_S7_RKNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEN3ros8DurationE[_ZNK7tf2_ros15BufferInterface9transformIN13geometry_msgs13PointStamped_ISaIvEEEEERT_RKS6_S7_RKNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEN3ros8DurationE]+0x7b): undefined reference to `std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > const& tf2::getFrameId<geometry_msgs::PointStamped_<std::allocator<void> > >(geometry_msgs::PointStamped_<std::allocator<void> > const&)'
tf2_test_tf2_point.cpp:(.text._ZNK7tf2_ros15BufferInterface9transformIN13geometry_msgs13PointStamped_ISaIvEEEEERT_RKS6_S7_RKNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEN3ros8DurationE[_ZNK7tf2_ros15BufferInterface9transformIN13geometry_msgs13PointStamped_ISaIvEEEEERT_RKS6_S7_RKNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEN3ros8DurationE]+0xc8): undefined reference to `void tf2::doTransform<geometry_msgs::PointStamped_<std::allocator<void> > >(geometry_msgs::PointStamped_<std::allocator<void> > const&, geometry_msgs::PointStamped_<std::allocator<void> >&, geometry_msgs::TransformStamped_<std::allocator<void> > const&)'
collect2: error: ld returned 1 exit status
tf2_test/CMakeFiles/tf2_test_tf2_point.dir/build.make:120: recipe for target 'tf2_test/tf2_test_tf2_point' failed
make[2]: *** [tf2_test/tf2_test_tf2_point] Error 1
CMakeFiles/Makefile2:1340: recipe for target 'tf2_test/CMakeFiles/tf2_test_tf2_point.dir/all' failed
make[1]: *** [tf2_test/CMakeFiles/tf2_test_tf2_point.dir/all] Error 2
Makefile:138: recipe for target 'all' failed
make: *** [all] Error 2
Invoking "make -j4 -l4" failed
```

- cause：缺库，没有包含头文件<tf2_geometry_msgs/tf2_geometry_msgs.h>
- solution：

```
#include <tf2_geometry_msgs/tf2_geometry_msgs.h>
```

17. ubuntu20.04打开系统监视器

```
gnome-system-monitor 
```

18. 更换实时性内核后，无法更新nvidia驱动

- cause：实时性内核无法安装nvidia驱动，必须换回标准linux内核后，才能安装，并且推荐在系统自带的Software&Update中安装

19. clion中.py文件中，import rospy报错

- cause：没有导入python解释器
- solution：

pycharm左上角，依次点击 File->settings->Project->Project interpreter
在顶部Python Interpreter：Python 2.7 /usr/bin/python右侧点击 [设置] 按钮，选择show all
点击上侧边栏最后一个按钮：Interpreter Paths
在弹出的界面中，选择右侧的加号，复制ros中的Python路径

20. 动yaw时，pitch有一个类似正弦的setpoint

**cause**：

- imu实际的位置与程序认为的位置相差过大
- base_link与odom不是水平的，动yaw时会给pitch一个补偿，让他保持水平

**solution**：

- 保证imu的安装是正的
- 不加载orientation_controller（对实际其实影响不大，因为开了orientation controller那么base_link跟odom就肯定不会水平，但是实际表现没有什么影响，只有在测重复度时可能会有影响，所以测试时建议不加载）

21. 进入track后，摇杆不能操控云台，但是云台没有移动

**cause**：没有解算出来，可能是射速上限没有设置对

22. 进入track并且瞄准后，不能发射

**cause**：没有解算出来

**solution**：将云台移动到较偏的位置，然后再开摩擦轮瞄




