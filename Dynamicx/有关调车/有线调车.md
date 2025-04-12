有线连接：
自己IP：192.168.100.1 不设置则为10.42.01/24
小电脑：192.168.100.2
nmap 192.168.100.1/24 检查线连接另一端的IP


调试时关闭自启服务：
sudo systemctl stop rm_can_start.service start_master.service vision_start.service


测发射：
一、开roscore 
二、启动launch文件 
mon launch rm_config rm_can_hw.launch 
mon launch rm_config load_controllers.launch
三、rqt 发布指令 plotjuggler 看曲线


新电机测offset，即弹丸恰好没有发射出去的拨盘旋转角度。
修改拨盘offset 大英路径：rm_ws\src\rm_description\urdf\hero\shooter.transmission.urdf.xacro
小英路径：rm_ws\src\rm_description\urdf\hero2\shooter.transmission.urdf.xacro
