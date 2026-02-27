# imu零飘补偿
> 更新时间: 2026年02月27日

imu零飘补偿：
1.将rm_config/rm_hw/${robot_type}.yaml中的imu:gimbal_imu的angular_vel_offset全部给0.
2.plotjuggler查看gimbal_imu/angular_x/y/z.
3.右键图像，选择apply_filter_to_data,选择moving_average,将simple_count拉满（1000）。
4.让机器人静止一段时间，等到图像小幅度波动，记录三个图像大概的值。（最大加最小/2）
5.将4.所得到的值取反，填到rm_config/rm_hw/${robot_type}.yaml中的imu:gimbal_imu的angular_vel_offset。
