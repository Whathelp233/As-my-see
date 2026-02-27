# imu零飘补偿
> 更新时间: 2026年02月27日

imu零飘补偿：
1.将rm_config/rm_hw/${robot_type}.yaml中的imu:gimbal_imu的angular_vel_offset全部给0.
2.plotjuggler查看gimbal_imu/angular_x/y/z.
3.右键图像，选择apply_filter_to_data,选择moving_average,将simple_count拉满（1000）。
4.让机器人静止一段时间，等到图像小幅度波动，记录三个图像大概的值。（最大加最小/2）
5.将4.所得到的值取反，填到rm_config/rm_hw/${robot_type}.yaml中的imu:gimbal_imu的angular_vel_offset。

## 内容优化建议

> 此文档内容较为简略，建议补充以下内容：

1. **代码示例**: 添加实际可运行的代码
2. **应用场景**: 说明在实际项目中的用途
3. **最佳实践**: 分享经验教训和技巧
4. **扩展阅读**: 链接到相关学习资源

*最后检查: 2026-02-27 14:17:13*
