# 模型预测控制(mpc)

## 介绍

https://zhuanlan.zhihu.com/p/99409532

模型预测控制（MPC）是一种控制方法，它利用一个已知的模型，根据系统**当前的状态和期望的输出**，来**预测和优化系统未来的控制量**。

MPC的基本思想是：

- 在每个控制周期，根据系统模型和当前状态，预测未来一段时间内（预测时域）的系统输出。
- 将预测的输出与期望的输出进行比较，构建一个损失函数，表示系统的性能。
- 通过求解一个优化问题，找到最优的控制量序列，使得损失函数最小。
- 将控制量序列中的第一个元素作为当前控制周期的控制量，应用到系统上。
- 在下一个控制周期，重复上述步骤。

MPC的优点是：

- 可以处理多输入多输出、非线性、受约束的系统。
- 可以考虑系统的前瞻性，避免贪婪或短视的控制策略。
- 可以灵活地定义损失函数和约束条件，满足不同的控制目标和需求。

MPC的缺点是：

- 需要有准确且可行的系统模型。
- 需要在每个控制周期内实时求解优化问题，可能存在计算复杂度和实时性的问题。
- 需要选择合适的预测时域和控制时域，平衡计算开销和控制性能。



## 和lqr控制比较

LQR（线性二次调节器）和MPC（模型预测控制）是两种常用的最优控制方法，它们在车辆自动驾驶控制中有各自的优缺点。

LQR和MPC的主要区别有以下几点：

- LQR只适用于**线性系统**，而MPC可以处理**线性和非线性系统**。
- LQR在一个固定的时间窗口内进行优化，而MPC在一个滚动的时间窗口内进行优化。
- LQR只求解一次最优解，而MPC每个控制周期都重新求解最优解。
- LQR不考虑系统的约束条件，而MPC可以考虑系统的输入、输出、状态等约束条件。
- LQR通过求解黎卡提方程来得到控制律，而MPC通过求解二次规划问题来得到控制律。

一般来说，MPC相比LQR能够带来更好的控制性能和鲁棒性，但也需要更多的计算资源和实时性



**问题**

1. 为什么lqr只能用于线性系统

LQR只能用于线性系统的原因是它的控制律是基于黎卡提方程的解，而黎卡提方程是由线性系统的状态方程和二次型性能函数导出的。[1](https://zhuanlan.zhihu.com/p/139145957)[2](https://zhuanlan.zhihu.com/p/87070103)

如果系统是非线性的，那么黎卡提方程就不成立，LQR控制律就失效了。[3](https://www.guyuehome.com/36216)

一种解决方法是对非线性系统进行线性化，然后用LQR控制器进行近似控制，但这样会带来一定的误差和局限性。

```c
黎卡提方程是一种非线性方程，形如y’=P (x)y 2 +Q (x)y+R (x)。在控制理论中，黎卡提方程主要是用来求解线性二次型最优化问题的。

线性二次型最优化问题是指给定一个线性系统和一个二次型的性能函数，求一个最优的控制律，使得系统稳定且性能函数最小。

黎卡提方程是由线性系统的状态方程和二次型性能函数导出的一个代数方程，它的解可以得到最优控制律的反馈增益矩阵。

黎卡提方程在控制理论中的重要性和作用有以下几点：
黎卡提方程可以用来设计LQR（线性二次型调节器），这是一种常用的最优控制方法，它可以平衡系统的状态误差和控制消耗，提高系统的性能和鲁棒性。
黎卡提方程可以用来分析系统的稳定裕度，即系统在受到扰动或不确定性时能否保持稳定。通过求解黎卡提方程，可以得到系统的特征值和特征向量，从而判断系统的稳定性和灵敏度。
黎卡提方程可以用来设计输出调节器和输出跟踪器，这是一种基于状态反馈的输出反馈控制方法，它可以使系统的输出跟踪给定的参考信号或抑制干扰信号。通过求解黎卡提方程，可以得到输出反馈增益矩阵。
```



2. 为什么mpc可以适用于非线性系统

MPC（模型预测控制）是一种基于模型的预测、滚动优化和前馈-反馈的控制策略。[1](https://zhuanlan.zhihu.com/p/42099679)

MPC可以适用于非线性系统的原因是它可以直接使用非线性模型来预测系统的未来动态，并在线求解一个有限时间的开环优化问题，得到最优的控制序列。[2](https://zhuanlan.zhihu.com/p/139833089)

当然，使用非线性模型会带来一些挑战，比如优化问题可能是非凸的，导致求解困难或陷入局部最优；或者优化问题的计算复杂度过高，导致实时性不足。[2](https://zhuanlan.zhihu.com/p/139833089)

为了解决这些问题，通常有一些方法可以采用，比如：

- 对非线性模型进行适当的简化或近似，减少状态变量或控制变量的数量，降低优化问题的维度。[3](https://zhuanlan.zhihu.com/p/169368155)
- 对非线性模型进行线性化或分段线性化，将非凸优化问题转化为凸优化问题，利用现有的快速求解算法。[4](https://zhuanlan.zhihu.com/p/358836526)
- 对非线性模型进行离散化或参数化，将连续时间的优化问题转化为离散时间或有限维度的优化问题，利用数值方法求解。
- 对非线性模型进行自适应或增益调度，根据系统的工作点或工况变化，动态调整模型参数或控制器参数，提高系统的鲁棒性和适应性。





# OSC2

https://github.com/leggedrobotics/ocs2

> OSC2[是一个C++工具箱，用于**开关系统的最优控制**（OCS2）。它提供了以下算法的高效实现：
>
> - SLQ：连续时间域约束DDP
> - iLQR：离散时间域约束DDP
> - SQP：基于HPIPM的多射击算法
> - IPM：基于非线性内点法的多射击算法
> - SLP：基于PIPG的顺序线性规划
>
> [OCS2可以处理一般的路径约束，并提供了一些额外的工具，如从URDF模型设置系统动力学和代价/约束，以及自动微分工具和ROS接口。这个项目是由**苏黎世联邦理工学院的机器人系统实验室**开发和维护的[3](https://github.com/leggedrobotics)。



##  配置环境

###  拉取

>  正常拉取即可

因为blasefo等包是自动下载的，可以修改为gitee的仓库来避免链接不到

我们可以修改cmakelist中的仓库地址：

```c
# Download & build source
FetchContent_Declare(blasfeoDownload
	GIT_REPOSITORY https://github.com/giaf/blasfeo 
      //这里改为gitee仓库https://gitee.com/lebment/hpipm.git
	GIT_TAG ae6e2d1dea015862a09990b95905038a756ffc7d
	UPDATE_COMMAND ""
	SOURCE_DIR ${BLASFEO_DOWNLOAD_DIR}
	BINARY_DIR ${BLASFEO_BUILD_DIR}
	BUILD_COMMAND $(MAKE)
	INSTALL_COMMAND "$(MAKE) install"
)
```





### 编译

> ocs2是一个工具箱，你应该选择需要的包编译，否则会因为部分包没有激活码等原因无法完成编译
>
> 同一架构的设备可以把编译文件直接复制进工作空间使用，这并没有问题，但是不同架构的文件会有指令集相关的报错，解决方法是在目标架构下编译或者使用交叉编译

```bash
git clone https://github.com/leggedrobotics/ocs2.git
git clone https://github.com/leggedrobotics/ocs2_robotic_assets.git

catkin config --install 
catkin config -DCMAKE_BUILD_TYPE=Release

catkin build ocs2_你需要的包 #注意不能全部编译，因为有一些包的依赖很大且需要激活码(raisim)

中间会有一些依赖包需要去官网找
```

例如：·[GLPK](https://www.gnu.org/software/glpk/)



- 在X86下编译

正常选择依赖包编译即可，目前没有遇到问题



- 在ARM下编译

1. blasfeo_catkin

这个包会在github拉取blasfeo并编译，然而github上面的blasfeo的makefile.rule默认以X86/64构建库从而会报出编译错误。

错误的方法：在gihub手动拉取blasfeo并编译安装，找到目录(/opt/hpipm/lib)，在camkelist里取消其自动拉取hpipm的部分，并指定链接库，这是不对的，这样做及时这个包编译通过，那么子包仍会报依赖错误，可能有解决方法但目前没找到，也许是漏了什么

```cmake
错误示范
## Download & build source
#FetchContent_Declare(hpipmDownload

## 指定静态/动态库
link_directories(/opt/hpipm/lib)
```

只要仔细观察，在blasfeo_catkin的camkelist里面有设置编译选项的部分，其中的target的是设置架构，这里我修改为了GENERIC，选择合适的即可，样例可以在blasfeo的源代码里找到makefile.rule，里面有注释后的一系列target

注意如果编译balance仓库时出现`undefined reference to kernel_dgetrf_pivot_8_vs_lib4'`说明架构不匹配，更换一个合适的即可

```c
# BLASFEO Settings
set(BUILD_SHARED_LIBS ON CACHE STRING "Build shared libraries" FORCE)
set(TARGET GENERIC CACHE STRING "Target architecture" FORCE)
set(BLASFEO_EXAMPLES OFF CACHE BOOL "Examples enabled")
```

2. hpipm_catkin

和上面的一样，在camkelist里加上下面的即可

```c
set(TARGET ARMV8A_ARM_CORTEX_A57 CACHE STRING "Target architecture" FORCE)
```



### 工作空间依赖

因为只使用部分包且只编译一次，我们新开一个依赖工作空间并将其install Realse编译

> 由于⼀些依赖的 ROS Package 只需要当为依赖编译⼀次后就不再改动，因此我们可以把
> 它放在另⼀个⼯作空间当成软件依赖源，与我们需要开发的 Package 在⼯作空间上分离

```bash
mkdir install_ws && cd install_ws && mkdir src

#注释bashrc中的source ..../my_ws/devel/setup.bash，确保输出没有依赖到下的包路径，否则会造成循环依赖
echo ${ROS_PACKAGE_PATH}

catkin config --install # 设置 install 模式
catkin config -DCMAKE_BUILD_TYPE=Release
catkin build <Dependent_ROS_Package>

cd ~/catkin_ws

source ~/depend_ws/install/setup.bash#打开clion或编译前也要记得source这个
catkin config --merge-devel
catkin build <Package_In_catkin_ws>

#使⽤ catkin_ws 下的包时，记得 
source ~/catkin_ws/devel/setup.bash
```

对于平衡步

```bash
#在depend_ws
#sudo apt-get install ros-noetic-interactive-markers
catkin build ocs2_msgs ocs2_core ocs2_mpc ocs2_sqp ocs2_ipm ocs2_robotic_tools ocs2_ros_interfaces ocs2_ddp ocs2_pinocchio ocs2_slp ocs2_python_interface
#或者
catkin build ocs2_ballbot ocs2_ipm ocs2_ros_interfaces ocs2_pinocchio

#在rm_ws
source ../../depend_ws/install/setup.bash 
catkin build rm_balance*
```

> 好像还有些问题，balance里rm环境是opt，编译depend是source的是rm，然后mpc是source的是depend，依赖树不一样
>
> 之后自启source mpc，bashrc里source rm，这样可以直接编译rm

- clion project config

```bash
-DCATKIN_DEVEL_PREFIX=../devel
```

编译 catkin_ws 下包时，保证 ${ROS_PACKAGE_PATH} 为
/home/luohx/install_ws/install/share:/opt/ros/noetic/share



目前更优秀的是**extend**，它不需要手动source：

```bash
mkdir -p depend_ws/src

#设置 install 模式
catkin install
# build_type 为 release 比 debug 的代码运行地快一点
catkin config -DCMAKE_BUILD_TYPE=Release
#清注释掉所有你 source 过的工作空间，保证 echo ${ROS_PACKAGE_PATH} 的输出为 /opt/ros/noetic/share
catkin build

#然后回到你的 rm_ws 下
catkin clean
#注释掉所有你 source 过的工作空间，保证 echo ${ROS_PACKAGE_PATH} 的输出为 /opt/ros/noetic/share
catkin config --extend /home/xxxx/depend_ws/install
#直接设置 depend_ws 为 ie 依赖
catkin build
```



## task.info

> task.info文件是一个配置文件，用于设置MPC问题的一些参数，如目标时间、初始状态、约束、代价、参考轨迹等

以平衡步兵rm_balance_control下的task.info为例



### Mode sequence

```
; Mode sequence
subsystemsSequence
{
  [0]     0
}
```

这个参数是用于设置**系统的模式序列**，即在MPC的时间范围内，系统会经历哪些模式。每个模式对应一个子系统，每个子系统有自己的动力学模型和代价/约束函数。这个参数是一个数组，每个元素表示一个模式的编号，从0开始。例如，[0, 1, 0\]表示系统先在模式0，然后切换到模式1，再切换回模式0。

如果系统只有一个模式，则可以将subsystemsSequence设置为[0]。



### Template mode

```c
; Template mode sequence
templateSubsystemsSequence
{
  [0]     0
}
templateSwitchingTimes
{
}
```

这两个参数是用于设置[**切换系统的最优控制**（OCS2）](https://github.com/leggedrobotics/ocs2)的一些选项。它们的含义是：

- templateSubsystemsSequence：一个数组，表示系统的子系统序列，每个子系统对应一个动力学模型和代价/约束函数
- templateSwitchingTimes：一个数组，表示子系统切换的时间点，必须与子系统序列的长度匹配

这两个参数可以用于定义具有多个模式的混合动力学系统，例如跳跃机器人或接触机器人[1](https://github.com/leggedrobotics/ocs2)。如果你的系统只有一个模式，你可以将templateSubsystemsSequence设置为[0]，并将templateSwitchingTimes设置为空。



### IPM

```c
; Multiple_Shooting IPM settings
ipm
{
  nThreads                              3
  dt                                    0.01
  ipmIteration                          5
  deltaTol                              1e-4
  g_max                                 10.0
  g_min                                 1e-6
  computeLagrangeMultipliers            true
  printSolverStatistics                 true
  printSolverStatus                     false
  printLinesearch                       false
  useFeedbackPolicy                     false
  integratorType                        RK2
  threadPriority                        95

  initialBarrierParameter               1e-4
  targetBarrierParameter                1e-4
  barrierLinearDecreaseFactor           0.2
  barrierSuperlinearDecreasePower       1.5
  barrierReductionCostTol               1e-3
  barrierReductionConstraintTol         1e-3

  fractionToBoundaryMargin              0.995
  usePrimalStepSizeForDual              false

  initialSlackLowerBound                1e-4
  initialDualLowerBound                 1e-4
  initialSlackMarginRate                1e-2
  initialDualMarginRate                 1e-2
}
```

这个参数是用于设置[**基于非线性内点法的多射击算法**（IPM)]((https://leggedrobotics.github.io/ocs2/))的一些选项。它包括以下子参数：

- nThreads：并行计算的线程数
- dt：离散化的时间步长
- ipmIteration：每次MPC迭代的IPM迭代次数

```c
ipmIteration是一个参数，用于设置内点法（IPM）求解器的最大迭代次数。内点法是一种多射击算法，基于非线性内点方法求解最优控制问题。ipmIteration越大，求解器的精度越高，但也需要更多的计算时间。
```

- deltaTol：IPM收敛的容差

```c
IPM求解器的收敛容差，当相邻两次迭代的目标函数值之差小于该值时，认为求解器已经收敛。
```

- g_max：初始的惩罚因子
- g_min：最小的惩罚因子

```c
g_max：IPM求解器的初始惩罚因子，用于处理路径约束。惩罚因子越大，约束越严格，但也可能导致求解器不收敛或陷入局部最优。
g_min：IPM求解器的最小惩罚因子，用于防止惩罚因子过小而导致约束被忽略。
```

- computeLagrangeMultipliers：是否计算拉格朗日乘子

```c
computeLagrangeMultipliers这个参数是一个布尔值，用于设置是否计算拉格朗日乘子。拉格朗日乘子是一种用于处理约束优化问题的方法，它可以反映约束对目标函数的影响程度2。如果computeLagrangeMultipliers为true，那么ocs2会在每次迭代后计算拉格朗日乘子，并将其作为输出之一返回。如果为false，那么ocs2不会计算拉格朗日乘子，这样可以节省一些计算时间，但也会失去一些关于约束的信息。
```

- printSolverStatistics：是否打印求解器的统计信息
- printSolverStatus：是否打印求解器的状态
- printLinesearch：是否打印线搜索的信息
- useFeedbackPolicy：是否使用反馈策略

```c
useFeedbackPolicy这个参数是一个布尔值，用于设置是否使用反馈策略。反馈策略是一种在每次迭代后，根据当前状态和最优控制轨迹，计算一个反馈增益矩阵，用于修正控制输入2。如果useFeedbackPolicy为true，那么ocs2会在每次迭代后计算反馈增益矩阵，并将其作为输出之一返回。如果为false，那么ocs2不会计算反馈增益矩阵，而是直接使用最优控制轨迹的控制输入。使用反馈策略可以提高控制器的鲁棒性和稳定性，但也会增加一些计算时间和复杂度。
```

- integratorType：积分器的类型，可以是RK2或RK4
- threadPriority：线程的优先级，越高越好，但需要[特殊权限](https://github.com/leggedrobotics/ocs2)
- initialBarrierParameter：初始的障碍参数
- targetBarrierParameter：目标的障碍参数

```c
initialBarrierParameter和targetBarrierParameter 用于设置障碍参数的初始值和目标值。障碍参数是一种用于处理约束优化问题的方法，它可以将约束转化为目标函数中的一项惩罚项。障碍参数越小，惩罚项越小，目标函数越接近原始问题，但也可能导致求解器不收敛或陷入局部最优。ocs2会根据一定的规则逐渐减小障碍参数，直到达到目标值或满足收敛条件。
```

- barrierLinearDecreaseFactor：障碍参数的线性减少因子
- barrierSuperlinearDecreasePower：障碍参数的超线性减少指数
- barrierReductionCostTol：障碍参数减少时的代价容差
- barrierReductionConstraintTol：障碍参数减少时的约束容差
- fractionToBoundaryMargin：边界保护系数，越接近1越好，但可能导致步长过小
- usePrimalStepSizeForDual：是否使用原始步长作为对偶步长
- initialSlackLowerBound：初始松弛变量的下界
- initialDualLowerBound：初始对偶变量的下界
- initialSlackMarginRate：初始松弛变量的边界裕度比率
- initialDualMarginRate：初始对偶变量的边界裕度比率



### Rollout

```c
; Rollout settings
rollout
{
  timeStep                      1e-2
  maxNumStepsPerSecond          100000
  checkNumericalStability       false
}
```

这个参数是用来设置系统的仿真参数的，也就是说系统会按照这个参数来进行动态模拟和控制。

这个参数的含义如下：

- timeStep是指每次仿真的时间步长，也就是说系统会以这个时间间隔来更新状态和控制量。
- maxNumStepsPerSecond是指每秒钟最多可以进行多少次仿真步骤，也就是说系统会限制仿真的速度，以防止过快或过慢。
- checkNumericalStability是指是否检查仿真的数值稳定性，也就是说系统会检查是否出现了数值溢出或奇异值等异常情况，如果出现了，系统会停止仿真并报错。



### MPC

```c
; MPC settings
mpc
{
  timeHorizon                    1.0   ; [s]
  solutionTimeWindow             0.2   ; [s]
  coldStart                      false

  debugPrint                     false

  mpcDesiredFrequency            250   ; [Hz]
  mrtDesiredFrequency            500   ; [Hz]
}
```

这个参数是用来设置MPC（模型预测控制）的一些基本信息的，比如预测和控制的时间范围、是否使用冷启动、是否打印调试信息、MPC和MRT的期望频率等。

这个参数的含义如下：

- timeHorizon是指预测和控制的时间范围，也就是说MPC会在每个时刻根据当前的状态和约束，优化未来这个时间范围内的控制序列。
- solutionTimeWindow是指解决方案的时间窗口，也就是说MPC会在每个时刻只应用优化得到的控制序列中的这个时间窗口内的部分，然后在下一个时刻重新优化。
- coldStart是指是否使用冷启动，也就是说MPC在每次优化时，是否使用上一次优化得到的控制序列作为初始猜测，以提高收敛速度和质量。
- debugPrint是指是否打印调试信息，也就是说MPC在每次优化时，是否输出一些详细的信息，以方便调试和分析。
- mpcDesiredFrequency是指MPC的期望频率，也就是说MPC会尽量以这个频率进行优化和更新控制序列。
- mrtDesiredFrequency是指MRT（Model Reference Tracking）的期望频率，也就是说MRT会尽量以这个频率进行状态估计和反馈控制。



### **MRT**

> Model Reference Tracking
>
> 是一种模型参考跟踪的控制策略，它的目的是使系统的输出跟随一个给定的参考模型的输出，而不管系统的内部结构或动态特性。
>
> MRT的基本思想是将系统的输出和参考模型的输出之间的误差作为一个反馈信号，然后设计一个合适的控制器，使得这个误差趋于零或有界。
>
> MRT可以用于线性或非线性系统，也可以用于有约束或无约束系统。
>
> MRT有一些优点，比如：
>
> - MRT可以实现系统的性能指标，比如稳定性、快速性、精确性等，而不需要知道系统的精确模型。
> - MRT可以提高系统的鲁棒性，即使系统受到参数变化或外部干扰的影响，也能保持良好的跟踪性能。
> - MRT可以简化控制器的设计，只需要根据参考模型的特征来选择合适的控制器结构和参数。

MRT和MPC的关系是：

- MRT和MPC都是基于模型的控制策略，它们都需要知道系统的模型或参考模型的模型。
- MRT和MPC都是基于预测的控制策略，它们都需要预测系统或参考模型的未来动态。
- MRT和MPC都是基于优化的控制策略，它们都需要求解一个优化问题，来得到最优的控制量。

不过，MRT和MPC也有一些区别，比如：

- MRT的目标是使系统的输出**跟随参考模型的输出**，而MPC的目标是使系统的输出**满足一些约束和性能指标**。
- MRT的优化问题是一个输出反馈控制问题，而MPC的优化问题是一个状态反馈控制问题。
- MRT的优化问题是一个静态优化问题，而MPC的优化问题是一个动态优化问题。
- MRT的优化问题只需要求解一次，而MPC的优化问题需要在每个控制周期重新求解。



1. 为什么MRT作为MPC的一个参数存在？

MRT作为MPC的一个参数选项存在，是因为MRT可以作为MPC的一个子模块，用于实现状态估计和反馈控制。

MPC是一个基于滚动优化和前馈控制的控制策略，它需要知道系统的当前状态，才能进行预测和优化。

如果系统的状态不能直接测量或观测，那么就需要用一个状态估计器，来根据系统的输出和控制量，来估计系统的状态。

MRT就是一种基于输出反馈的状态估计器，它可以利用参考模型的输出，来估计系统的状态，并提供一个反馈控制量，来使系统的输出跟随参考模型的输出。

因此，MRT可以作为MPC的一个辅助模块，来提供状态信息和反馈信息，从而实现一个完整的模型预测跟踪控制器。



### Q&R

```c
; state weight matrix
Q
{
  scaling 1e+1

  (0,0) 0.0  ; px
  (1,1) 0.0   ; theta
  (2,2) 10.0  ; psi
  (3,3) 20.0  ; px_dot
  (4,4) 0.1   ; theta_dot
  (5,5) 5.0   ; psi_dot
}

; control weight matrix
R
{
  scaling 1e-0

  (0,0)  10.0  ; torque
  (1,1)  10.0  ; torque
}
```

这两个参数是用来设置MPC的性能函数的权重矩阵的，也就是说MPC会根据这些参数来平衡系统的状态误差和控制消耗。

这两个参数的含义如下：

- Q是指状态权重矩阵，它是一个对角矩阵，每个对角元素表示一个状态变量的权重，也就是说MPC会根据这些权重来调整对不同状态变量的关注程度。权重越大，表示对该状态变量的误差越敏感，MPC会更加努力地使该状态变量接近期望值。
- R是指控制权重矩阵，它也是一个对角矩阵，每个对角元素表示一个控制变量的权重，也就是说MPC会根据这些权重来调整对不同控制变量的消耗。权重越大，表示对该控制变量的消耗越敏感，MPC会更加节约地使用该控制变量。
- scaling是指一个缩放因子，它可以用来调整Q和R矩阵的整体大小，以避免数值问题或提高计算效率







## 约束

###  ocs2::StateInputConstraint

#### getValue()

- ```
  vector_t getValue(scalar_t time, const vector_t& /*state*/, const vector_t& input, const PreComputation& /*preComp*/) const override
  ```

https://github.com/leggedrobotics/ocs2/blob/main/ocs2_core/include/ocs2_core/constraint/StateInputConstraint.h

> 是一个抽象类，用于定义**状态输入约束**，即对系统的状态和输入的组合施加的约束。这个类有以下几个虚函数，需要由子类实现：
>
> - getConstraintSize：返回约束的维度
> - getValue：计算约束的值
> - getDerivative：计算约束的导数
> - getQuadraticApproximation：计算约束的二次近似
>
> 这个类可以用于定义一些非线性或线性的状态输入约束，例如速度限制、力矩限制、摩擦锥约束等



1. 一个示例函数如下，为什么limit直接加在了参数上？

```c++
vector_t getValue(scalar_t time, const vector_t& /*state*/, const vector_t& input, const PreComputation& /*preComp*/) const override {
 vector_t ret(getNumConstraints(time));
 scalar_t limit = 7.1;
 // clang-format off
 ret << input(0) + limit,
 -input(0) + limit,
 input(1) + limit,
 -input(1) + limit;
 // clang-format on
 return ret;
}
```

这个示例函数是用于定义一个**输入的范围约束**，即输入的每个分量都必须在[-limit, limit]之间。limit直接加在了参数上，是为了简化约束的形式，使其符合ocs2::StateInputConstraint类的接口，即约束的值必须小于等于0。如果不加limit，那么约束的值就必须在[-limit, 0]之间，这样就不符合输入的范围约束的定义了。



#### getLinearApproximation()

> [github](https://github.com/leggedrobotics/ocs2/blob/main/ocs2_robotic_examples/ocs2_mobile_manipulator/src/constraint/EndEffectorConstraint.cpp) 或 balance controller的pitch约束

- ```
  VectorFunctionLinearApproximation getLinearApproximation(scalar_t time, const vector_t& state, const vector_t& input,
                                                           const PreComputation& preComp) const override 
  ```

这个函数是用于计算约束的**线性近似**，即约束的值和导数的线性组合。这个函数返回一个ocs2::VectorFunctionLinearApproximation结构体，它包含以下几个成员：

- f：约束的值，即getValue函数的返回值
- dfdx：约束对状态的导数，即一个矩阵
- dfdu：约束对输入的导数，即一个矩阵

这个函数里，因为约束只和输入有关，所以dfdx是一个零矩阵，而dfdu是一个单位矩阵。



```c++
VectorFunctionLinearApproximation getLinearApproximation(scalar_t time, const vector_t& state, const vector_t& input,
                                                         const PreComputation& preComp) const override {
  VectorFunctionLinearApproximation ret(getNumConstraints(time), STATE_DIM, INPUT_DIM);
  ret.f = getValue(time, state, input, preComp);
  ret.dfdx.setZero();
  // clang-format off
  ret.dfdu << 1, 0,
             -1, 0,
              0, 1,
              0, -1;
  // clang-format on
  return ret;
}
```



1. 为什么上面代码矩阵ret赋值方式是一个4行2列的矩阵？

这个矩阵是用于表示约束对输入的导数，即**每一行对应一个约束**，**每一列对应一个输入分量**。因为约束的形式是：

```
input(0) + limit <= 0
-input(0) + limit <= 0
input(1) + limit <= 0
-input(1) + limit <= 0
```

所以，约束对输入的导数是：

```
1, 0
-1, 0
0, 1
0, -1
```

这就是为什么这个矩阵是这样赋值的。

==总结：行数代表约束个数，列数代表输入量个数或状态量个数==

如果是状态量约束(stateConstraint)，则赋值给ret.dfds 输入量约束则赋值给ret.dfdu



### ocs2::StateInputConstraintCppAd

> 这个类是一个**基于CppAD的状态输入约束类**，它继承自ocs2::StateInputConstraint类，用于定义一些可以用CppAD自动微分的状态输入约束[1](https://github.com/leggedrobotics/ocs2)。这个类有以下几个特点：
>
> - 它只需要实现getValue函数，其他的虚函数都会自动调用CppAD来计算
> - 它可以用于定义一些非线性或复杂的状态输入约束，例如摩擦锥约束、接触力约束等
> - 它可以提高求解器的性能和稳定性，因为它可以避免手动计算导数的错误和不精确
> - 它需要使用ocs2::Scalar类型来定义约束的值和参数，而不是普通的浮点数



示例

```c++
//需要重写来说明约束个数
size_t getNumConstraints(scalar_t /*time*/) const override { return 1; }
```



```c++
//必须使用scalar而不是double
//在这里展示功率约束
ad_vector_t constraintFunction(ad_scalar_t /*time*/, const ad_vector_t& state, const ad_vector_t& input,
                               const ad_vector_t& /*parameters*/) const override {
  scalar_t limit = 100;
  scalar_t coeff_effort = 2.35;
  scalar_t coeff_vel = 0.00905;
  scalar_t offset = 9.8;

  ad_scalar_t wheel_left_speed = state(3) / param_.r_ - state(4) - state(5) * param_.d_ / 2 / param_.r_;
  ad_scalar_t wheel_right_speed = state(3) / param_.r_ - state(4) + state(5) * param_.d_ / 2 / param_.r_;
  ad_scalar_t power = abs(input(0) * wheel_left_speed) + coeff_effort * input(0) * input(0) +
                      coeff_vel * wheel_left_speed * wheel_left_speed + abs(input(1) * wheel_right_speed) +
                      coeff_effort * input(1) * input(1) + coeff_vel * wheel_right_speed * wheel_right_speed + offset;
  ad_vector_t ret(1);
  ret(0) = limit - power;
  return ret;
}
```



### ocs2::StateConstraint

> 这个类是一个抽象类，用于定义**状态约束**，即对系统的状态施加的约束[1](https://github.com/leggedrobotics/ocs2/blob/main/ocs2_core/include/ocs2_core/constraint/StateInputConstraint.h)。这个类有以下几个虚函数，需要由子类实现：
>
> - getConstraintSize：返回约束的维度
> - getValue：计算约束的值
> - getDerivative：计算约束的导数
> - getQuadraticApproximation：计算约束的二次近似
>
> 这个类可以用于定义一些非线性或线性的状态约束，例如位置限制、姿态限制、碰撞避免等[2](https://github.com/leggedrobotics/ocs2)。

使用方法和上面的StateInputConstraint类似

```ac++
vector_t getValue(scalar_t /*time*/, const vector_t& state, const PreComputation& /*preComp*/) const override {
  vector_t ret(2);
  scalar_t limit = 0.42;
  // clang-format off
  ret << state(1) + limit,    // state(1) + limi <= 0
        -state(1) + limit;    // -state(1) + limit <= 0
  // clang-format on
  return ret;
}
VectorFunctionLinearApproximation getLinearApproximation(scalar_t time, const vector_t& state,
                                                         const PreComputation& preComp) const override {
  VectorFunctionLinearApproximation ret(2, STATE_DIM);
  ret.f = getValue(time, state, preComp);
  // clang-format off
  ret.dfdx << 0, 1, 0, 0, 0, 0,
              0, -1, 0, 0, 0, 0;
  // clang-format on
  return ret;
}
```



# 系统(control)

## ocs2::SystemDynamicsBaseAD

> SystemDynamicsBaseAD是ocs2中的一个抽象类，用于表示系统动力学的自动微分版本。它继承自SystemDynamicsBase类，提供了一些虚函数，如computeFlowMap、computeJumpMap等，用于计算系统的状态方程和跳变方程。它还提供了一些辅助函数，如initialize、preJump、postJump等，用于初始化和更新系统的状态和参数。它的子类需要实现这些虚函数，并提供系统动力学的具体表达式。
>
> 

### clone()

> clone() const override函数是一个虚函数，用于返回一个动作的克隆。它是SystemDynamicsBase类的一个成员函数，被SystemDynamicsBaseAD类重写。它的作用是根据当前的系统动力学对象，创建一个新的对象，并返回其指针。这样可以方便地复制和复用系统动力学对象，而不需要重新创建或初始化。

```c++
 BalanceSystemDynamics* clone() const override { return new BalanceSystemDynamics(*this); }
```



### systemFlowMap()

> systemFlowMap函数是一个虚函数，用于计算系统的状态方程。它是SystemDynamicsBase类的一个成员函数，被SystemDynamicsBaseAD类重写。它的作用是根据当前的时间、状态、输入和参数，返回系统状态的导数。它的返回值是一个向量，表示系统状态的变化率。它的子类需要实现这个函数，并提供系统动力学的具体表达式。

```c++
ad_vector_t systemFlowMap(ad_scalar_t time, const ad_vector_t& state, const ad_vector_t& input,
                          const ad_vector_t& parameters) const override;
```

在cpp的实现中，它就展示了系统状态，输入加在一起后的变化率结果





## ocs2::RobotInterface

> RobotInterface类是ocs2中的一个抽象类，用于表示一个最优控制问题的接口。它继承自OptimalControlProblem类，提供了一些虚函数，如getInitialState、getTargetTrajectories、getModeSchedule等，用于获取系统的初始状态、目标轨迹和模式序列。它还提供了一些辅助函数，如createSystemDynamics、createCostFunction、createConstraints等，用于创建系统动力学、代价函数和约束函数。它的子类需要实现这些虚函数，并提供最优控制问题的具体参数和表达式。





# Controller(control_ros)

## 成员

### 观测者

#### SystemObservation

> ocs2::ocs2::DummyObserver是一个观察者类，用于实现观察者模式。它是ocs2::ocs2::Observer类的一个子类，实现了其虚函数update()。它的作用是在每次MPC求解器更新时，接收一个事件对象，并打印出事件的类型和时间。这样可以方便地监测MPC求解器的运行状态和性能，以及检测可能的延迟或异常。

在代码中我们需要更新它并用ros::Publisher发布观测数据给预测部分

```c++
// Update the current state of the system
mpcMrtInterface_->setCurrentObservation(currentObservation_);

// Load the latest MPC policy
mpcMrtInterface_->updatePolicy();

// Evaluate the current policy
vector_t optimizedState, optimizedInput;
size_t plannedMode = 0;  // The mode that is active at the time the policy is evaluated at.
mpcMrtInterface_->evaluatePolicy(currentObservation_.time, currentObservation_.state, optimizedState, optimizedInput, plannedMode);
```



### 预测者

#### TargetTrajectoriesPublisher

> TargetTrajectoriesPublisher.cpp订阅Controller发布的的观测数据，获取==cmd_vel==结合状态并使用TargetTrajectoriesRosPublisher类发布预测数据

```c++
TargetTrajectoriesRosPublisher类是一个继承自TargetTrajectoriesPublisher类的子类，它是用来将ocs2的目标轨迹转换为ROS消息，并通过ROS话题发送给ocs2的MPC控制器的。它的话题名称由构造函数中的topicPrefix参数决定，一般是机器人的名字加上"_target_trajectories"。它的话题被ocs2的MPC控制器订阅，用来接收目标轨迹，并根据它们计算最优控制策略。
```

发布的xxx_mpc_target话题是谁订阅呢？是`RosReferenceManager`类

```c
 auto rosReferenceManagerPtr = std::make_shared<ocs2::RosReferenceManager>(robotName, balanceInterface_->getReferenceManagerPtr());
```



#### TargetTrajectoriesKeyboardPublisher

> 一个用于从键盘读取运动指令并发布target话题的ROS类

```c
TargetTrajectoriesKeyboardPublisher和TargetTrajectoriesROSPublisher的区别是，前者是一个用于从键盘输入目标轨迹的ROS类，后者是一个用于从ROS话题接收目标轨迹的ROS类。它们都继承自TargetTrajectoriesPublisher类，所以它们都可以发布目标轨迹给ocs2的MPC控制器1。但是，它们的构造函数和发布方式不同
```

TargetTrajectoriesKeyboardPublisher类的构造函数接受一个相对状态限制的数组，用来限制用户输入的X方向和速度的变化量，以及一个函数指针，用来将用户输入转换为目标轨迹。它提供了一个publishKeyboardCommand()方法，用来向用户显示一条提示信息，并等待用户输入。然后，它会将用户输入和当前观测数据一起送到函数指针中，得到一个ocs2_msgs::TargetTrajectories类型的消息，并发布到机器人名字加上"_target_trajectories"的话题下。
TargetTrajectoriesROSPublisher类的构造函数接受一个话题前缀参数，用来确定发布和订阅的话题名称。它提供了一个subscribe()方法，用来订阅ocs2_msgs::TargetTrajectories类型的消息，并将其转换为ocs2::TargetTrajectories类型，并存储在内部。它还提供了一个publish()方法，用来发布ocs2::TargetTrajectories类型的消息到机器人名字加上"_target_trajectories"的话题下。





### 订阅者

#### RosReferenceManager

> 订阅者通常和mpc一起工作，在控制器中我们读取传感器获取了当前观测值并发布，预测者==订阅观测者发布的数据结合命令生成和发布预测值==，RosReferenceManager就会订阅并将值给予mpc

RosReferenceManager类是一个用来管理ocs2的模式序列和目标轨迹的类，它是一个装饰器，给ReferenceManager类添加了ROS订阅器，用来接收ROS消息。它的作用是将收到的ocs2_msgs::ModeSchedule和ocs2_msgs::TargetTrajectories类型的消息转换为ocs2::ModeSchedule和ocs2::TargetTrajectories类型，并存储在ReferenceManager类的成员变量中。然后，ocs2的MPC控制器可以通过ReferenceManager类的接口，来==获取最新的模式序列和目标轨迹==，并根据它们计算最优控制策略。

```c++
/**
 * Decorates ReferenceManager with ROS subscribers to receive ModeSchedule and TargetTrajectories through ROS messages.
 */
class RosReferenceManager final : public ReferenceManagerDecorator {
 public:
  /**
   * Constructor which decorates referenceManagerPtr.
   *
   * @param [in] topicPrefix: The ReferenceManager will subscribe to "topicPrefix_mode_schedule" and "topicPrefix_mpc_target"
   * @param [in] referenceManagerPtr: The ReferenceManager which will be decorated with ROS subscribers functionalities.
   * topics to receive user-commanded ModeSchedule and TargetTrajectories respectively.
   */
  explicit RosReferenceManager(std::string topicPrefix, std::shared_ptr<ReferenceManagerInterface> referenceManagerPtr);
```



controller配置manager的代码：

```c++
// ROS ReferenceManager
ros::NodeHandle nh;
auto rosReferenceManagerPtr = std::make_shared<ocs2::RosReferenceManager>(robotName, balanceInterface_->getReferenceManagerPtr());
rosReferenceManagerPtr->subscribe(nh);
```





### MPC

```c++
// Nonlinear MPC
std::shared_ptr<ocs2::MPC_BASE> mpc_;
std::shared_ptr<ocs2::MPC_MRT_Interface> mpcMrtInterface_;

// Thread
std::thread mpcThread_;
```



#### MPC_BASE

> ocs2::MPC_BASE是一个抽象类，用于表示一个MPC求解器的基类。它提供了一些虚函数，如reset、updatePolicy、getPolicy等，用于**重置、更新和获取**MPC策略。它还提供了一些辅助函数，如setTargetTrajectories、setModeSchedule、setInitialState等，用于设置目标轨迹、模式序列和初始状态。它的子类需要实现这些虚函数，并提供MPC求解器的具体算法和参数。



#### MPC_MRT_Interface

> ocs2::MPC_MRT_Interface是一个具体类，用于实现一个多速率控制器的MPC求解器。它继承自ocs2::MPC_BASE类，重写了其虚函数。它的作用是在每次MPC求解器更新时，从系统中获取当前的观测值，并根据目标轨迹和模式序列，计算出最优的状态和输入轨迹，并将其封装为一个策略对象。它还提供了一些额外的函数，如advanceMpc、initialPolicyReceived等，用于执行MPC求解器的一次迭代，并判断是否收到初始策略。

所以我们先定义MPC_BASE对象，在将其作为参数给MPC_MRT_Interface生成使用

```c++
mpc_ = std::make_shared<ocs2::IpmMpc>(balanceInterface_->mpcSettings(), balanceInterface_->ipmSettings(),
                                      balanceInterface_->getOptimalControlProblem(), balanceInterface_->getInitializer());
mpc_->getSolverPtr()->setReferenceManager(rosReferenceManagerPtr);

mpcMrtInterface_ = std::make_shared<ocs2::MPC_MRT_Interface>(*mpc_);
mpcMrtInterface_->initRollout(&balanceInterface_->getRollout());
```



#### 线程mpc和节点mpc

官方原本将mpc放在一个节点来结算(BalanceIpmMpcNode.cpp)，controller中则是新开一个线程来运行



## 代码

### 观测部分

在控制器中，我们先更新观测者再将观测者的数据导入MPC解算

```c++
//更新观测者
currentObservation_.state(5) = (jointVel(1) - jointVel(0)) / params_.d_ * params_.r_;
  currentObservation_.state(4) = gyro.y;
  currentObservation_.state(3) = (jointVel(0) + jointVel(1) + 2 * currentObservation_.state(4)) / 2. * params_.r_;
  currentObservation_.state(2) = yawLast + angles::shortest_angular_distance(yawLast, yaw);
  currentObservation_.state(1) = pitch;
  currentObservation_.state(0) += currentObservation_.state(3) * period.toSec();
```

之后会将观测数据更新mpc中，主要完成

- 更新系统的当前观测数据，这是从ROS话题接收的。
- 加载最新的MPC策略，这是由另一个线程计算的。
- 评估当前策略在当前时间和状态下的输出，得到优化的状态和输入，以及计划的模式。
- 将当前观测数据的输入更新为优化的输入，以便发送给系统。

```c++
//更新mpc
// Update the current state of the system
mpcMrtInterface_->setCurrentObservation(currentObservation_);

// Load the latest MPC policy
mpcMrtInterface_->updatePolicy();

// Evaluate the current policy
vector_t optimizedState, optimizedInput;
size_t plannedMode = 0; // The mode that is active at the time the policy is evaluated at.
mpcMrtInterface_->evaluatePolicy(currentObservation_.time, currentObservation_.state, optimizedState, optimizedInput, plannedMode);

currentObservation_.input = optimizedInput;
```

接着会发布观测数据

```c++
observationPublisher_.publish(ocs2::ros_msg_conversions::createObservationMsg(currentObservation_));
```



### 预测部分

> TargetTrajectoriesPublisher.cpp订阅Controoler发布的的观测数据，获取cmd_vel结合状态发布预测数据

cmd_vel通过一个lambda表达式生成一个储存命令的vector，之后将vector导入观测者

导入观测者的过程是调用一个构造函数中传入的函数指针`cmdVelToTargetTrajectories_(std::move(cmdVelToTargetTrajectories)`

```c
ocs2的TargetTrajectoriesRosPublisher类是一个用于发布目标轨迹的ROS类。它可以将一条路径转换为一组时间、状态和输入的轨迹，并通过ROS话题发送给ocs2的MPC控制器。它还可以接收ocs2的观测数据，并用它来估计到达目标所需的时间。
```



### 调参部分

### 约束里的参数

rm_balance_control的各种约束有的需要动态变化的，需要传入共享指针cmdPtr，通过它获取最新参数

同时约束需要放入BalanceInterface里面才能生效(BalanceInterface.cpp)

```c++
problem_.stateInequalityConstraintPtr->add("pitchConstraint", std::make_unique<PitchConstraint>(balanceControlCmdPtr_));
```



这个cmdPtr是在balance interface里面的，把它返回出来给rm_balance_control_ros的RosReferenceManager，在这之后每当演算前程序都会调用manager里面的preslove函数，在其余时间manager订阅相关命令话题并将指令保存在buff中

```c++
  auto rosReferenceManagerPtr =
      std::make_shared<rm::RosReferenceManager>(balanceInterface_->getReferenceManagerPtr(), balanceInterface_->getBalanceControlCmd());
  rosReferenceManagerPtr->subscribe(nh);
```



### 模型里的参数

在BalanceSystemDynamics.h里有函数

```c
  ad_vector_t systemFlowMap(ad_scalar_t time, const ad_vector_t& state, const ad_vector_t& input,
                            const ad_vector_t& parameters) const override;
```

这个函数是定义在ocs2_core库中的一个虚函数，它的作用是计算系统动力学的流图。流图是指系统状态和输入之间的关系，它可以用来描述系统的行为和性能。

因为部分参数可能会动态变化的，所以需要函数里的parameters参数

我们也因此需要重写下面两个函数

```c
  vector_t getFlowMapParameters(scalar_t time, const PreComputation& preComputation) const override;
  size_t getNumFlowMapParameters() const override { return 2; }
```

`getFlowMapParameters()`会在`systemFlowMap()`执行时传入它获得的参数给parameters。

`getFlowMapParameters()`的数据来源通常是一个共享指针，以确保其他程序通过这个共享指针修改参数的值



这个动态变化的值是在哪里更新的呢？

在RosReferenceManager.cpp中，通过函数会修改一个共享指针的对象的值，廖在写代码时，这个共享指针是一个结构体，内部有多个变量，在定义约束对象和模型对象是会传入这个结构体的共享指针，并在需要的时候这些对象会读取共享指针



### 更新部分

 



# 调试问题

## Permission denied

> 当载入控制器时，报错：
>
> ```c
> /rm_hw: boost::filesystem::create_directory: Permission denied: "/tmp/rm/PowerLimit/cppad
> ```

重新编译都没有，su权限下删除/tmp/rm就好了，运行时会再生成一次
