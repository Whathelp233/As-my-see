# 将ROS和STM32连接

> 装载ROS的是树莓派，NUC等主控，如何将主控与STM32连接起来。例如主控想要通过stm32控制一些电机

原理：

![2022-11-29 21-29-48 的屏幕截图](/home/yuchen/图片/2022-11-29 21-29-48 的屏幕截图.png)

需要一块串口转换芯片来作为“翻译官”，因为二者的通信协议是不同的

软件设置：

![2022-11-29 21-31-33 的屏幕截图](images/将ROS和STM32连接/2022-11-29 21-31-33 的屏幕截图.png)