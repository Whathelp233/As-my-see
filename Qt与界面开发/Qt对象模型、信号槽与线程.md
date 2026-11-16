# Qt 对象模型、信号槽与线程

> 本文中的 C++ 代码均为 API 片段，省略完整类声明、构建文件和应用入口。按目标 Qt 版本补齐工程上下文后使用。

## 应用程序与事件循环

Qt Widgets 程序通常由一个 `QApplication` 管理界面对象和平台设置。调用 `exec()` 后，主线程进入事件循环：Qt 收取窗口系统事件、定时器事件和队列中的调用，再把它们分发给对应对象。窗口重绘、按键、鼠标、用户触发的信号槽都依赖事件处理能够继续运行。

```cpp
// 片段：常见的 Widgets 应用入口
QApplication app(argc, argv);
MainWindow window;
window.show();
return app.exec();
```

`exec()` 的返回值是应用退出码；正常的 `quit()` 路径通常返回 0，但代码不应把所有非零返回值解释成某种 Qt 错误。不要在 GUI 线程做长时间计算、阻塞网络读写或长时间等待锁：事件循环停住时，窗口不能响应输入和重绘。把耗时工作移到工作线程，并向 GUI 线程发送结果。

## 元对象系统

Qt 在标准 C++ 之上提供元对象系统，用于运行时类型信息、属性、信号槽和反射式调用。构建期间，Meta-Object Compiler（MOC）会处理需要 Qt 元对象功能的类并生成 C++ 代码。声明自定义信号、Qt 属性或需要元对象识别的槽时，类通常要包含 `Q_OBJECT`。

```cpp
// 片段：带有自定义信号的 QObject
class ValueSource : public QObject
{
    Q_OBJECT

public:
    using QObject::QObject;

signals:
    void valueChanged(int value);
};
```

信号由 MOC 生成，不在 .cpp 中手写实现。槽本质上仍是函数；现代写法通常直接把普通成员函数连接到信号，不必为了每个回调都使用 `slots:` 宏段。旧式 `SIGNAL(...)` / `SLOT(...)` 字符串写法仍可在遗留代码中见到，但编译器难以检查它们的拼写和参数，优先使用成员函数指针写法。

`Q_PROPERTY` 可以把读取、写入、重置等接口登记为 Qt 属性；Designer、动画、样式和元对象 API 可据此访问属性。属性宏声明的读写函数仍需由类实现。不要把属性系统和普通 C++ 成员变量自动等同：只有登记的属性才会出现在 Qt 元对象接口中。

## 信号与槽：松耦合的对象通信

信号表示对象状态变化或事件发生，槽表示对此作出的响应。发送者无需知道接收者是谁；同一信号可连接到多个槽，多个信号也可汇入同一个槽。信号的参数类型应与接收函数兼容；接收函数可以少接收一些尾部参数。

```cpp
// 片段：用类型安全的成员函数指针连接
connect(button, &QPushButton::clicked,
        this, &MainWindow::close);

// 片段：短小操作可写成 lambda，并提供接收上下文
connect(button, &QPushButton::clicked, this, [this] {
    refreshView();
});
```

默认的 `Qt::AutoConnection` 在信号发射时比较当前发射线程与接收对象的线程亲和性：相同则直接调用，不同则排队到接收对象所属线程的事件循环。判断依据不是调用 `connect()` 时所在的线程，也不是 sender 对象的线程亲和性。显式的 `Qt::DirectConnection` 会在发射信号的线程中立即执行接收端代码，跨线程触及界面时不要这样做。队列连接会等接收线程的事件循环处理该调用，因此接收线程必须仍在运行。

一个信号可以连接到普通槽、另一个信号或 lambda。连接是否存在，与信号发出后具体槽的同步或异步执行方式是两个不同问题。需要准确推断执行线程时，结合发射时当前线程、接收对象的线程亲和性和所选连接类型判断，不要只凭“代码写在某个类里”判断。

## lambda 捕获与连接上下文

lambda 的捕获列表决定闭包如何访问外部变量：

- `[]`：不捕获局部变量。
- `[name]`：按值保存变量副本。
- `[&name]`：按引用访问原变量。
- `[this]`：保存当前对象指针，访问其成员。
- `[=]` 和 `[&]`：按需捕获当前作用域中被使用的局部变量，不是把整个作用域中的每个变量都复制或引用一遍。
- `mutable` 允许修改闭包中按值保存的副本；它不会修改外部原变量。

函数返回或局部作用域结束后，引用捕获的变量可能已经销毁。界面信号通常比创建连接的函数活得更久，因此不要让异步 lambda 持有局部变量引用。成员函数中的 `[=]` 使用成员时会涉及 `this` 指针捕获；代码中明确写 `[this]` 更便于审查生命周期。

lambda 的一般形式是捕获列表、参数列表、可选的 `mutable` / 返回类型和函数体。编译器为每个 lambda 生成闭包类型；通常用 `auto` 保存它，只有需要统一存储不同 callable 时才考虑 `std::function`。C++14 起可用 `auto` 参数创建泛型 lambda：

~~~cpp
// C++14 片段：可处理不同数值容器元素类型的比较函数
const auto lessMagnitude = [](const auto &left, const auto &right) {
    return std::abs(left) < std::abs(right);
};

std::sort(values.begin(), values.end(), lessMagnitude);
~~~

若 lambda 按值捕获变量，闭包保存其副本；只有加 `mutable` 才能修改闭包里的副本，外部变量仍保持原值。按引用捕获则直接访问外部对象，因此要求该对象在每次调用期间都仍然存活。

lambda 连接应优先指定接收上下文 QObject。连接会在上下文对象析构时自动断开，队列调用也会在接收对象所属线程执行。上下文决定连接生命周期和队列目标；它不会让捕获的局部引用变得安全。

```cpp
// 片段：上下文对象是界面的一部分，销毁时连接自动失效
connect(worker, &Worker::resultReady,
        ui.statusLabel, &QLabel::setText,
        Qt::QueuedConnection);
```

无上下文的 functor/lambda 连接无法自动根据某个界面对象的生命周期断开，并且其执行线程容易被误判。Qt 6.7 起还可以用 `QT_NO_CONTEXTLESS_CONNECT` 禁止这类连接。需要在 lambda 中访问界面时，给 `connect` 指定 GUI 线程中的 QObject 上下文，或者连接到界面对象的槽函数。

## QObject 对象树与所有权

`QObject` 可通过父子关系构成对象树。把 QObject 子对象设为父对象后，父对象销毁时会销毁仍属于它的子对象。Widgets 在 QObject 父子关系基础上还建立了可视嵌套：子控件使用父控件的坐标系，并通常被父控件边界裁剪。

```cpp
// 片段：父控件拥有新建的子控件
auto *button = new QPushButton(tr("关闭"), this);
button->move(12, 12);
```

自动释放只适用于对象树中的子对象，不是“Qt 创建的任何对象都会自动释放”。普通 C++ 对象、没有 parent 的 QObject 指针，以及由标准库智能指针管理的对象遵循各自的所有权规则。QObject 的成员变量不会仅因它是某个 QObject 的成员而自动成为子对象；需要显式传入父对象或调用 `setParent()`。栈 QObject 的父子顺序尤其要清楚：若先构造栈父对象、再构造栈子对象，作用域结束时子对象先析构并从父对象移除，通常是安全的；危险情况是父对象先销毁（例如后构造的父对象先离开作用域），而栈子对象仍存活，此时父析构会删除子对象，之后子对象还会再次走 C++ 作用域析构。对可能提前销毁的父对象，不要把仍由栈负责析构的 QObject 设为其子对象。

对象的 parent 必须与对象处于同一线程。调用 `moveToThread()` 会迁移该对象及其 QObject 子对象；带 parent 的对象不能单独移动。该父子规则也意味着，不能把由某线程拥有的 QWidget 或 QObject 随意交给另一个线程销毁。

对堆上创建、需要在窗口关闭时释放的独立窗口，可让 parent 管理它，或在适当场景设置 `Qt::WA_DeleteOnClose`。后者会在窗口关闭事件被接受时删除窗口，之后不能再使用旧指针。非模态窗口的生命周期应由父对象、持有指针或智能指针明确负责，避免每次点击都创建一个无人管理的新窗口。

线程边界上的 QObject 不应被另一个线程随意直接调用或删除。跨线程销毁应优先安排在对象所属线程执行，例如通过 `deleteLater()`。延迟删除依赖接收线程的事件循环；如果线程已退出且没有相应清理路径，不能指望一个之后无人处理的事件替你释放资源。

## Qt 线程与 GUI 更新

Qt 中每个 QObject 都有线程亲和性。默认情况下，对象属于创建它的线程；排队信号槽和事件会由对象所属线程的事件循环处理。QObject 通常可在不同线程之间传递信号，但大多数 QObject 子类本身并不因此变成线程安全。共享状态仍需设计同步或复制消息。

所有 QWidget 及其子类都只能由 GUI 主线程访问。ROS 回调、文件读取线程、计算线程或网络线程不得直接设置 QLabel 文本、更新绘图控件或调用 QWidget 的方法。将结果作为值传递给 GUI 线程中的接收对象，再由该对象更新控件：

```cpp
// 片段：worker 在后台发信号，label 在 GUI 线程接收
connect(worker, &Worker::resultReady,
        ui.statusLabel,
        [label = ui.statusLabel](const QString &text) {
            label->setText(text);
        },
        Qt::QueuedConnection);
```

如果 GUI 元素可能先于生产者销毁，确保接收上下文是会随该界面一起销毁的 QObject；连接断开后，尚未执行的队列调用也不应再访问已销毁界面。对于复杂消息，发送不可变、具备良好复制语义的数据，避免在两个线程之间共享一个正在修改的对象。队列连接需要把参数封装后投递；自定义类型在某些 Qt 版本和使用方式下还要向元类型系统注册，并应满足所需的可复制/可构造语义。跨 Qt 版本时核对该版本的元类型注册要求。

`QThread` 对象本身通常仍属于创建它的线程，不等于它启动的执行线程。常见做法是创建一个独立 Worker QObject，将 Worker 移到 QThread，再通过信号槽启动、交付结果和关闭；不要误以为在 QThread 子类里声明的普通槽会自动在新线程中执行。Worker 使用 `QTimer`、`QTcpSocket` 等事件驱动对象时，工作线程需要运行自己的事件循环。

## 定时器不是实时钟

`QTimer` 会在线程事件循环中投递 timeout。定时器对象在哪个线程，就必须在哪个线程启动和停止；该线程要有事件循环。GUI 定时器适合动画、刷新显示或轻量的周期任务，重任务仍应交给工作线程。系统负载和事件循环繁忙会让定时器延后，因此它不能保证精确周期，更不能替代实时控制时钟。

```cpp
// 片段：界面对象在 GUI 线程创建并管理定时器
auto *timer = new QTimer(this);
connect(timer, &QTimer::timeout, this, &MainWindow::refreshStatus);
timer->start(500);  // 示例间隔，单位为毫秒
```

要在工作线程运行定时器，应先确保拥有它的 Worker 已迁移到目标线程，并在该线程的事件循环运行后再启动、停止。不要在 GUI 线程里通过 `sleep` 等待定时器；这会阻止界面事件处理。

## 版本提示

| 主题 | Qt 5 | Qt 6 |
| --- | --- | --- |
| MOC / `Q_OBJECT` | 信号槽、属性和元对象功能需要 MOC 处理；CMake 项目可启用 AUTOMOC | 机制相同；目标与组件通常使用 `Qt6::...`，并确认所用 CMake API 的最低 Qt 版本 |
| lambda 连接 | 类型安全的成员函数指针连接和带上下文的 lambda 连接可用 | 同样可用；Qt 6.7 增加禁止 context-less functor 连接的构建选项 |
| `QObject::moveToThread` 返回值 | 返回 `void` | 从 Qt 6.7 起返回 `bool`；较旧 Qt 6 代码可能仍是 `void` |
| GUI 线程规则 | QWidget 在 GUI 主线程使用 | 规则相同，不能因 Qt 6 支持更多异步 API 就跨线程访问 QWidget |

Qt 版本、编译器标准和 rqt 发行版会共同决定可用接口。尤其不要只按 Qt 主版本猜测某个新重载一定可用；核对目标安装版本的类参考。

## 参考资料

- [Object Trees & Ownership](https://doc.qt.io/qt-6/objecttrees.html)
- [Signals & Slots](https://doc.qt.io/qt-6/signalsandslots.html)
- [Threads and QObjects](https://doc.qt.io/qt-6/threads-qobject.html)
- [QObject](https://doc.qt.io/qt-6/qobject.html)
- [Timers](https://doc.qt.io/qt-6/timers.html)
