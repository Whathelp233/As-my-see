# Cmake 常见问题



## Catkin无法编译，clion可以

> inverted_pendulum_controller需要inverted_pendulum_msg包，但是编译inverted_pendulum_msg后还是找不到

catkin编译会预览camkelist，clion里不用，如果find package的依赖不对，即使仓库内有依赖的包，现在编译的包也会报找不到依赖的错误

```cmake
find_package(catkin REQUIRED COMPONENTS
        roscpp
        rospy
        std_msgs
        angles
        controller_interface
        effort_controllers
        dynamic_reconfigure

        rm_common
        inverted_pendulum_msg #增加依赖
        )
```





## find_package()依赖冲突

> 在find_package()申明对包的依赖后却提示已经有包存在且发生冲突

```cmake
CMake Error at /home/yuchen/usetest/RM_ROS/build/my_ros/two_wheel_robot/two_wheel_robot_msg/cmake/two_wheel_robot_msg-genmsg.cmake:79 (add_custom_target):
  add_custom_target cannot create target
  "two_wheel_robot_msg_generate_messages_eus" because another target with the
  same name already exists.  The existing target is a custom target created
  in source directory
  "/home/yuchen/usetest/RM_ROS/src/my_ros/two_wheel_robot/two_wheel_robot_controller".
```

这种情况是因为依赖包没有在package.xml申明，虽然有时候这样的情况clion会提醒你没有申明，但这样就没有，以后注意一下就行了

```xml
<depend>two_wheel_robot_msg</depend>
```
