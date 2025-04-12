

> tf2展示了机器人各部件的相对坐标系及转换。


# 入门

> https://wiki.ros.org/tf2/Tutorials/Introduction%20to%20tf2

## 小海龟

> 第二只小海龟将会跟随你操纵的小海龟

```
sudo apt-get install ros-$ROS_DISTRO-turtle-tf2 ros-$ROS_DISTRO-tf2-tools ros-$ROS_DISTRO-tf
```

```
$ roslaunch turtle_tf2 turtle_tf2_demo.launch
```

![turtle_tf_start.png](https://wiki.ros.org/tf2/Tutorials/Introduction%20to%20tf2?action=AttachFile&do=get&target=turtle_tf_start.png)

$$有问题：$$

> 你可以依次尝试执行以下命令：

**No module named yaml**

```c
sudo apt-get install python-yaml //不是python3-yaml
```

**No module named rospkg**

> ros已经舍弃了python和python2，故使用rospkg文件将会报错

```bash
sudo apt install python-is-python3
```

**其他**

```bash
sudo apt-get install python3-catkin-pkg
```







## 观察tf树

> ```rosrun tf2_tools view_frames.py
> rosrun tf2_tools view_frames.py
> ```
>
> ```
> evince frames.pdf
> ```

![view_frames_2.png](https://wiki.ros.org/tf2/Tutorials/Introduction%20to%20tf2?action=AttachFile&do=get&target=view_frames_2.png)



## TF帧之间的信息

> 展示两个帧之间的坐标变换

```
rosrun tf tf_echo [reference_frame] [target_frame]
```

例：rosrun tf tf_echo turtle1 turtle2



> ```
> [ INFO] 1253585683.529245000: Started node [/tf2_echo_1253585683508144000], pid [24418], bound on [aqy], xmlrpc port [41125], tcpros port [57369], logging to [~/ros/ros/log/tf2_echo_1253585683508144000_24418.log], using [real] time
> Exception thrown:Frame id /turtle1 does not exist! When trying to transform between /turtle2 and /turtle1.
> The current list of frames is:
> 
> Success at 1253585684.557003974
> [0.000000 0.000000 0.140754 0.990045] Euler(0.282446 -0.000000 0.000000)
> Translation: [-0.000036 -0.000010 0.000000]
> Success at 1253585685.544698953
> [0.000000 0.000000 0.140754 0.990045] Euler(0.282446 -0.000000 0.000000)
> Translation: [-0.000036 -0.000010 0.000000]
> Success at 1253585686.557049989
> [0.000000 0.000000 0.140754 0.990045] Euler(0.282446 -0.000000 0.000000)
> Translation: [-0.000036 -0.000010 0.000000]
> Success at 1253585687.552628993
> [0.000000 0.000000 0.140754 0.990045] Euler(0.282446 -0.000000 0.000000)
> Translation: [-0.000036 -0.000010 0.000000]
> Success at 1253585688.553683042
> [0.000000 0.000000 0.140754 0.990045] Euler(0.282446 -0.000000 0.000000)
> Translation: [-0.000036 -0.000010 0.000000]
> Success at 1253585688.910640001
> [0.000000 0.000000 0.140754 0.990045] Euler(0.282446 -0.000000 0.000000)
> Translation: [-0.000036 -0.000010 0.000000]
> ```





## RVIZ&&TF

> 使用rviz工具观察tf配置

```bash
 rosrun rviz rviz -d `rospack find turtle_tf2`/rviz/turtle_rviz.rviz
```

![attachment:turtle_tf_rviz.png](https://wiki.ros.org/tf2/Tutorials/Introduction%20to%20tf2?action=AttachFile&do=get&target=turtle_tf_rviz.png)







# 进阶

> https://wiki.ros.org/tf2/Tutorials/Writing%20a%20tf2%20broadcaster%20%28C%2B%2B%29



## 创建TF包

> 现在我们创建一个tf包，它包含以下依赖：tf2,tf2_ros,roscpp,rospy,turlesim

```c
catkin_create_pkg learning_tf2 tf2 tf2_ros roscpp rospy turtlesim
```



## 广播坐标系

> 我们建立一个cpp文件来完成tf坐标系的广播。
>
> **`src/turtle_tf2_broadcaster.cpp`**. 

```c
//tf2包提供了TransformBroadcaster的实现，以帮助简化发布转换的任务。要使用TransformBroadcaster，我们需要包括TransformBroadcaster.h头文件。 
   1 #include <ros/ros.h>
   2 #include <tf2/LinearMath/Quaternion.h>
   3 #include <tf2_ros/transform_broadcaster.h>
   4 #include <geometry_msgs/TransformStamped.h>
   5 #include <turtlesim/Pose.h>
   6 
   7 std::string turtle_name;
   8 
   9 void poseCallback(const turtlesim::PoseConstPtr& msg){
       
       //建立一个广播者和它所广播的数据类型
  10   static tf2_ros::TransformBroadcaster br;
  11   geometry_msgs::TransformStamped transformStamped;
  12   
      //设置时间戳为time
  13   transformStamped.header.stamp = ros::Time::now();
       //设置父框架的名称
  14   transformStamped.header.frame_id = "world";
       //设置子框架的名称
  15   transformStamped.child_frame_id = turtle_name;
       
       //海龟的姿态被复制进3D变换
  16   transformStamped.transform.translation.x = msg->x;
  17   transformStamped.transform.translation.y = msg->y;
  18   transformStamped.transform.translation.z = 0.0;
  19   tf2::Quaternion q;
  20   q.setRPY(0, 0, msg->theta);
  21   transformStamped.transform.rotation.x = q.x();
  22   transformStamped.transform.rotation.y = q.y();
  23   transformStamped.transform.rotation.z = q.z();
  24   transformStamped.transform.rotation.w = q.w();
  25 
      //这才是真正的工作所在。使用TransformBroadcaster发送转换只需要传入转换本身。 
  26   br.sendTransform(transformStamped);
      //注意：sendTransform和StampedTransform的父级和子级顺序相反。 
  27 }
  28 
  29 int main(int argc, char** argv){
  30   ros::init(argc, argv, "my_tf2_broadcaster");
  31 
  32   ros::NodeHandle private_node("~");
  33   if (! private_node.hasParam("turtle"))
  34   {
  35     if (argc != 2){ROS_ERROR("need turtle name as argument"); return -1;};
  36     turtle_name = argv[1];
  37   }
  38   else
  39   {
  40     private_node.getParam("turtle", turtle_name);
  41   }
  42     
  43   ros::NodeHandle node;
  44   ros::Subscriber sub = node.subscribe(turtle_name+"/pose", 10, &poseCallback);
  45 
  46   ros::spin();
  47   return 0;
  48 };
```



## 编辑

### CMAKELIST.list

```cmake
add_executable(turtle_tf2_broadcaster src/turtle_tf2_broadcaster.cpp)
target_link_libraries(turtle_tf2_broadcaster
 ${catkin_LIBRARIES}
)
```



### LAUNCH

```c
  <launch>
     <!-- Turtlesim Node-->
    <node pkg="turtlesim" type="turtlesim_node" name="sim"/>

    <node pkg="turtlesim" type="turtle_teleop_key" name="teleop" output="screen"/>
    <!-- Axes -->
    <param name="scale_linear" value="2" type="double"/>
    <param name="scale_angular" value="2" type="double"/>

    <node pkg="learning_tf2" type="turtle_tf2_broadcaster"
          args="/turtle1" name="turtle1_tf2_broadcaster" />
    <node pkg="learning_tf2" type="turtle_tf2_broadcaster"
          args="/turtle2" name="turtle2_tf2_broadcaster" />

  </launch>
```



### 将文件标记为安装

```c
## Mark other files for installation (e.g. launch and bag files, etc.)
install(FILES
 start_demo.launch
 # myfile2
 DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}
)
```



## 运行

```c
roslaunch learning_tf2 start_demo.launch
```



> 现在，使用tf_echo工具检查海龟姿势是否实际被广播到tf2：

```c
 rosrun tf tf_echo /world /turtle1
```

