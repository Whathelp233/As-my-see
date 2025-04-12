# 配置文件创建controllers

> controller通过配置文件的形式载入到ros的参数服务器中（param service），之后通过ros的服务（service）来启动它们

### yaml

之前作业中的雷达小车的controllers配置文件

``` c
smb_joint_publisher:
  type: "joint_state_controller/JointStateController"
  publish_rate: 50

smb_velocity_controller:
  type: "diff_drive_controller/DiffDriveController"
   //填写whell joint的名称
  left_wheel: ['LF_WHEEL_JOINT', 'LH_WHEEL_JOINT']
  right_wheel: ['RF_WHEEL_JOINT', 'RH_WHEEL_JOINT']
  publish_rate: 50
   //位姿_协方差_对角线 
  pose_covariance_diagonal: [0.1, 0.001, 0.001, 0.001, 0.001, 0.3]
   //速度_协方差_对角线 
  twist_covariance_diagonal: [0.001, 0.001, 0.001, 0.001, 0.001, 0.03]
  cmd_vel_timeout: 0.25
  velocity_rolling_window_size: 2
  enable_odom_tf: false

gazebo_ros_control:
  pid_gains:
    LF_WHEEL_JOINT:
      p: 100.0
    RF_WHEEL_JOINT:
      p: 100.0
    LH_WHEEL_JOINT:
      p: 100.0
    RH_WHEEL_JOINT:
      p: 100.0

  # Base frame_id
  base_frame_id: base_link

  # Odometry fused with IMU is published by robot_localization, so
  # no need to publish a TF based on encoders alone.
  enable_odom_tf: false

  # Smb hardware provides wheel velocities
  estimate_velocity_from_position: false

  # Wheel separation and radius multipliers
  wheel_separation_multiplier: 1.875 # default: 1.0
  wheel_radius_multiplier    : 1.0 # default: 1.0

  # Velocity and acceleration limits
  # Whenever a min_* is unspecified, default to -max_*
  linear:
    x:
      has_velocity_limits    : true
      max_velocity           : 1.1   # m/s
      has_acceleration_limits: true
      max_acceleration       : 2.0   # m/s^2
  angular:
    z:
      has_velocity_limits    : true
      max_velocity           : 1.1   # rad/s
      has_acceleration_limits: true
      max_acceleration       : 3.0   # rad/s^2
```



接着在launch中载入节点

``` c
<node name="base_controller_spawner" pkg="controller_manager" type="spawner"
        args="smb_joint_publisher smb_velocity_controller"/>

  <node name="smb_robot_state_publisher" pkg="robot_state_publisher" type="robot_state_publisher" output="screen">
    <param name="publish_frequency" value="50"/>
    <param name="use_tf_static"     value="true"/>
    //将robot_descripition映射
    <remap from="robot_description" to="$(arg robot_description)"/>
  </node>
```

