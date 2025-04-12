# ros_control补充解析



#### controllers

已经定义好的的controllers如下图所示，当然你也可以定义自己的controllers

![clip_image010](https://www.guyuehome.com/Uploads/wp/2017/03/clip_image010_thumb.png)

**effort_controllers**：通过一个期望扭矩/力矩，来控制关节。里面包含了一些接口： ①joint_effort_controller ②joint_position_controller ③joint_velocity_controller

**joint_state_controller**-读取所有关节位置。 ①joint_state_controller

**position_controllers**-一次设置一个或多个关节位置。 ①joint_position_controller ②joint_group_position_controller

**velocity_controllers**-一次设置一个或多个关节速度。 ①joint_velocity_controller ②joint_group_velocity_controller

**joint_trajectory_controllers**-用于为整个轨迹加附加功能。 ①position_controller ②velocity_controller ③effort_controller ④position_velocity_controller ⑤position_velocity_acceleration_controlle



#### 传动（transmissions）

每个关节都需要相应的传动，一般URDF可以直接添加传动。添加的元素一般有关节类型（type,/type)，关节名称（joint name）,执行器（actuator）,硬件接口（hardwareInterface）。所有元素将与关节绑定。

```
<transmission name="simple_trans">
	<type>transmission_interface/SimpleTransmission</type>
	<joint name="foo_joint">
		<hardwareInterface>EffortJointInterface</hardwareInterface>
	</joint>
	<actuator name="foo_motor">
 		<mechanicalReduction>50</mechanicalReduction>
		<hardwareInterface>EffortJointInterface</hardwareInterface>
	</actuator>
</transmission>
```

- `<joint name="">` ：必须对应你在urdf文件中定义的关节名称
- `<type>`-传输类型。该插件当前仅实现了“ transmission_interface /SimpleTransmission”， 因此不要做更改
- `<hardwareInterface>`-：在`<actuator>`和`<joint>`标签中的，告诉gazebo_ros_control插件要加载的硬件接口（位置，速度或力矩接口）。当前仅实现了EffortJointInterface这一功能，同样也不要随意更改

> effort 不同的joint类型有不同的含义，一般是力矩，力（语义比较混乱在各个不同派系的开源代码中）。执行器模型抽象为actuator  ，与joint不一样的部分是actuator的属性值需要一定变换才能对应到joint，可以理解为电机减速，或者机构传动。



#### 关节限制（Joint Limits）

一个限位关节的数据结构，可以在ROS的服务器参数加载，也可以从urdf中加载。数据结构包含关节速度，位置，加速度，加加速度，力矩，软限位速度，位置边界等。

```

```

其余的需要加载的参数另外可以借助编写yaml文件载入参数服务器，编写元素有位置（position），速度（velocity），加速度（acceleration），加加速度（jerk），还有effort。

``` 
```

相关编写示例在ros_control可找到。



#### 命令行工具

通过在命令行输入命令直接进行操纵，除了单个控制命令

```
$ rosrun controller_manager controller_manager <command> <controller_name>
```

```
$ rosrun controller_manager controller_manager <command>
```



还有多运行命令

```c
 $ rosrun controller_manager spawner [--stopped] name1 name2 name3
                                                   //stopped参数：只加载不运行
```

```c
 $ rosrun controller_manager unspawner name1 name2 name3
 												  //只停止不卸载
```



#### Launch工具

对应于命令行工具的功能

加载并启动

```
 <launch>
   <node pkg="controller_manager"
         type="spawner"
         args="controller_name1 controller_name2" /> 
 </launch>
```



只需要加载：

```
<launch>
  <node pkg="controller_manager"
    type="spawner"
    args="--stopped controller_name1 controller_name2" />
</launch>
```



#### gazebo装载ros_control

我们需要向URDF中添加Gazebo插件，它会自动解析transmission标签，装载合适的硬件接口和controller manager。它可以通过插件架构在ros_control和gazebo之间来扩展自定义的机器人硬件接口。

一般添加到URDF的默认插件形如：

<gazebo>
  <plugin name="gazebo_ros_control" filename="libgazebo_ros_control.so">
    <robotNamespace>/MYROBOT</robotNamespace>
  </plugin>
</gazebo>

这个 gazebo_ros_control的< plugin>标签有如下可选的子标签：

    < robotNamespace>: 插件实例所使用的ROS命名空间，默认为URDF中robot的name
    < controlPeriod>: 控制器的更新时钟，默认为gazebo的时钟
    < robotParam>: 参数服务器中robot_description的位置，默认为’/robot_description’
    < robotSimType>:所使用自定义机器人仿真接口的插件名字，默认为’DefaultRobotHWSim’
