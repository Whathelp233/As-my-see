# CAN命令

> 包含5个独立的命令程序
>
> ```****
> canconfig,candump,canecho,cansend,cansequence
> ```



### 操作流程

```bash
sudo ip link set can0 up type can bitrate 1000000   #设置can0波特率  can0和can1都需要初始化
```
```bash
candump can0                              #打开另一个终端，接受can0数据
```

```bash
cansend can0 0x11                         #打开一个终端，发送默认id 0x1的can标准帧，每次最大8byte
```





#### ip

```bash
sudo ip link add dev vcan0 type vcan
#添加vcan0网卡
#ip link set can0 type can --help
ip link set can0 up type can bitrate 800000
#设置can0的波特率为800kbps,CAN网络波特率最大值为1Mbps
ip link set can0 up type can bitrate 800000 loopback on
#设置回环模式，自发自收，用于测试是硬件是否正常,loopback不一定支持
ip link set can0 down(up)
#关闭(开启)can0 网络 
```



#### cansend

```bash
cansend can0 0x11 0x22 0x33 0x44 0x55 0x66 0x77 0x88
#发送默认ID为0x1的can标准帧，数据为0x11 22 33 44 55 66 77 88
#每次最大8个byte
cansend can0 -i 0x800 0x11 0x22 0x33 0x44 0x55 0x66 0x77 0x88 -e
#-e 表示扩展帧，CAN_ID最大29bit，标准帧CAN_ID最大11bit 
#-i表示CAN_ID 0x800
cansend can0 -i 0x02 0x11 0x12 --loop=20
#--loop 表示发送20个包 
```










> can0和can1 设备为两个 CAN 总线接口。
>
> 使用 ip 命令来配置 CAN 总线的位速率：
>
> ```
> ip link set can0 type cantq 125 prop-seg 6phase-seg1 7 phase-seg2 2 sjw 1
> ```
>
> 
>
> ```bash
> ip link set can0 type can bitrate 125000   #ip 命令直接设定位速率
> ```
>
> ```bash
> ip -details link show can0                 #查询 can0 设备的参数设置
> ```
>
> ```bash
> ifconfig -a                                #检查can状态
> ```
>
> 
>
> ```bash
> ifconfig can0 up                           #使能 can0 设备
> ```
>
> ```bash
> ifconfig can0 down                         #取消 can0 设备使能
> ```
>
> ```bash
> ip -details -statistics link show can0     #查询工作状态
> ```
>
> 