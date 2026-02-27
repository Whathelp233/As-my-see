# Referee
> 更新时间: 2026年02月27日

> 目前，我们展示的是已经完成分离功能后的referee，它将只保留获取裁判系统信息和发送交互数据的功能。其中交互数据包括自定义机器人间交互数据和ui绘制。现在依靠这篇文档，我将带您了解referee的基础功能。

- **在阅读开始前，我们建议您先阅读裁判系统[串口协议](https://rm-static.djicdn.com/tem/17348/RoboMaster_%E8%A3%81%E5%88%A4%E7%B3%BB%E7%BB%9F%E4%B8%B2%E5%8F%A3%E5%8D%8F%E8%AE%AE%E9%99%84%E5%BD%95%20V1.3.pdf)，这将帮助您了解referee**
- 整个referee以多个头文件相继包含组成，理清头文件的包含结构将帮助您更快速地熟悉referee



# 裁判系统

> 我们首先需要了解，裁判系统在RobotMaster中是一个怎样的存在。在实物上，您在机器人的底盘上会见到一个黑色带有屏幕的方块，这便是裁判系统主控本身，依靠这块主控，机器人能够将数据通过串口传输至服务器，从而在裁判系统界面显示出来。裁判系统中传输的数据，包括但不限于机器人状态，比赛阶段信息，场地情况，交互数据...，我们首先要做到的，是从裁判系统中接受数据，这将是referee工作的基础。

让我们先从referee接受数据开始。、



# 数据接受

> main.cpp中for循环调用read(),而在rm_referee/referee.h文件中，我们能够找到函数**read()**,通过这个函数，我们能够读到裁判系统串口传输而来的数据，它是如何而实现？接下来我们进行解析：首先在clion中尝试在read()函数的位置同时按下ctrl与鼠标左键，我们将会跳到referee.cpp，这是该函数实现的地方。

```c
void Referee::read()
{
    
  //rm_referee节点需要保证长时间且稳定地运行，因此要避免因串口暂时得不到数据而中断rm_referee进程。
  if (base_.serial_.available())
  {
    rx_len_ = (int)base_.serial_.available();
    base_.serial_.read(rx_buffer_, rx_len_);
  }
  else
  {
    ROS_INFO("Port exception before read");
    return;
  } 
  //检查Dbus判断是否触发UI绘制
  checkUiAdd();
  //临时变量
    //先将缓冲区置零
  uint8_t temp_buffer[256] = { 0 };
  int frame_len;
    
  //实时性判断
    //通过时间差来判断数据是否实时，这会很重要，非实时数据会干扰到我们许多的判断
  if (ros::Time::now() - last_get_ > ros::Duration(0.1))
    referee_data_.is_online_ = false;
    
  //赋值
  if (rx_len_ < k_unpack_buffer_length_)
  {
    for (int kI = 0; kI < k_unpack_buffer_length_ - rx_len_; ++kI)
      temp_buffer[kI] = unpack_buffer_[kI + rx_len_];
    for (int kI = 0; kI < rx_len_; ++kI)
      temp_buffer[kI + k_unpack_buffer_length_ - rx_len_] = rx_buffer_[kI];
    for (int kI = 0; kI < k_unpack_buffer_length_; ++kI)
      unpack_buffer_[kI] = temp_buffer[kI];
  }
    
  //解包
    //具有标识符的帧将会解包，unpack()会执行数据获取的功能
  for (int kI = 0; kI < k_unpack_buffer_length_ - k_frame_length_; ++kI)
  {
    if (unpack_buffer_[kI] == 0xA5)
    {
      frame_len = unpack(&unpack_buffer_[kI]);
      if (frame_len != -1)
        kI += frame_len;
    }
  }
 //读取超级电容数据
  super_capacitor_.read(rx_buffer_);
 //获取到数据后，我们该发布了，有需要的用户可以订阅它
  publishCapacityData();
 //获取机器人数据，包含本机id等
  getRobotInfo();
 //清除缓冲区
  clearRxBuffer();
}
```

这个函数就是rm_referee的主循环函数。现在我们能从这段代码大概了解referee初步的功能了，首先获取数据帧，接着完成解包，之后处理数据，最后将数据发布出去。其中每一步都由函数完成。

通过ctrl+加鼠标左击的方式，跳到函数实现的地方，详细了解函数如何完成它自己的功能。





# 数据发布

> unpack()函数将会在解包赋值并绘制ui(部分数据下)后发布话题，ui绘制的部分下一节会详细阐述。实际上我们可以发现ui绘制是以裁判系统接收到相应数据时的回调函数触发的。

这里先以game_robot_status数据举例

```c
        case rm_referee::RefereeCmdId::ROBOT_STATUS_CMD:
        {
          rm_referee::GameRobotStatus game_robot_status_ref;
          memcpy(&game_robot_status_ref, rx_data + 7, sizeof(rm_referee::GameRobotStatus));

          base_.game_robot_status_data_.mains_power_chassis_output = game_robot_status_ref.mains_power_chassis_output_;
		  /*===
		  	省略
		  */===
          base_.game_robot_status_data_.stamp = last_get_;

          base_.referee_pub_data_.is_online = base_.referee_data_is_online_;

          base_.referee_pub_data_.stamp = last_get_;

          //绘制ui
          referee_ui_->robotStatusDataCallBack(base_.game_robot_status_data_, last_get_);

          //发布话题
          game_robot_status_pub_.publish(base_.game_robot_status_data_);
          referee_pub_.publish(base_.referee_pub_data_);
          break;
        }
```



对应于上一部分发布的话题，在referee.cpp的referee类的构造函数我们可以了解到更多。值得注意的的是可以在构造函数中看到串口初始化过程。

```c
    // initSerial
    base_.initSerial();
```



**提问：**

1. unpack()函数整整有331行，但每个case上执行的代码是大同小异的。尝试将case中的代码归类，得出自己的理解



unpack()中有一段用于过滤的命令，在实际测试过程中会出现因为收到的数据中的数据长度极长(1w以上)而导致程序崩溃的情况(过长导致的越界访问).所以加上一句检测数据长度的指令。但注意数据长度只是从数据帧解包出来的数据帧长度(数据帧中有分配帧有多长的数据位），数据帧的实际长度可能并没有这么长

```c
if (frame_header.data_length_ > 256)  // temporary and inaccurate value
```







# UI绘制

> RobotMaster支持选手自定义ui，和我们预设想的花里胡哨种样繁多的游戏ui不同，我们将要绘制的ui既不能加入劲爆的打击音效，也不能添加屏幕交互。我们所能做到的是将操作手需要的一些数据打印出来。

ui发送的本质其实就是机器人交互数据，它和机器人间交互数据几乎共用一套逻辑。

```c
交互数据包括一个统一的数据段头结构。数据段包含了内容 ID，发送者以及接收者的 ID 和内容数据段，
整个交互数据的包总共长最大为 128 个字节，减去 frame_header,cmd_id 和 frame_tail 共 9 个字节以及
数据段头结构的 6 个字节，故而发送的内容数据段最大为 113。
```



我们从数据封装的工作讲起



# 数据封装

> 假设我们将要将已经配置好的ui发送到串口，那么直接发送数据可不行，我们应当先将数据进行封装打包。

在graph.cpp中：

```c
void Graph::pack(uint8_t* tx_buffer, uint8_t* data, int cmd_id, int len) const
{
  memset(tx_buffer, 0, k_frame_length_);
  auto* frame_header = (rm_referee::FrameHeader*)tx_buffer;

  //设置帧头，数据长度和数据
  frame_header->sof_ = 0xA5;
  frame_header->data_length_ = len;
  memcpy(&tx_buffer[k_header_length_], (uint8_t*)&cmd_id, k_cmd_id_length_);
    
  //appendCRC8CheckSum()实际上是CRC校验的一部分，它的代码由官方提供
  base_.appendCRC8CheckSum(tx_buffer, k_header_length_);
  memcpy(&tx_buffer[k_header_length_ + k_cmd_id_length_], data, len);
  base_.appendCRC16CheckSum(tx_buffer, k_header_length_ + k_cmd_id_length_ + len + k_tail_length_);
}
```

> 联系到上文的解包工作(unpack())，它们之间有什么联系？



# UI发送

> 谁会调用上述的pack()函数？实际上我们的ui绘制工作有addui()和sendui()两部分，在sendui()中，它将会完成将缓冲区的数据打包和发送到串口的工作。

在graph.cpp中：

```c
void Graph::sendUi(const ros::Time& time)
{
  //检查发送延时，设置数据长度
  if (ui_queue_.empty() || time - last_send_ < ros::Duration(0.05))
    return;
  rm_referee::GraphData tx_data;
  int data_len = (int)sizeof(rm_referee::GraphData);
    
  //检查发送者接受者id是否被正确赋值
  if (base_.robot_id_ == 0 || base_.client_id_ == 0)
    return;
    
  //发送者，接受者id赋值
  tx_data.header_.sender_id_ = base_.robot_id_;
  tx_data.header_.receiver_id_ = base_.client_id_;
  tx_data.config_ = ui_queue_.back().first;
    
  //判断图像类型并安排不同的数据
  if (ui_queue_.back().second.empty())
  {
    tx_data.header_.data_cmd_id_ = rm_referee::DataCmdId::CLIENT_GRAPH_SINGLE_CMD;
    data_len -= 30;
  }
  else
  {
    tx_data.header_.data_cmd_id_ = rm_referee::DataCmdId::CLIENT_CHARACTER_CMD;
    for (int i = 0; i < 30; i++)
    {
      if (i < (int)ui_queue_.back().second.size())
        tx_data.content_[i] = ui_queue_.back().second[i];
      else
        tx_data.content_[i] = ' ';
    }
  }
    
  //封装打包
  pack(tx_buffer_, (uint8_t*)&tx_data, rm_referee::RefereeCmdId::INTERACTIVE_DATA_CMD, data_len);
  tx_len_ = k_header_length_ + k_cmd_id_length_ + k_tail_length_ + data_len;
    
  //删除ui队列中已处理好的数据
  ui_queue_.pop_back();
  last_send_ = time;

  //尝试写入串口
  try
  {
    base_.serial_.write(tx_buffer_, tx_len_);
  }
  catch (serial::PortNotOpenedException& e)
  {
  }

  //清空发送缓冲区
  clearTxBuffer();
}
```



# UI添加

> 上文我们已经提到addui()函数，它工作在sendui()之前，并且sendui()中的ui队列会在addui()中体现。

在graph.cpp中：

```c
void Graph::addUi(const rm_referee::GraphConfig& config, const std::string& content, bool priority_flag)
{
  //防止ui队列过长，限制20
  for (int i = 0; i < (int)ui_queue_.size() - 20; i++)
    ui_queue_.erase(ui_queue_.begin());
  
  //优先级判断
  	//ui_queue_是vecor容器，请理解push_back(),insert()的工作
  if (priority_flag)
    ui_queue_.push_back(std::pair<rm_referee::GraphConfig, std::string>(config, content));
  else
    ui_queue_.insert(ui_queue_.begin(), std::pair<rm_referee::GraphConfig, std::string>(config, content));
}
```

sendui()执行的的是`ui_queue_.pop_back()`函数来缩短队列，那么队列里哪里的ui会先被发送出去？这一点就是优先级的作用效果。



# Display()

> display()的工作是更新ui内容数据，同时调用addui()配置队列和ui的优先级。该函数有进行重载。同时有dispalyTwice()函数，顾名思义它会对重要ui发布两次防止在队列中被挤掉。

在graph.cpp：

```c
void Graph::display(bool priority_flag)
{
  //重复ui返回
  if (config_ == last_config_ && title_ == last_title_ && content_ == last_content_)
    return;
    
  if (!title_.empty() && !content_.empty())
    config_.end_angle_ = (int)(title_ + content_).size();
   
  //更新配置
  addUi(config_, title_ + content_, priority_flag);
    
  //displayTwice()中仅更改上面这行为：
  /*
    for (int i = 0; i < 2; ++i)
    addUi(config_, title_ + content_, priority_flag);
  */
  last_content_ = content_;
  last_title_ = title_;
  last_config_ = config_;
}
```

```c
void Graph::display(const ros::Time& time)
{
  //display()，但是有延时
  if (time - last_time_ < delay_)
    return;
  display();
  last_time_ = time;
}
```



# Update()

> update()将会调用diaplay(),sendui()，它将ui进行更新并发送出去。此时我们已经由graph类涉及到了ui类

在ui.cpp中，以trigger ui举例：

```c
void TriggerChangeUi::update(const std::string& graph_name, uint8_t main_mode, bool main_flag, uint8_t sub_mode,
                             bool sub_flag)
{
  auto graph = graph_vector_.find(graph_name);
  if (graph != graph_vector_.end())
  {
    //根据参数更新ui配置
    updateConfig(graph_name, graph->second, main_mode, main_flag, sub_mode, sub_flag);
      
    //rm_referee::GraphOperation由裁判系统官方定义，告诉裁判系统方面我方对这个ui进行的操作
    graph->second->setOperation(rm_referee::GraphOperation::UPDATE);
      
    if (graph->first == "chassis" || graph->first == "gimbal")
    {
      //chassis和gimbal ui是重要ui，调用displayTwice()
      graph->second->displayTwice(true);
      //ui即时发送
      graph->second->sendUi(ros::Time::now());
    }
    else
    {
      graph->second->display();
      graph->second->sendUi(ros::Time::now());
    }
  }
}
```

在日常ui维护中我们也更多地是调用update()函数，它已经处于较上层次。在其他派生uiBase类的update()的函数中都有各自的处理，不过它们仍遵循上述基本结构，比如TimeChangeUi的update()会为不同的ui调用不同的函数。



# Add()

> 上面数据接收一节中我们看到了checkUiAdd()函数，联系到Update()一节里代码中提到的rm_referee::GraphOperation，我们实际上是告诉裁判系统我们要添加ui了。
>
> 注意，如果ui没有先add(rm_referee::GraphOperation::ADD),选手端是不会显示出ui的，后续的update(rm_referee::GraphOperation::UPDATE)也没有意义。

```c
void RobotReferee::addUi()
{
  RefereeBase::addUi();
  ROS_INFO("time ui");
  time_change_ui_->add();//调用add()函数
  usleep(200000);
  ROS_INFO("trigger ui");
  trigger_change_ui_->add();
  usleep(200000);
  ROS_INFO("fixed ui");
  fixed_ui_->add();
  usleep(200000);
}
```

```c
//add()函数具体的实现
void TimeChangeUi::add()
{
  for (auto graph : graph_vector_)
  {
    if (graph.first == "capacitor" && data_.base_.capacity_data_.cap_power == 0.)
      continue;
    graph.second->setOperation(rm_referee::GraphOperation::ADD);
    graph.second->display(true);
    graph.second->sendUi(ros::Time::now());
  }
}
```







# Graph类

> 在graph.h文件中我们可以找到graph类，在这个类中程序将会实现图像的具体配置和对图像的打包发送。图像的具体配置包括告诉裁判系统这个图像类型是什么以及图像的颜色，文本内容等等。



# 图像配置

> 图像配置是我们修改ui时最终触及的内容，对ui的修改最终都会转到对config的修改上。
>
> 我们找到config变量
>
> `rm_referee::GraphConfig config_{}`

以下就是config包含的可修改的内容了，可以看到包含了以下内容

```c
  uint8_t graphic_id_[3];       //图像id，在删除，修改等操作中，作为客户端的索引
  uint32_t operate_type_ : 3;   //操作类型，上文有提及
  uint32_t graphic_type_ : 3;   //图像类型，具体在官方裁判系统文档有阐述
  uint32_t layer_ : 4;          //图层数，0~9
  uint32_t color_ : 4;          //颜色
  uint32_t start_angle_ : 9;    //起始角度，单位：°，范围[0,360]；
  uint32_t end_angle_ : 9;      //终止角度，单位：°，范围[0,360]。
  uint32_t width_ : 10;         //线宽
  uint32_t start_x_ : 11;       //起点 x 坐标，注意屏幕坐标以屏幕左上角为原点
  uint32_t start_y_ : 11;       //起点 y 坐标。
  uint32_t radius_ : 10;        //字体大小或者半径
  uint32_t end_x_ : 11;         //终点 x 坐标
  uint32_t end_y_ : 11;         //终点 y 坐标
```

实际编写图像的过程中并不需要把上面的变量全部填满，根据图形的需要填写部分即可。具体的编写方法在官方裁判系统文档有阐述

变量是按位域分配的，请注意



**位域**

> 位域（bit field），表示定义的数据所占用的，不是整数字节（如char是“1字节”，short是“两字节”等等），而是按“位”(bit)分配的。

```c
//例：
struct x {
    int a : 6;
    int b : 2;
};
```

其中 a 占 6bits, b 占 2bits，两者合起来占 8bits，就是一字节。





# 图像发送

> graph类的第二个功能，对图像进行打包和发送到串口，以下函数设计到这部分内容

```c
//这连个函数完成的功能一样，区别在于sendUi()属于关于客户端图形的机器人间通信，sendInteractiveData()属于交互数据的机器人间通信。这两部分都属于学生机器人间通信
void sendUi(const ros::Time& time);
void sendInteractiveData(int data_cmd_id, int receiver_id, unsigned char data);
```

（好家伙endInteractiveData()部分里的串口发送还没写）

以sendUi()为例分析

```c
 //如果ui队列为空或发送间隔太短则退出
  if (ui_queue_.empty() || time - last_send_ < ros::Duration(0.05))
    return;
  rm_referee::GraphData tx_data;
  int data_len = static_cast<int>(sizeof(rm_referee::GraphData));

//检查发送者和接受者是不是都是机器人自己，因为该类机器人通信只允许对自身的发送与接收
  if (base_.robot_id_ == 0 || base_.client_id_ == 0)
    return;
  tx_data.header_.sender_id_ = base_.robot_id_;
  tx_data.header_.receiver_id_ = base_.client_id_;
  tx_data.config_ = ui_queue_.back().first;

//检查图像类型
  if (ui_queue_.back().second.empty())
  {
    //客户端绘制一个图形
    tx_data.header_.data_cmd_id_ = rm_referee::DataCmdId::CLIENT_GRAPH_SINGLE_CMD;
    data_len -= 30;
  }
  else
  {
    //客户端绘制字符
    tx_data.header_.data_cmd_id_ = rm_referee::DataCmdId::CLIENT_CHARACTER_CMD;
    for (int i = 0; i < 30; i++)
    {
      if (i < static_cast<int>(ui_queue_.back().second.size()))
        tx_data.content_[i] = ui_queue_.back().second[i];
      else
        tx_data.content_[i] = ' ';
    }
  }

//打包数据，更新发送的缓存数据
  pack(tx_buffer_, reinterpret_cast<uint8_t*>(&tx_data), rm_referee::RefereeCmdId::INTERACTIVE_DATA_CMD, data_len);
  tx_len_ = k_header_length_ + k_cmd_id_length_ + k_tail_length_ + data_len;
  ui_queue_.pop_back();
  last_send_ = time;

//向串口写入
  try
  {
    base_.serial_.write(tx_buffer_, tx_len_);
  }
  catch (serial::PortNotOpenedException& e)
  {
  }

//清空发送的缓存数据
  clearTxBuffer();
```
