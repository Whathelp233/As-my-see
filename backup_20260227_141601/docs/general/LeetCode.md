# LeetCode
> 更新时间: 2026年02月27日



# 爬楼梯

> 假设你正在爬楼梯。需要 `n` 阶你才能到达楼顶。
>
> 每次你可以爬 `1` 或 `2` 个台阶。你有多少种不同的方法可以爬到楼顶呢？



# 动态规划

我们可以发现因为一次可以爬 1 或 2 个台阶，那么当我爬到第 1 个台阶是一定只有一种爬法，但我爬到第 2 个台阶时就可以有两种爬法了，可以一次爬一个台阶，也可以一次爬 2 个台阶

当我们爬到第 3 个台阶时该怎么办呢我们观察可以发现，**将爬到第一个台阶和爬到第二个台阶的方法结合，在只有一步可走的情况下，我可以在第二级台阶基础上一个台阶的爬；也可以在第一级台阶的基础上上爬两个，即分别对应前两个状态；**，这样以来我们的状态转移方程就有了



 $$DP[i] = DP[i - 1] + DP[i - 2]$$



- 这玩意就是-斐波那契数列-

那么初始化状态呢，刚刚通过分析也可以得到第 1 和第 2 个台阶不符合状态转移方程所需要的步骤，所以作为特殊情况进行初始化即DP[0] = 1,DP[1] = 2

``` 1
虽然第一步，第二步不符合，你也可以假设多两个步骤，即从第0级到第0级，第0级到第一级。
```



# 通项公式

**数列的特征方程**

一个数列:

![img](https://bkimg.cdn.bcebos.com/formula/a9b5b71f33d54eb9ec8c0e5c71b95aad.svg)

设 有r，s使

![img](https://bkimg.cdn.bcebos.com/formula/aa74c79d940c2b792a0abeaad4553bfb.svg)

所以

![img](https://bkimg.cdn.bcebos.com/formula/13831585e7633042c6ba9c792f288bba.svg)

得

![img](https://bkimg.cdn.bcebos.com/formula/e9ec407ae32ddc1452e5a7919e766b82.svg)

![img](https://bkimg.cdn.bcebos.com/formula/8ae70e6222559ad968dbcb81aeeba6f1.svg)

消去s就导出特征方程式

![img](https://bkimg.cdn.bcebos.com/formula/a5359fb2eacad42fefd72aa5ed3296ad.svg)





**斐波那契数列的特征方程**：

**0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, ...**



![img](https://bkimg.cdn.bcebos.com/formula/94b8c9731e50371cf2596e9dc1edc14f.svg)

解得

![img](https://bkimg.cdn.bcebos.com/formula/046c54102aac3f8c1c11c8f3a43e221c.svg)

则

![img](https://bkimg.cdn.bcebos.com/formula/238676724d116c9afbcc45fcea05bc13.svg)

因为

![img](https://bkimg.cdn.bcebos.com/formula/ba2ec74454e3c96d6a854ad432303e33.svg)

所以

![img](https://bkimg.cdn.bcebos.com/formula/669d76d534370c4891429500cc706cdb.svg)

解得：

![img](https://bkimg.cdn.bcebos.com/formula/6800cdaaba9e8d9781f54c7a928c7a36.svg)

所以

![img](https://bkimg.cdn.bcebos.com/formula/8a23e32f64deddec79215bc5d34ada85.svg)



接着我们就可以通过这个公式直接求第 n项了





# X的平方根

>给你一个非负整数 x ，计算并返回 x 的 算术平方根 。
>
>由于返回类型是整数，结果只保留 整数部分 ，小数部分将被 舍去 。
>
>注意：不允许使用任何内置指数函数和算符，例如 pow(x, 0.5) 或者 x ** 0.5 。

# 普通平方法

第一次尝试并成功的方法，挨个遍历一定范围内的数字，满足条件后返回

```c++
for(long int i=0;i<=x/2+1;i++)
        {
            j=i*i;
            if(j==x) return i;
            if(j>x&&x>buff) return i-1;
            buff=i*i;
        }
//使用范围为x/2 + 1，比较粗糙
//判断条件，平方后等于目标数或目标数在两个数的中间
```

运行时间较长，内存大小不错



# 对数法

题目没说不能用对数函数，所以，额：

```c++
result = exp(0.5*log(x));
        
        if((long long)(result+1)*(result+1)<=x) result++;
return result；
//对数有误差，需要判断（例如：2147395600）
//原因在于小数被直接舍去
```



# 二分法

不断的二分以逼近结果

```c++
if(x==1) return 1;
        
        mid=(right+left)/2;//不能使用r-(r-l)/2，因为int会略小数
        while(mid!=left)
        {
            
            if((long long)mid*mid<=x) 
            {
                left=mid;
            }
            else          
            {
                right=mid;
            
            } 
            
            mid=(right+left)/2;//不能使用r-(r-l)/2，因为int会略小数
            
        }
```



# 牛顿迭代法

求$$x^2-a=0$$ 零点任意选取横坐标x，得到点$$(x,f(x))$$ 以当前点求切线，切线延长交横坐标于一点，以该点横坐标继续求函数上切线再切，往复多次后得到较精确数值

```c++
        double xn1=100;
        double xn2=(xn1+a/xn1)/2;
        
        for(int i=0;i<15;i++)//迭代次数，多一点
        {
            xn1=xn2;
            xn2=(xn1+a/xn1)/2;
        }
```
