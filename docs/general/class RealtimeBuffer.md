# class RealtimeBuffer
> 更新时间: 2026年02月27日

> 实时工具的一大特点就是使用“锁”，在锁的使用中实时工具会执行和普通变量获取类似的操作

```c
//普通的回调函数
	//订阅
	track_sub_ = nh.subscribe<rm_msgs::TrackData>("/track", 10, &ManualBase::trackCallback, this);

	//回调
  virtual void trackCallback(const rm_msgs::TrackData::ConstPtr& data)
  {
    track_data_ = *data;
  }
```



```c
//实时工具的回调
	//订阅
	cmd_gimbal_sub_ = controller_nh.subscribe<rm_msgs::GimbalCmd>("command", 1, &Controller::commandCB, this);

	//回调
void Controller::commandCB(const rm_msgs::GimbalCmdConstPtr& msg)
{
  cmd_rt_buffer_.writeFromNonRT(*msg);//这里调用写入非实时数据的函数，数据会先写到非实时缓冲里等待存入实时缓冲
}
```

可以看到我们数据不是简单的复制而是先写入非实时数据里，之后才会i进一步处理得到实时数据



下面先看存入非实时的这个函数

```c
//writeFromNonRT()
	void writeFromNonRT(const T& data)//是引用
  {
#ifdef NON_POLLING
    std::lock_guard<std::mutex> guard(mutex_);
#else
    std::unique_lock<std::mutex> guard(mutex_, std::try_to_lock);
    //程序会先循环尝试获得锁才会执行下一步，避免数据被另一个进程操控
    while (!guard.owns_lock()) {
      std::this_thread::sleep_for(std::chrono::microseconds(500));
      guard.try_lock();//锁了
    }
#endif

    //写入非实时，并通过bool值提示新数据传入
    // copy data into non-realtime buffer
    *non_realtime_data_ = data;
    new_data_available_ = true;
  }
```





非实时已经来了，那数据怎么被判断成实时？

我们的主循环函数里有一个数据读取的命令

```c
cmd_gimbal_ = *cmd_rt_buffer_.readFromRT();
```

```c
//readFromRT()
T* readFromRT()
  {
    // Check if the data is currently being written to (is locked)
    //std::mutex 是C++11 中最基本的互斥量，std::mutex对象提供了独占所有权的特性
    std::unique_lock<std::mutex> guard(mutex_, std::try_to_lock);
    
    //如果是锁的，那么数据是实时的，进行读取
    if (guard.owns_lock())
    {
      // swap pointers
      if (new_data_available_)
      {
        T* tmp = realtime_data_;
	realtime_data_ = non_realtime_data_;
        non_realtime_data_ = tmp;
	new_data_available_ = false;
      }
    }
    return realtime_data_;//返回实时值
  }
```







``` c++
#ifndef REALTIME_TOOLS__REALTIME_BUFFER_H_
#define REALTIME_TOOLS__REALTIME_BUFFER_H_

#include <chrono>
#include <mutex>
#include <thread>

namespace realtime_tools
{
  //承接realtime_tools::RealtimeBuffer<Commands> command_;接受特定类
template <class T>
class RealtimeBuffer
{
 public:
  RealtimeBuffer()                                                                 //构造函数
    : new_data_available_(false)
  {
    
    non_realtime_data_ = new T();
    realtime_data_ = new T();
  }

  /**
   * @brief Constructor for objects that don't have
   * a default constructor
   * @param data The object to use as default value
   */
  RealtimeBuffer(const T& data)
  {
    // 分配内存
    non_realtime_data_ = new T(data);
    realtime_data_ = new T(data);
  }
  //析构函数：有数据则释放动态内存
  ~RealtimeBuffer()
  {
    if (non_realtime_data_)
      delete non_realtime_data_;
    if (realtime_data_)
      delete realtime_data_;
  }

  RealtimeBuffer(const RealtimeBuffer &source)                                    //复制构造函数
  {
    // 分配内存
    non_realtime_data_ = new T();
    realtime_data_ = new T();

    // Copy the data from old RTB to new RTB
    writeFromNonRT(*source.readFromNonRT());
  }

  /*!
   * 自定义赋值运算符，使得类之间可以赋值
   */
  RealtimeBuffer &operator =(const RealtimeBuffer& source)
  {
    if (this == &source)
      return *this;

    // Copy the data from old RTB to new RTB
    writeFromNonRT(*source.readFromNonRT());

    return *this;
  }

  T* readFromRT()
  {
    // 检查数据当前是否正在写入（已锁定）
    std::unique_lock<std::mutex> guard(mutex_, std::try_to_lock);
    if (guard.owns_lock())      //是否拥有一个锁定的互斥体
                    //truec如果*this拥有一个关联的互斥体，并拥有它的共享所有权
    {
      // swap pointers
      if (new_data_available_)
      {
        T* tmp = realtime_data_;
	realtime_data_ = non_realtime_data_;
        non_realtime_data_ = tmp;
	new_data_available_ = false;
      }
    }
    return realtime_data_;
  }

  T* readFromNonRT() const
  {
    std::lock_guard<std::mutex> guard(mutex_);

    if (new_data_available_)
      return non_realtime_data_;
    else
      return realtime_data_;
  }

  void writeFromNonRT(const T& data)
  {
#ifdef NON_POLLING
    std::lock_guard<std::mutex> guard(mutex_);
#else
    std::unique_lock<std::mutex> guard(mutex_, std::try_to_lock);
    while (!guard.owns_lock()) {
      std::this_thread::sleep_for(std::chrono::microseconds(500));
      guard.try_lock();
    }
#endif

    // copy data into non-realtime buffer
    *non_realtime_data_ = data;
    new_data_available_ = true;
  }

  void initRT(const T& data)
  {
    *non_realtime_data_ = data;    
    *realtime_data_ = data;    
  }

 private:

  T* realtime_data_;
  T* non_realtime_data_;
  bool new_data_available_;

  // 设置为可变，以便可以在常量缓冲区上执行readFromNonRT（）
  mutable std::mutex mutex_;

}; // class
}// namespace

#endif
```
