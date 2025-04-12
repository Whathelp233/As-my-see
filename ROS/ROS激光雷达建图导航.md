# ROS激光雷达建图导航

> [项目地址](https://www.theconstructsim.com/ros-projects-exploring-ros-using-2-wheeled-robot-part-1/)
>
> [bilibili视频](https://www.bilibili.com/video/BV1aK4y147Uy?p=3&vd_source=782af047fbca87ac3084937682017138)



## 新建一个雷达link

> 该link描述一个激光雷达

> ```xml
>  <link name="sensor_laser">
>     <inertial>
>       <origin xyz="0 0 0" rpy="0 0 0" />
>       <mass value="1" />
>       <!-- RANDOM INERTIA BELOW -->
>       <inertia ixx="0.02" ixy="0" ixz="0" iyy="0.02" iyz="0" izz="0.02"/>
>     </inertial>
> 
>     <visual>
>       <origin xyz="0 0 0" rpy="0 0 0" />
>       <geometry>
>         <cylinder radius="0.05" length="0.1"/>
>       </geometry>
>       <material name="white" />
>     </visual>
> 
>     <collision>
>       <origin xyz="0 0 0" rpy="0 0 0"/>
>       <geometry>
>         <cylinder radius="0.05" length="0.1"/>
>       </geometry>
>     </collision>
>   </link>
> 
>   <joint name="joint_sensor_laser" type="fixed">
>     <origin xyz="0.15 0 0.05" rpy="0 0 0"/>
>     <parent link="link_chassis"/>
>     <child link="sensor_laser"/>
>   </joint>
> ```



现在加载一个雷达插件让这个link被仿真为激光雷达

```xml
<gazebo reference="sensor_laser">
    <sensor type="ray" name="head_hokuyo_sensor">
      <pose>0 0 0 0 0 0</pose>
      <visualize>false</visualize>
      <update_rate>20</update_rate>
      <ray>
        <scan>
          <horizontal>
            <samples>720</samples>
            <resolution>1</resolution>
            <min_angle>-1.570796</min_angle>
            <max_angle>1.570796</max_angle>
          </horizontal>
        </scan>
        <range>
          <min>0.10</min>
          <max>10.0</max>
          <resolution>0.01</resolution>
        </range>
        <noise>
          <type>gaussian</type>
          <mean>0.0</mean>
          <stddev>0.01</stddev>
        </noise>
      </ray>
      <plugin name="gazebo_ros_head_hokuyo_controller" filename="libgazebo_ros_laser.so">
        <topicName>/m2wr/laser/scan</topicName>
        <frameName>sensor_laser</frameName>
      </plugin>
    </sensor>
  </gazebo>
```

```
update_rate表示更新频率，samples表示激光雷达采样点数，resolution表示分辨率，min_angle和max_angle表示扫描范围，min和max表示距离范围，noise表示噪声参数。plugin标签中的filename属性指定了激光雷达插件的共享库文件。

frameName是被申明为激光雷达的link
```

启动launch，观察相应话题数据

![https://www.theconstructsim.com/wp-content/uploads/2018/01/l_data.png](./images/ROS%E6%BF%80%E5%85%89%E9%9B%B7%E8%BE%BE%E5%BB%BA%E5%9B%BE%E5%AF%BC%E8%88%AA/l_data.png)



## 过滤激光雷达数据

在包中，程序读取激光雷达数据并进行处理

现在通过代码获取雷达每隔一定距离的扫描最小值

```python
#python举例
def clbk_laser(msg):
    # 720/5 = 144
    regions = [ 
      min(min(msg.ranges[0:143]), 10), #考虑到有无穷大值，所以需要对无穷大值进行过滤
      min(min(msg.ranges[144:287]), 10),
      min(min(msg.ranges[288:431]), 10),
      min(min(msg.ranges[432:575]), 10),
     min( min(msg.ranges[576:713]), 10),
     ]
     rospy.loginfo(regions)
```



## 实现逻辑避障

将扫描获取的数据进行分析，得到要如何运动以规避障碍

![https://www.theconstructsim.com/wp-content/uploads/2018/01/53.png](./images/ROS%E6%BF%80%E5%85%89%E9%9B%B7%E8%BE%BE%E5%BB%BA%E5%9B%BE%E5%AF%BC%E8%88%AA/53.png)

```python
# 以python为例
def take_action(regions):
    msg = Twist()
    linear_x = 0
    angular_z = 0
    
    state_description = ''
    
    #定义所有的运动状态，当距离满足某个状态时就触发
    if regions['front'] > 1 and regions['fleft'] > 1 and regions['fright'] > 1:
        state_description = 'case 1 - nothing'
        linear_x = 0.6
        angular_z = 0
    elif regions['front'] < 1 and regions['fleft'] > 1 and regions['fright'] > 1:
        state_description = 'case 2 - front'
        linear_x = 0
        angular_z = 0.3
    elif regions['front'] > 1 and regions['fleft'] > 1 and regions['fright'] < 1:
        state_description = 'case 3 - fright'
        linear_x = 0
        angular_z = 0.3
    elif regions['front'] > 1 and regions['fleft'] < 1 and regions['fright'] > 1:
        state_description = 'case 4 - fleft'
        linear_x = 0
        angular_z = -0.3
    elif regions['front'] < 1 and regions['fleft'] > 1 and regions['fright'] < 1:
        state_description = 'case 5 - front and fright'
        linear_x = 0
        angular_z = 0.3
    elif regions['front'] < 1 and regions['fleft'] < 1 and regions['fright'] > 1:
        state_description = 'case 6 - front and fleft'
        linear_x = 0
        angular_z = -0.3
    elif regions['front'] < 1 and regions['fleft'] < 1 and regions['fright'] < 1:
        state_description = 'case 7 - front and fleft and fright'
        linear_x = 0
        angular_z = 0.3
    elif regions['front'] > 1 and regions['fleft'] < 1 and regions['fright'] < 1:
        state_description = 'case 8 - fleft and fright'
        linear_x = 0.3
        angular_z = 0
    else:
        state_description = 'unknown case'
        rospy.loginfo(regions)

    rospy.loginfo(state_description)
    msg.linear.x = -linear_x
    msg.angular.z = angular_z
    pub.publish(msg)
```



## 里程计和全局定位

> 在这部分中，我们将实现一个简单的导航算法，将机器人从任意点移动到所需的点。我们将使用状态机的概念来实现导航逻辑。在状态机中，有有限数量的状态表示系统的当前状况（或行为）

现在定义三个状态：

- Fix Heading

​	表示机器人航向与所需航向相差超过阈值时的状态（由代码中的yaw_precision_表示）	

- Go Straight

​	表示机器人具有正确的航向，但距离所需点的距离大于某个阈值时的状态（由代码中的dist_precision_表示）

- Done

​	表示机器人方向正确并到达目的地时的状态。

![https://www.theconstructsim.com/wp-content/uploads/2018/01/60.png](./images/ROS%E6%BF%80%E5%85%89%E9%9B%B7%E8%BE%BE%E5%BB%BA%E5%9B%BE%E5%AF%BC%E8%88%AA/60.png)



### 发布里程计

在ROS中，发布里程计需要将当前机器人的位置信息发布到ROS系统中。可以通过以下步骤实现：

- 创建一个ros::Publisher对象并设置Topic名称和消息类型。

```
ros::Publisher odom_pub = nh.advertise<nav_msgs::Odometry>("odom", 50);
```

- 创建nav_msgs/Odometry消息，并填充其各个字段。

```
cpp
nav_msgs::Odometry odom;
odom.header.stamp = current_time;
odom.header.frame_id = "odom";
odom.child_frame_id = "base_link";
odom.pose.pose.position.x = robot_x;
odom.pose.pose.position.y = robot_y;
odom.pose.pose.position.z = 0.0;
odom.pose.pose.orientation = tf::createQuaternionMsgFromYaw(robot_yaw);
odom.twist.twist.linear.x = linear_velocity;
odom.twist.twist.angular.z = angular_velocity;
```

- 调用发布者的publish()方法将消息发布到Topic上。

```
odom_pub.publish(odom);
```

其中，robot_x, robot_y, robot_yaw, linear_velocity和angular_velocity是机器人的位置和速度信息。

注意：里程计的发布频率较高，需要在一个while循环中不断地发布消息，同时需要保证循环周期的稳定性。



> odom数据类型：**nav_msgs/Odometry**
>
> ```css
> Header header
> string child_frame_id
> geometry_msgs/PoseWithCovariance pose
> geometry_msgs/TwistWithCovariance twist
> ```
>
> `header`包含了时间戳和坐标系等信息，`child_frame_id`为机器人的坐标系，`pose`包含了机器人的位姿信息，包括位置和方向，以及协方差矩阵；`twist`包含了机器人的线速度和角速度信息，以及协方差矩阵



> 姿态函数
>
> 在ROS的tf库中，可以使用以下函数将姿态转换为四元数或旋转矩阵，从而填入odom的位姿中：
>
> ```c++
> tf::createQuaternionMsgFromYaw(yaw)：将yaw角度转换为四元数。
> tf::createQuaternionFromRPY(roll, pitch, yaw)：将欧拉角转换为四元数。
> tf::createMatrix3FromQuaternion(quat)：将四元数转换为旋转矩阵。
> ```
>
> 其中，yaw表示绕z轴的旋转角度，roll、pitch、yaw表示分别绕x、y、z轴的旋转角度，quat表示四元数。





### 实现状态机

- 回调函数

接收里程计数据并提取位置和偏航信息。里程数据以四元数编码方向信息。为了获得偏航，将四元数转换为欧拉角

```python
    # yaw
    quaternion = (
        msg.pose.pose.orientation.x,
        msg.pose.pose.orientation.y,
        msg.pose.pose.orientation.z,
        msg.pose.pose.orientation.w)
    euler = transformations.euler_from_quaternion(quaternion)
    yaw_ = euler[2]
```

- 状态更新

此函数更改存储机器人状态信息的全局状态变量的值。

- 校准航向角

当机器人处于状态0（固定航向）时，执行此功能。首先，检查机器人的当前航向和所需航向。如果航向差大于阈值，机器人将被命令转向其位置。

- 向前直行

当机器人处于状态1（直行）时，执行此功能。该状态发生在机器人修正偏航误差后。在此状态下，将机器人当前位置和期望位置之间的距离与阈值进行比较。如果机器人进一步远离所需位置，则命令其向前移动。如果当前位置更接近所需位置，则再次检查偏航是否存在错误，如果偏航与所需偏航值显著不同，则机器人进入状态0。

- 运动完成

最终机器人实现了正确的航向和正确的位置。一旦处于这种状态，机器人就会停止。





## 沿墙行走

> 在这一部分中，我们将编写一个算法，让机器人沿着墙走。我们可以从上一部分继续，也可以从新项目开始。









# 实物雷达



## YDILAR

> https://yahboom.com/study/YDLIDAR-X3





## Gmapping

> 建图软件
>
> 博客：
>
> https://blog.csdn.net/hongliang2009/article/details/77916000
>
> [有用的](https://blog.csdn.net/VampireWolf/article/details/90042517?utm_medium=distribute.pc_relevant.none-task-blog-2~default~baidujs_baidulandingword~default-0-90042517-blog-77916000.pc_relevant_3mothn_strategy_recovery&spm=1001.2101.3001.4242.1&utm_relevant_index=3)

### 有里程计

> [参考](https://blog.csdn.net/EAIBOT/article/details/51219032?locationNum=1&fps=1&utm_medium=distribute.pc_relevant.none-task-blog-2~default~baidujs_baidulandingword~default-5-51219032-blog-77916000.pc_relevant_3mothn_strategy_and_data_recovery&spm=1001.2101.3001.4242.4&utm_relevant_index=8)

- 配置好雷达的驱动后，安装slam包

```bash
git clone https://github.com/ros-perception/slam_gmapping`
git clone https://github.com/ros-perception/openslam_gmapping
```

- 修改参数

在官方提供的sdk中为3600比默认值2048大．所以对应的到头文件中将值修改为：4096． 
`~/catkin_rikirobot/src/slam_gmapping/openslam_gmapping/include/gmapping/scanmatcher/scanmatcher.h`

```
//#define LASER_MAXBEAMS 2048
#define LASER_MAXBEAMS 4096
```

- 新增lanuch文件

```xml
<launch>
  <arg name="scan_topic"  default="scan" />
  <arg name="base_frame"  default="base_footprint"/>
  <arg name="odom_frame"  default="odom"/>
    
  <include file="$(find lslidar_n301_decoder)/launch/lslidar_n301.launch"/>
  <node pkg="tf" type="static_transform_publisher" name="link1_broadcaster" args="0 0 0 0 0 0 base_link lslidar 100" /> <!--change laser -->
    
  <node pkg="gmapping" type="slam_gmapping" name="slam_gmapping" output="screen">
    <param name="base_frame" value="$(arg base_frame)"/>
    <param name="odom_frame" value="$(arg odom_frame)"/>
    <param name="map_update_interval" value="0.01"/>
    <param name="maxUrange" value="4.0"/>
    <param name="maxRange" value="5.0"/>
    <param name="sigma" value="0.05"/>
    <param name="kernelSize" value="3"/>
    <param name="lstep" value="0.05"/>
    <param name="astep" value="0.05"/>
    <param name="iterations" value="5"/>
    <param name="lsigma" value="0.075"/>
    <param name="ogain" value="3.0"/>
    <param name="lskip" value="0"/>
    <param name="minimumScore" value="30"/>
    <param name="srr" value="0.01"/>
    <param name="srt" value="0.02"/>
    <param name="str" value="0.01"/>
    <param name="stt" value="0.02"/>
    <param name="linearUpdate" value="0.05"/>
    <param name="angularUpdate" value="0.0436"/>
    <param name="temporalUpdate" value="-1.0"/>
    <param name="resampleThreshold" value="0.5"/>
    <param name="particles" value="8"/>
  <!--
    <param name="xmin" value="-50.0"/>
    <param name="ymin" value="-50.0"/>
    <param name="xmax" value="50.0"/>
    <param name="ymax" value="50.0"/>
  make the starting size small for the benefit of the Android client's memory...
  -->
    <param name="xmin" value="-1.0"/>
    <param name="ymin" value="-1.0"/>
    <param name="xmax" value="1.0"/>
    <param name="ymax" value="1.0"/>

    <param name="delta" value="0.05"/>
    <param name="llsamplerange" value="0.01"/>
    <param name="llsamplestep" value="0.01"/>
    <param name="lasamplerange" value="0.005"/>
    <param name="lasamplestep" value="0.005"/>
    <remap from="scan" to="$(arg scan_topic)"/>
  </node>
</launch>
```

- 执行

```bash
roscore
roslaunch rikirobot stm32bringup.launch
roslaunch lslidar_n301_decoder gmapping.launch
rosrun rviz rviz
```



#### `static_transform_publisher`

> 静态发布器，`static_transform_publisher`主要用于发布静态的坐标系之间的变换，而`robot_state_publisher`则用于发布机器人的动态运动信息

假设我们有一个机器人系统，包括机器人底座、激光雷达和相机，它们的坐标系关系如下：

- 机器人底座坐标系：base_link
- 激光雷达坐标系：laser_link
- 相机坐标系：camera_link

假设我们需要将激光雷达坐标系与机器人底座坐标系之间的静态变换发布出去，可以使用static_transform_publisher来实现。假设激光雷达在机器人底座的前方0.5米处，离机器人底座中心轴线偏离20度，可以使用如下命令发布变换：

```
rosrun tf static_transform_publisher 0.5 0 0 0 0 0.35 base_link laser_link 100
```

这里的参数含义分别是：

- 0.5 0 0：激光雷达相对于机器人底座在X、Y、Z三个方向上的位移，单位为米。
- 0 0 0.35：激光雷达相对于机器人底座的旋转角度，分别绕X、Y、Z三个轴旋转的角度，单位为弧度。
- base_link：父坐标系名称，即机器人底座坐标系的名称。
- laser_link：子坐标系名称，即激光雷达坐标系的名称。
- 100：发布频率，单位为Hz。

这样就可以在ROS系统中发布一个名为"/base_link"到"/laser_link"的坐标系变换了，其他节点可以通过tf库订阅该变换，并在不同坐标系下进行数据转换和计算。



### 无里程计

> https://www.codenong.com/cs105662151/

无里程计要使用gmapping和激光雷达进行建图，可以按照以下步骤进行：

1. 安装ROS和gmapping包：首先需要安装ROS和gmapping包，可以使用命令

   `sudo apt-get install ros-<distro>-gmapping`

2. 下载无里程计工具包

​	 https://github.com/ccny-ros-pkg/scan_tools.git

3. 修改demo_gmapping.launch

```xml
  #### set up data playback from bag #############################

  <param name="/use_sim_time" value="false"/>

  <!--node pkg="rosbag" type="play" name="play" 
    args="$(find laser_scan_matcher)/demo/demo.bag --delay=5 --clock"/-->
    
  #### start your lidar node
   <node name="ydlidar_node"  pkg="ydlidar_ros"  type="ydlidar_node" output="screen">
    <param name="port"         type="string" value="/dev/ttyUSB0"/>  
    <param name="baudrate"     type="int"    value="115200"/>
    <param name="frame_id"     type="string" value="laser_frame"/>
  </node>

  #### publish an example base_link -> laser transform ###########

  <node pkg="tf" type="static_transform_publisher" name="base_link_to_laser" 
    args="0.0 0.0 0.0 0.0 0.0 0.0 /base_link /laser_frame 40" />

  #### start rviz ################################################

  <node pkg="rviz" type="rviz" name="rviz" 
    args="-d $(find laser_scan_matcher)/demo/demo_gmapping.rviz"/>

  #### start the laser scan_matcher ##############################

  <node pkg="laser_scan_matcher" type="laser_scan_matcher_node" 
    name="laser_scan_matcher_node" output="screen">

    <param name="fixed_frame" value = "odom"/>
    <param name="max_iterations" value="10"/>
    
    <param name="base_frame" value="base_link"/>
    <param name="use_odom" value="false" />
    <param name="publy_pose" value = "true" />
    <param name="publy_tf" value="true" />
  </node>
```

4. 现在可以运行launch了

5. 保存地图：当地图建立完成后，可以使用`rosrun map_server map_saver -f <mapname>`来保存地图。其中`<mapname>`是地图的文件名，例如`map`。



#### `laser_scan_matcher`

对没有里程计的设备使用，生成仿真里程计。包中提供了一个节点，它可以接收激光雷达数据并使用扫描匹配算法将机器人在地图中的位置进行估计。该软件包还提供了一些参数配置选项，可以用于调整扫描匹配算法的性能和精度

> 这个包发布里程计，也就是底盘base_link到odom的位置姿态，同时静态发布器static_transform_publisher发布雷达坐标系到base_link的变换。
>
> gmapping通过参数：
>
> ```xml
> <arg name="scan_topic"  default="scan" />
> <arg name="base_frame"  default="base_footprint"/>
> <arg name="odom_frame"  default="odom"/>
> ```
>
> 在/tf上获取机器人底盘坐标系(默认base_link)和世界坐标系(默认odom)关系，并利用雷达话题scan_topic获取点云，在代码中会获取坐标系转换：
>
> ```c++
> //在laserCallback()函数
>  tf::Transform laser_to_map = tf::Transform(tf::createQuaternionFromRPY(0, 0, mpose.theta), tf::Vector3(mpose.x, mpose.y, 0.0)).inverse();
>  tf::Transform odom_to_laser = tf::Transform(tf::createQuaternionFromRPY(0, 0, odom_pose.theta), tf::Vector3(odom_pose.x, odom_pose.y, 0.0));
> ```
>
> 

```c
sudo apt-get install ros-noetic-laser-scan-matcher
```

```
roslaunch laser_scan_matcher laser_scan_matcher.launch
```

```xml
 <node pkg="laser_scan_matcher" type="laser_scan_matcher_node"
 name="laser_scan_matcher_node" output="screen">
 <param name="fixed_frame" value="odom"/>
 <param name="max_iterations" value="10"/>
```



## Cartographer

> 和gmapping类似，可以边建图边定位，同时性能消耗较小
>
> [github](https://github.com/cartographer-project/cartographer_ros)
>
> [安装](https://zhuanlan.zhihu.com/p/335778454) [2](https://blog.csdn.net/qq_46274948/article/details/126160650?utm_medium=distribute.pc_relevant.none-task-blog-2~default~baidujs_baidulandingword~default-0-126160650-blog-113117562.235^v38^pc_relevant_sort_base2&spm=1001.2101.3001.4242.1&utm_relevant_index=3)
>
> [使用和介绍](https://zhuanlan.zhihu.com/p/116455345)
>
> [参数配置](https://blog.csdn.net/qleelq/article/details/112237663)

安装方式有**官网整包**下载和**分包下载**

### 官网整包

1. 安装 wstool下载工具、rosdep和ninja编译工具（ninja是一个新型的编译小工具，用来替换复杂的make，从而实现快速编译）

```bash
#还需要安装rosdep 或rosdepc
#wget http://fishros.com/install -O fishros && . fishros
sudo apt-get install -y python3-wstool ninja-build
```

2. 建立一个wstool下载+ROS基本编译的二合一环境

```bash
mkdir catkin_ws
cd catkin_ws
wstool init src
wstool merge -t src https://raw.githubusercontent.com/googlecartographer/cartographer_ros/master/cartographer_ros.rosinstall

#执行下载
wstool update -t src
```

这是 wstool 命令生成 .rosinstall 的文件里面的内容，可以看到设置了**cartographer、cartographer-ros**下载链接。

3.安装proto3

Protocol Buffers(简称Protobuf) ，是Google出品的序列化框架，与开发语言无关，和平台无关，具有良好的可扩展性。Protobuf和所有的序列化框架一样，都可以用于数据存储、通讯协议。

```bash
src/cartographer/scripts/install_proto3.sh
src/cartographer/scripts/install_abseil.sh
```

如果出现

```cpp
cd /usr/local/stow
sudo stow absl
sudo: stow：找不到命令
```

则自行安装stow，然后执行以下操作：

```cpp
sudo apt install stow
cd /usr/local/stow/
sudo stow absl
```

此外其实除了Protobuf我们还可以配置其他依赖，这些脚本都在/scripts目录下

4. rosdepc

安装起来很简单，一句话的事情，后面小鱼会让其变得更简单。

```text
sudo pip install rosdepc
```

如果显示没有pip可以试试pip3。

```text
sudo pip3 install rosdepc
```

如果pip3还没有

```text
sudo apt-get install python3-pip 
sudo pip install rosdepc
```

**使用**

```text
sudo rosdepc init
rosdepc update
rosdepc install -r --from-paths src --ignore-src --rosdistro $ROS_DISTRO -y 
```

5. 编译

```bash
catkin_make_isolated --install --use-ninja
```



### 分包下载

**1.eigen**

**Eigen是高级 C ++ 模板标头库，用于线性代数，矩阵和矢量运算，几何变换，数值求解器和相关算法。自3.1.1版以来，Eigen是根据Mozilla Public License 2.0许可的开源软件。早期版本是根据GNU较宽松通用公共许可证授权的。**

注意警告：cartographer对eigen，ceres，protobuf有严格的版本限制，版本必须严格！！！

```text
#选择版本3.2.9
git clone  https://gitlab.com/libeigen/eigen.git
mkdir build
cd build
cmake ..
sudo make install
```


安装完成

2.ceres

Ceres solver 是谷歌开发的一款用于非线性优化的库，在谷歌的开源激光雷达slam项目cartographer中被大量使用。

**注意：**ceres版本必须是1.13.0,其它版本与eigen3.2.9不匹配

```text
#选择版本1.13.0
git clone https://github.com/ceres-solver/ceres-solver.git
mkdir build
cd build
cmake ..
make -j8
sudo make install
```

编译过程中如果出现这个编译问题：

**Failed to find glog**

```c
-- Failed to find installed glog CMake configuration, searching for glog build directories exported with CMake.

-- Failed to find an installed/exported CMake configuration for glog, will perform search for installed glog components.

-- Failed to find glog - Could not find glog include directory, set GLOG_INCLUDE_DIR to directory containing glog/logging.h

这个原因是缺失**glog**库(**glog 是一个 C++ 日志库，它提供 C++ 流式风格的 API。在安装 glog 之前需要先安装 gflags，这样 glog 就可以使用 gflags 去解析命令行参数**)，我们可以用apt-get install安装，也可以下载源码进行编译安装.
```

apt-get install安装:

```text
sudo apt-get install libgoogle-glog-dev
```



下载源码进行编译安装:

```text
git clone https://github.com/google/glog.git
cd glog
mkdir build
cmake ..
make
sudo make install
```



再重新进行cere编译安装，又通过一关

![img](./images/ROS%E6%BF%80%E5%85%89%E9%9B%B7%E8%BE%BE%E5%BB%BA%E5%9B%BE%E5%AF%BC%E8%88%AA/v2-3ce90f22a9db1a4555c60ce1a8a15d38_720w.webp)



3. protobuf

Protocol Buffers(简称Protobuf) ，是Google出品的序列化框架，与开发语言无关，和平台无关，具有良好的可扩展性。Protobuf和所有的序列化框架一样，都可以用于数据存储、通讯协议。

注意：protobuf安装方式特殊，脚本安装

```text
选择版本3.0.0
git clone https://github.com/protocolbuffers/protobuf.git
./autogen.sh
```

这次也会遇到error问题，

第一个error **48: autoreconf: not found**

是在不同版本的 tslib 下执行 autogen.sh 产生。它们产生的原因一样,是因为没有安装automake 工具, 用下面的命令安装好就可以了。

```text
sudo apt-get install autoconf automake libtool
```

第二个error可能是下载问题，这边会提示你下载失败，你可以选择注释掉，或者使用我提供的第二种编译方法：

```text
#如遇见Error，prot：443,注释autogen.sh脚本34行
./configure
make -j8
sudo make install
sudo ldconfig
#测试一下protobuf
protoc --version
#不出意外将会显示libprotoc 3.0.0
```

第二种编译方法：

上文说到，我们在cartographer/scripts目录下可以找到cartographer依赖文件的下载的脚本，这些的脚本里面还有编译的选项，这时候我们就可以看下install_proto3.sh 这个文件，里面可以看到如下内容：

```text
mkdir build
cd build
cmake -G Ninja \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -Dprotobuf_BUILD_TESTS=OFF \
  ../cmake
ninja
sudo ninja install
```

我们直接复制直接编译即可。

4.abseil

abseil 是 google 开源的 C++通用库，其目标是作为标准库的补充。abseil 不但提供了标准库没有但很常用的功能，也对标准库的一些功能进行了增强设计，使用 abseil 库能使程序性能和开发效率都取得不错的提升。

cartographer对abseil没有版本要求，但是一定要有。

```text
git clone https://github.com/abseil/abseil-cpp.git
mkdir build
cd build
cmake .. -DCMAKE_CXX_STANDARD=11
make -j8
sudo make install
```

不过在后续编译abseil，大家可能会遇到这个问题

```c
CMake Error at CMakeLists.txt:49 (find_package):
By not providing "FindAbseil.cmake" in CMAKE_MODULE_PATH this project has
asked CMake to find a package configuration file provided by "Abseil", but
CMake did not find one.
Could not find a package configuration file provided by "Abseil" with any
of the following names:
AbseilConfig.cmake
abseil-config.cmake
Add the installation prefix of "Abseil" to CMAKE_PREFIX_PATH or set
"Abseil_DIR" to a directory containing one of the above files. If "Abseil"
provides a separate development package or SDK, be sure it has beeninstalled.
```

![img](./images/ROS%E6%BF%80%E5%85%89%E9%9B%B7%E8%BE%BE%E5%BB%BA%E5%9B%BE%E5%AF%BC%E8%88%AA/v2-a3d0eb9566da001293852ad3c1000076_720w.webp)



不过没事，是因为CMakeLists.txt在进行搜寻absil中，定义的名称和你编译abseil名称不同，CMakeLists.txt是大写的，而实际你编译安装后的包名称为小写。



![img](./images/ROS%E6%BF%80%E5%85%89%E9%9B%B7%E8%BE%BE%E5%BB%BA%E5%9B%BE%E5%AF%BC%E8%88%AA/v2-ffd77e4e1da1b4926b5673fad396d971_720w.webp)



修改如上所示：**Abseil** 修改为 **absl**

5.carographer

**注意：**carographer和cartographer _ros版本必须对应

```bash
mkdir cartographer
cd cartographer & mkdir src
cd src


git clone https://github.com/cartographer-project/cartographer.git
git clone https://github.com/cartographer-project/cartographer_ros.git

catkin_make_isolated --install --use-ninja
source install_isolated/setup.bash
```



6. 运行例程

```bash
wget -P ~/Downloads https://storage.googleapis.com/cartographer-public-data/bags/backpack_2d/cartographer_paper_deutsches_museum.bag
roslaunch cartographer_ros demo_backpack_2d.launch bag_filename:=${HOME}/Downloads/cartographer_paper_deutsches_museum.bag
```



### 报错

- jinja2

> ImportError: cannot import name ‘contextfilter‘ from ‘jinja2‘

jinja版本3.00之后，context被替代，降级即可

```bash
pip uninstall jinja2
pip install jinja2==2.11.3
```

- markupsafe

> mportError: cannot import name 'soft_unicode' from 'markupsafe' (/home/yuchen/.local/lib/python3.8/site-packages/markupsafe/__init__.py)

问题和jinja类似，要降级

```bash
pip uninstall markupsafe
pip install markupsafe==2.0.1
```





# SLAM

对比：https://blog.csdn.net/qq_40695642/article/details/128472360?ydreferer=aHR0cHM6Ly93d3cuYmluZy5jb20v



## rtabmap_ros

>   一个融合多种传感器进行定位的包
>
> wiki: http://wiki.ros.org/rtabmap_ros/Tutorials/SetupOnYourRobot
>
> github: https://github.com/introlab/rtabmap_ros





## cartographer

cartographer和gmapping都是SLAM算法的实现，用于构建地图和定位机器人。它们的主要不同在于：

- 算法原理不同：gmapping基于概率滤波器，而cartographer基于优化算法。
- 实现方式不同：gmapping是基于ROS的包，而cartographer是独立的C++库。
- 功能不同：gmapping可以实现实时地图构建和机器人定位，而cartographer还支持多机器人协同构建地图和定位。

另外，还有一些其他的SLAM算法，如Hector和Karto，它们也有各自的优缺点和适用场景。你可以根据你的需求和条件选择合适的算法。





# Move_base

> [github](https://github.com/ros-planning/navigation)
>
> [wiki](https://wiki.ros.org/navfn?distro=fuerte)
>
> [知乎](https://zhuanlan.zhihu.com/p/428332784)



