# class RealtimePublisher
> 更新时间: 2026年02月27日

``` c++
/*
*发布ROS消息很困难，因为发布功能
*不是实时安全的。此类提供了适当的锁定，以便
*您可以调用实时发布和单独的（非实时）发布
*线程将确保消息通过ROS发布。 
 */
#ifndef REALTIME_TOOLS__REALTIME_PUBLISHER_H_
#define REALTIME_TOOLS__REALTIME_PUBLISHER_H_

#include <string>
#include <ros/node_handle.h>
#include <boost/utility.hpp>
#include <boost/thread/mutex.hpp>
#include <boost/thread/thread.hpp>
#include <boost/thread/condition.hpp>
#include <chrono>
#include <thread>

namespace realtime_tools {

template <class Msg>
class RealtimePublisher : boost::noncopyable
{

public:
  /// The msg_ variable contains the data that will get published on the ROS topic.
  Msg wmsg_;
  
  /** 实时发布服务器的构造函数：
   *
   * \param "node"       : the nodehandle that specifies the namespace (or prefix) that is used to advertise the ROS topic
   * \param "topic"      : the topic name to advertise
   * \param "queue_size" :the size of the outgoing ROS buffer（缓冲区）
   * \param "latched"    :optional argument (defaults to false) to specify is publisher is latched or not
   */
  RealtimePublisher(const ros::NodeHandle &node, const std::string &topic, int queue_size, bool latched=false)
    : topic_(topic), node_(node), is_running_(false), keep_running_(false), turn_(REALTIME)
  {
    construct(queue_size, latched);
  }

  RealtimePublisher()
    : is_running_(false), keep_running_(false), turn_(REALTIME)
  {
  }
=============================================================================
  /// Destructor
  ~RealtimePublisher()
  {
    stop();
    while (is_running())
    {
     //表示当前线程休眠一段时间(100微秒)，休眠期间不与其他线程竞争CPU，根据线程需求，等待若干时间。
     //std::chrono::microseconds:  chrono库，用于实现定时功能
      std::this_thread::sleep_for(std::chrono::microseconds(100));
    }
     //关闭发布者
    publisher_.shutdown();
  }

  void init(const ros::NodeHandle &node, const std::string &topic, int queue_size, bool latched=false)
  {
    topic_ = topic;
    node_ = node;
    construct(queue_size, latched);
  }

  /// 阻止实时发布者发送更多ROS消息 
  void stop()
  {
    keep_running_ = false;
  //轮询（Polling）是一种CPU决策如何提供周边设备服务的方式，又称“程控输入输出”（Programmed I/O）。轮询法的概念是：由CPU定时发出询问，依序询问每一个周边设备是否需要其服务，有即给予服务，服务结束后再问下一个周边，接着不断周而复始。
#ifdef NON_POLLING
    //来自boost::condition_variable updated_cond_;
    //notify_one:唤醒等待队列中的第一个线程,执行到wait时会阻塞
    updated_cond_.notify_one();  // So the publishing loop can exit
#endif
  }

  /**  尝试从实时获取数据锁 
   *
   * To publish data from the realtime loop, you need to run trylock to
   * attempt to get unique access to the msg_ variable. Trylock returns
   * true if the lock was aquired, and false if it failed to get the lock.
   */
  bool trylock()
  {
    //来自boost::mutex msg_mutex_;
    //互斥量（mutex）：调用线程从成功调用lock()或try_lock()开始，到unlock()为止占有mutex对象。当存在某线程占有mutex时，所有其他线程若调用lock则会阻塞，而调用try_lock会得到false返回值。
    if (msg_mutex_.try_lock())
    {
      if (turn_ == REALTIME)
      {
        //实时且开锁情况下返回ture
        return true;
      }
      else
      {
        //非实时情况下开锁尝试获取最新数据并返回flase
        msg_mutex_.unlock();
        return false;
      }
    }
    else
    {
      //锁定时返回flase
      return false;
    }
  }

  /**  解锁msg_变量 
   *
   * After a successful trylock and after the data is written to the mgs_
   * variable, the lock has to be released for the message to get
   * published on the specified topic.
   */
  void unlockAndPublish()
  {
    turn_ = NON_REALTIME;
    msg_mutex_.unlock();
#ifdef NON_POLLING
    updated_cond_.notify_one();
#endif
  }

  /** 非实时获取数据锁表单
   *
   * To publish data from the realtime loop, you need to run trylock to
   * attempt to get unique access to the msg_ variable. Trylock returns
   * true if the lock was aquired, and false if it failed to get the lock.
   */
  void lock()
  {
#ifdef NON_POLLING
    msg_mutex_.lock();
#else
    // never actually block on the lock
    while (!msg_mutex_.try_lock())
    {
      //如果没开锁则循环等待，每个循环200微秒
      std::this_thread::sleep_for(std::chrono::microseconds(200));
    }
#endif
  }

  /**  解锁数据而不发布任何内容 
   *
   */
  void unlock()
  {
    msg_mutex_.unlock();
  }

private:
  void construct(int queue_size, bool latched=false)
  {
    publisher_ = node_.advertise<Msg>(topic_, queue_size, latched);
    keep_running_ = true;
    thread_ = boost::thread(&RealtimePublisher::publishingLoop, this);
  }


  bool is_running() const { return is_running_; }

  void publishingLoop()
  {
    is_running_ = true;
    turn_ = REALTIME;

    while (keep_running_)
    {
      Msg outgoing;

      // Locks msg_ and copies it
      lock();
      while (turn_ != NON_REALTIME && keep_running_)
      {
#ifdef NON_POLLING
        updated_cond_.wait(lock);
#else
        unlock();
        std::this_thread::sleep_for(std::chrono::microseconds(500));
        lock();
#endif
      }
      outgoing = msg_;
      turn_ = REALTIME;

      unlock();

      // Sends the outgoing message
      if (keep_running_)
        publisher_.publish(outgoing);
    }
    is_running_ = false;
  }

  std::string topic_;
  ros::NodeHandle node_;
  ros::Publisher publisher_;
  volatile bool is_running_;
  volatile bool keep_running_;

  boost::thread thread_;

  boost::mutex msg_mutex_;  // Protects msg_

#ifdef NON_POLLING
  boost::condition_variable updated_cond_;
#endif

  enum {REALTIME, NON_REALTIME};
  int turn_;  // Who's turn is it to use msg_?
};

#include <memory>
template <class Msg>
using RealtimePublisherSharedPtr = std::shared_ptr<RealtimePublisher<Msg> >;

}

#endif

```
