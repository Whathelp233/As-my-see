# LinuxCAN编程



[Linux CAN编程详解](https://blog.csdn.net/lizhu_csdn/article/details/51490958)

[can-utils源码解析cansend](https://blog.csdn.net/weixin_30807677/article/details/96494884?spm=1001.2101.3001.6650.5&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7Edefault-5.queryctrv2&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7Edefault-5.queryctrv2&utm_relevant_index=10)





实例

​    server端的程序，一个服务器的程序（采用原始套接字），该程序接收来自客户端发来的数据：

```  c
{
int sock_fd;

​        unsigned long nbytes, len;

​        struct sockaddr_can addr;

​        struct ifreq ifr;

​       /*为了能够接收CAN报文，我们需要定义一个CAN数据格式的结构体变量*/

​       struct can_frame frame;

​       struct can_frame *ptr_frame;

​       /*建立套接字，设置为原始套接字，原始CAN协议 */

​       sock_fd = socket(PF_CAN,SOCK_RAW,CAN_RAW);

​      /*以下是对CAN接口进行初始化，如设置CAN接口名，即当我们用ifconfig命令时显示的名字 */

​      strcpy(ifr.ifr_name,"can0");

​       ioctl(sock_fd, SIOCGIFINDEX, &ifr);

​      printf("can0 can_ifindex = %x\n",ifr.ifr_ifindex);

​      /*设置CAN协议 */

​      addr.can_family = AF_CAN;

​      addr.can_ifindex = 0;

​     /*将刚生成的套接字与网络地址进行绑定*/

​     bind(sock_fd, (struct sockaddr*)&addr, sizeof(addr));

​     /*开始接收数据*/

​     nbytes = recvfrom(sock_fd, &frame, sizeof(struct can_frame), 0, (struct sockaddr *)&addr, &len);

​    

​     /*get interface name of the received CAN frame*/

​     ifr.ifr_ifindex = addr.can_ifindex;

​     ioctl(sock_fd, SIOCGIFNAME, &ifr);

​     printf("Received a CAN frame from interface %s\n",ifr.ifr_name);

​    /*将接收到的CAN数据打印出来，其中ID为标识符，DLC为CAN的字节数，DATA为1帧报文的字节数*/

​     printf("CAN frame:\n ID = %x\n DLC = %x\n" \

​           "DATA = %s\n",frame.can_id,frame.can_dlc,frame.data);

​     ptr_frame = &frame;

​     return 0;

}
```



​     接下来是CAN的发送程序，即客户端，代码如下：

``` c
     int sock_fd;

​     unsigned long nbytes;

​     struct sockaddr_can addr;

​     struct ifreq ifr;

​     struct can_frame frame;

​     /*建立套接字，设置为原始套接字，原始CAN协议 */

​     sock_fd = socket(PF_CAN,SOCK_RAW,CAN_RAW);

​     /*以下是对CAN接口进行初始化，如设置CAN接口名，即当我们用ifconfig命令时显示的名字 */

​     strcpy((char *)(ifr.ifr_name), "can0");

​     ioctl(sock_fd, SIOCGIFINDEX, &ifr);

​     printf("can0 can_ifindex = %x\n", ifr.ifr_ifindex);   

​     addr.can_family = AF_CAN;      

​     addr.can_ifindex = ifr.ifr_ifindex;    

​     /*将刚生成的套接字与CAN套接字地址进行绑定*/     

​     bind(sock_fd, (struct sockaddr*)&addr, sizeof(addr));  

​     /*设置CAN帧的ID号，可区分为标准帧和扩展帧的ID号*/    

​     frame.can_id = 0x1122;     
          
​     strcpy((char *)frame.data,"hello");    

​     frame.can_dlc = strlen(frame.data);    

​     printf("Send a CAN frame from interface %s\n", ifr.ifr_name); 

​     /*开始发送数据*/     

​     nbytes = sendto(sock_fd, &frame, sizeof(struct can_frame), 0, (struct sockaddr*)&addr,sizeof(addr));    
          
​               return 0；
}
```

> 注：server从CAN总线上接收数据，client将数据发到CAN总线上，当CAN总线上有数据时，server才能接收数据，当CAN总线空闲时，client才能将数据发送出去

  



#### socketcan的数据发送

  （1） 创建一个套接字socket，采用AF_CAN协议；

  （2）将创建的套接字返回描述符sockfd，绑定到本地的地址；

  （3）通过sendto系统调用函数进行发送；



sendto的函数声明：

``` c
int sendto(int sockfd, const void *msg, intlen,unsigned intflags, const struct sockaddr *to, int tolen);
```

> > ​     sockfd:通过socket函数生成的套接字描述符；
> >
> > ​     msg:该指针指向需要发送数据的缓冲区；
> >
> > ​     len:是发送数据的长度；
> >
> > ​     to:目标主机的IP地址及端口号信息；