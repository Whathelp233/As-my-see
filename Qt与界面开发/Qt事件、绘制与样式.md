# Qt 事件、绘制与样式

> 本文代码均为 Qt API 片段，不含完整可执行应用；按目标 Qt 版本补齐工程上下文后使用。

## 事件处理路径

鼠标、键盘、绘制、定时器和窗口状态变化都可表示为 Qt 事件。事件循环收到事件后，把它投递给目标 QObject。QObject 的 `event()` 是总入口，QWidget 为常见事件提供更具体的虚函数，如 `mousePressEvent()`、`keyPressEvent()` 和 `paintEvent()`。大多数自定义控件只需重写与自身职责相关的处理函数。

处理函数可以接受或忽略事件。接受表示当前对象已处理；忽略的鼠标事件在适用时可继续沿父控件链传播。重写处理函数时，如果当前类没有处理该事件，应调用基类实现，以保留基类行为。

~~~cpp
// 片段：只处理左键，其余输入继续交给基类
void IconButton::mousePressEvent(QMouseEvent *event)
{
    if (event->button() == Qt::LeftButton) {
        beginSelection(event->position());
        event->accept();
        return;
    }
    QPushButton::mousePressEvent(event);
}
~~~

如想集中拦截另一个对象的输入，可实现 `QObject::eventFilter`，并通过 `installEventFilter()` 安装。事件过滤器返回 true 表示该事件已经处理，不再交给被监视对象的常规处理；返回 false 则允许正常分发。过滤器对象与被监视对象必须位于同一线程。过滤器通常适合跨多个控件的统一策略，单个控件自己的行为更适合重写控件事件函数。

~~~cpp
// 片段：只截获特定控件上的鼠标按下
bool Panel::eventFilter(QObject *watched, QEvent *event)
{
    if (watched == ui.label &&
        event->type() == QEvent::MouseButtonPress) {
        handleLabelPress();
        return true;
    }
    return QWidget::eventFilter(watched, event);
}
~~~

安装过滤器之后，被监视对象和过滤器的生命周期都要明确。销毁过滤器时 Qt 会自动移除它；如果过滤器处理不完整就返回 true，会吞掉控件原本需要的输入。鼠标事件还可能因为被接受、被忽略或被过滤而走不同路径，调试时应确认事件实际到达了哪个对象。

## 鼠标、滚轮与键盘

鼠标的 press、release、double-click、move 分别对应不同处理函数。`event->button()` 是触发当前按下或释放事件的按钮；`event->buttons()` 是事件发生时仍处于按下状态的按钮集合。鼠标移动事件默认主要在拖动中产生；需要无按键移动时可对控件设置 `setMouseTracking(true)`。

事件坐标有局部、窗口和屏幕等坐标系。局部坐标适合判断控件内部命中区域；拖动窗口或跨控件计算时应明确转换坐标系。不要把 `QCursor::pos()` 的当前指针位置和事件携带的事件发生时位置混为一谈。

滚轮事件的 `angleDelta()` 以 1/8 度为单位；常见滚轮的 120 个单位约为 15 度，但高分辨率设备可以给出更小步长。若平台提供 `pixelDelta()`，它表示屏幕像素位移，适合高分辨率触控板。处理不了滚动事件时调用 `ignore()`，让父控件还有机会处理。

~~~cpp
// Qt 6 片段：记录当前局部位置并安排重绘
void Canvas::mouseMoveEvent(QMouseEvent *event)
{
    cursorPosition_ = event->position();
    update();
    QWidget::mouseMoveEvent(event);
}
~~~

键盘事件发给具有键盘焦点的控件。可通过焦点策略、tab 顺序和明确的焦点移交，让键盘操作可以完成相同任务。需要读取按键本身时重写 `keyPressEvent()` 和 `keyReleaseEvent()`；若控件不处理某按键，应交给基类，以免破坏控件内建行为。

悬停反馈可用 QSS 伪状态，也可通过 `enterEvent()`、`leaveEvent()` 处理。鼠标指针可设置为手形、等待或拖动形态；通过 `setCursor()` 设置后，窗口失焦或离开控件时要考虑是否恢复默认状态。全局键鼠输入和直接读取操作系统设备文件不属于 Qt 普通控件事件，具有平台与权限依赖，不能作为可移植界面的默认实现。

## Qt 5 / Qt 6 输入 API

| 用途 | Qt 5 常见接口 | Qt 6 接口 | 迁移提示 |
| --- | --- | --- | --- |
| 鼠标控件内位置 | `QMouseEvent::pos()` 返回整数点；`localPos()` 保留浮点位置 | `position()` 返回相对于接收控件的浮点位置 | Qt 6 应优先使用 `position()`；整数取整会丢失亚像素信息 |
| 屏幕位置 | `globalPos()` 或 `screenPos()` | `globalPosition()` | 移动窗口时用事件中的全局位置，避免使用已经变化的当前控件位置 |
| 滚轮方向与幅度 | `angleDelta()`；支持平台时也可读 `pixelDelta()` | 同样使用 `angleDelta()` 和 `pixelDelta()` | 不要沿用早期 Qt 代码中的旧式滚轮 delta 接口；小于 120 的角度增量也要处理 |

Qt 5 与 Qt 6 的同名类还可能在返回值类型、重载和可用版本上有所区别。若要兼容多种 Qt 5 小版本，应确认目标最低版本是否提供特定函数，不要只看 Qt 6 当前文档。

## QWidget 绘制事件

窗口需要重绘时，Qt 会调用控件的 `paintEvent()`。例如，窗口大小改变、遮挡恢复或调用 `update()` 都可能安排绘制。只在绘制事件中通过 `QPainter` 绘制 QWidget；不要从任意线程或普通业务函数直接在 QWidget 上创建画家对象。

~~~cpp
// 片段：简单的自定义绘制
void Meter::paintEvent(QPaintEvent *event)
{
    Q_UNUSED(event);

    QPainter painter(this);
    painter.setRenderHint(QPainter::Antialiasing);

    QPen pen(QColor("#2878b5"));
    pen.setWidth(3);
    painter.setPen(pen);
    painter.drawLine(QPoint(8, 20), QPoint(width() - 8, 20));

    painter.setBrush(QColor("#f0a23b"));
    painter.drawEllipse(QPoint(width() / 2, height() / 2), 8, 8);
}
~~~

`QPen` 描述轮廓的颜色、宽度和线型；`QBrush` 描述封闭区域的填充。抗锯齿是绘制提示，是否以及怎样实现还取决于绘图引擎。改坐标、缩放或旋转等 painter 状态时，可以用 `save()` / `restore()` 限定状态影响范围。

`update()` 安排之后的绘制事件，并允许 Qt 合并连续更新；`repaint()` 通常会立即请求绘制，容易造成不必要的重复工作。不要直接调用 `paintEvent()`；更新控件状态后调用 `update()`，让事件循环安排重绘。Qt Widgets 自带绘制缓冲，无需为普通控件重复实现双缓冲。

`QPainter` 也可以绘制到 `QImage`、`QPixmap` 或 `QPicture` 等绘图设备。需要读取或修改像素时可用 `QImage`；以界面显示为主时通常用 `QPixmap`；`QPicture` 可记录并重放绘图命令。绘图设备的用途不同，不能把其中一类与另一类的线程和像素访问特性视为相同。

## 样式表与视觉状态

Qt Style Sheets（QSS）使用接近 CSS 的选择器和属性语法，适合调整控件颜色、边框、内边距、字体和部分子控件外观。它不是完整浏览器 CSS：布局、动画和选择器行为以 Qt 支持的子集为准。可以给控件设置 `objectName`，用 `#name` 选择单个对象；也可用 `QPushButton:hover`、`QLineEdit:focus` 表达状态。

~~~cpp
// 片段：对单个控件设置局部样式
ui.applyButton->setStyleSheet(
    "QPushButton { padding: 6px 12px; border-radius: 4px; }"
    "QPushButton:hover { background-color: #dceeff; }"
);
~~~

局部样式表通常比应用级全局规则更容易维护。选择器范围过宽可能影响嵌套控件或第三方控件；若多个来源设置同一属性，样式级联与优先级也会影响最终结果。避免把每个动态状态都拼成大量字符串；对于简单交互状态，优先使用控件属性、调色板、标准图标或少量 QSS 伪状态。样式表用于外观，不应承担业务状态存储。

## 参考资料

- [Events and Filters](https://doc.qt.io/qt-6/eventsandfilters.html)
- [QMouseEvent (Qt 5.15)](https://doc.qt.io/archives/qt-5.15/qmouseevent.html)
- [QMouseEvent (Qt 6)](https://doc.qt.io/qt-6/qmouseevent.html)
- [QWheelEvent (Qt 5.15)](https://doc.qt.io/archives/qt-5.15/qwheelevent.html)
- [QWheelEvent (Qt 6)](https://doc.qt.io/qt-6/qwheelevent.html)
- [Qt Style Sheets](https://doc.qt.io/qt-6/stylesheet.html)
