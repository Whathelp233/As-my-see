# PID算法的程序流程
> 更新时间: 2026年02月27日

# **PID算法的程序流程**

​                                                                                            **增量型PID算法和位置型PID算法的程序流程**

![img](https://img2020.cnblogs.com/blog/1149873/202003/1149873-20200328144942199-1982693739.png)

# **增量型PID算法的程序流程**



a、 增量型PID算法的算式

​      ![img](https://img2020.cnblogs.com/blog/1149873/202003/1149873-20200328144823163-541828766.png)

​    式中![img](https://img2020.cnblogs.com/blog/1149873/202003/1149873-20200328144834516-834022472.png)，![img](https://img2020.cnblogs.com/blog/1149873/202003/1149873-20200328144853197-809235535.png)，![img](https://img2020.cnblogs.com/blog/1149873/202003/1149873-20200328144901954-270471695.png)

 $$或$$

<img src="https://gss0.baidu.com/94o3dSag_xI4khGko9WTAnF6hhy/zhidao/wh%3D600%2C800/sign=5bff6908f21986184112e7827add024b/b812c8fcc3cec3fd14e74b1cdc88d43f869427fa.jpg" alt="pid算法中位置型和增量型有什么区别，分析两者优缺点 " style="zoom: 80%;" />

> K~p~，K~i~，K~D~表示比例，积分，微分系数; e表示误差

> 由于计算机输出的u（k）可直接控制执行机构（如阀门），u（k）的值和执行机构的位置（如阀门开度）是一一对应的

> 缺点：每次输出均与过去的状态有关，计算时要对e（k）进行累加，计算机运算工作量大。



​    

#  

# 位置型PID算法的程序流程

​    位置型的递推形式

​       ![img](https://img2020.cnblogs.com/blog/1149873/202003/1149873-20200328145004263-823428702.png)

​    $$或$$

<img src="https://gss0.baidu.com/94o3dSag_xI4khGko9WTAnF6hhy/zhidao/wh%3D600%2C800/sign=602c1a97c9fdfc03e52debbee40fabac/e4dde71190ef76c60f3f17429716fdfaae5167ee.jpg" alt="pid算法中位置型和增量型有什么区别，分析两者优缺点 " style="zoom:80%;" />

位置和增量没有本质区别，就是数字pid的两种不同表示形式而已,位置型只需在增量型PID算法的程序流程基础上增加一次加运算Δu(n)+u(n-1)=u(n)和更新u(n-1)即可。

> 位置型需要历次的偏差信号，而增量型只需一个增量信号即可。位置型计算繁琐，保存E占用很多内存，控制不方便。由于计算机输出增量，所以误动作影响小，必要时可用逻辑判断的方法去掉;

> 增量型误动作小，易于实现手动/自动的无扰动切换，不产生积分失控。但是缺点在于积分截断效应大，有静态误差;积分截断效应大，溢出影响大。因此，应该根据被控对象的实际情况加以选择。



# **区别：**

​	　　（1）位置式PID控制的输出与整个过去的状态有关，用到了误差的累加值;而增量式PID的输出只与当前拍和前两拍的误差有关，因此位置式PID控制的累积误差相对更大;

​	　　（2 ）增量式PID控制输出的是控制量增量，并无积分作用，因此该方法适用于执行机构带积分部件的对象，如步进电机等，而位置式PID适用于执行机构不带积分部件的对象，如电液伺服阀。

​	　　（3 ）由于增量式PID输出的是控制量增量，如果计算机出现故障，误动作影响较小，而执行机构本身有记忆功能，可仍保持原位，不会严重影响系统的工作，而位置式的输出直接对应对象的输出，因此对系统影响较大。





**参考样码**

``` matlab


    clear all;close all;clc;
    target_speed = [5*ones(300,1);ones(300,1);ones(300,1)*10;ones(300,1)*2]; %目标值矩阵
    real_speed = zeros(length(target_speed),1);                              %实际值矩阵
    Kp = 0.2;Ki = 0.1;Kd = 0.1;                                              %系数
    intergral = 0;                                                          %总偏差(位置型)
    pre_err = 0;                                                            %上一个误差
    for i=2:length(target_speed)                                            %遍历目标矩阵
        
        err = target_speed(i) - real_speed(i-1);
        intergral = intergral + err;                                        %更新总偏差
        u = Kp*err + Ki*intergral + Kd*(err - pre_err);
        pre_err = err;                                                      %更新上一个偏差
        
        real_speed(i) = u;　　　　%简化一下，控制量直接转为状态量了
    end
    plot(target_speed,'b')
    hold on;                     %保留上一副作图
    plot(real_speed,'r')
    legend('目标','实际')


```

****

**练习**

``` matlab
clear; clc;                                                       %P控制
target = 10*ones(100,1);
real   = zeros(100,1);

Kp = 0.2;%Ki = 0.1;Kd = 0.1;                           
    intergral = 0;
    pre_err = 0;
for i=2:length(target)
    err = target(i) - real(i-1);
    intergral = intergral + err;
    u = Kp*err;
    
    pre_err = err;
    real(i)=u;
end

plot(target,'b')
hold on
plot(real,'r')
legend('目标','实际')
```

![img](https://i0.hdslb.com/bfs/album/d9db240080010f34a65eaa50b2baa3557ec49204.png@518w.webp)

​                                                     $$P控制:有一个稳态误差，图中比较突出$$



``` matlab
clear; clc;                                                        %PI控制
target = [10*ones(100,1);ones(100,1)];
real   = zeros(200,1);

Kp = 0.2;Ki = 0.1;%Kd = 0.1;                           
    intergral = 0;
    pre_err = 0;
for i=2:length(target)
    err = target(i) - real(i-1);
    intergral = intergral + err;
    u = Kp*err+Ki*intergral;
    
    pre_err = err;
    real(i)=u;
end

plot(target,'b')
hold on;
plot(real,'r')
legend('目标','实际')
```

​                         ![img](https://i0.hdslb.com/bfs/album/1047dc7bce25837d3e422f78bb50da2d146c2a86.png@518w.webp)

​                                                                  $$PI控制：效果得到改善$$



``` matlab
clear; clc;                                                        %PID控制
target = [10*ones(100,1);ones(100,1)];
real   = zeros(200,1);

Kp = 0.22;Ki = 0.47;Kd = 0.03;                           
    intergral = 0;
    pre_err = 0;
for i=2:length(target)
    err = target(i) - real(i-1);
    intergral = intergral + err;
    u = Kp*err+Ki*intergral+Kd*(err-pre_err);
    
    pre_err = err;
    real(i)=u;
end

plot(target,'b')
hold on;
plot(real,'r')
legend('目标','实际')
```

![img](https://i0.hdslb.com/bfs/album/873a2996351cb8a16a5da6062ab3d46c1382fef0.png@518w.webp)

​                                                                    $$PID控制：效果进一步提高$$
