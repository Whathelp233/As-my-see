## URDF and Git pre-commit gitignore学习历程

### urdf

其实关于urdf本身的编写只要对着tag的

[解释]: https://zhuanlan.zhihu.com/p/83280676

和队内文档的编写规范就好了。

urdf的推荐文件树：

​	config:存放rviz文件还有参数文件

​	launch:启动文件

​	meshes:用于渲染的stl模型

​	urdf:编写的模型文件

遭遇过的问题：

  没写终止符 （善用check_urdf）(记得这个需要安装对应的包)

  传动标签<transmission>的接口一定一定要对应（不要有错字）

  controller_manager找不到对应的接口：因为光是在urdf中定义接口是不够的，我们要把对应的接口写出来（这里实际上使用的是gazebo_ros插件来引入抽象类接口，后续有自己写接口的打算但是道阻且长）



### Git

##### 	pre-commit使用：

​	首先要安装pre-commit:

	pip install pre-commit

​	然后到对应的项目根目录下：

```bash
pre-commit install
touch .pre-commit-config.yaml
```

​	yaml内可以去网上抄模板

​	写完之后，可以：

```
pre-commit run --all-file
```

​	之后就可以正常运行了

##### 	gitignore（理解方式：git ignore）：

​	在Clion里的插件市场里面搜 .ignore

​	安装好之后直接在项目之下新建一个.ignore file即可



为啥有时候gitignore不生效

有时候我们明明添加了匹配模式，但是就是排除不了对应的文件或目录；

那是因为那个文件或目录已经被添加到了git的记录中(执行过git add)，此时再在gitignore中添加匹配模式是无法生效的；

解决办法就是从git记录中删除对应的文件或目录；

```
git rm -rf --cached .
```



结果![](./img/urdf.png)
