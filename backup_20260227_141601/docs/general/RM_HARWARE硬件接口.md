# RM_HARWARE硬件接口
> 更新时间: 2026年02月27日



# can_bus.h

> 类CanBus: 设置了can name和保存有can数据的指针data_ptr
>
> ```c++
>   can::SocketCAN socket_can_;
>   CanDataPtr data_ptr_;
>   std::string bus_name_;
>   std::vector<CanFrameStamp> read_buffer_;
> 
>   can_frame rm_frame0_{};  // for id 0x201~0x204
>   can_frame rm_frame1_{};  // for id 0x205~0x208
> 
> mutable std::mutex mutex_//互斥量，确保只有一个线程访问该对象
> ```
>
> 
>
> 结构体CanFrameStamp: 结构体can_frame与 ros::time stamp
>
> ```c++
> //一系列can帧的结构
> canid_t can_id;  /* 32 bit CAN_ID + EFF/RTR/ERR flags */
> 	__u8    can_dlc; /* frame payload length in byte (0 .. CAN_MAX_DLEN) */
> 	__u8    __pad;   /* padding */
> 	__u8    __res0;  /* reserved / padding */
> 	__u8    __res1;  /* reserved / padding */
> 	__u8    data[CAN_MAX_DLEN] __attribute__((aligned(8)));
> ```

can bus将会从read_buffer中获取数据存储到指针data_ptr中，包括位置，速度，torque等，并在之后清空read_buffer



# 构造函数

```c++
CanBus::CanBus(const std::string& bus_name, CanDataPtr data_ptr) : data_ptr_(data_ptr), bus_name_(bus_name)
{
  // Initialize device at can_device, false for no loop back.
  while (!socket_can_.open(bus_name, boost::bind(&CanBus::frameCallback, this, _1)) && ros::ok())
    ros::Duration(.5).sleep();

  ROS_INFO("Successfully connected to %s.", bus_name.c_str());
  // Set up CAN package header
  rm_frame0_.can_id = 0x200;
  rm_frame0_.can_dlc = 8;
  rm_frame1_.can_id = 0x1FF;
  rm_frame1_.can_dlc = 8;
}
```



# void CanBus::write()

```c++
//首先默认认为write没有执行，并将frame帧填充为0
bool has_write_frame0 = false, has_write_frame1 = false;
std:fill(... ,0);
    
//for循环写入数据

//socket_can写入数据
socket_can_.write(&frame);
//之后判断has_write_frame，又调用了skocket_can的write?
```

string::npos参数： npos是一个常数，用来表示不存在的位置，npos定义的类型是： string::size_type。



# void read(ros::Time time);

```c++
将命令写入can bus
//使用了互斥mutex_，避免多线程在
```



# void frameCallback(const can_frame& frame);

```c++
帧回调，回调从socketcan获取的帧
```
