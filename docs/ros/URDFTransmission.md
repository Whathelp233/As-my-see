# URDF:Transmission
> 更新时间: 2026年02月27日

> 用来描述关节和驱动器之间的关系,功能包括定义关节传动比和连杆之间的关系等。 
>  通过复杂的转化可以把多驱动器和多关节联系在一起。
>
> transmission把TF（ros）的连接关系与仿真平台上的驱动设备（gazebo）联系在了一起，这样，**当物理引擎下，这个驱动设备进行了动作的时候，ros就能知道是哪个TF需要变化**



- 为了让Gazebo可以识别<transmission>标签，需要家在一个gazebo的ros_control插件：

>  *除了传输标签，还需要向URDF添加Gazebo插件，该插件实际解析传输标签并加载适当的硬件接口和控制器管理器。默认情况下，gazebo_ros_control插件非常简单，但它也可以通过附加的插件架构进行扩展，以允许超级用户在ros_control和gazebo之间创建自己的自定义机器人硬件接口.*

```
<gazebo>
  <plugin name="gazebo_ros_control" filename="libgazebo_ros_control.so">
    <robotNamespace>/rrbot</robotNamespace>
  </plugin>
</gazebo>
```



``` c++
    //定义关系传递的唯一名字
<transmission name="simple_trans">
//指定类型
  <type>transmission_interface/SimpleTransmission</type>
//指定关节依赖，可定义一个或多个，将会拥有其系列属性
    //关节名
  <joint name="foo_joint">
    //以上关节支持的硬件接口
    <hardwareInterface>EffortJointInterface</hardwareInterface>
  </joint>
//指定连接的致动器，可定义一个或多个，将会拥有以下标签
  <actuator name="foo_motor">
    //（可选）定义电机/关节减速比
    <mechanicalReduction>50</mechanicalReduction>
    //（可选）指定支持的硬件接口
    <hardwareInterface>EffortJointInterface</hardwareInterface>
   </actuator>
</transmission>

```





- hardwareInterface标签的可选项及对应控制器:

```c
//·Joint Command Interfaces           --effort_controllers - 直接控制关节的力/扭矩。 
    Effort Joint Interface                  joint_effort_controller
    Velocity Joint Interface                joint_position_controller
    Position Joint Interface                joint_velocity_controller
//·Joint State Interfaces             --joint_state_controller -读取所有关节位置
                                            joint_state_controller
//·Actuator State Interfaces          --position_controllers   -一次设置1/n个关节
                                            joint_position_controller
                                            joint_group_position_controller
//·Actuator Command Interfaces        --velocity_controllers - 一次设置一个／多个关节速度。
    Effort Actuator Interface               joint_velocity_controller
    Velocity Actuator Interface             joint_group_velocity_controller
    Position Actuator Interface     //--joint_trajectory_controllers -扩展功能用于规划整个轨迹 
                                                position_controller
    											velocity_controller
    											effort_controller
  											  position_velocity_controller
  											  position_velocity_acceleration_controller
        
//·Force-torque sensor Interface            

//·IMU sensor Interface
```




# Plugin

> **transmission只是将两个标签联系在了一起，但是并不代表ros发送一个消息，**gazebo plugin就是在ros和gazebo之间的一座桥梁
>
> *Gazebo Plugins为您的URDF提供了更强大的功能，并可以将ROS消息和服务呼叫与传感器输出和电机输入联系起来。*



``` c++
   //leftJoint和rightJoint要填写你模型中的名称，然后下面的两个wheel separation和wheel diameter也要根据你的轮子相距的距离和轮子的直径 
<gazebo>
        <plugin name="differential_drive_controller" filename="libgazebo_ros_diff_drive.so">
            <alwaysOn>true</alwaysOn>
            <updateRate>50.0</updateRate>
            <leftJoint>car_base_front_left_wheel</leftJoint>
            <rightJoint>car_base_front_right_wheel</rightJoint>
            <wheelSeparation>1.0</wheelSeparation>
            <wheelDiameter>0.5</wheelDiameter>
            <torque>1.0</torque>
            <commandTopic>cmd_vel</commandTopic>
            <odometryTopic>odom</odometryTopic>
            <odometryFrame>odom</odometryFrame>
            <robotBaseFrame>base_link</robotBaseFrame>
            <publishWheelTF>true</publishWheelTF>
            <publishWheelJointState>true</publishWheelJointState>
            <legecyMode>false</legecyMode>
            <wheelAcceleration>1</wheelAcceleration>
        </plugin>
</gazebo>
```



载入完成后，ros将会多出cmd_vel话题



# 各传感器的插件

> [使用](https://blog.csdn.net/weixin_43455581/article/details/106378239?utm_medium=distribute.pc_relevant.none-task-blog-2~default~baidujs_title~default-0.pc_relevant_paycolumn_v3&spm=1001.2101.3001.4242.1&utm_relevant_index=3)



# 差速驱动插件

```c
<gazebo>
<plugin name="differential_drive_controller" filename="libgazebo_ros_diff_drive.so">
 <alwaysOn>true</alwaysOn>
 <updateRate>${update_rate}</updateRate>
 <leftJoint>${base_link_right_wheel_joint}</leftJoint>
 <rightJoint>${base_link_left_wheel_joint}</rightJoint>
 <wheelSeparation>0.100</wheelSeparation>
 <wheelDiameter>0.040</wheelDiameter>
 <torque>20</torque>
 <commandTopic>cmd_vel</commandTopic>
 <odometryTopic>odom</odometryTopic>
 <odometryFrame>odom</odometryFrame>
 <robotBaseFrame>${base_link}</robotBaseFrame>
</plugin>
</gazebo>
```





# 滑动转向驱动

```c
<gazebo>
<plugin name="skid_steer_drive_controller" filename="libgazebo_ros_skid_steer_drive.so">
 <alwaysOn>true</alwaysOn>
 <updateRate>${update_rate}</updateRate>
 <leftFrontJoint>${base_link_wheel1_joint}</leftFrontJoint>
 <rightFrontJoint>${base_link_wheel2_joint}</rightFrontJoint>
<leftRearJoint>${base_link_wheel3_joint}</leftRearJoint>
 <rightRearJoint>${base_link_wheel4_joint}</rightRearJoint> 
 <wheelSeparation>0.100</wheelSeparation> 
 <wheelDiameter>0.040</wheelDiameter>
 <torque>20</torque>
 <commandTopic>cmd_vel</commandTopic>
 <odometryTopic>odom</odometryTopic>
 <odometryFrame>odom</odometryFrame>
 <robotBaseFrame>${base_link}</robotBaseFrame>
 <broadcastTF>1</broadcastTF>
</plugin>
</gazebo>
```





# 单目相机插件

```c
<!-- camera -->
   <gazebo reference="${camera_link}">
     <sensor type="camera" name="camera1">
       <update_rate>${update_rate}</update_rate>
       <camera name="head">
         <horizontal_fov>1.3962634</horizontal_fov>
         <image>
           <width>800</width>
           <height>800</height>
           <format>R8G8B8</format>
         </image>
         <clip>
           <near>0.02</near>
           <far>300</far>
         </clip>
         <noise>
           <type>gaussian</type>
           <!-- Noise is sampled independently per pixel on each frame.
                That pixel's noise value is added to each of its color
                channels, which at that point lie in the range [0,1]. -->
           <mean>0.0</mean>
           <stddev>0.007</stddev>
         </noise>
       </camera>
       <plugin name="camera_controller" filename="libgazebo_ros_camera.so">
        <alwaysOn>true</alwaysOn>
         <updateRate>0.0</updateRate>
         <cameraName>camera</cameraName>
         <imageTopicName>image</imageTopicName>
         <cameraInfoTopicName>camera_info</cameraInfoTopicName>
         <frameName>${camera_link}</frameName>
         <hackBaseline>0.07</hackBaseline>
         <distortionK1>0.0</distortionK1>
         <distortionK2>0.0</distortionK2>
         <distortionK3>0.0</distortionK3>
         <distortionT1>0.0</distortionT1>
         <distortionT2>0.0</distortionT2>
       </plugin>
     </sensor>
   </gazebo>
```





# RGB-D相机插件

```c
<gazebo reference="${camera_link}">
  <sensor type="depth" name="camera1">
      <always_on>1</always_on>
      <visualize>true</visualize>             
      <camera>
          <horizontal_fov>1.047</horizontal_fov>  
          <image>
              <width>640</width>
              <height>480</height>
              <format>R8G8B8</format>
          </image>
          <depth_camera>     
      </depth_camera>
      <clip>
          <near>0.1</near>
          <far>100</far>
      </clip>
  </camera>
       <plugin name="camera_controller" filename="libgazebo_ros_openni_kinect.so">
       <alwaysOn>true</alwaysOn>
          <updateRate>10.0</updateRate>
          <cameraName>camera</cameraName>
          <frameName>${camera_link}</frameName>                   
      <imageTopicName>rgb/image_raw</imageTopicName>
      <depthImageTopicName>depth/image_raw</depthImageTopicName>
      <pointCloudTopicName>depth/points</pointCloudTopicName>
      <cameraInfoTopicName>rgb/camera_info</cameraInfoTopicName>              
         <depthImageCameraInfoTopicName>depth/camera_info</depthImageCameraInfoTopicName>            
         <pointCloudCutoff>0.4</pointCloudCutoff>                
             <hackBaseline>0.07</hackBaseline>
             <distortionK1>0.0</distortionK1>
             <distortionK2>0.0</distortionK2>
             <distortionK3>0.0</distortionK3>
             <distortionT1>0.0</distortionT1>
             <distortionT2>0.0</distortionT2>
         <CxPrime>0.0</CxPrime>
         <Cx>0.0</Cx>
         <Cy>0.0</Cy>
         <focalLength>0.0</focalLength>
         </plugin>
 </sensor>
 </gazebo>
```





# 激光雷达插件

```c
<gazebo reference="${hokuyo_link}">
 <sensor type="ray" name="head_hokuyo_sensor">
   <pose>0 0 0 0 0 0</pose>
   <visualize>false</visualize>
   <update_rate>40</update_rate>
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
       <max>30.0</max>
       <resolution>0.01</resolution>
     </range>
     <noise>
       <type>gaussian</type>
       <!-- Noise parameters based on published spec for Hokuyo laser
            achieving "+-30mm" accuracy at range < 10m.  A mean of 0.0m and
            stddev of 0.01m will put 99.7% of samples within 0.03m of the true
            reading. -->
       <mean>0.0</mean>
       <stddev>0.01</stddev>
     </noise>
   </ray>
   <plugin name="gazebo_ros_head_hokuyo_controller" filename="libgazebo_ros_laser.so">
     <topicName>/laser/scan</topicName>
     <frameName>${hokuyo_link}</frameName>
   </plugin>
 </sensor>
</gazebo>
```





# 平衡车

```c
<gazebo>
   <plugin name="differential_drive_controller" 
           filename="libgazebo_ros_diff_drive.so">
       <rosDebugLevel>Debug</rosDebugLevel>
       <publishWheelTF>true</publishWheelTF>
       <robotNamespace>/</robotNamespace>
       <publishTf>1</publishTf>
       <publishWheelJointState>true</publishWheelJointState>
       <alwaysOn>true</alwaysOn>
       <updateRate>100.0</updateRate>
       <legacyMode>true</legacyMode>
       <leftJoint>left_wheel_joint</leftJoint>
       <rightJoint>right_wheel_joint</rightJoint>
       <wheelSeparation>0.2</wheelSeparation>
       <wheelDiameter>0.6</wheelDiameter>
       <broadcastTF>1</broadcastTF>
       <wheelTorque>30</wheelTorque>
       <wheelAcceleration>1.8</wheelAcceleration>
       <commandTopic>cmd_vel</commandTopic>
       <odometryFrame>odom</odometryFrame> 
       <odometryTopic>odom</odometryTopic> 
       <robotBaseFrame>base_footprint</robotBaseFrame>
   </plugin>
</gazebo> 
```





# 四轮车

```c
<gazebo>
     <plugin name="differential_drive_controller" filename="/opt/ros/noetic/lib/libgazebo_ros_skid_steer_drive.so">
         <robotNamespace>/</robotNamespace>
         <alwaysOn>true</alwaysOn>
         <updateRate>50.0</updateRate>
         <leftFrontJoint>car_base_wheel2</leftFrontJoint>
         <rightFrontJoint>car_base_wheel4</rightFrontJoint>
         <leftRearJoint>car_base_wheel1</leftRearJoint>
         <rightRearJoint>car_base_wheel3</rightRearJoint>
         <wheelSeparation>0.8</wheelSeparation>
         <wheelDiameter>0.2</wheelDiameter>
         <torque>1.0</torque>
         <commandTopic>cmd_vel</commandTopic>
         <odometryTopic>odom</odometryTopic>
         <odometryFrame>odom</odometryFrame>
         <robotBaseFrame>base_link</robotBaseFrame>
         <broadcastTF>1</broadcastTF>
         <publishWheelTF>true</publishWheelTF>
         <publishWheelJointState>true</publishWheelJointState>
         <legecyMode>false</legecyMode>
         <wheelAcceleration>1</wheelAcceleration>
     </plugin>
</gazebo>
```
