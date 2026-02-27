# method
> 更新时间: 2026年02月27日

1. 将rm_config/rm_hw/${robot_type}.yaml中的imu：gimbal_imu的angular_vel_offset全部设成0

2. plotjuggler查看gimbla_imu/angular_x/y/z
3. 右键点击图像，选中apply_filter_to_data，选中moving_average，将simple_count拉满
4. 机器人静止一段时间，等到图像小幅波动时，记录三个图像的大概的值（我一般buffer给200，然后等到最开始那段波动大的没有了之后，每个轴取最大跟最小的平均值）
5. 将4中得到的值取反，填到rm_config/rm_hw/${robot_type}.yaml中的imu：gimbal_imu的angular_vel_offset

## 内容优化建议

> 此文档内容较为简略，建议补充以下内容：

1. **代码示例**: 添加实际可运行的代码
2. **应用场景**: 说明在实际项目中的用途
3. **最佳实践**: 分享经验教训和技巧
4. **扩展阅读**: 链接到相关学习资源

*最后检查: 2026-02-27 14:17:12*
