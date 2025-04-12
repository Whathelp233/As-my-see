---
tags:
  - Linux（Dynamicx）
---
首先输入ip a查看现在NUC的网口信息

一般来说，有
```
1： lo: <LOOKBACK ....> //这种是NUC本身的网口
2： enpxxs0        //这个一般是Ecat的网口
3： enxxxxx        //这个一般是拓展坞的网口
4:  wlo1           //这个一般是无线WIFI的
```
其实只要记住：e开头的一般都是有网口的，w一般是（wireless）无线的。
记住拓展坞的设备名
然后
```
cd /etc/netplan
sudo vim 00-installer-config.yaml //这里也可以用tab不全00-(tab)-(tab).(tab)
```
然后就会见到
```
# This is the network config written by'subquity'
network:
	etrhernets:
		enp8xs0:
			dhcp4:false
			optional:true
			addresses:[192.168.100.4/24] #这里的话哨兵是4，步兵是3
			optional:true
			namesevers:
				addresses:[255.255.255.0]
		version:2
```
然后我们就赋值一遍enp里面这部分，然后把名字改成拓展坞的名字，如下：
```
# This is the network config written by'subquity'
network:
	etrhernets:
		enp8xs0:
			dhcp4:false
			optional:true
			addresses:[192.168.100.4/24] #这里的话哨兵是4，步兵是3
			optional:true
			namesevers:
				addresses:[255.255.255.0]
		version:2
		enpxxxx:
			dhcp4:false
			optional:true
			addresses:[192.168.100.2/24] #注意这里改为100.2
			optional:true
			namesevers:
				addresses:[255.255.255.0]
		version:2
```
然后保存退出，接下来
```
cd rm_ws/src/rm_bringup/scripts/auto_start
vim auto_set_metric.sh
```
里面的话是这样的（这里主要是解决分配优先级问题）
```
#!/bin/bash
ECAT_IFACE=enpxxxx
EXCHANGE_IFACE=enxxxxxxx

echo "Starting auto_set_metric.sh!"

while true
do
if sudo ifmetric ${ECAT_IFACE} 200; then
    echo "${ECAT_IFACE} Metric: $(route -n | grep '0.0.0.0' | grep "${ECAT_IFACE}" | awk '{print $5}')"
else
    echo "Failed to set metric for ${ECAT_IFACE}"
    exit 1
fi

if sudo ifmetric ${EXCHANGE_IFACE} 100; then
    echo "${EXCHANGE_IFACE} Metric: $(route -n | grep '0.0.0.0' | grep "${EXCHANGE_IFACE}" | awk '{print $5}')"
else
    echo "Failed to set metric for ${EXCHANGE_IFACE}"
    exit 1
fi

sleep 10
done

echo "auto_set_metric.sh executed successfully!"

```
然后改`EXCHANGE_IFACE`里面的内容，改为我们拓展坞的名字
改完之后
```
./delete_specific_service.sh auto_set_metric
./create_specific_service.sh auto_set_metric
cd /etc/netplan
sudo netplan apply
sudo reboot
```
重启完之后ip a