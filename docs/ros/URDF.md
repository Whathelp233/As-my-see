# URDF总览
> 更新时间: 2026年02月27日

> 属性：https://www.guyuehome.com/36082

# 简单link示例

``` c++
<?xml version="1.0"?>
<robot name="rbo" xmlns:xacro="http://www.ros.org/wiki/xacro">
    <link name="car_link">
//visual标签：这表示着我们是否可以在图形界面上观察到这个link，没有的话就观察不到，主要包含geometry标签
        <visual>
            <geometry>
                <box size="2.0 1.0 0.5"/>
            </geometry>
        </visual>
//collision标签：这表示着传感器(主要指激光等投射型的传感器)是否可以在物理引擎上检测到这个link，同时标志着是否会与别的link进行碰撞检测，也主要包含geometry标签
    
        <collision>
            <geometry>
                <box size="2.0 1.0 0.5"/>
            </geometry>
        </collision>
    </link>
</robot>
————————————————
https://blog.csdn.net/wubaobao1993/article/details/80947968
```

另有：

  inertial标签：这表示着**物理引擎**是否能够感受到link的存在，主要包含3个标签： 

- origin：link重心的位置
- mass：link的重量
- inertia：link的旋转惯量

``` 
由于在gazebo中，机器人节点的驱动主要靠物理引擎，该标签极为重要
```

> 载入模型命令
>
> roslaunch urdf_tutorial display.launch model:=rbo.urdf.xacro





# 宏定义文件xacro

> 经常需要重复使用的link（例如轮子），可以使用xacro在保证代码完整性的同时提高效率和简化代码量
>
> http://wiki.ros.org/urdf/XML/link



![](http://wiki.ros.org/urdf/XML/link?action=AttachFile&do=get&target=inertial.png)





# geometry标签

>  **<geometry>** *(required)*
>
> > **<box>** 
> >
> > - **size** attribute contains the three side lengths of the box. The origin of the box is in its center. 
> >
> > **<cylinder>** 
> >
> > - Specify the **radius** and **length**. The origin of the cylinder is in its center. ![cylinder_coordinates.png](http://wiki.ros.org/urdf/XML/link?action=AttachFile&do=get&target=cylinder_coordinates.png) 
> >
> > **<sphere>** 
> >
> > - Specify the **radius**. The origin of the sphere is in its center. 
> >
> > **<mesh>** 
> >
> > - 自定义模型文件，它必须是本地文件。在文件名前面加package://<packagename>/<path>
> > - 例 <mesh filename="package://robot_description/meshes/base_link.DAE"/>



# visual标签

> **<visual>** *(optional)*
>
> > **name** *(optional)* 
> >
> > - Specifies a name for a part of a link's geometry. This is useful to be able to  refer to specific bits of the geometry of a link. 
> >
> > **<origin>** *(optional: defaults to identity if not specified)* 
> >
> > - 说明视觉元素相对于关联物块位置
> >
> >   
> >
> >   **xyz** *(optional: defaults to zero vector)* 
> >
> >   - 表示**x**、**y**、**z**偏移量。
> >
> >   **rpy** *(optional: defaults to identity if not specified)* 
> >
> >   -  以弧度表示固定轴滚动、俯仰和偏航角度。 
> >
> > **<geometry>** *(required)* 
> >
> > 可以通过xacro:macro预先定义该标签
> >
> > - The shape of the visual object. This can be *one* of the following: 
> >
> > - **<box>** 
> >
> >   - **size** attribute contains the three side lengths of the box. The origin of the box is in its center. 
> >
> >   **<cylinder>** 
> >
> >   - Specify the **radius** and **length**. The origin of the cylinder is in its center. ![cylinder_coordinates.png](http://wiki.ros.org/urdf/XML/link?action=AttachFile&do=get&target=cylinder_coordinates.png) 
> >
> >   **<sphere>** 
> >
> >   - Specify the **radius**. The origin of the sphere is in its center. 
> >
> >   **<mesh>** 
> >
> >   - -------
> >
> > **<material>** *(optional)* 
> >
> > - The material of the visual element. It is allowed to specify a material  element outside of the 'link' object, in the top level 'robot' element.  From within a link element you can then reference the material by name. 
> >
> > - **name** name of the material 
> >
> > - **<color>** *(optional)* 
> >
> >   - **rgba** The color of a material specified by set of four numbers representing red/green/blue/alpha, each in the range of [0,1]. 
> >
> >   **<texture>** *(optional)* 
> >
> >   - The texture of a material is specified by a **filename**





# collision标签

link的碰撞属性

> **<collision>** *(optional)*
>
> > **name** *(optional)* 
> >
> > - Specifies a name for a part of a link's geometry. This is useful to be able to  refer to specific bits of the geometry of a link. 
> >
> > **<origin>** *(optional: defaults to identity if not specified)* 
> >
> > - 该碰撞元素的参考系
> >
> >   
> >
> >   **xyz** *(optional: defaults to zero vector)* 
> >
> >   - Represents the **x**, **y**, **z** offset. 
> >
> >   **rpy** *(optional: defaults to identity if not specified)* 
> >
> >   - Represents the fixed axis roll, pitch and yaw angles in radians. 
> >
> > **<geometry>** 
> >
> > - See the geometry description in the above visual element. 







``` c++
举例
    <?xml version="1.0"?>
 //首先我们要告诉robot我们要用xacro，也就是在robot的标签中添加:
    <robot name="rbo" xmlns:xacro="http://www.ros.org/wiki/xacro"> //
 //定义一个宏定义的值
    <xacro:property name="PI" value="3.1415926"/>
    <xacro:property name="car_width" value="1.0"/>
    <xacro:property name="car_length" value="2.0"/>
    <xacro:property name="car_height" value="0.4"/>

 //定义一个宏定义，名称是name后的字符串，参数在param后面，多参数可用空格隔开
    <xacro:macro name="default_inertial" params="mass">
      <inertial>
        <mass value="${mass}" />
        <inertia ixx="1.0" ixy="0.0" ixz="0.0" iyy="1.0" iyz="0.0" izz="1.0" />
      </inertial>
    </xacro:macro>
        
    <xacro:macro name="box_geometry" params="width length height">
        <geometry>
            <box size="${width} ${length} ${height}"/>
        </geometry>
    </xacro:macro>

    <link name="car_link">
        <visual>
            <xacro:box_geometry width="${car_width}" length="${car_length}" height="${car_height}"/>
        </visual>
        <collision>
            <xacro:box_geometry width="${car_width}" length="${car_length}" height="${car_height}"/>
        </collision>
        <xacro:default_inertial mass="5.0"/>
    </link>
</robot>

```





# Joint

Joint和ros的控制器获取位置信息有关，类似于link，要想让joint工作，你必须声明它所必须的标签，主要包括下面的主要标签：
1.name：标签的名称
2.type：指明这个标签的类型，主要有以下的属性

    旋转（revolute） - 具有由上限和下限指定的有限范围，例如机械臂上的肘关节。
    连续（continuous） - 绕轴旋转，没有上限和下限，例如底盘上的轮子
    棱柱形（prismatic） - 滑动接头，沿轴线滑动，并具有由上限和下限指定的有限范围，例如某个关节是丝杆连接
    固定（fixed） - 所有自由度都被锁定，比如你把摄像头用3M胶粘在了底盘上，那么这个关节就是固定的
    浮动 - 此关节允许所有6个自由度的运动，这个着实不好举例，6个自由度都可以运动的话总感觉这个关节好像只是一个约束一样
    平面 - 此关节允许在垂直于轴的平面内运动，用的比较少

3.parent：这个关节的一端，称为父端
4.child：这个关节的另一端，称为子端
5.origin：父端与子端的初始transform，例如相机的坐标系与底盘的坐标系方向相同，但是在x方向上差了0.1m，那么就在这个标签上填充上相应的值，该标签默认的值是两个质心是完全重合的。
6.axes：旋转轴，type标签里面反复提到的旋转轴就是这个标签，它指示了绕什么轴进行旋转，例如绕父节点的z轴旋转，那么该标签的值就为xyz=“0 0 1”
7.limit：有限值旋转类型必备标签，指示旋转所能到到的上下限 

```c
//申明type为continuous
<joint name="car_base_wheel" type="continuous">
    //轮子在方块中间
        <origin xyz="${(wheel_length+car_width)/2.0} 0.0 0.0" rpy="0.0 0.0 0.0"/>
    //父端
        <parent link="car_link"/>
    //子端
        <child link="wheel"/>
    //旋转轴
        <axis xyz="0.0 1.0 0.0"/>
 </joint>

```



- 通常机器人有高度，因此需要设置base_link一般都是与机器人最下方的link进行固定连接

``` CC
    <!-- base_link -->
    <link name="base_link"/>
    <joint name="base_link_car" type="fixed">
        <origin xyz="0.0 0.0 ${wheel_radius}" rpy="0.0 0.0 0.0"/>
        <parent link="base_link"/>
        <child link="car_link"/>
    </joint>
```

![image-20220205203501484](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220205203501484.png)

``` R
                                      如图，base_link被设置在了正方体下面 
```





# Gazebo属性

gazebo能够添加更多的关于物件的属性，例如表面摩擦系数

```c 
<!-- gazebo -->
<gazebo reference="car_link">
    //为上面的car_link添加木质地板色泽(仅显示在gazebo，rviz不显示)
    <material>Gazebo/WoodFloor</material>
    //添加摩擦系数
    <mu1>0.5</mu1>
    <mu2>0.5</mu2>
</gazebo>
```



除了mu1，mu2还有其他的属性标签：

![link gazebo](https://img-blog.csdn.net/20180708174346296?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3d1YmFvYmFvMTk5Mw==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

作用于joint的gazebo标签：

![这里写图片描述](https://img-blog.csdn.net/20180708180610275?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3d1YmFvYmFvMTk5Mw==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)





# Transmissions

针对joint打上执行器标签，详情参考**URDFTransmissions**文档



上述综合参考代码：

``` c
<?xml version="1.0"?>
<robot name="rbo" xmlns:xacro="http://www.ros.org/wiki/xacro">
    <!-- variable -->
    <xacro:property name="PI" value="3.1415926"/>
    <xacro:property name="car_width" value="1.0"/>
    <xacro:property name="car_length" value="2.0"/>
    <xacro:property name="car_height" value="0.3"/>
    <xacro:property name="wheel_length" value="0.13"/>
    <xacro:property name="wheel_radius" value="0.25"/>
    <xacro:property name="wheel_origin_xyz" value="0.0 0.0 0.0"/>
    <xacro:property name="wheel_origin_rpy" value="0.0 ${PI/2} 0.0"/>

    <!-- rviz color -->
    <material name="blue">
        <color rgba="0 0 1 1"/>
    </material>

    <material name="black">
        <color rgba="0 0 0 1"/>
    </material>

    <!-- macro -->
    <xacro:macro name="default_inertial" params="mass">
        <inertial>
            <mass value="${mass}" />
            <inertia ixx="1.0" ixy="0.0" ixz="0.0" iyy="1.0" iyz="0.0" izz="1.0" />
        </inertial>
    </xacro:macro>

    <xacro:macro name="box_geometry" params="width length height">
        <geometry>
            <box size="${width} ${length} ${height}"/>
        </geometry>
    </xacro:macro>

    <xacro:macro name="cylinder_geometry" params="length radius">
        <geometry>
            <cylinder length="${length}" radius="${radius}"/>
        </geometry>
    </xacro:macro>

    <xacro:macro name="default_origin" params="xyz rpyaw">
        <origin xyz="${xyz}" rpy="${rpyaw}"/>
    </xacro:macro>

    <!-- links -->
    <link name="car_link">
        <visual>
            <xacro:box_geometry width="${car_width}" length="${car_length}" height="${car_height}"/>
            <material name="blue"/>
        </visual>
        <collision>
            <xacro:box_geometry width="${car_width}" length="${car_length}" height="${car_height}"/>
        </collision>
        <xacro:default_inertial mass="3.0"/>

    </link>

    <!-- gazebo -->
    <gazebo reference="car_link">
        <material>Gazebo/SkyBlue</material>
        <mu1>0.5</mu1>
        <mu2>0.5</mu2>
    </gazebo>

    <!-- wheel joint macro -->
    <!-- right:1 left:-1 -->
    <xacro:macro name="wheel_car_joint" params="wheel_name front_end left_right">
        <link name="${wheel_name}">
            <visual>
                <xacro:cylinder_geometry length="${wheel_length}" radius="${wheel_radius}"/>
                <xacro:default_origin xyz="${wheel_origin_xyz}" rpyaw="${wheel_origin_rpy}" />
                <material name="black"/>
            </visual>
            <collision>
                <xacro:cylinder_geometry length="${wheel_length}" radius="${wheel_radius}"/>
                <xacro:default_origin xyz="${wheel_origin_xyz}" rpyaw="${wheel_origin_rpy}" />
            </collision>
            <xacro:default_inertial mass="1.0"/>
        </link>

        <!-- joints -->
        <joint name="car_base_${wheel_name}" type="continuous">
            <origin xyz="${left_right*(wheel_length+car_width)/2.0} ${front_end*car_length*0.6/2.0} 0.0" rpy="0.0 0.0 0.0"/>
            <parent link="car_link"/>
            <child link="${wheel_name}"/>
            <axis xyz="0.0 1.0 0.0"/>
        </joint>

        <gazebo reference="${wheel_name}">
            <material>Gazebo/Black</material>
            <mu1>0.5</mu1>
            <mu2>0.5</mu2>
        </gazebo>

        <transmission name="${wheel_name}_transmission">
            <type>transmission_interface/SimpleTransmission</type>
            <joint name="car_base_${wheel_name}">
                <hardwareInterface>hardware_interface/VelocityJointInterface</hardwareInterface>
            </joint>
            <actuator name="${wheel_name}_motor">
                <mechanicalReducction>1</mechanicalReducction>
            </actuator>
        </transmission>
    </xacro:macro>

    <xacro:wheel_car_joint wheel_name="front_right_wheel" front_end="1.0" left_right="1.0"/>
    <xacro:wheel_car_joint wheel_name="front_left_wheel" front_end="1.0" left_right="-1.0"/>
    <xacro:wheel_car_joint wheel_name="end_right_wheel" front_end="-1.0" left_right="1.0"/>
    <xacro:wheel_car_joint wheel_name="end_left_wheel" front_end="-1.0" left_right="-1.0"/>

    <!-- base_link -->
    <link name="base_link"/>
    <joint name="base_link_car" type="fixed">
        <origin xyz="0.0 0.0 ${wheel_radius}" rpy="0.0 0.0 0.0"/>
        <parent link="base_link"/>
        <child link="car_link"/>
    </joint>

</robot>
```







# 附录

# 常见颜色RGBA表

**RGBA**是代表**R**ed（红色）**G**reen（[绿色](https://baike.baidu.com/item/绿色)）**B**lue（[蓝色](https://baike.baidu.com/item/蓝色)）和**A**lpha的色彩空间，**alpha通道**一般用作不透明度参数。

RGB颜色格式：#RRGGBB

(两个R代表了红色光，两个G代表了绿色光，两个B代表了蓝色光,RGB均用16进制数字表示) ,如#0000ff代表了0份红色光，0份绿色光和255份蓝色光。

> RGB常用颜色编码是24bit对齐R,G,B各元素各占8位，一个像素点具有R,G,B三个分量
>
> 白色RGB分别为255，255，255
>
> 青色RGB分别为0，255，255
>
> 黄色RGB分别为255，255，0
>
> 深红色RGB分别为255，0，255
>
> 蓝色RGB分别为0，0，255
>
> 绿色RGB分别为0，255，0
>
> 红色RGB分别为255，0，0
>
> 黑色RGB分别为0，0，0
>





> <material name="Black">
> 	<color rgba="0 0 0 1"/>
> </material>
> <material name="Yellow">
> 	<color rgba="255 255 0 1"/>
> </material>
> <material name="Green">
> 	<color rgba="0 255 0 1"/>
> </material>
> <material name="Red">
> 	<color rgba="255 0 0 1"/>
> </material>
> <material name="Blue">
> 	<color rgba="0 0 255 1"/>
> </material>
