# Display Widgets控件



## Label控件

> 标签控件，不仅可以显示文字，也可以显示图片



```c++
//利用Label显示图片
	ui->label2->setPixmap(QPixmap(":/images/XXX.png"));

//放gif动图
	QMovie *movie = new QMovie(":/images/XXX.gif");
	ui->label2->setMovie(movie);
  //播放动图
	movie->start()
```

```c++
//调整大小
	ui->label2->setScaledContents(true);
```



