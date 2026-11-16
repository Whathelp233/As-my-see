# rqt 插件与 GUI 线程桥接

> 本文只讲 Qt Widgets 插件结构和界面线程边界。ROS 节点、执行器、话题、QoS 和运行时组织由 [ROS 与软件架构](../ROS与软件架构/节点执行与组件化架构.md)主讲。代码为结构示例，ROS 发行版和 rqt/Qt 组合各异，按目标发行版的官方 API 核对后使用。

## 插件生命周期与界面嵌入

`rqt_gui_cpp::Plugin` 是用 C++ 编写 rqt 插件的基类。插件通常在 `initPlugin(PluginContext&)` 创建顶层 widget、加载 Designer 生成的 UI 并调用 `context.addWidget()`，由 rqt 把窗口内容嵌入自己的面板。插件可实现 `shutdownPlugin()` 释放资源，并通过 `saveSettings()` / `restoreSettings()` 保存和恢复轻量界面状态。具体虚函数签名以目标发行版安装的头文件为准。

~~~cpp
// 结构示例：插件持有自己的 widget 与生成 UI
class StatusPlugin : public rqt_gui_cpp::Plugin
{
    Q_OBJECT

public:
    StatusPlugin()
    {
        setObjectName("StatusPlugin");
    }

    void initPlugin(qt_gui_cpp::PluginContext &context) override
    {
        widget_ = new QWidget();
        ui_.setupUi(widget_);
        context.addWidget(widget_);
    }

    void shutdownPlugin() override
    {
        // 停止自有异步工作，并释放非 parent 管理的资源
    }

signals:
    void statusSnapshotReady(const QString &text);

private:
    QWidget *widget_ = nullptr;
    Ui::StatusWidget ui_;
};
~~~

插件与普通桌面应用的主要区别是宿主负责创建 GUI 应用和事件循环。插件代码不应另建 `QApplication` 或启动第二个 UI 事件循环。插件自己的界面对象应有清晰的所有权：宿主加入 widget 后按框架约定管理其嵌入生命周期；插件持有的后台任务、连接和独立资源仍需在关闭阶段停止或断开。具体宿主所有权合同应核对目标版本的插件 API。

## 构建与发现

rqt 插件一般由 C++ 插件类、pluginlib 导出、插件描述清单和 ROS 包构建配置组成。插件类通常导出为 `rqt_gui_cpp::Plugin`，插件清单声明库、类名和基类。包清单和 CMake 还要声明对应发行版的 ament 或 catkin 依赖，以及 Qt Widgets、UIC/MOC 等构建需求。编译系统和 XML 字段会随 ROS 发行版变化；应复制目标发行版官方示例的接口格式，再按包结构调整，而不要把某个发行版的 CMake 配置当作跨版本固定模板。

插件清单中声明的类名、C++ 导出宏、共享库名称和安装路径必须相互一致。常见发现失败包括：库未安装、pluginlib 描述未导出、基类字符串错误、类导出名拼写不匹配、Qt 元对象代码没有生成。检查时先看宿主报告的 pluginlib 错误，再逐项核对包安装和导出元数据。

## 从回调线程向界面传递状态

rqt 中通常存在 GUI 事件循环和 ROS 回调处理路径。若回调运行在非 GUI 线程，回调不应直接调用 QLabel、QTableView 或其他 QWidget。采用数据消息桥接：在回调一侧读取必要值，构造小型快照，然后通过带 GUI QObject 上下文的 queued signal-slot 投递给界面；GUI 侧槽更新控件。

~~~cpp
// 结构示例：statusLabel 是 widget_ 中由 Designer 生成的 QLabel*
connect(this, &StatusPlugin::statusSnapshotReady,
        widget_, [label = ui_.statusLabel](const QString &text) {
            label->setText(text);
        },
        Qt::QueuedConnection);

// 回调线程里只生成值消息并发信号，不读写 QWidget
const QString snapshot = makeStatusSnapshot();
emit statusSnapshotReady(snapshot);
~~~

需要从 worker 线程发射信号时，发送的参数应是可安全复制的数据快照，不要传递仍会被另一线程修改的裸指针或引用。自定义 queued 参数按目标 Qt 版本注册元类型，并满足其排队传递所需的复制语义。连接的接收上下文应随插件界面销毁；插件关闭时停止异步回调来源或解除注册，防止新的结果继续进入已关闭界面。

如果使用 `QMetaObject::invokeMethod()` 投递 lambda，先检查目标 Qt 版本是否提供所需重载，并提供 GUI 对象作为 context。不要使用无上下文的 lambda 连接后在其中捕获 widget 裸指针；没有接收上下文时，生命周期和执行线程都更难保证。若结果产生得比界面刷新快，可在 GUI 侧合并或丢弃过期快照，但该策略要依据界面用途定义，不能盲目丢弃需要完整处理的业务事件。

## RViz 与 Qt 的线程桥接

RViz 面板也是 Qt Widgets 界面的一种扩展形式。ROS 回调或后台处理结果需要跨线程交给 Qt 主线程时，沿用同一原则：传递不可变值、让 Qt GUI 线程更新 widget、确保接收对象与面板生命周期绑定。线程消息桥接只处理界面交付，不替代 ROS 执行器、数据同步或业务状态机设计；这些归属见 [ROS 与软件架构](../ROS与软件架构/节点执行与组件化架构.md)。

## 参考资料

- [rqt_gui_cpp 包索引](https://index.ros.org/p/rqt_gui_cpp/)
- [rqt_image_view 插件头文件（Rolling）](https://github.com/ros-visualization/rqt_image_view/blob/rolling-devel/include/rqt_image_view/image_view.hpp)
- [rqt_image_view 插件实现（Rolling）](https://github.com/ros-visualization/rqt_image_view/blob/rolling-devel/src/rqt_image_view/image_view.cpp)
- [rqt_image_view 构建配置（Rolling）](https://github.com/ros-visualization/rqt_image_view/blob/rolling-devel/CMakeLists.txt)
- [Threads and QObjects](https://doc.qt.io/qt-6/threads-qobject.html)
- [QObject](https://doc.qt.io/qt-6/qobject.html)
