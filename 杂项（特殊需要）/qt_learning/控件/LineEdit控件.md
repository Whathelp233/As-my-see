# LineEdit控件

 图标可以放置在QLineEdit的前部和后部，通过QLineEdit::ActionPosition属性来设置。



添加图标的代码

```c++
 QAction *pTrailingAction = new QAction(this);
 pTrailingAction->setIcon(QIcon("D:/qt/LineEdit/Test.ico"));
 LineEdit->addAction(pTrailingAction, QLineEdit::TrailingPosition);
 // 连接信号和槽
 connect(pTrailingAction, SIGNAL(triggered(bool)), this, SLOT(onSearch(bool)));
```






改变颜色的代码：

```c++
 lineEdit->setStyleSheet(/*"color: blue;"*/
 "background-color: yellow;"
 "selection-color: yellow;"
 "selection-background-color: blue;" );

//自定义颜色
background-color: rgb(255, 253, 252);
```



 

设置控件圆角显示的代码：

```c
 lineEdit->setStyleSheet("border:2px groove gray;border-radius:10px;padding:2px 4px");
```

