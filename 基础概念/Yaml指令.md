# Yaml指令



## 概念

> 大括号{}被视为映射
>
> 
>
> 中括号[]被视为序列，和
>
> ```c
> - a
> - b
> - c
> ```
>
> 等价

### 结构体

> 这是一个结构体

```yaml
config: {name:"1",if:"2",color:"3"}
config2: {"1","2","3"}//这一种好像不能用
```

读取参数的方法

`config["name"]`

`config2[0]`



问题：

```yaml
name:
      - config: "1"
        color:  "2"
和
name:
      - {config: "1" ,color:"2"}
是等价的吗
```

是的，这两种写法是等价的，都表示name下只有一个字典元素，字典元素的键为`config`和`color`，对应的值分别为`"1"`和`"2"`。只是第二种写法使用了一种更加简洁的写法，可以将多个键值对用大括号括起来，逗号分隔，不需要在每行都写上键名。



## 读取

### 获取字符串参数

```yaml
name: "engineering_polygon"
   - group_name: "a"
```

```
group_name_ = static_cast<std::string>(rpc_value["group_name"]);
```



### 获取序列

> 用类似于数组的索引

```cpp
XmlRpc::XmlRpcValue xml;
nh.getParam("chassis", xml);
if (xml.getType() == XmlRpc::XmlRpcValue::TypeArray) {
  int size = xml.size();
  for (int i = 0; i < size; ++i) {
    XmlRpc::XmlRpcValue value = xml[i];
    // 这里可以根据 value 的类型来获取对应的值
    // 如果 value 是字符串类型，可以使用 static_cast<std::string>(value) 来获取字符串
    // 如果 value 是整数类型，可以使用 static_cast<int>(value) 来获取整数
    // 如果 value 是序列类型，可以使用 value.arrayValue() 来获取序列
    // ...
  }
}
```



### 获取序列里的数组

```yaml
config:
	- group_type: "polygon"
	- graph_config: { width: 2, delay: 0.5 ,color: "cyan" }
	- points:
		- [ 1,200 ]
		- [ 2,300 ]
```

```cpp
if (nh.getParam("config", result)) {
  // Check if the "points" field exists and is an array
  if (result[2].hasMember("points") && result[2]["points"].getType() == XmlRpc::XmlRpcValue::TypeArray) {
    // Get the "points" array
    XmlRpc::XmlRpcValue points = result[2]["points"];

    // Loop through the array and print each point
    for (int i = 0; i < points.size(); i++) {
      XmlRpc::XmlRpcValue point = points[i];
      int x = point[0];
      int y = point[1];
      ROS_INFO_STREAM("Point " << i << ": (" << x << ", " << y << ")");
    }
  }
}
```



问题：

- 可以用config["group_type"]来读取group_type参数吗？

不可以，config节点是一个包含多个字典的数组，因此需要先使用下标操作符[]获取数组中的某个元素，再使用键值访问其中的字典。

```c++
std::string group_type = config[0]["group_type"];//正确
std::string group_type = config["group_type"];   //错误
```





## 定义

### 生成一个{}

在代码里用XmlRpc::XmlRpcValue生成

```yaml
config: { start_position: [ 400, 700 ], size: 15, width: 2, title: "target: " }
```

```c++
#include <XmlRpcValue.h>

int main()
{
  XmlRpc::XmlRpcValue config;
  config["start_position"].setSize(2);
  config["start_position"][0] = 400;
  config["start_position"][1] = 700;
  config["size"] = 15;
  config["width"] = 2;
  config["title"] = "target: ";
  
  return 0;
}
```

