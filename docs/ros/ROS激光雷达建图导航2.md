# ROS激光雷达建图导航
> 更新时间: 2026年02月27日

> 基于本文档进行编写：http://www.autolabor.com.cn/book/ROSTutorials/



# 概念理解

- 在基于map_server下谁在move_base中完成地图的补充或构建

```从、
move_base的动态建图功能是由obstacle_layer这个插件实现的。obstacle_layer是costmap_2d包中的一个类，它可以从传感器数据中提取障碍物信息，并将其更新到代价地图中。obstacle_layer可以从激光雷达、声纳、RGB-D相机等传感器中获取障碍物信息，也可以从其他节点订阅障碍物信息。obstacle_layer可以根据障碍物的类型（静态或动态）和持续时间（过期或永久）来设置不同的代价值
```

- 全局与局部代价地图的区别与作用

```c
global_costmap是用于全局路径规划的代价地图，它通常是由静态地图提供，并在此基础上融合了障碍物层和膨胀层的参数。它可以长期稳定地描述整个环境，主要用于计算机器人从起点到终点的最优路径。它的坐标系通常是map，它的大小和分辨率与静态地图一致。
local_costmap是用于局部运动规划和避障的代价地图，它通常是实时更新的，并且只覆盖机器人周围一定范围内的代价地图信息。它主要用于根据全局路径和机器人的状态，生成一条可行的局部轨迹，并控制机器人的速度和角速度。它的坐标系通常是odom，它的大小和分辨率可以根据需要设置。
```

- 全局和局部代价地图如何生成的？

```c
global_costmap全局代价地图，在导航开始前基于静态地图层和障碍物地图层构建的，通常不会随着机器人的移动而改变。global_costmap主要用于全局路径规划，即给定一个目标位置，规划一条从当前位置到目标位置的路径。

local_costmap是局部代价地图，它是基于障碍物地图层和膨胀层构建的，通常会随着机器人的移动而滚动更新。local_costmap主要用于局部路径规划和避障，即根据全局路径和当前环境，规划一条短期的、安全的、可行的轨迹。

local在自己的小范围内建图，离开这片区域后除非主动在全局下储存否则记录的信息会丢失，所以需要在global设置同步更新
```

<img src="images/ROS激光雷达建图导航2/2023-10-05 03-39-28 的屏幕截图.png" alt="2023-10-05 03-39-28 的屏幕截图" style="zoom: 50%;" />

地图中间高亮矩形区域，是局部代价地图，和以下参数有关:

```yaml
local_costmap:
  global_frame: map
  robot_base_frame: base_link
  update_frequency: 20.0
  publish_frequency: 10.0
  static_map: false    #首先开启这个，表示地图会更新，下面的几个参数也需要填写
  rolling_window: true #地图是否会以机器人为中心，local需要为true，否则地图就出现在原点不动了
  width: 5
  height: 5
  resolution: 0.05
  transform_tolerance: 0.5
```

四周灰色的是全局代价地图，参数和上面类似





# 参数文件 

一份move_base的参数文件通常有以下所示：

- costmap_common_params.yaml

无论是全局还是局部规划器，都有自己的代价地图参数，这个参数在更换命名空间后在相应的规划器里面生效

- global_costmap_params.yaml

全局代价地图参数

- local_costmap_params.yaml

局部代价地图参数

- dwa/teb/..._loacl_planner_params.yaml

局部规划器的参数，根据不同的规划器修改值



# 代价地图参数

# costmap_common

这些参数都是用来配置costmap_2d中的不同的层的，每个层都有自己的功能和属性。具体来说：

```yaml
#---standard pioneer footprint---
#---(in meters)---
#footprint: [ [0.254, -0.0508], [0.1778, -0.0508], [0.1778, -0.1778], [-0.1905, -0.1778], [-0.254, 0], [-0.1905, 0.1778], [0.1778, 0.1778], [0.1778, 0.0508], [0.254, 0.0508] ]
footprint: [ [-0.1,-0.125], [0.5,-0.125], [0.5,0.125], [-0.1,0.125] ]

#transform_tolerance 参数是用来设置 TF 变换的容忍误差的，它是一个以秒为单位的时间值。这个参数可以用来处理 TF 变换时可能出现的时间延迟或不同步的问题。例如，你给出的 transform_tolerance 参数为 0.2，表示如果 TF 变换时请求的时间戳与最近可用的数据之间的差值小于或等于 0.2 秒，则可以进行插值或外推；否则，会报错 Extrapolation Error。这个参数可以用来提高 TF 变换的鲁棒性和稳定性。
transform_tolerance: 0.2  
map_type: costmap

#obstacle_layer: 这是一个用来检测和标记障碍物的层，它可以从不同的传感器数据源获取障碍物信息，并将其更新到成本地图中。
obstacle_layer:
 enabled: true         #是否启用这个层，true表示启用，false表示禁用。
 obstacle_range: 5.0   #传感器能够检测到障碍物的最大距离，单位是米。
 raytrace_range: 5.5   #传感器能够清除障碍物的最大距离，单位是米。这个参数通常要比obstacle_range大一点，以避免留下残留的障碍物
 inflation_radius: 0.1 #障碍物周围要膨胀的半径，单位是米。这个参数可以增加机器人与障碍物之间的安全距离
 track_unknown_space: false #是否跟踪未知空间，true表示跟踪，false表示不跟踪。未知空间是指没有被传感器探测到的区域，如果跟踪的话，会将其标记为不可通行的区域。
 combination_method: 1 #障碍物层与其他层之间的组合方法，1表示取最大值，0表示取覆盖值。

 observation_sources: laser_scan_sensor #传感器数据源的名称列表，用空格分隔。每个数据源都需要在下面定义其类型、话题、标记和清除等属性
 laser_scan_sensor: {data_type: LaserScan, topic: scan, marking: true, clearing: true} #一个传感器数据源的示例，它的类型是LaserScan，话题是scan，标记和清除都是true，表示这个传感器既可以标记也可以清除障碍物。

#这是一个用来对障碍物进行膨胀处理的层，它可以根据障碍物与机器人之间的距离计算出一个成本函数，并将其应用到成本地图中。
inflation_layer:
  enabled:              true  #是否启用这个层，true表示启用，false表示禁用。
  cost_scaling_factor:  10.0  #成本函数中的比例因子，它决定了成本值随着距离的变化而衰减的速率。比例因子越大，成本值越低。 (default: 10)
  inflation_radius:     2.5  # 障碍物周围要膨胀的半径，单位是米。这个参数可以增加机器人与障碍物之间的安全距离

#这是一个用来加载静态地图的层，它可以从一个外部源获取一个不变的地图，并将其作为成本地图的基础。
static_layer:
  enabled:              true   #是否启用这个层，true表示启用，false表示禁用。
  map_topic:            "/map" #静态地图发布的话题名称。通常由map_server提供。
```



```c
源: 与必应的对话， 2023/10/5
(1) costmap配置教程和详细理解-CSDN博客. https://blog.csdn.net/ahelloyou/article/details/106159373.
(2) ROS导航系列(三)：costmap2D详解_ros costmap_little_miya的博客-CSDN博客. https://blog.csdn.net/allenhsu6/article/details/113057784.
(3) [ROS2] 你应该知道Costmap_2d 的这些细节 - 知乎 - 知乎专栏. https://bing.com/search?q=costmap_2d%e5%8f%82%e6%95%b0%e8%af%b4%e6%98%8e.
(4) costmap · 中国大学MOOC———《机器人操作系统入门》讲义. https://sychaichangkun.gitbooks.io/ros-tutorial-icourse163/content/chapter10/10.3.html.
(5) [ROS2] 你应该知道Costmap_2d 的这些细节 - 知乎 - 知乎专栏. https://zhuanlan.zhihu.com/p/493093960.
```



# global_costmap

```yaml
global_costmap:
  global_frame: map            #运行costmap的全局坐标系，通常是map。
  robot_base_frame: base_link  #机器人基本链接的坐标系，通常是base_link。
  update_frequency: 0.001      #costmap更新的频率，单位是赫兹。这个参数决定了costmap多久更新一次障碍物信息和机器人位置。
  #这个值太小了，所以全局代价不会更新
  publish_frequency: 0.0005    #costmap发布的频率，单位是赫兹。这个参数决定了costmap多久发布一次自己的数据给其他节点。
  static_map: true             #是否使用静态地图初始化costmap，true表示使用，false表示不使用。如果使用静态地图，那么costmap的大小和障碍物信息会与静态地图一致，如果不使用静态地图，那么costmap的大小和障碍物信息会根据机器人的运动而变化。
 
 #允许等待tf转换的最大时间，单位是秒。如果tf树没有按照预期的速率更新，那么导航堆栈会停止机器人。
  transform_tolerance: 0.5
  
  #插件列表，用来指定costmap使用哪些层来构建自己。每个插件都有一个名称和一个类型，名称用来定义插件的参数命名空间，类型用来指定插件的实现类
  plugins:  ##这些插件的具体声明在costmap_common里面
    - {name: static_layer,            type: "costmap_2d::StaticLayer"} #一个用来加载静态地图的层，它可以从一个外部源获取一个不变的地图，并将其作为costmap的基础。
    - {name: obstacle_layer,          type: "costmap_2d::VoxelLayer"}  #一个用来检测和标记障碍物的层，它可以从不同的传感器数据源获取障碍物信息，并将其更新到costmap中。在这里，obstacle_layer使用了VoxelLayer这个类，它是一个基于体素网格的三维障碍物层，可以在三维空间中表示障碍物信息，并将其投影到二维平面上。
    - {name: inflation_layer,         type: "costmap_2d::InflationLayer"} #一个用来对障碍物进行膨胀处理的层，它可以根据障碍物与机器人之间的距离计算出一个成本函数，并将其应用到costmap中。这个层可以增加机器人与障碍物之间的安全距离。
```



```c

源: 与必应的对话， 2023/10/5
(1) costmap配置教程和详细理解-CSDN博客. https://blog.csdn.net/ahelloyou/article/details/106159373.
(2) ROS导航系列(三)：costmap2D详解_ros costmap_little_miya的博客-CSDN博客. https://blog.csdn.net/allenhsu6/article/details/113057784.
(3) [ROS2] 你应该知道Costmap_2d 的这些细节 - 知乎 - 知乎专栏. https://bing.com/search?q=costmap_2d%e5%8f%82%e6%95%b0%e8%af%b4%e6%98%8e.
(4) costmap · 中国大学MOOC———《机器人操作系统入门》讲义. https://sychaichangkun.gitbooks.io/ros-tutorial-icourse163/content/chapter10/10.3.html.
(5) [ROS2] 你应该知道Costmap_2d 的这些细节 - 知乎 - 知乎专栏. https://zhuanlan.zhihu.com/p/493093960.
```



# local_costmap

```yaml
#这些参数是用来配置local_costmap的，它是一个用于局部运动规划和避障的代价地图，它可以描述机器人周围一定范围内的环境信息，包括障碍物、空闲空间、未知区域等
local_costmap:
  global_frame: map
  robot_base_frame: base_link
  update_frequency: 20.0
  publish_frequency: 10.0
  static_map: false
  rolling_window: true  #是否使用成本图的滚动窗口版本。如果设置为true，意味着当机器人移动时，保持机器人在本地代价地图中心。如果设置为false，意味着本地代价地图不会随机器人移动而改变。
  width: 5              #滚动窗口的宽度，单位是米。这个参数决定了本地代价地图覆盖的水平范围。
  height: 5             #滚动窗口的高度，单位是米。这个参数决定了本地代价地图覆盖的垂直范围。
  resolution: 0.25      #滚动窗口的分辨率，单位是米/像素。这个参数决定了本地代价地图中每个单元格的大小。
  transform_tolerance: 0.5
  
  plugins:
   - {name: static_layer,        type: "costmap_2d::StaticLayer"}
   - {name: obstacle_layer,      type: "costmap_2d::ObstacleLayer"}
```

```c

源: 与必应的对话， 2023/10/5
(1) local_costmap_params.yaml参数注释_kobesdu的博客-CSDN博客. https://blog.csdn.net/kobesdu/article/details/119566177.
(2) costmap配置教程和详细理解-CSDN博客. https://blog.csdn.net/ahelloyou/article/details/106159373.
(3) ROS导航包中的costmap的一些参数理解 - CSDN博客. https://blog.csdn.net/jinking01/article/details/104193666.
```



# 局部规划器参数

# TEB

```c
这些参数是用来配置TEB轨迹规划算法的，它是一种基于时间弹性带（TEB）的局部运动规划和避障算法，可以根据给定的全局路径和机器人的状态，生成一条可行的局部轨迹，并控制机器人的速度和角速度。它的参数的意思如下：

- TebLocalPlannerROS: 这是一个命名空间，用来定义TEB轨迹规划算法的参数。
- odom_topic: 里程计话题的名称，用来获取机器人的位置和速度信息。
- Trajectory: 这是一个子命名空间，用来定义轨迹相关的参数。
    - teb_autosize: 是否自动调整轨迹中每两个位姿之间的时间间隔，以适应不同的速度和加速度。如果为True，那么轨迹中的位姿数量会根据dt_ref和dt_hysteresis动态变化，如果为False，那么轨迹中的位姿数量会固定为max_samples。
    - dt_ref: 参考时间间隔，单位是秒。这个参数表示理想情况下轨迹中每两个位姿之间的时间差，通常取决于机器人的最大速度和加速度。如果teb_autosize为True，那么实际的时间间隔会根据速度和加速度自动调整，但不会超过dt_ref加减dt_hysteresis的范围。
    - dt_hysteresis: 时间间隔的滞后系数，单位是秒。这个参数表示允许时间间隔在dt_ref附近波动的范围，一般取dt_ref的10%左右。如果teb_autosize为True，那么当实际时间间隔大于dt_ref加上dt_hysteresis时，会在轨迹中插入新的位姿；当实际时间间隔小于dt_ref减去dt_hysteresis时，会在轨迹中删除多余的位姿。
    - max_samples: 最大位姿数量。这个参数表示轨迹中最多可以有多少个位姿。如果teb_autosize为False，那么轨迹中的位姿数量会固定为这个值；如果teb_autosize为True，那么轨迹中的位姿数量会根据时间间隔动态变化，但不会超过这个值。
    - global_plan_overwrite_orientation: 是否覆盖全局路径中每个点的朝向。这个参数表示是否使用TEB算法计算每个点应该有的朝向，而不是直接使用全局路径中给出的朝向。如果为True，那么TEB算法会根据全局路径中后面几个点计算平均角度，并用这个角度来覆盖每个点的朝向；如果为False，那么TEB算法会直接使用全局路径中给出的朝向。
    - allow_init_with_backwards_motion: 是否允许初始时向后移动。这个参数表示是否允许机器人在开始时向后移动来执行轨迹。如果为True，那么TEB算法会根据机器人当前位置和目标位置选择最优方向进行移动；如果为False，那么TEB算法只会让机器人向前移动。
    - max_global_plan_lookahead_dist: 最大全局路径预览距离，单位是米。这个参数表示TEB算法考虑优化的全局路径子集的最大长度（累积欧几里得距离）。如果为0或负数，则禁用此功能；长度也受本地代价地图大小的限制。
    - global_plan_viapoint_sep: 全局路径中的通过点间隔，单位是米。这个参数表示从全局路径中选取的每两个连续通过点之间的最小间隔。如果为负数，则禁用此功能。
    - global_plan_prune_distance: 全局路径的修剪距离，单位是米。这个参数表示从机器人当前位置的后面一定距离开始修剪全局路径。这样可以减少全局路径的长度，提高优化效率。
    - exact_arc_length: 是否使用精确的弧长计算速度、加速度和转弯半径。这个参数表示是否在速度、加速度和转弯半径计算中使用精确的弧长，而不是使用欧几里德近似。如果为True，那么TEB算法会更加精确，但也会增加CPU时间；如果为False，那么TEB算法会更加快速，但也会损失一些精度。
    - feasibility_check_no_poses: 可行性检查的位姿数量。这个参数表示在判断生成的轨迹是否与障碍物冲突时，从轨迹起点开始逐个检查轨迹上的多少个点。如果所有检查的点都不发生碰撞，则认为本次轨迹有效；如果有任何一个点发生碰撞，则认为本次轨迹无效。如果小于0，则检查所有路径点。
    - publish_feedback: 是否发布包含完整轨迹和活动障碍物列表的规划器反馈。这个参数表示是否将TEB算法的优化结果和相关信息发布到一个话题上，以供其他节点订阅和分析。如果为True，那么TEB算法会发布反馈信息；如果为False，那么TEB算法不会发布反馈信息。
- Robot: 这是一个子命名空间，用来定义机器人相关的参数。
    - max_vel_x: 最大x方向前向速度，单位是米/秒。这个参数表示机器人在x方向上能够达到的最大前进速度。
    - max_vel_x_backwards: 最大x方向后退速度，单位是米/秒。这个参数表示机器人在x方向上能够达到的最大后退速度。
    - max_vel_y: 最大y方向速度，单位是米/秒。这个参数表示机器人在y方向上能够达到的最大速度。对于非全向机器人，这个值应该设为0。
    - max_vel_theta: 最大角速度，单位是弧度/秒。这个参数表示机器人能够达到的最大转向角速度。注意，对于类似汽车的机器人，角速度还受到最小转弯半径的限制（r = v / omega）。
    - acc_lim_x: 最大x方向加速度，单位是米/秒^2^。这个参数表示机器人在x方向上能够达到的最大加速度。
    - acc_lim_theta: 最大角加速度，单位是弧度/秒^2^。这个参数表示机器人能够达到的最大角加速度。
    - min_turning_radius: 最小转弯半径，单位是米。这个参数表示类似汽车的机器人能够实现的最小转弯半径。对于非类似汽车的机器人，这个值应该设为0。
    - wheelbase: 轮距，单位是米。这个参数表示类似汽车的机器人驱动轴和转向轴之间的距离。对于后轮驱动的机器人，这个值可能为负数。
    - cmd_angle_instead_rotvel: 是否将收到的角速度消息转换为操作上的角度变化。这个参数表示是否将订

源: 与必应的对话， 2023/10/5
(1) TEB算法详解 参数详解_teb参数-CSDN博客. https://blog.csdn.net/YiYeZhiNian/article/details/130233031.
(2) TEB算法2－teb参数说明及调试小记 - CSDN博客. https://blog.csdn.net/Draonly/article/details/125119683.
(3) TEB轨迹优化算法-代码解析与参数建议 - CSDN博客. https://blog.csdn.net/zz123456zzss/article/details/104692548.
(4) 现实环境中，关于Teb Local Planner 参数调试总结 - CSDN博客. https://blog.csdn.net/qq_39266065/article/details/110820022.
(5) TEB轨迹规划算法教程-配置和导航 - 创客智造/爱折腾智能机器人. https://www.ncnynl.com/archives/201809/2601.html.
```



```c
- footprint_model: 这是一个用来定义机器人轮廓模型的参数，它可以影响障碍物检测和轨迹优化的结果。它有以下几种类型：
    - point: 点模型，表示机器人是一个无大小的点，这种类型适用于非全向机器人，但是不太准确。
    - circular: 圆形模型，表示机器人是一个有一定半径的圆，这种类型适用于全向机器人，但是不太灵活。
    - two_circles: 双圆模型，表示机器人是由两个圆组成的，分别代表前轮和后轮，这种类型适用于类似汽车的机器人，但是不太通用。
    - line: 线段模型，表示机器人是一个有一定长度的线段，这种类型适用于非全向机器人，但是不太精确。
    - polygon: 多边形模型，表示机器人是一个由多个顶点组成的多边形，这种类型适用于任何形状的机器人，但是需要手动指定顶点坐标。
- xy_goal_tolerance: 这是一个用来定义目标位置容差的参数，单位是米。这个参数表示机器人到达目标位置时允许的最大偏差。如果为0或负数，则禁用此功能。
- yaw_goal_tolerance: 这是一个用来定义目标朝向容差的参数，单位是弧度。这个参数表示机器人到达目标朝向时允许的最大偏差。如果为0或负数，则禁用此功能。
- free_goal_vel: 这是一个用来决定是否允许机器人以最大速度驶向目标的参数。如果为True，那么TEB算法不会对机器人的最终速度进行限制；如果为False，那么TEB算法会让机器人在到达目标时减速停止。
- complete_global_plan: 这是一个用来决定是否使用完整的全局路径进行优化的参数。如果为True，那么TEB算法会考虑全局路径中所有的点进行优化；如果为False，那么TEB算法只会考虑局部代价地图范围内的点进行优化。
- min_obstacle_dist: 这是一个用来定义最小障碍物距离的参数，单位是米。这个参数表示机器人与障碍物之间需要保持的最小安全距离。注意，这个值还需要包括机器人自身的扩展，因为footprint_model被设置为"line"。
- inflation_dist: 这是一个用来定义障碍物膨胀距离的参数，单位是米。这个参数表示障碍物周围要增加的额外距离，以增加安全裕度。注意，这个值应该大于min_obstacle_dist。
- include_costmap_obstacles: 这是一个用来决定是否将代价地图中的障碍物信息纳入优化的参数。如果为True，那么TEB算法会将代价地图中所有非零值的单元格视为障碍物，并根据其代价值计算障碍物成本；如果为False，那么TEB算法不会考虑代价地图中的障碍物信息。
- costmap_obstacles_behind_robot_dist: 这是一个用来定义代价地图中考虑障碍物范围的参数，单位是米。这个参数表示只有在机器人后方一定距离内的代价地图单元格才会被视为障碍物，并纳入优化。这样可以减少不必要的障碍物信息，提高优化效率。
- obstacle_poses_affected: 这是一个用来定义受障碍物影响的轨迹点数量的参数。这个参数表示在计算障碍物成本时，只考虑轨迹上距离障碍物最近的一定数量的点，而不是所有的点。这样可以减少计算量，提高优化效率。
- dynamic_obstacle_inflation_dist: 这是一个用来定义动态障碍物膨胀距离的参数，单位是米。这个参数表示动态障碍物周围要增加的额外距离，以增加安全裕度。注意，这个值应该大于min_obstacle_dist。
- include_dynamic_obstacles: 这是一个用来决定是否将动态障碍物信息纳入优化的参数。如果为True，那么TEB算法会将从传感器数据中检测到的动态障碍物视为特殊的障碍物，并根据其速度和位置对轨迹进行优化；如果为False，那么TEB算法不会考虑动态障碍物信息。
- costmap_converter_plugin: 这是一个用来指定代价地图转换插件的参数。这个参数表示使用哪个插件来将代价地图中的变化转换为动态障碍物，并传递给TEB算法进行优化。如果为空，则禁用此功能。
- costmap_converter_spin_thread: 这是一个用来决定是否使用单独的线程来运行代价地图转换插件的参数。如果为True，那么代价地图转换插件会在一个单独的线程中运行，以提高实时性；如果为False，那么代价地图转换插件会在主线程中运行，以节省资源。
- costmap_converter_rate: 这是一个用来定义代价地图转换插件的运行频率的参数，单位是赫兹。这个参数表示代价地图转换插件多久运行一次，并将结果传递给TEB算法进行优化。

```



```c
- Optimization: 这是一个子命名空间，用来定义优化相关的参数。
    - no_inner_iterations: 内部迭代次数。这个参数表示在每次外部迭代中，执行多少次内部迭代。内部迭代是指对轨迹上的每个点进行优化，外部迭代是指对轨迹上的所有点进行优化。
    - no_outer_iterations: 外部迭代次数。这个参数表示执行多少次外部迭代。外部迭代是指对轨迹上的所有点进行优化，内部迭代是指对轨迹上的每个点进行优化。
    - optimization_activate: 是否激活优化。这个参数表示是否执行优化算法。如果为True，那么TEB算法会根据多个目标函数和约束条件对轨迹进行优化；如果为False，那么TEB算法不会执行优化算法。
    - optimization_verbose: 是否输出优化信息。这个参数表示是否将优化过程中的信息输出到控制台或日志文件中。如果为True，那么TEB算法会输出优化过程中的信息，如目标函数值、约束条件值、收敛情况等；如果为False，那么TEB算法不会输出优化过程中的信息。
    - penalty_epsilon: 惩罚因子。这个参数表示在使用惩罚方法处理不等式约束时，使用的惩罚因子大小。惩罚方法是一种将不等式约束转换为目标函数的方法，它会在目标函数中加入一个与不等式约束值成正比的惩罚项，使得不等式约束越大，目标函数越大，从而使得优化过程倾向于满足不等式约束。惩罚因子越大，惩罚项越大，对不等式约束的满足程度要求越高；惩罚因子越小，惩罚项越小，对不等式约束的满足程度要求越低。
    - obstacle_cost_exponent: 障碍物成本指数。这个参数表示在计算障碍物成本时，使用的指数函数的指数值。障碍物成本是一种反映机器人与障碍物之间距离的目标函数，它使用一个指数函数来计算机器人与障碍物之间距离的倒数，并乘以一个权重系数。指数函数的指数值越大，障碍物成本越敏感，对距离障碍物越近的情况惩罚越大；指数函数的指数值越小，障碍物成本越不敏感，对距离障碍物越近的情况惩罚越小。
    - weight_max_vel_x: 最大x方向速度权重。这个参数表示在计算最大x方向速度约束时，使用的权重系数。最大x方向速度约束是一种限制机器人在x方向上不能超过最大速度的约束条件，它使用一个二次函数来计算机器人实际速度与最大速度之差的平方，并乘以一个权重系数。权重系数越大，最大x方向速度约束越重要，对超过最大速度的情况惩罚越大；权重系数越小，最大x方向速度约束越不重要，对超过最大速度的情况惩罚越小。
    - weight_max_vel_theta: 最大角速度权重。这个参数表示在计算最大角速度约束时，使用的权重系数。最大角速度约束是一种限制机器人不能超过最大角速度的约束条件，它使用一个二次函数来计算机器人实际角速度与最大角速度之差的平方，并乘以一个权重系数。权重系数越大，最大角速度约束越重要，对超过最大角速度的情况惩罚越大；权重系数越小，最大角速度约束越不重要，对超过最大角速度的情况惩罚越小。
    - weight_acc_lim_x: 最大x方向加速度权重。这个参数表示在计算最大x方向加速度约束时，使用的权重系数。最大x方向加速度约束是一种限制机器人在x方向上不能超过最大加速度的约束条件，它使用一个二次函数来计算机器人实际加速度与最大加速度之差的平方，并乘以一个权重系数。权重系数越大，最大x方向加速度约束越重要，对超过最大加速度的情况惩罚越大；权重系数越小，最大x方向加速度约束越不重要，对超过最大加速度的情况惩罚越小。
    - weight_acc_lim_theta: 最大角加速度权重。这个参数表示在计算最大角加速度约束时，使用的权重系数。最大角加速度约束是一种限制机器人不能超过最大角加速度的约束条件，它使用一个二次函数来计算机器人实际角加速度与最大角加速度之差的平方，并乘以一个权重系数。权重系数越大，最大角加速度约束越重要，对超过最大角加速度的情况惩罚越大；权重系数越小，最大角加速度约束越不重要，对超过最大角加速度的情况惩罚越小。
    - weight_kinematics_nh: 非完整性运动学权重。这个参数表示在计算非完整性运动学约束时，使用的权重系数。非完整性运动学约束是一种反映机器人运动模型的约束条件，它使用一个二次函数来计算机器人实际运动与理想运动之间的误差，并乘以一个权重系数。非完整性运动学包括两种类型：正交和非正交。正交类型指的是机器人只能沿着自身坐标系的x轴或y轴移动，不能沿着其他方向移动；非正交类型指的是机器人可以沿着任意方向移动，但是需要满足一定的几何关系。例如，类似汽车的机器人就属于非正交类型，它需要满足转弯半径等于车长除以转向角正切的关系。权重系数越大，非完整性运动学约束越重要，对违反运动模型的情况惩罚越大；权重系数越小，非完整性运动学约束越不重要，对违反运动模型的情况惩罚越小。

- weight_kinematics_forward_drive: 前进驱动权重。这个参数表示在计算前进驱动约束时，使用的权重系数。前进驱动约束是一种限制机器人只能向前移动而不能向后移动的约束条件，它使用一个二次函数来计算机器人实际x方向速度与0之差的平方，并乘以一个权重系数。权重系数越大，前进驱动约束越重要，对向后移动的情况惩罚越大；权重系数越小，前进驱动约束越不重要，对向后移动的情况惩罚越小。
- weight_kinematics_turning_radius: 转弯半径权重。这个参数表示在计算转弯半径约束时，使用的权重系数。转弯半径约束是一种限制机器人不能超过最小转弯半径的约束条件，它使用一个二次函数来计算机器人实际转弯半径与最小转弯半径之差的平方，并乘以一个权重系数。权重系数越大，转弯半径约束越重要，对超过最小转弯半径的情况惩罚越大；权重系数越小，转弯半径约束越不重要，对超过最小转弯半径的情况惩罚越小。
- weight_optimaltime: 最优时间权重。这个参数表示在计算最优时间目标时，使用的权重系数。最优时间目标是一种反映机器人到达目标所需时间的目标函数，它使用一个线性函数来计算机器人实际到达目标所需时间，并乘以一个权重系数。权重系数越大，最优时间目标越重要，对到达目标时间越长的情况惩罚越大；权重系数越小，最优时间目标越不重要，对到达目标时间越长的情况惩罚越小。注意，这个参数必须大于0，否则会导致优化无解。
- weight_shortest_path: 最短路径权重。这个参数表示在计算最短路径目标时，使用的权重系数。最短路径目标是一种反映机器人到达目标所需距离的目标函数，它使用一个线性函数来计算机器人实际到达目标所需距离，并乘以一个权重系数。权重系数越大，最短路径目标越重要，对到达目标距离越长的情况惩罚越大；权重系数越小，最短路径目标越不重要，对到达目标距离越长的情况惩罚越小。
- weight_obstacle: 静态障碍物权重。这个参数表示在计算静态障碍物成本时，使用的权重系数。静态障碍物成本是一种反映机器人与静态障碍物之间距离的目标函数，它使用一个指数函数来计算机器人与静态障碍物之间距离的倒数，并乘以一个权重系数。指数函数的指数值由obstacle_cost_exponent参数给出。权重系数越大，静态障碍物成本越重要，对距离静态障碍物越近的情况惩罚越大；权重系数越小，静态障碍物成本越不重要，对距离静态障碍物越近的情况惩罚越小。
- weight_inflation: 静态障碍物膨胀权重。这个参数表示在计算静态障碍物膨胀成本时，使用的权重系数。静态障碍物膨胀成本是一种反映机器人与静态障碍物膨胀区域之间距离的目标函数，它使用一个指数函数来计算机器人与静态障碍物膨胀区域之间距离的倒数，并乘以一个权重系数。指数函数的指数值由obstacle_cost_exponent参数给出。权重系数越大，静态障碍物膨胀成本越重要，对距离静态障碍物膨胀区域越近的情况惩罚越大；权重系数越小，静态障碍物膨胀成本越不重要，对距离静态障碍物膨胀区域越近的情况惩罚越小。
- weight_dynamic_obstacle: 动态障碍物权重。这个参数表示在计算动态障碍物成本时，使用的权重系数。动态障碍物成本是一种反映机器人与动态障碍物之间距离的目标函数，它使用一个指数函数来计算机器人与动态障碍物之间距离的倒数，并乘以一个权重系数。指数函数的指数值由obstacle_cost_exponent参数给出。权重系数越大，动态障碍物成本越重要，对距离动态障碍物越近的情况惩罚越大；权重系数越小，动态障碍物成本越不重要，对距离动态障碍物越近的情况惩罚越小。注意，这个参数目前还没有被使用，因为动态障碍物信息还没有被纳入优化。
- weight_dynamic_obstacle_inflation: 动态障碍物膨胀权重。这个参数表示在计算动态障碍物膨胀成本时，使用的权重系数。动态障碍物膨胀成本是一种反映机器人与动态障碍物膨胀区域之间距离的目标函数，它使用一个指数函数来计算机器人与动态障碍物膨胀区域之间距离的倒数，并乘以一个权重系数。指数函数的指数值由obstacle_cost_exponent参数给出。权重系数越大，动态障碍物膨胀成本越重要，对距离动态障碍物膨胀区域越近的情况惩罚越大；权重系数越小，动态障碍物膨胀成本越不重要，对距离动态障碍物膨胀区域越近的情况惩罚越小。
- weight_viapoint: 通过点权重。这个参数表示在计算通过点目标时，使用的权重系数。通过点目标是一种反映机器人是否经过预设的通过点的目标函数，它使用一个二次函数来计算机器人实际经过点与预设通过点之间的欧几里得距离，并乘以一个权重系数。权重系数越大，通过点目标越重要，对偏离预设通过点的情况惩罚越大；权重系数越小，通过点目标越不重要，对偏离预设通过点的情况惩罚越小。
- weight_adapt_factor: 适应因子权重。这个参数表示在计算适应因子目标时，使用的权重系数。适应因子目标是一种反映机器人轨迹是否适应当前环境的目标函数，它使用一个线性函数来计算机器人轨迹上每个点与其最近障碍物之间距离的倒数，并乘以一个权重系数。权重系数越大，适应因子目标越重要，对距离障碍物越近的情况惩罚越大；权重系数越小，适应因子目标越不重要，对距离障碍物越近的情况惩罚越小。

```



```c
- Homotopy Class Planner: 这是一个子命名空间，用来定义同伦类规划相关的参数。同伦类规划是一种能够在复杂环境中寻找多条不同拓扑结构的轨迹的规划方法，它使用了一种基于图的方法来表示不同的同伦类，并使用一种基于签名的方法来判断两条轨迹是否属于同一个同伦类。
    - enable_homotopy_class_planning: 是否启用同伦类规划。这个参数表示是否使用同伦类规划方法来寻找多条不同拓扑结构的轨迹。如果为True，那么TEB算法会在每次规划时生成一个路线图，并从中选择最优的同伦类进行优化；如果为False，那么TEB算法只会优化当前最优的同伦类。
    - enable_multithreading: 是否启用多线程。这个参数表示是否使用多线程来加速同伦类规划过程。如果为True，那么TEB算法会在每次规划时创建多个线程，并将路线图中的不同节点分配给不同的线程进行计算；如果为False，那么TEB算法只会使用单线程进行计算。
    - max_number_classes: 最大同伦类数量。这个参数表示在每次规划时能够考虑的最大同伦类数量。这个参数可以限制TEB算法搜索空间的大小，避免生成过多无效或冗余的同伦类。如果为0或负数，则不限制同伦类数量。
    - selection_cost_hysteresis: 选择成本滞后系数。这个参数表示在选择最优同伦类时使用的滞后系数。这个参数可以防止TEB算法频繁地在不同的同伦类之间切换，提高稳定性。滞后系数越大，TEB算法越倾向于保持当前最优的同伦类；滞后系数越小，TEB算法越倾向于选择新出现的更优的同伦类。
    - selection_prefer_initial_plan: 选择偏好初始计划系数。这个参数表示在选择最优同伦类时使用的偏好初始计划系数。这个参数可以使TEB算法在选择同伦类时考虑与初始计划的相似度，避免产生过大的偏离。偏好初始计划系数越大，TEB算法越倾向于选择与初始计划更相似的同伦类；偏好初始计划系数越小，TEB算法越倾向于选择与初始计划更不相似的同伦类。
    - selection_obst_cost_scale: 选择障碍物成本比例系数。这个参数表示在选择最优同伦类时使用的障碍物成本比例系数。这个参数可以使TEB算法在选择同伦类时考虑障碍物成本的影响，避免产生过多的碰撞风险。障碍物成本比例系数越大，TEB算法越倾向于选择障碍物成本更小的同伦类；障碍物成本比例系数越小，TEB算法越倾向于选择障碍物成本更大的同伦类。
    - selection_alternative_time_cost: 是否选择替代时间成本。这个参数表示在选择最优同伦类时是否使用替代时间成本。替代时间成本是一种基于轨迹长度和速度限制的时间成本，它可以避免使用实际时间成本导致的局部最优问题。如果为True，那么TEB算法会使用替代时间成本来评价不同的同伦类；如果为False，那么TEB算法会使用实际时间成本来评价不同的同伦类。
    - roadmap_graph_no_samples: 路线图采样点数量。这个参数表示在每次规划时生成路线图时使用的采样点数量。采样点数量越多，路线图越密集，能够表示更多的同伦类；采样点数量越少，路线图越稀疏，能够表示更少的同伦类。
    - roadmap_graph_area_width: 路线图区域宽度。这个参数表示在每次规划时生成路线图时使用的区域宽度。区域宽度越大，路线图越宽，能够覆盖更多的空间；区域宽度越小，路线图越窄，能够覆盖更少的空间。
    - roadmap_graph_area_length_scale: 路线图区域长度比例系数。这个参数表示在每次规划时生成路线图时使用的区域长度比例系数。区域长度比例系数越大，路线图越长，能够延伸到更远的地方；区域长度比例系数越小，路线图越短，能够延伸到更近的地方。
    - h_signature_prescaler: 同伦签名预缩放系数。这个参数表示在计算同伦签名时使用的预缩放系数。同伦签名是一种用来判断两条轨迹是否属于同一个同伦类的方法，它使用一种基于积分和哈希的方法来生成一个唯一的签名，并根据签名进行比较。预缩放系数可以影响签名的敏感度和鲁棒性。预缩放系数越大，签名越敏感，对轨迹变化反应越快；预缩放系数越小，签名越鲁棒，对轨迹变化反应越慢。
    - h_signature_threshold: 同伦签名阈值。这个参数表示在比较同伦签名时使用的阈值。同伦签名是一种用来判断两条轨迹是否属于同一个同伦类的方法，它使用一种基于积分和哈希的方法来生成一个唯一的签名，并根据签名进行比较。阈值越大，比较越宽松，对轨迹变化容忍度越高；阈值越小，比较越严格，对轨迹变化容忍度越低。
    - obstacle_heading_threshold: 障碍物朝向阈值。这个参数表示在计算障碍物对轨迹的影响时使用的阈值。障碍物对轨迹的影响是一种反映机器人与障碍物之间相对朝向的因子，它使用一个余弦函数来计算机器人与障碍物之间的夹角，并乘以一个权重系数。阈值越大，障碍物对轨迹的影响越小，对朝向不一致的情况惩罚越小；阈值越小，障碍物对轨迹的影响越大，对朝向不一致的情况惩罚越大。
    - switching_blocking_period: 切换阻塞周期。这个参数表示在切换最优同伦类时使用的阻塞周期。阻塞周期是一种用来避免频繁切换同伦类导致不稳定的机制，它使用一个时间窗口来限制切换同伦类的频率。如果在时间窗口内已经发生了一次切换，那么在时间窗口结束之前不会再发生切换。阻塞周期越大，切换同伦类的频率越低，稳定性越高；阻塞周期越小，切换同伦类的频率越高，稳定性越低。
    - viapoints_all_candidates: 是否考虑所有通过点候选。这个参数表示在选择最优同伦类时是否考虑所有通过点候选。通过点候选是一种用来增加同伦类多样性的方法，它使用一种基于路线图的方法来生成不同的通过点，并将它们作为同伦类规划的约束条件。如果为True，那么TEB算法会考虑所有通过点候选，并根据它们与全局路径中预设通过点的距离来评价不同的同伦类；如果为False，那么TEB算法只会考虑最近的通过点候选。
    - delete_detours_backwards: 是否删除后退绕路。这个参数表示在优化轨迹时是否删除后退绕路。后退绕路是一种由于优化过程中产生了不合理的拐弯导致轨迹向后延伸或回环的现象，它会增加轨迹长度和时间，并降低效率和安全性。如果为True，那么TEB算法会检测并删除后退绕路；如果为False，那么TEB算法不会检测或删除后退绕路。
    - max_ratio_detours_duration_best_duration: 最大绕路持续时间比例。这个参数表示在优化轨迹时使用的最大绕路持续时间比例。绕路持续时间比例是一种用来衡量轨迹是否有过多绕路的指标，它使用一个比值来计算当前轨迹持续时间与最佳轨迹持续时间的比例。最佳轨迹持续时间是一种基于轨迹长度和速度限制的时间估计，它可以避免使用实际时间成本导致的局部最优问题。如果绕路持续时间比例超过最大绕路持续时间比例，那么TEB算法会认为当前轨迹有过多绕路，并尝试重新初始化轨迹。
    - visualize_hc_graph: 是否可视化同伦类图。这个参数表示是否将同伦类图的信息发布到一个主题上，以便用rviz或其他工具进行可视化。同伦类图是一种用来表示不同同伦类之间的关系的图结构，它使用节点来表示同伦类，使用边来表示同伦类之间的转换。如果为True，那么TEB算法会将同伦类图的信息发布到/teb_local_planner/homotopy_class_graph这个主题上；如果为False，那么TEB算法不会发布同伦类图的信息。
    - visualize_with_time_as_z_axis_scale: 是否使用时间作为z轴比例。这个参数表示是否在可视化轨迹时使用时间作为z轴比例。如果为True，那么TEB算法会将轨迹上每个点的时间作为z轴坐标，并乘以一个缩放系数；如果为False，那么TEB算法不会使用时间作为z轴比例。

```



```
- shrink_horizon_backup: 是否启用收缩视野备份。这个参数表示是否在优化失败时使用一种收缩视野的方法来恢复。收缩视野的方法是一种将轨迹长度缩短到一定比例的方法，它可以避免一些由于轨迹过长导致的不可行或不稳定的情况。如果为True，那么TEB算法会在优化失败时尝试收缩视野；如果为False，那么TEB算法不会尝试收缩视野。
- shrink_horizon_min_duration: 收缩视野最小持续时间。这个参数表示在收缩视野时使用的最小持续时间。最小持续时间是一种限制轨迹长度不能低于一定时间的条件，它可以避免轨迹过短导致的不准确或不连续的情况。最小持续时间越大，收缩视野后的轨迹越长；最小持续时间越小，收缩视野后的轨迹越短。
- oscillation_recovery: 是否启用震荡恢复。这个参数表示是否在检测到震荡时使用一种震荡恢复的方法来恢复。震荡恢复的方法是一种将机器人速度设置为零或反向的方法，它可以避免一些由于机器人在障碍物附近来回摆动导致的震荡现象。如果为True，那么TEB算法会在检测到震荡时尝试震荡恢复；如果为False，那么TEB算法不会尝试震荡恢复。
- oscillation_v_eps: 震荡速度阈值。这个参数表示在检测震荡时使用的速度阈值。速度阈值是一种判断机器人是否发生震荡的条件，它使用一个绝对值来比较机器人当前速度与上一次速度的差异。如果差异超过阈值，那么TEB算法会认为机器人发生了震荡；如果差异低于阈值，那么TEB算法不会认为机器人发生了震荡。
- oscillation_omega_eps: 震荡角速度阈值。这个参数表示在检测震荡时使用的角速度阈值。角速度阈值是一种判断机器人是否发生震荡的条件，它使用一个绝对值来比较机器人当前角速度与上一次角速度的差异。如果差异超过阈值，那么TEB算法会认为机器人发生了震荡；如果差异低于阈值，那么TEB算法不会认为机器人发生了震荡。
- oscillation_recovery_min_duration: 震荡恢复最小持续时间。这个参数表示在震荡恢复时使用的最小持续时间。最小持续时间是一种限制机器人保持零速度或反向速度的时间的条件，它可以避免机器人过早地恢复正常速度导致再次发生震荡。最小持续时间越大，震荡恢复后的停顿或后退时间越长；最小持续时间越小，震荡恢复后的停顿或后退时间越短。
- oscillation_filter_duration: 震荡滤波持续时间。这个参数表示在检测震荡时使用的滤波持续时间。滤波持续时间是一种限制机器人在一定时间内不再检测震荡的条件，它可以避免机器人在震荡恢复后立即又被检测到震荡导致的反复恢复。滤波持续时间越大，机器人在震荡恢复后不再检测震荡的时间越长；滤波持续时间越小，机器人在震荡恢复后不再检测震荡的时间越短。

```







# 路径规划

# 局部路径规划

> https://blog.csdn.net/weixin_44504228/article/details/117673333

总结：计算能力差的用DWA，能力好的用TEB



# 地图保存

首先在自定义的导航功能包下新建 map 目录，用于保存生成的地图数据。地图保存的语法比较简单，编写一个launch文件，内容如下:

```xml
<launch>
    <arg name="filename" value="$(find nav)/map/nav" />
    <node name="map_save" pkg="map_server" type="map_saver" args="-f $(arg filename)" />
</launch>
Copy
```

其中通过 filename 指定了地图的保存路径以及保存的文件名称。

SLAM建图完毕后，执行该launch文件即可。

**测试:**

首先，参考上一节，依次启动仿真环境，键盘控制节点与SLAM节点；

然后，通过键盘控制机器人运动并绘图；

最后，通过上述地图保存方式保存地图。

结果：在指定路径下会生成两个文件，xxx.pgm 与 xxx.yaml



或者使用命令行：

```bash
rosrun map_server map_saver -f  ~/racecar/src/racecar/map/mymap
```





**读取地图**

通过 map_server 的 map_server 节点可以读取栅格地图数据，编写 launch 文件如下:

```xml
<launch>
    <!-- 设置地图的配置文件 -->
    <arg name="map" default="nav.yaml" />
    <!-- 运行地图服务器，并且加载设置的地图-->
    <node name="map_server" pkg="map_server" type="map_server" args="$(find mycar_nav)/map/$(arg map)"/>
</launch>
Copy
```

其中参数是地图描述文件的资源路径，执行该launch文件，该节点会发布话题:map(nav_msgs/OccupancyGrid)，最后，在 rviz 中使用 map 组件可以显示栅格地图。





# 多点导航

> [zhihu](https://zhuanlan.zhihu.com/p/413587126)

move_base实现导航的方式是读取一个geometry_msgs/PoseStamped数据类型的话题，并作为action的goal完成。实现多点导航就是发送一个点，完成后发下一个点



```c++
#include <ros/ros.h>
#include <move_base_msgs/MoveBaseAction.h>
#include <actionlib/client/simple_action_client.h>
#include<iostream>
using namespace std;

typedef actionlib::SimpleActionClient<move_base_msgs::MoveBaseAction> MoveBaseClient;
int main(int argc, char** argv){
    ros::init(argc, argv, "send_goals_node");
    MoveBaseClient ac("move_base", true);
    uint8_t goal_number = 4;

    while(!ac.waitForServer( ros::Duration( 5.0 ) )){
        ROS_INFO("Waiting for the move_base action server to come up");
    }
    move_base_msgs::MoveBaseGoal goal[4];

    // 第一个待发送的 目标点 在 map 坐标系下的坐标位置
    goal[0].target_pose.pose.position.x = 1.84500110149;
    goal[0].target_pose.pose.position.y =  -0.883078575134;
    goal[0].target_pose.pose.orientation.z =  -0.306595935327;  
    goal[0].target_pose.pose.orientation.w = 0.951839761956;  

    // 第二个待发送的 目标点 在 map 坐标系下的坐标位置
    goal[1].target_pose.pose.position.x = 3.24358606339;
    goal[1].target_pose.pose.position.y = 0.977679371834;
    goal[1].target_pose.pose.orientation.z = 0.647871240469;  
    goal[1].target_pose.pose.orientation.w = 0.761749864308;  

    // 第三个待发送的 目标点 在 map 坐标系下的坐标位置
    goal[2].target_pose.pose.position.x = 2.41693687439;
    goal[2].target_pose.pose.position.y = 1.64631867409;
    goal[2].target_pose.pose.orientation.z = 0.988149484601;  
    goal[2].target_pose.pose.orientation.w = 0.153494612555;  

    // 第四个待发送的 目标点 在 map 坐标系下的坐标位置
    goal[3].target_pose.pose.position.x =-0.970185279846;
    goal[3].target_pose.pose.position.y = 0.453477025032;
    goal[3].target_pose.pose.orientation.z = 0.946238058267;  
    goal[3].target_pose.pose.orientation.w = -0.323471076121;  

    ROS_INFO(" Init success!!! ");
    while(goal_number )    // total is 4 goals
    {
        switch( (4 - goal_number) ){
            case 0:
                     goal[4 -goal_number].target_pose.header.frame_id = "map";
                     goal[4 -goal_number].target_pose.header.stamp = ros::Time::now();
                     ac.sendGoal(goal[4 -goal_number]);
                     ROS_INFO("Send NO. %d Goal !!!", 4-goal_number );
                break;
            case 1:
                     goal[4 -goal_number].target_pose.header.frame_id = "map";
                     goal[4 -goal_number].target_pose.header.stamp = ros::Time::now();
                     ac.sendGoal(goal[4 -goal_number]);
                     ROS_INFO("Send NO. %d Goal !!!", 4-goal_number );
                break;
            case 2:
                     goal[4 -goal_number].target_pose.header.frame_id = "map";
                     goal[4 -goal_number].target_pose.header.stamp = ros::Time::now();
                     ac.sendGoal(goal[4 -goal_number]);
                     ROS_INFO("Send NO. %d Goal !!!", 4-goal_number );
                break;
            case 3:
                     goal[4 -goal_number].target_pose.header.frame_id = "map";
                     goal[4 -goal_number].target_pose.header.stamp = ros::Time::now();
                     ac.sendGoal(goal[4 -goal_number]);
                     ROS_INFO("Send NO. %d Goal !!!", 4-goal_number );
                break;
            default:
                break;
        }
        ac.waitForResult();
        if(ac.getState() == actionlib::SimpleClientGoalState::SUCCEEDED){
            ROS_INFO("The NO. %d Goal achieved success !!!", 4-goal_number );
            goal_number -- ;
        }else{ROS_WARN("The NO. %d Goal Planning Failed for some reason",4-goal_number); }
    }
  return 0;}
```

---

## 📚 扩展阅读

### 官方文档
- [相关官方文档链接]()

### 学习资源
- [推荐教程]()
- [示例代码]()

### 常见问题
1. **问题描述**
   解决方案

## 🛠️ 实践建议

1. **学习路径**
2. **实践项目**
3. **调试技巧**

> 最后更新: 2026-02-27 | 由OpenClaw优化
