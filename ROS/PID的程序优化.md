# PID的程序优化



### 积分分离

在普通 PID 控制中,引入积分环节的目的,主要是为了消除静差,提高控制精度。但是在启动、结束或大幅度增减设定时,短时间内系统输出有很大的偏差,会造成 PID 运算的积分积累,导致控制量超过执行机构可能允许的最大动作范围对应极限控制量,从而引起较大的超调,甚至是震荡,这是绝对不允许的。为了克服这一问题,引入了积分分离的概念,其基本思路是 **当被控量与设定值偏差较大时,取消积分作用; 当被控量接近给定值时,引入积分控制,以消除静差,提高精度**。 

使用后可以提高系统接近目标值的速度。

``` c++
样码示例
#include <iostream>
#include<cmath>

using namespace std;

void PID_init();
float PID_realize(float speed);

struct _pid{
float SetSpeed;//定义设定值
float ActualSpeed;//定义实际值
float err;//定义偏差值
float err_last;//定义上一个偏差值
float Kp,Ki,Kd;//定义比例、积分、微分系数
float voltage;//定义电压值(控制执行器的变量)                                           //因变量
float integral;//定义积分值
}pid;

bool index;
int main()
{
    cout<<"System begin \n";
    PID_init();
    int count=0;
    while(count<1000)
    {
    float speed=PID_realize(200.0);
    cout<<"第 "<<count<<" 次的速度为: "<<speed<<endl;
    count++;
    }
    return 0;

}


void PID_init(){                                                                   //创建初始数值
cout<<"PID_init begin \n";
pid.SetSpeed=0.0;
pid.ActualSpeed=0.0;
pid.err=0.0;
pid.err_last=0.0;
pid.voltage=0.0;
pid.integral=0.0;
pid.Kp=0.2;
pid.Ki=0.04;
pid.Kd=0.2;
cout<<"PID_init end \n";
}


float PID_realize(float speed){
pid.SetSpeed=speed;
pid.err=pid.SetSpeed-pid.ActualSpeed;
if(abs(pid.err)>180)                                                              //判断依据：误差大小
{
index=0;
}else{
index=1;
pid.integral+=pid.err;
}
pid.voltage=pid.Kp*pid.err+index*pid.Ki*pid.integral+pid.Kd*(pid.
err-pid.err_last);
//算法具体实现过
pid.err_last=pid.err;
pid.ActualSpeed=pid.voltage*1.0;
return pid.ActualSpeed;
}


```





### 抗积分饱和

所谓的积分饱和现象是指如果系统存在一个方向的偏差,PID 控制器的输出由于积分作用的不断累加而加大,从而导致执行机构达到极限位置,若控制器输出 U(k)继续增大,执行器开度不可能再增大,此时计算机输出控制量超出了正常运行范围而进入饱和区。一旦系统出现反向偏差,u(k)逐渐从饱和区退出。进入饱和区越深则退出饱和区时间越长。在**这段时间里,执行机构仍然停留在极限位置而不随偏差反向而立即做出相应的改变**,这时系统就像失控一样,造成控制性能恶化,这种现象称为积分饱和现象或积分失控现象。防止积分饱和的方法之一就是抗积分饱和法,该方法的思路是在计算 u(k)时,首先判断上一时刻的控制量 u(k-1)是否已经超出了极限范围: 如果$$u(k−1)>umaxu(k−1)>umax$$,则只累加负偏差（**防止正偏差过大**）; 如果 $$u(k−1)<umin$$,则只累加正偏差（**防止负偏差过大**）。从而避免控制量长时间停留在饱和区。 

``` c++
样码示例
    #include <iostream>

using namespace std;

void PID_init();
float PID_realize(float speed);

struct _pid{
float SetSpeed;//定义设定值
float ActualSpeed;//定义实际值
float err;//定义偏差值
float err_last;//定义上一个偏差值
float Kp,Ki,Kd;//定义比例、积分、微分系数
float voltage;//定义电压值(控制执行器的变量)
float integral;//定义积分值
float umax;//执行机构可执行的最大值
float umin;//执行机构可执行的最小值
}pid;


int main()
{
    cout<<"System begin \n";
    PID_init();
    int count=0;
    while(count<1000)
    {
    float speed=PID_realize(200.0);
    cout<<"第 "<<count<<" 次的速度为: "<<speed<<endl;
    count++;
    }
    return 0;

}


void PID_init(){
cout<<"PID_init begin \n";
pid.SetSpeed=0.0;
pid.ActualSpeed=0.0;
pid.err=0.0;
pid.err_last=0.0;
pid.voltage=0.0;
pid.integral=0.0;
pid.Kp=0.2;
pid.Ki=0.1;
pid.Kd=0.2;
pid.umax=400;
pid.umin=-200;
cout<<"PID_init end \n";
}


float PID_realize(float speed){
    pid.SetSpeed=speed;
    pid.err=pid.SetSpeed-pid.ActualSpeed;
    if(pid.ActualSpeed>pid.umax)                                                      //先尝试抗积分再尝试积分分离
    {
    //灰色底色表示抗积分饱和的实现
   		if(abs(pid.err)>200)                                                          //判断依据：误差
    //蓝色标注为积分分离过程
    	{
   	 	index=0;
    	}
    	else
        {
    	index=1;
   	 		if(pid.err<0)
    		{
    			pid.integral+=pid.err;
    		}
   	 	}
    }
    //////////////////////////////////////////////////
    else if(pid.ActualSpeed<pid.umin)
    {
    	if(abs(pid.err)>200)
    //积分分离过程
    	{
    	index=0;
    	}
        else
        {
    	index=1;
    		if(pid.err>0)
    		{
    			pid.integral+=pid.err;
    		}
    	}
    }
    //////////////////////////////////////////////////
    else
    {
    	if(abs(pid.err)>200)
    //积分分离过程
    	{
    	index=0;
    	}
        else
        {
    	index=1;
    	pid.integral+=pid.err;
    	}
    }
    
    pid.voltage=pid.Kp*pid.err+index*pid.Ki*pid.integral+pid.Kd*(pid.
    err-pid.err_last);
    pid.err_last=pid.err;
    pid.ActualSpeed=pid.voltage*1.0;
    return pid.ActualSpeed;
}

```

