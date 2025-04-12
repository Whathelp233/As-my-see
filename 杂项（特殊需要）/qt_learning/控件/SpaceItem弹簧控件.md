# 弹簧控件

> 建议先看这篇Qt 之addSpacing(int size)、addStretch(int stretch = 0)、addSpacerItem(QSpacerItem *spacerItem)的区别
> https://blog.csdn.net/zhou123456tao/article/details/113481942



1.new一个弹簧控件添加到布局中

```c++
addSpacerItem(QSpacerItem(int w, int h,QSizePolicy::Policy hData = QSizePolicy::Minimum,QSizePolicy::Policy vData = QSizePolicy::Minimum)）

#include<QSpacerItem>
// new一个宽可以拉伸，高度固定的弹簧在layout里直接additem(sparcer_item)即可
QSpacerItem * sparcer_item = new QSpacerItem(0,160,QSizePolicy::Expanding,QSizePolicy::Fixed);
main_layout->addItem(sparcer_item);
//or
main_layout->addSpacerItem(new QSpacerItem(0,160,QSizePolicy::Expanding,QSizePolicy::Fixed));
```



2.在layout之间插入间距，其插入的间距是在setSpacing(int)的基础上的，即是layout的控件间的间距为addSpacing值+setSpacing值。注意layout布局的控件之间默认距离为10（即setSpacing默认设置为10）通过setSpacing(0)函数设置为0可使控件紧贴。

```c
main_layout->addSpacing(10);
```



3.用addStretch函数实现将nLayout的布局器的空白空间平均分配。
addStretch(int stretch = 0)是在布局器中增加一个伸缩量，里面的参数表示QSpacerItem的个数，默认值为零，会将你放在layout中的空间压缩成默认的大小。

```c++
例如：一个layout布局器，里面有三个控件，一个放在最左边，一个放在最右边，最后一个放在layout的1/3处，这就可以通过addStretch去实现。(可以控制布局中空白部分占比，相当于把空白部分分为9份，每块占比。)

main_layout->addStretch(1);
main_layout->addWidget(button1);
main_layout->addStretch(1);
main_layout->addWidget(button2);
main_layout->addStretch(1);
main_layout->addWidget(button3);
main_layout->addStretch(6);
```





# 使用流程

> 我们需要首先定义弹簧控件它的属性，将控件加入目标窗口的对象树中，接着按照顺序将弹簧与其他控件依次加入layout里，最后在目标窗口中调用setLayout(最高级layout名)来让layout生效

```c++
    //按下按钮打开另一个窗口
    QDialog *new_wid = new QDialog;
    new_wid->move(100,100);

	//文本控件
    QTextEdit *name = new QTextEdit(new_wid);
    name->setText("恰宫爆鸡丁");

	//弹簧控件
	//第一个参数：长   第二个参数： 宽
	//第三个参数：长的延长属性  第四个参数：宽的延长属性
    QSpacerItem *item1 = new QSpacerItem(160,0,QSizePolicy::Fixed,QSizePolicy::Expanding);
    QSpacerItem *item2 = new QSpacerItem(160,0,QSizePolicy::Fixed,QSizePolicy::Expanding);
    QHBoxLayout *h_layout = new QHBoxLayout;

	//加入水平布局
    h_layout->addItem(item1);
    h_layout->addWidget(name);
    h_layout->addItem(item2);
	//最后setLayout
    new_wid->setLayout(h_layout);
```





## 网格布局中控件占据多个格子

```c
layout->addWidget(btn,0,0,1,3);//从(0,0)开始，占据1行3列
```
