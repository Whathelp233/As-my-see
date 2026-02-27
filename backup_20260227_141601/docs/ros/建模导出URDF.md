# 建模导出URDF
> 更新时间: 2026年02月27日

> 对于脚本无法处理的模型转URDF，需要手动建立URDF模型

对于一个urdf，属性设置的顺序是link<inertial>->joint->link<visual>/<collision>

以这种方式设置一个link后再设置这个link的子link



[ROS wiki-如何写xml](http://wiki.ros.org/urdf/XML)



# Fusion360

> 我们需要在fusion中获取模型零部件的属性填入之后的urdf中，选中所需要的零部件右键属性后可以分析出物理数据

# 注意：

- base_link的位置是排除轮子后的车体质心位置
- 算惯性矩可以使用乘法 *1e-9 简化操作，其他地方类似，和python语法一样
- 尽量使用碰撞箱包裹link，因为stl的碰撞面复杂得多，仿真会变卡变复杂
- stl的scale原来是0.001，这主要是为了和机械给的米制stl匹配，现在应该让机械出毫米制stl并删去scale参数

```
<geometry>
	<mesh filename="package://rm_description/meshes/balance/wheel.stl" scale="0.001 .001 0.001"/>
</geometry>

===变为====
                <geometry>
                    <mesh filename="package://rm_description/meshes/balance/wheel.stl"/>
                </geometry>
```



# Link

> link是机器人的单位实体，因为过大的stl文件会极大影响运行效果，所以需要对机器人的模型进行简化并保留关键部分以让单个stl文件大小小于2MB

一个link的举例：

```
<link name="trigger">
    <inertial>
        <mass value="0.952"/>
        <origin xyz="-0.012227 -0.000055 0.010137"/>
        <inertia ixx="8.90e-4" ixy="2.012e-6" ixz="1.911e-4" iyy="1.768e-3"
                 iyz="-7.72e-7" izz="2.067e-3"/>
    </inertial>
    <visual>
        <origin xyz="0 0 0" rpy="0 0 0"/>
        <geometry>
            <mesh filename="package://rm_description/meshes/standard/trigger.stl" scale="0.001 0.001 0.001"/>
        </geometry>
    </visual>
    <collision>
        <origin xyz="0 0 0" rpy="0 0 0"/>
        <geometry>
            <mesh filename="package://rm_description/meshes/standard/trigger.stl" scale="0.001 0.001 0.001"/>
        </geometry>
    </collision>
</link>
```



# inertial

> inertial描述了部件的质量，质心位置以及惯性，对于保留模型核心部分的link，它的质量，质心和惯性依然需要以完整体为准。也就是说简化的只是外观的视觉和碰撞部分。

注意：

- mass的单位是kg，origin单位是m，inertia的值要在fusion360给出的值的基础上乘以`10^-9`，例如689.2 -> 6.892E-07

- 所有质心的origin坐标，inertia惯性是相对于一个joint的(自己处于子link时的所对应的joint)。fusion会提供相对于质心的惯性和相对于原点的惯性，请选择相对于质心的惯性

- 所有joint的origin是相对于父joint的坐标(该joint的父link在作为子link时的joint)

- stl文件出的时候需要将模型单独放在一个原点下并进行偏移，直接在机器人模型上出stl会有位移，从而导致需要修改视觉和碰撞。因此在衍生模型后需要通过偏移让joint点(该link作为子link时对应的joint)移到原点(在原模型中计算joint到原点的偏移量)

- 代码中的参数和仿真的参数不一样。在仿真中，世界原点是整车去除轮子后的质心，因此轮子，底盘和云台yaw的质心需要设置相对于这个质心的偏移(也就是xx相对于质心的偏移)，第一级的link例如轮子的stl和底盘的stl以自己的质心为原点，所以在urdf中需要在认为整车去除轮子后的质心为世界原点的基础上填入底盘，轮子自己质心的偏移; 第二级的yaw的stl则以旋转中心yaw_joint为原点，指明自己的质心相对于yaw_joint的偏移，需要注意yaw_joint的偏移是相对与整车去除轮子质心的偏移

  总之，第一级link base_link没有父joint，或者说世界原点就是父joint，你需要在出他们的stl时以整车去除轮子为世界原点，然后在inerial属性填base_link质心相对于整车去除轮子质心的偏移
  
  

# visual

> link的视觉部分，在填入inertia和joint后再调整，因为只涉及外观，优先度不高



# collision

> link的碰撞部分，通常和视觉部分一样，在填入inertia和joint后再调整，因为只涉及仿真的碰撞，优先度不高





# Joint

> 连接link的关节，以父link相对于父父link关节的位置为相对位置

```
<joint name="pitch_joint" type="revolute">
    <origin xyz="0 0 0.1772" rpy="${pi} ${pi} ${pi}"/>
    <dynamics damping="0.0" friction="0.1"/>
    <limit effort="1.2" velocity="13.82" lower="${pitch_lower_limit}" upper="${pitch_upper_limit}"/>
    <safety_controller k_velocity="0.1"
                       k_position="100"
                       soft_lower_limit="${pitch_lower_limit+threshold}"
                       soft_upper_limit="${pitch_upper_limit-threshold}"/>
    <parent link="yaw"/>
    <child link="pitch"/>
    <axis xyz="0 1 0 "/>
</joint>
```

例如 link1通过joint1相对于base_link旋转；link2通过joint2相对于link1旋转，则joint2的坐标的xyz是相对于joint1位置的偏移量

> 有些机器人建模需要baselink，有的不用，好奇有什么影响。
>
> 如果想发tf的话是需要base_link的



# Gazebo

gazebo中需要检查质心位置，模型位置

# 用 check_urdf 检查

在编写完 urdf 代码后，先使用 check_urdf 来检查是否出现报错。

# 检查坐标系

打开 gazebo ，勾选 **Edit | Reset World Pose** 将机器人还原为初始位置以及状态，然后再勾选 **View | Trasnparent** 将机器人的模型透明化，

完成后勾选 **View | Link Frames** 检查坐标系朝向是否正确。

- 注意urdf中【rpy的旋转顺序是z，x，y轴

# 检查惯性矩

在 gazebo 中勾选 **View | inertia** 查看惯性矩是否正确，检查前要确保质心位置是否准确以及质量大小是否准确，检查标准：

- 粉色立方体是否将模型基本包裹住
- 假如质心不在模型的几何中心，那么粉色立方体应该偏向质心位置。

# 检查碰撞箱

勾选  **View | collision**  检查碰撞箱是否基本将模型包裹住。



# 并联机构

> URDF不支持并联机构，我们可以综合运用gazebo自己的joint来实现并联
>
> https://github.com/2b-t/closed_loop
>
> https://github.com/PR2/pr2_common/blob/melodic-devel/pr2_description/urdf/gripper_v0/gripper.gazebo.xacro

```urdf
<gazebo>
    <joint name="right_connect_joint" type="revolute">
        <parent>right_front_second_leg</parent>
        <child>right_back_second_leg</child>
        <axis>
            <xyz>0 1 0</xyz>
            <dynamics> (这一段也许会影响运行可以去掉)
                <damping>0.01</damping>
            </dynamics>
        </axis>
        <pose>$0 0 0 0 0 0</pose> (x y z r p y)
    </joint>
</gazebo>
```



#  为模型添加纹理

> https://answers.gazebosim.org//question/4761/how-to-build-a-world-with-real-image-as-ground-plane/

You can create a material script, and then use that material script on a ground plane.

1. Create a new model directory:

   mkdir ~/.gazebo/models/my_ground_plane

2. Create the materials directories:

   mdkir -p ~/.gazebo/models/my_ground_plane/materials/textures mdkir -p ~/.gazebo/models/my_ground_plane/materials/scripts

3. Create your material script file `~/.gazebo/models/my_ground_plane/materials/scripts/my_ground_plane.material` with the following contents:

```
    material MyGroundPlane/Image
    {
      technique
      {
        pass
        {
          ambient 0.5 0.5 0.5 1.0
          diffuse 1.0 1.0 1.0 1.0
          specular 0.0 0.0 0.0 1.0 0.5

          texture_unit
          {
            texture MyImage.png
            filtering trilinear
          }
        }
      }
    }
```

1. Copy your image to `~/.gazebo/models/my_ground_plane/materials/textures/MyImage.png`

2. Create a `~/.gazebo/models/my_ground_plane/model.sdf` file with the following contents

   ```
   <?xml version="1.0"?>
   <sdf version="1.4">
   <model name="my_ground_plane">
     <static>true</static>
       <link name="link">
         <collision name="collision">
           <geometry>
             <plane>
               <normal>0 0 1</normal>
               <size>100 100</size>
             </plane>
           </geometry>
           <surface>
             <friction>
               <ode>
                 <mu>100</mu>
                 <mu2>50</mu2>
               </ode>
             </friction>
           </surface>
         </collision>
         <visual name="visual">
           <cast_shadows>false</cast_shadows>
           <geometry>
             <plane>
               <normal>0 0 1</normal>
               <size>100 100</size>
             </plane>
           </geometry>
           <material>
             <script>
               <uri>model://my_ground_plane/materials/scripts/my_ground_plane.material</uri>
               <name>MyGroundPlane/Image</name>
             </script>
           </material>
         </visual>
       </link>
     </model>
   </sdf>
   ```

3. Create a `~/.gazebo/models/my_ground_plane/model.config` file with the following contents


   <model> <name>My Ground Plane</name> <version>1.0</version> <sdf version="1.4">model.sdf</sdf>

   ```
   <description>
     My textured ground plane.
   </description>
   ```

   </model>

4. In your world SDF file, use your ground plane like so:

   ```
   <include>
     <uri>model://my_ground_plane</uri>
   </include>
   ```





# 注意点

- 如果碰撞箱给大小为0,则会导致stl文件显示不出来





# Transmission

# 减速比

电机+同步带+丝杆

电机转一圈(3.14*2)对应同步带的减速比(12比50)，同步带转一圈对应的丝杆的前进距离(一圈前进1.5mm[导程])

```c
同步带：输入转50圈，输出转12圈
丝杆：输入一圈前进1.5mm，换算国际单位则前进0.0015m，前进1m需要666.66圈，丝杆的减速比为666.66
```

错误的：

3.14×2 * (12/50) x (1/(1.5/100)) = 3.14x2x12/50x666.66



正确的：

1 / [(3.14x2 * 12/50 * 0.0015) /  (3.14×2)] = 2777.77

```c
分析：
    减速比：电机屁股转一圈，丝杆前进了a米，减速比为1/a
式子表示电机屁股转了一圈，丝杆前进了（12/50 * 0.0015）米，对这个值取倒数得到减速比
    前面算错是因为没有把两个的减速比相乘，“前进1m需要666.66圈，丝杆的减速比为666.66”，同时“输入转50圈，输出转12圈”减速比应该为50/12,所以应该是666.66 × 50/12而不是666.66 x 12/50。
```

思路就一个，`第一级的输入/输出 × 第二级的输入/输出` 后取倒数或者直接 `第一级的输出/输入 / 第二级的输出/输入`ope
