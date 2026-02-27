# yaw、pitch pid调试
> 更新时间: 2026年02月27日

yaw、pitch pid:
gimbal_controller（mode为0）发布速度指令：
yaw:2*sin*(2*pi*i/100) pos_error在0.004以内
pitch:0.3*sin*(2*pi*i/150) pos_error在0.006以内



一般yaw和pitch均为双环pid，一个为速度环，另外一个为位置环，速度环需要发布云台指令然后进行调参将误差减小，位置环不用发布指令，手掰不超调不抖动即可。

第一环为速度环，一般只给p，i。

第二环为位置环，一般只给p。
