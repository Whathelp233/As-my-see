# Referee



## rm_common referee

### 构造函数

```c++
Referee()  : super_capacitor_(referee_data_.capacity_data)
    		, last_get_(ros::Time::now())
    		, last_send_(ros::Time::now())
    		, client_id_(0)
    //获取超级电容数据
    //设置上次更新时间为当前时间
    //证书id
    //设置机器人伤害类型
```



### 读取裁判数据

```c++
void read();
	//重置环境缓存temp_buffer，初始化帧长度frame_len	
	//根据上次接受时间判断是否超时is_online
	//解包unpack，调用循环向temp_buffer写入新数据
	//超级电容读取数据
	//获取机器人数据getRobotInfo()，发送数据 publishData()
```



### 解包

```c++
int Referee::unpack(uint8_t* rx_data)
    //向头帧拷贝memcpy()包体，校验verifyCRC8CheckSum()
    //校验成功后生成帧长度
    //判断帧数据类型，向裁判系统相应位置拷贝数据，匹配不到则报错
    //is_online设置为true
    //更新上一次更新时间为现在，返回帧长度
```

> GAME_STATUS_CMD
>
> GAME_RESULT_CMD
>
> GAME_ROBOT_HP_CMD
>
> DART_STATUS_CMD
>
> ICRA_ZONE_STATUS_CMD
>
> FIELD_EVENTS_CMD
>
> SUPPLY_PROJECTILE_ACTION_CMD
>
> REFEREE_WARNING_CMD
>
> DART_REMAINING_CMD
>
> ROBOT_STATUS_CMD
>
> POWER_HEAT_DATA_CMD
>
> ROBOT_POS_CMD
>
> BUFF_CMD
>
> AERIAL_ROBOT_ENERGY_CMD
>
> ROBOT_HURT_CMD
>
> SHOOT_DATA_CMD
>
> BULLET_REMAINING_CMD
>
> ROBOT_RFID_STATUS_CMD
>
> DART_CLIENT_CMD
>
> INTERACTIVE_DATA_CMD



### 裁判系统录入机器人ID

```c++
void Referee::getRobotInfo()
    //获取机器人id，机器人阵营
    //向证书录入非哨兵机器人id，分为红蓝阵营
```




###  裁判系统验证数据

```c++
void Referee::publishData()
    //计算阵营各自的枪口热量，底盘电压，功率限制
    //机器人剩余血量，装甲id，受击类型，子弹速度
    //更新当前数据为上一次数据（旧数据）
```



### 发送交互数据


```c++
void sendInteractiveData(int data_cmd_id, int receiver_id, unsigned char data);
	//生成带有id的数据包student_interactive_data
	//设置数据包长度tx_len
```



###  加入UI数据

```c++
void addUi(const rm_common::GraphConfig& config, const std::string& content, bool priority_flag = false);
	//生成ui消息队列
	//有优先级判断以更早地插入重要数据
```



### 发送UI数据

```c++
void sendUi(const ros::Time& time);
	//当ui消息队列为空或发送过于频繁，返回return
	//图像数据rm_common::GraphData tx_data；
	//判断消息队列是否为空以执行单个图像/角色命令
	//生成带id的数据包pack()，设置数据长度，发送数据
	//更新上一次更新的时间为当前
```



### 生成数据包

```c++
void Referee::pack(uint8_t* tx_buffer, uint8_t* data, int cmd_id, int len) const
    //置空tx_buffer数据
    //设置头帧：起始id 0xA5，数据长度 len
    //数据拷贝
    //有crc校验
```



### CRC8校验

> CRC即循环冗余校验码：是数据通信领域中最常用的一种查错校验码

```c++
uint8_t getCRC8CheckSum(unsigned char* pch_message, unsigned int dw_length, unsigned char uc_crc_8)

uint32_t verifyCRC8CheckSum(unsigned char* pch_message, unsigned int dw_length)
    
void appendCRC8CheckSum(unsigned char* pch_message, unsigned int dw_length)

uint16_t getCRC16CheckSum(uint8_t* pch_message, uint32_t dw_length, uint16_t w_crc)
    
void appendCRC16CheckSum(uint8_t* pch_message, uint32_t dw_length)
```



### 超级电容

#### 读取数据

```c++
void SuperCapacitor::read(const std::vector<uint8_t>& rx_buffer)
    //重置receieve（接收缓存），ping_pong（往返交换缓存）的缓冲数据
    //拷贝rx_buffer数据
    //规范底盘功率(0~120)
    //检查数据是否实时
```

#### 回调函数

```c++
void SuperCapacitor::receiveCallBack(unsigned char package_id, const unsigned char* data)
    //判断包id是否为0
    //更新上一次数据时间为当前，设定为实时数据
    //检查功率并赋值结果data_
```

#### 接收

```c++
void SuperCapacitor::dtpReceivedCallBack(unsigned char receive_byte)
    //扫描数据帧，获取起始，结尾的位置
    //从缓存区拷贝数据
    //获取pid
    //调用回调函数检查receiveCallBack()referee_pub_
```




### 清空缓冲区referee_pub_

```c++
void clearBuffer()
    //清除数据
```





## rm_manual referee



### graph

#### 构造函数

```c++
Graph::Graph(const XmlRpc::XmlRpcValue &config, rm_common::Referee &referee, int id) : referee_(referee)
    //图像配置初始化
```

#### 展现

```c++
void Graph::display(bool priority_flag) 
    //调用addUi()函数向ui发送数据
    //更新最后一次更新的时间为当前

void Graph::displayTwice(bool priority_flag)
    //再次尝试发送数据，避免遗漏
    
void Graph::display(const ros::Time &time)
    //函数重构，不断调用display()并更新时间
    
void Graph::display(const ros::Time &time)
    //检查多发，避免频繁发布
```

#### 更新坐标

```c++
void Graph::updatePosition(int index) 
    //位置差大于1，更新位置
    
void Graph::initPosition(XmlRpc::XmlRpcValue value, std::vector<std::pair<int, int>> &positions) 
    //设置位置
```

#### 获取颜色，物体形状

```c++
rm_common::GraphColor Graph::getColor(const std::string &color)
    //黄色，绿色，橙色，紫色，粉色，青色，黑色，默认白色
    
rm_common::GraphType Graph::getType(const std::string &type)
    //矩形，圆，椭圆，弧线，线
```



### 图形交互界面UI

> 有多个ui：UiBase TriggerChangeUi TimeChangeUi FixedUi FlashUi



#### UiBase

基础ui

```c++
UiBase::UiBase(ros::NodeHandle &nh, Data &data, const std::string &ui_type) : data_(data)
    //id：2
    //获取参数ui_type
    //插入底盘数据
    
void UiBase::add()
    //图像展示
```



#### triggerChangeUi

触发器配置

```c++
TriggerChangeUi::TriggerChangeUi(ros::NodeHandle &nh, Data &data) : UiBase(nh, data, "trigger_change")
    //不同的机器人类型设置不同触发器
    //graph匹配到chassis：如果是工程机器人，发送RAW，其他机器人发送FOLLOW
    //graph匹配到target：发送armor，红方装甲板为青色，蓝方粉色
    //什么也没有返回0
    
void TriggerChangeUi::update(const std::string &graph_name, uint8_t main_mode, bool main_flag,uint8_t sub_mode, bool sub_flag) 
    //更新并展示最新图形数据
    
void TriggerChangeUi::updateConfig(const std::string &name, Graph *graph, uint8_t main_mode,bool main_flag, uint8_t sub_mode, bool sub_flag)
    //更新设置，匹配chassis，target，card，sentry，exposure
    //匹配到的目标根据mode，flag的不同配置不同颜色
    //匹配完成后展示相应数据
    
std::string TriggerChangeUi::getChassisState(uint8_t mode)
    //匹配底盘的raw，follow，gyro，twist运动模式
    
std::string TriggerChangeUi::getTargetState(uint8_t target, uint8_t armor_target)
    //红蓝方装甲板目标
    //装甲目标等级：buff armor_all(所有机器人) armor_base(前哨) eject(弹出) all base
    
std::string TriggerChangeUi::getExposureState(uint8_t level)
    //设置触发器顺序发布的等级0-4
```



#### FixedUi

锁定

```c++
void FixedUi::update()
    //更新并展示
    
int FixedUi::getShootSpeedIndex()
    //裁判系统对非英雄机器人的17mm弹丸的初速度匹配
```



#### FlashUi

装甲展示

```c++
void FlashUi::update(const std::string &name, const ros::Time &time, bool state)
    //设置机器人伤害类型和装甲板id
    //展示

void FlashUi::updateArmorPosition(const std::string &name, Graph *graph)
    //更新装甲板方位
    
uint8_t FlashUi::getArmorId(const std::string &name)
    //获取装甲板id，有四块，armor0-3对应id0-3
```



#### TimeChangeUi

```c++
void TimeChangeUi::add()
    //
    
void TimeChangeUi::update(const std::string &name, const ros::Time &time, double data) 
    //更新数据capacitor，effort，progress，temperature
    
void TimeChangeUi::setCapacitorData(Graph &graph)
    //展示电容状态
    //峰值能量，充电提示
    
void TimeChangeUi::setEffortData(Graph &graph) 
    //输出关节力
    
void TimeChangeUi::setProgressData(Graph &graph, double data)
    //进度：什么的进度？
    
void TimeChangeUi::setTemperatureData(Graph &graph) 
    //温度数据
```





# 串口传输协议

## 机器人间通信



### ID说明
> 机器人 ID：1，英雄(红)；2，工程(红)；3/4/5，步兵(红)；6，空中(红)；7，哨兵(红)；9，雷达站（红）；
> 101，英雄(蓝)；102，工程(蓝)；103/104/105，步兵(蓝)；106，空中(蓝)；107，哨兵(蓝)； 109，雷达站
> （蓝）。
> 客户端 ID：0x0101 为英雄操作手客户端(红)；0x0102，工程操作手客户端((红)；0x0103/0x0104/0x0105，
> 步兵操作手客户端(红)；0x0106，空中操作手客户端((红)； 0x0165，英雄操作手客户端(蓝)；0x0166，工
> 程操作手客户端(蓝)；0x0167/0x0168/0x0169，步兵操作手客户端步兵(蓝)；0x016A，空中操作手客户端
> (蓝)。

### 最大带宽

![img](https://i0.hdslb.com/bfs/album/14c2806e161b16c2ea195d0548f4101d85f7e188.png@1036w.webp)

> ```c
>     typedef enum {
>         ROBOT_INTERACTIVE_CMD_MIN = 0x0200,
>         ROBOT_INTERACTIVE_CMD_MAX = 0x02FF,
>         CLIENT_GRAPH_DELETE_CMD = 0x0100,
>         CLIENT_GRAPH_SINGLE_CMD = 0x0101,
>         CLIENT_GRAPH_DOUBLE_CMD = 0x0102,
>         CLIENT_GRAPH_FIVE_CMD = 0x0103,
>         CLIENT_GRAPH_SEVEN_CMD = 0x0104,
>         CLIENT_CHARACTER_CMD = 0x0110,
>     } DataCmdId;
> ```







# 优化

## Msg：is_online

> Referee.msg可以舍去，具体的判断放在manual中，manual判断频率最高的robot_state是否离线，再传入需要这个的地方

优先级不高，下一个pr提交



##  Topic: Referee

机器人间交互数据

> /topic1: 其他结点向这个话题发消息，referee订阅这个话题，把这些数据发进其他机器人串口
>
> /topic2：接收者机器人的referee把串口收到的数据发送到本机的这个话题上，给需要这个数据的结点订阅

下一个pr提交



## 减少派生

> 一个referee_base类可以处理所有ui，删去robot_referee hero_referee等等。



## ui CommandSender化

> ui写为一个类，内部配置接口，功能包括数据接收，触发发送的功能。

manual内部对原来裁判系统referee来的数据的的回调只是把数据存下来，现在在ui command sender中有一个接口函数，只要收到消息就会调用这个函数，该函数会遍历需要这个数据的子类

ui如果需要多个数据，那就配置多个接口；ui配置发一次的接口

原来referee base里保存了所有msg，现在把ui各自的类里面加入
