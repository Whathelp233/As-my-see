# 坐标系、刚体变换与 TF

标定公式首先是一种坐标语句。两个相同的三元数，如果分别表示在传感器系和机器人系中，不能直接相加或比较。写清变换方向、旋转约定和时间戳，才能判断一个结果是否有物理意义。

## 1. 坐标系、点与方向

坐标系是一组带原点的正交基。空间中的点是几何对象；坐标则是该点相对某个坐标系原点和轴的数值表达。换坐标系时，同一个点的坐标会改变。方向向量只随旋转变化，不受平移影响；这在变换法线、速度方向和重力方向时很重要。

本文使用右手系和列向量，记

$$
T_{A\leftarrow B}
=\begin{bmatrix}R_{A\leftarrow B}&t_{A\leftarrow B}\\0&1\end{bmatrix}.
$$

它把 B 系坐标变成 A 系坐标：

$$
p_A=R_{A\leftarrow B}p_B+t_{A\leftarrow B}.
$$

平移 $t_{A\leftarrow B}$ 的几何意义是“B 原点在 A 系中的坐标”。如果 $T_{A\leftarrow B}$ 是传感器相对机器人基座的安装外参，那么它的平移不是基座原点在传感器中的坐标。

点的齐次坐标末项为 1；方向向量末项为 0。因此平移会作用于点，不会作用于方向。法线作为方向变换：$n_A=R_{A\leftarrow B}n_B$。

### 变换的复合和求逆

若 B 坐标先变到 A，再把 C 坐标变到 B，则

$$
T_{A\leftarrow C}=T_{A\leftarrow B}T_{B\leftarrow C}.
$$

乘法顺序应按相邻帧标记检查：内侧帧相同才可消去。刚体变换的逆为

$$
T_{A\leftarrow B}^{-1}=T_{B\leftarrow A}
=\begin{bmatrix}R^T&-R^Tt\\0&1\end{bmatrix}.
$$

逆平移一般不是 $-t$。一个实用的单位测试是：随机选点，经正向和逆向变换后回到原点，误差应接近浮点精度。

数组按“每行一个点”储存时，常见写法是 `points @ R.T + t`。它与上面的列向量等式一致；数组形状不同不代表坐标变换方向不同。

## 2. 旋转的常用表示

三维旋转组成特殊正交群 $SO(3)$：

$$
SO(3)=\{R\in\mathbb R^{3\times3}\mid R^TR=I,\det R=1\}.
$$

矩阵有 9 个数，却只有 3 个自由度。独立拟合 9 个元素会破坏正交性，因此优化时要使用合法的 3 自由度更新，或在求解后将矩阵投影回 $SO(3)$。

### 旋转矩阵和欧拉角

记 $R_x(\phi)$、$R_y(\theta)$、$R_z(\psi)$ 为绕各轴旋转。本文的固定轴 roll–pitch–yaw 约定是

$$
R=R_z(\psi)R_y(\theta)R_x(\phi).
$$

对列向量，右侧的 $R_x$ 先作用。欧拉角的顺序必须作为接口的一部分保存：库可能使用内旋/外旋名称、不同的轴序或不同角度单位。接近 pitch $\pm90^\circ$ 时会出现万向节锁；此时同一姿态可能对应不稳定或不唯一的欧拉角数值。检查姿态时应比较旋转本身，而不是只比较三个角。

### 单位四元数

按 Hamilton 乘法，单位四元数可写作 $q=(q_w,\mathbf q_v)$，满足 $q_w^2+\|\mathbf q_v\|^2=1$。绕单位轴 $u$ 旋转角 $\alpha$ 的四元数为

$$
q=\left(\cos\frac\alpha2,\ u\sin\frac\alpha2\right).
$$

若 $p$ 表示纯虚四元数 $(0,\mathbf p)$，主动旋转可写为 $p'=q\otimes p\otimes q^*$。旋转组合依赖乘法顺序，不能按分量逐项相加。

$q$ 与 $-q$ 表示同一个旋转。比较四元数前应先处理符号双覆盖，或计算相对旋转。给定 $R_1,R_2$，可用

$$
R_\Delta=R_2R_1^T,\qquad
\alpha_\Delta=\cos^{-1}\!\left(\operatorname{clip}\!\left(\frac{\operatorname{tr}(R_\Delta)-1}{2},-1,1\right)\right)
$$

得到最短旋转角。四元数接口还要确认分量顺序：ROS 消息通常按 xyzw 存储，而某些数学库的构造函数按 wxyz 传入。应以具体 API 文档为准，不能仅凭变量名猜测。

### 旋转向量与指数映射

旋转向量 $\phi=\alpha u$ 的方向是旋转轴，长度是旋转角。叉乘矩阵定义为

$$
[\phi]_\times=
\begin{bmatrix}0&-\phi_z&\phi_y\\\phi_z&0&-\phi_x\\-\phi_y&\phi_x&0\end{bmatrix}.
$$

Rodrigues 公式把旋转向量映射为旋转矩阵：

$$
\operatorname{Exp}([\phi]_\times)
=I+\frac{\sin\alpha}{\alpha}[\phi]_\times
+\frac{1-\cos\alpha}{\alpha^2}[\phi]_\times^2.
$$

在 $\alpha\to0$ 时用稳定的小角度展开，例如 $R\approx I+[\phi]_\times$。反向的 $\operatorname{Log}(R)$ 返回局部旋转向量，适合构造 3 维旋转残差；它不是欧拉角，也不能在大角度处忽略分支选择。

### 姿态平均

不应直接对欧拉角或未处理符号的四元数分量做算术平均。对于一组单位四元数 $q_i$ 和非负权重 $w_i\ge0$、$\sum_i w_i>0$，常用的符号不变平均是取

$$
M=\sum_i w_iq_iq_i^T
$$

的最大特征值所对应单位特征向量；$q_iq_i^T=(-q_i)(-q_i)^T$，所以该结果不受任意符号翻转影响。另一类方法是在 $SO(3)$ 上用相对旋转的对数迭代求均值。两者优化的距离定义不同，不应混称为唯一“正确平均”。平移可按其噪声模型另行加权平均；最终变换要检查旋转仍在 $SO(3)$ 上。

若使用对应点求一个固定刚体旋转，可参考 Kabsch/SVD 或 Wahba 问题。它们解决“对应关系已知”的定向问题；从点云建立、拒绝和更新对应关系属于[扫描匹配与点云配准](../SLAM与定位/扫描匹配与点云配准.md)的范围。

## 3. $SO(3)$、$SE(3)$ 与局部扰动

刚体变换组成 $SE(3)$：

$$
SE(3)=\left\{\begin{bmatrix}R&t\\0&1\end{bmatrix}:R\in SO(3),\ t\in\mathbb R^3\right\}.
$$

它通过矩阵乘法组合、求逆，并保持刚体距离。变换矩阵是 4×4，但只有 6 个自由度。李代数 $\mathfrak{se}(3)$ 用局部 6 维向量 $\xi=(\rho,\phi)$ 表示切空间增量：

$$
\hat\xi=\begin{bmatrix}[\phi]_\times&\rho\\0&0\end{bmatrix},\qquad
\operatorname{Exp}(\hat\xi)=
\begin{bmatrix}\operatorname{Exp}([\phi]_\times)&J_l(\phi)\rho\\0&1\end{bmatrix}.
$$

$J_l$ 是 $SO(3)$ 左雅可比。令 $\Phi=[\phi]_\times$、$\theta=\|\phi\|$，则

$$
J_l(\phi)=I+\frac{1-\cos\theta}{\theta^2}\Phi
+\frac{\theta-\sin\theta}{\theta^3}\Phi^2.
$$

在 $\theta$ 很小时要用级数展开避免消去误差。完整 $SE(3)$ 指数映射中的平移由它耦合旋转增量；因此 $\rho$ 一般不等于变换矩阵右上角的 $t$。某些优化器明确选用“旋转乘法更新、平移直接加法”的局部参数化，那是一个求解约定，不能与完整指数映射混用。

更新方向也要明确。对 $T_{A\leftarrow B}$，左扰动

$$
T'=\operatorname{Exp}(\delta\xi_A^\wedge)T
$$

把增量表达在输出/目标坐标系 A；右扰动

$$
T'=T\operatorname{Exp}(\delta\xi_B^\wedge)
$$

把增量表达在输入/源坐标系 B。二者是同一局部变化的不同坐标表示，须通过伴随变换转换。将右扰动雅可比用于左扰动更新，常导致符号正确却方向错误的结果。

若 twist 按 $(\rho,\phi)$ 排列，变换的伴随矩阵是

$$
\operatorname{Ad}_T=
\begin{bmatrix}R&[t]_\times R\\0&R\end{bmatrix},\qquad
T\operatorname{Exp}(\delta\xi_B^\wedge)
=\operatorname{Exp}\!\left((\operatorname{Ad}_T\delta\xi_B)^\wedge\right)T.
$$

这里 $T=[R,t;0,1]$。换一种 twist 分量排列（例如 $(\phi,\rho)$）时，伴随矩阵块顺序也随之改变。

关于残差、雅可比、Gauss–Newton 和 LM 的通用推导见[非线性最小二乘优化](../数学与信号基础/非线性最小二乘优化.md)；这里的重点是保证参数更新留在正确的流形和坐标系中。

## 4. 插值与时间

时间 $\tau$ 时的位姿应写为 $T(\tau)$。在两次采样时刻 $\tau_0,\tau_1$ 之间，令 $s=(\tau-\tau_0)/(\tau_1-\tau_0)$。若只分别插值位置和旋转，记端点位置向量为 $p_0,p_1$、端点姿态为 $q_0,q_1$，则

$$
p(s)=(1-s)p_0+sp_1,\qquad q(s)=\operatorname{SLERP}(q_0,q_1,s).
$$

SLERP 通过单位四元数球面上的短弧插值，旋转速度在该区间恒定。实现通常在 $q_0^Tq_1<0$ 时翻转其中一个四元数以走短弧，并在点积很接近 1 时改用归一化线性插值。若模型要求恒定刚体螺旋运动，可在 $SE(3)$ 上插值：

$$
T(s)=T_0\operatorname{Exp}\!\left(s\operatorname{Log}(T_0^{-1}T_1)\right).
$$

两种插值都只描述采样间的假设，不会自动恢复未观测的高频运动。传感器时间戳不齐时，空间外参和运动状态可能互相补偿；高速转动时，一点点时间偏差就会表现为角度误差。点云逐点去畸变和传感器时间质量分别由[点云处理模块](../点云处理与障碍检测/点云时空同步与地图表达.md)与[传感器测量与时间戳](../传感器与硬件通信/传感器测量与时间戳.md)展开。

## 5. TF 树把静态几何与动态运动接起来

tf2 维护带时间缓存的坐标帧树，并可在指定时间查询帧间变换。每条边的语义仍是一个方向明确的变换；树中一个 frame 只能有一个 parent。传感器安装支架等刚性关系通常作为静态边发布；机器人位姿和定位关系则随时间变化。静态变换不会因为点消息的 `frame_id` 改名而自动应用，消费者必须请求真实坐标变换。

一个常见移动平台结构是

```text
map → odom → base_link → sensor_frame
```

`odom` 提供连续的局部参考，但会累积漂移；`map` 提供长期全局参照，定位修正可能造成跳变。二者语义不同，局部控制常需要连续运动，全球规划则要地图参照。实际系统可添加 `base_footprint`、`base_stabilized` 等中间帧，但应保留各帧的具体定义。ROS REP-103 约定常用右手系、机体 x 前 y 左 z 上；相机 optical frame 则常用 z 前 x 右 y 下。REP-105 说明移动平台 `map`、`odom`、`base_link` 的语义与拓扑。

查 TF 时应先核对：

1. 请求的 target/source frame 顺序，以及返回变换代表的方向。
2. 点消息的 `header.frame_id`、数据时间戳、时钟域和 TF 树的动态缓存覆盖范围。
3. camera optical frame 与普通机体帧的轴向是否转换正确。
4. 同一个 child 是否被多个节点发布不同 parent；TF 树不允许把有环图当成帧树。
5. 静态边是否确为刚体常量，动态边是否按观测时刻查询，而不是用“最新值”冒充同一时刻。

只把 frame 名称改成目标 frame 不会改变坐标数值。离线回放、仿真时，还要确认 TF 与消息使用同一时钟，并确保查询时间落在可用数据区间内。静态 TF 发布节点若只在启动时读取标定文件，文件变化不会自动变成运行时新外参；需要通过系统支持的重载或重启发布源生效。

### 示例：组合传感器链

若 `T_{map←base}`、`T_{base←camera}` 和相机测得的 `p_camera` 已知，先把点写成末项为 1 的齐次坐标 $\bar p_{camera}=[p_{camera}^T,1]^T$，再计算

$$
\bar p_{map}=T_{map\leftarrow base}T_{base\leftarrow camera}\bar p_{camera}.
$$

若外参条目实际表示 `T_{camera←base}`，就必须先求逆，不能靠重命名字符串纠正。对每次组合，写下中间帧并检查相邻符号是否消去，能快速定位反向边或重复乘边。

## 延伸阅读

- [ROS REP-103：单位与坐标约定](https://github.com/ros-infrastructure/rep/blob/master/rep-0103.rst)；[ROS REP-105：移动平台坐标帧](https://github.com/ros-infrastructure/rep/blob/master/rep-0105.rst)。
- [ROS 2 tf2 概念与时间教程](https://github.com/ros2/ros2_documentation/blob/rolling/source/ROS-Framework/interfaces/About-Tf2/About-Tf2.rst)；[tf2 时间旅行与指定时间查询](https://github.com/ros2/ros2_documentation/blob/rolling/source/ROS-Framework/client-libraries/Working-with-Client-Libraries/Tf2/Time-Travel-With-Tf2-Cpp.rst)。
- Solà、Deray、Atchuthan，[A micro Lie theory for state estimation in robotics](https://arxiv.org/abs/1812.01537)。
