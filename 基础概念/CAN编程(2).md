# CAN编程（2）

  SocketCAN 中大部分的数据结构和函数在头文件 **linux/can.h** 中进行了定义。 CAN 总线套接字的创建采用标准的网络套接字操作来完成。网络套接字在头文件 **sys/socket.h** 中定义，我们使用Linux原生的库来进行封装。



#### 	SocketCAN的通信实现

1. **初始化**

   ``` c
   1
   	int s;
   2
   	struct sockaddr_can addr;             //结构体创建
   3
   	struct ifreq ifr;
   4
   	s = socket(PF_CAN, SOCK_RAW, CAN_RAW);//创建 SocketCAN 套接字 
   5
   	strcpy(ifr.ifr_name, "can0" );        //字符串复制函数
   6
   	ioctl(s, SIOCGIFINDEX, &ifr);         //指定 can0 设备
   7
   	addr.can_family = AF_CAN;             //每个字节都用0填充
   8
   	addr.can_ifindex = ifr.ifr_ifindex;
   9
   	bind(s, (struct sockaddr *)&addr, sizeof(addr)); //将套接字与 can0 绑定
   ```



> **ifreq**结构定义在/usr/include/net/if.h，用来配置ip地址，激活接口，配置MTU等接口信息的。其中包含了一个接口的名字和具体内容——(是个共用体，有可能是IP地址，广播地址，子网掩码，MAC号，MTU或其他内容）。ifreq包含在ifconf结构中。而 ifconf结构通常是用来保存所有接口的信息。

> ``` c
> socket函数
> int socket(int af, int type, int protocol);
> //af:地址簇（ip地址类型）   type:传输类型，我们使用（SOCK_ROW）  protcocl:传输协议  
> ```

> ``` c
> ioctl函数
> int ioctl(int fd, int command, (char *) argstruct)； 
> //fd:文件描述符，即代码示例中的“s”   command：命令参数   argstruct：目标变量，即代码示例中的“ifr”
> ```



2. **数据发送**

 在数据收发的内容方面， CAN 总线与标准套接字通信稍有不同，每一次通信都采用 can_ frame结构体将数据封装成帧。 结构体定义如下：

``` c
1
	struct can_frame
   {
2
		canid_t can_id;       //CAN 标识符
3
		__u8 can_dlc;         //数据场的长度
4
		__u8 data[8];         //数据
5
	};
```

> can_id 是帧的标识符，如果发出的是标准帧， 就使用 can_id 的低 11 位； 如果为扩展帧， 就使用 0～ 28 位。 can_id 的第 29、 30、 31 位是帧的标志位，用来定义帧的类型，定义如下：
>
> ``` c
> 1
> 	#define CAN_EFF_FLAG 0x80000000U //扩展帧的标识
> 2
> 	#define CAN_RTR_FLAG 0x40000000U //远程帧的标识
> 3
> 	#define CAN_ERR_FLAG 0x20000000U //错误帧的标识，用于错误检查
> ```



  数据发送使用 write 函数来实现。 如果发送的数据帧(标识符为 0x123)包含单个字节(0xAB)的数据，可采用如下方法进行发送：

 如果要发送远程帧(标识符为 0x123)，可采用如下方法进行发送：

``` c
1
	struct can_frame frame;
2
	frame.can_id = 0x123;          //如果为扩展帧，那么 frame.can_id = CAN_EFF_FLAG | 0x123;
3
	frame.can_dlc = 1;             //数据长度为 1
4
	frame.data[0] = 0xAB;          //数据内容为 0xAB
5
	int nbytes = write(s, &frame, sizeof(frame)); //发送数据
6
	if(nbytes != sizeof(frame))    //如果 nbytes 不等于帧长度，就说明发送失败
7
	printf("Error\n!");
```

> ``` c
> write函数
>    ssize_t write (int fd, const void * buf, size_t count);   
> //fd:文件描述符，即代码示例中的“s”   //buf:发送者指针               //cout:所传输的字节数
> 
> //如果顺利write()会返回实际写入的字节数（len）。当有错误发生时则返回-1，错误代码存入errno中。
> ```



3. **数据接收**

 数据接收使用 read 函数来完成，实现如下：

``` c
1
	struct can_frame frame;
2
	int nbytes = read(s, &frame, sizeof(frame));
```

> ``` c
> read函数
> 	ssize_t read(int fd, void * buf, size_t count);
> //fd:文件描述符，即代码示例中的“s”    //buf:接收者指针              //cout:所接受的字节数
> /*
>   返回值为实际读取到的字节数, 如果返回0, 表示已到达文件尾或是无可读取的数据。若参数count 为0, 则read()不会有作用并返回0。另外，以下情况返回值小于count：
>   1.读常规文件时，在读到count个字节之前已到达文件末尾。例如，距文件末尾还有50个字节而请求读100个字节，则read返回50，下次read将返回0。
>   2.网络套接字接口，返回值可能小于count，详见：
>   blog.csdn.net/hhhlizhao/article/details/73912578
> */
> ```

​     套接字数据收发时常用的 send、 sendto、 sendmsg 以及对应的 recv 函数也都可以用于 CAN总线数据的收发。



4. **结束**

   ``` c
       close(int fd);                                                        //头文件：#include<unistd.h>
   //fd:所需要关闭的文件描述符                                                   关闭指针fp所指向的那个文件。
   /*
   返回值
   成功：返回0；
   失败：返回-1，并设置errno
   
   打开的文件描述符一定要记得关闭，否则资源会被大量的占用，导致内存不够
   */
   ```

   



***************

**错误处理**

...

**过滤**

...

**回环**

...



