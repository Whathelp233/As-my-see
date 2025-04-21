# C++游戏编程

## 基础

### 创建窗口

> 建立应用界面

```c++
#include <graphics.h> //c++图形界面，是VS特有库，其他软件使用请访问http://mb.sanhaostreet.com/caijing/202101/116991.html

initgraph(640,480);    //宽高

system("pause");//悬停窗口，用于窗口悬停
```



























# 实战

## 抽卡模拟

> 概念：卡池概率，卡池保底，
>
> 需求：随机数生成，保底算法

```c++
随机数生成
    num = rand()%5   //rand()函数会产生范围为0至32767的随机数，% 让它与5求余，变成0至4的随机数，不过每次启动程序产生的随机数都相等，一般用srand((unsigned int)time(NULL)) 产生种子。（记得要包含 time.h 库文件）
    
保底机制
    Draw_target_card(stars)  //调用函数，传入参数stars决定星级
    
    not_get_stars5++;        //保底参数
	if(not_get_stars>=10) Draw_target_card(5);

	if(stars == 5) not_get_stars5=0;//保底重置
```

