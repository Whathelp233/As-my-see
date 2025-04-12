# 代码库CAN

> rm库中的can交流方式

### socketcan.h

> 可以解决帧排队，高级传输协议，局限设备，仅单线程等问题的socketcan

对通信端点进行抽象，配置程序通过网络协议进行通信的接口

```c++
ifreq       interface_request_{};    
            //ifreq结构定义在/usr/include/net/if.h，用来配置ip地址，激活接口，配置MTU等接口信息
sockaddr_can address_{};
			//CAN套接字地址，这是一个网络地址，将会与生成的套接字绑定
pthread_t    receiver_thread_id_{};
            //过pthread_self(void) 函数获取当前线程的id

//线程id的类型为pthread_t

pthread.h 声明了pthread_self (void)的函数，格式如下

extern pthread_t pthread_self (void) __THROW __attribute__ ((__const__));

在pthreadtypes.h中：

typedef unsigned long int pthread_t;
//声明为无符号长整型
```



```c++
 bool open(const std::string& interface, boost::function<void(const can_frame& frame)> handler);
          //interface:接口名称，例如can0 handler：指向从CAN总线接收帧时应调用的函数的指针
 void close();
          //关闭套接字
 bool is_open() const;
		  //检测套接字是否打开，如果检测到开启，返回\c true
 void write(can_frame* frame) const;
		  //发送帧到总线 frame：将要发送的帧
 bool start_receiver_thread();
		  //增设线程，等待套接字

boost::function<void(const can_frame& frame)> reception_handler;
  		  //指向要调用的函数的指针，当总线上获取到帧时

```



#### 执行逻辑

- 析构函数：结束时先检测是否已有套接字，若有则关闭

- open( ):     进行套接字初始化操作 /建立套接字，设置为原始套接字，原始CAN协议/

