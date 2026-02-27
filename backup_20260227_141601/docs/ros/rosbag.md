# rosbag
> 更新时间: 2026年02月27日

rosbag：
小电脑：
～/Documents/control 包
scp -r 202 筛选出带202的bag，找出需要的bag

自己电脑：
scp -r dynamicx@192.168.100.2:/home/dynamicx/Documents/control/20240405_11_07 ~/(前面有空格，表示要从小电脑的路径拉到你想要的路径)
再从plotjuggler播放bag



修复：

rosbag reindex xxx.bag.active

rosbag fix xxx.bag.active xxx.bag
