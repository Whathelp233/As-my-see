# Arduino基础

## 函数

> 在官网www.arduino.cc下，你可以见到官方准备好的函数
>
> （Learning->function）
>
> http://www.taichi-maker.com/homepage/reference-index/arduino-code-reference/提供中文文档



### 数字I/O

#### pinMode()

> 通过pinMode()函数，你可以将Arduino的引脚配置为以下三种模式：
>
> - 输出(OUTPUT)模式
> - 输入(INPUT)模式
> - 输入上拉（INPUT_PULLUP）模式 （仅支持Arduino 1.0.1以后版本）

```c++
//分有高低阻抗状态
//函数有两个参数，第一个为引脚编号，也可以使用宏定义(关键字)
//不同单片机同一工作元件可能编号不同，使用关键字更方便有效
pinMode(LED_BULLTIN,OUTPUT);
```



#### digitalWrite()

> 将数字引脚写[HIGH](http://www.taichi-maker.com/homepage/reference-index/arduino-code-reference/high/)（高电平）或[LOW](http://www.taichi-maker.com/homepage/reference-index/arduino-code-reference/low/)（低电平）
>
> 输出模式: 通过digitalWrite()语句将该引脚设置为HIGH（5伏特）或LOW（0伏特/GND）。
>
> 输入模式:当通过digitalWrite()语句将该引脚设置为HIGH时，该引脚将被与设置为输入上拉(INPUT_PULLUP)模式相同。

```c
digitalWrite(引脚编号,状态)；
```



#### digitalRead()

> 读取数字引脚的 HIGH(高电平）或 LOW（低电平）。
>
> 返回HIGH / LOW

```c
digitalRead(引脚编号);
```







### 时间

```c++
delay(A);                                             //毫秒
delayMicroseconds(A);                                 //微秒
```









# 实例

## LED

> LED的长脚为正极端，它的工作电流约为20mA
>
> 通常我们需要限流电阻，如果led进入工作状态（阻值极低），电路会产生极大电流

工作图：

