# hardware interface
> 更新时间: 2026年02月27日

实际上是继承了robotHW这个类，然后写我们自己的rmHW；也就是写我们自己的硬件抽象层

# 1. init()

1. 获取参数
2. 注册接口

```c++
  registerInterface(&robot_state_interface_);
  registerInterface(&gpio_state_interface_);
  registerInterface(&gpio_command_interface_);
```

3. reset电机状态的实时发布者、定义一个服务器

# 2. read()

1. 遍历每一个can bus，调用CanBus::read()，读取can帧
2. 

## 内容优化建议

> 此文档内容较为简略，建议补充以下内容：

1. **代码示例**: 添加实际可运行的代码
2. **应用场景**: 说明在实际项目中的用途
3. **最佳实践**: 分享经验教训和技巧
4. **扩展阅读**: 链接到相关学习资源

*最后检查: 2026-02-27 14:17:13*
