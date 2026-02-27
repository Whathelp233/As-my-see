# 建立SSH
> 更新时间: 2026年02月27日

[链接](https://blog.csdn.net/weixin_44129041/article/details/110355360?spm=1001.2101.3001.6661.1&utm_medium=distribute.pc_relevant_t0.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-1.pc_relevant_default&depth_1-utm_source=distribute.pc_relevant_t0.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-1.pc_relevant_default&utm_relevant_index=1)

[作业:命令行环境](https://blog.csdn.net/m0_37169880/article/details/116611876)



首先，安装SSH服务器。

```bash 
sudo apt-get install openssh-server
```

登录ssh，即可实现远程访问。

```bash
ssh 用户名@IP地址
```

退出ssh登录。

```bash 
logout
```



启动ssh服务

```bash
sudo service ssh start                                 #还有stop，reload
```

查找ip

```bash
ifconfig                                                #找到需要的ip地址
```



例如在虚拟机上登录我自己电脑的ip

```bash
ssh yuchen@10.33.48.9                                   #之后输入密码
```

发现登录其他ifconfig上面的ip也能进去但是有的里面ls命令界面没东西





# 配置远程登陆用户

```
1.useradd -d /home/newuser -m newuser --创建用户
2.passwd newuser --重新定义密码
3.修改远程登陆的文件 vi /etc/ssh/sshd_config 新增 AllowUsers 用户名(newuser) 保存文件,退出
4.重启sshd:service sshd restart 操作完成之后就可以成功登陆
```



配置服务器后的操作

```
https://blog.csdn.net/weixin_44053794/article/details/122511907
```
