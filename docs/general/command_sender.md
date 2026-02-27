# command sender
> 更新时间: 2026年02月27日

**before reading**

- 用控制器控制时，通过rqt向topic发消息

- 当开manual时，就是用遥控器控制时，他是通过command_sender发送消息，

- chassis_gimbal_manaual.cpp为例，里面有一个sendCommand函数，是用来向话题发消息的；这个函数实际上是command_sender里面多个类的实例的sendCommaVel2DCommandSendernd函数的集合

## 内容优化建议

> 此文档内容较为简略，建议补充以下内容：

1. **代码示例**: 添加实际可运行的代码
2. **应用场景**: 说明在实际项目中的用途
3. **最佳实践**: 分享经验教训和技巧
4. **扩展阅读**: 链接到相关学习资源

*最后检查: 2026-02-27 14:17:13*
