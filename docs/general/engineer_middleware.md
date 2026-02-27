# engineer middleware
> 更新时间: 2026年02月27日

**before reading**

1. engineer_middleware.cpp中定义了节点的main函数，会循环调用Middleware::run()
2. 当收到一个goal时，会调用一个回调，回调中会把is_middleware_control_设为true；如果is_middleware_control为true，Middleware::run()会调用ChassisInterface::run()
3. ChassisInterface::run()
   - 获取base_link到map的偏移
   - 获得目标点跟当前位置的xy的误差
   - 将误差从map转换到base_link
   - 获取底盘yaw误差
   - 计算pid，设置cmd_vel
   - 发布cmd_vel
   - 更新error_pos，error_yaw

## 内容优化建议

> 此文档内容较为简略，建议补充以下内容：

1. **代码示例**: 添加实际可运行的代码
2. **应用场景**: 说明在实际项目中的用途
3. **最佳实践**: 分享经验教训和技巧
4. **扩展阅读**: 链接到相关学习资源

*最后检查: 2026-02-27 14:17:13*
