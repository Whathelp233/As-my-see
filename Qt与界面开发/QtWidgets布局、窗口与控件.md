# Qt Widgets 布局、窗口与控件

> 代码均为 C++ / Qt API 片段，不包含完整应用入口或项目构建文件；按目标 Qt 版本补齐工程上下文后使用。

## QWidget 与布局：让界面适应可用空间

Qt Widgets 中，`QWidget` 是可视控件的基础类。按钮、标签、输入框和复合控件都可以放进另一个 QWidget 中。控件的坐标可以手动指定，但固定坐标很难适应窗口大小、字体缩放和不同平台的样式。实际界面通常用布局对象自动安排子控件。

常用布局包括：

- `QHBoxLayout`：把控件排成一行。
- `QVBoxLayout`：把控件排成一列。
- `QGridLayout`：以行列组织控件；单个控件可以占多行、多列。
- `QFormLayout`：把标签和输入控件按表单行配对。
- 布局可以嵌套，也能加入另一个布局。

~~~cpp
// 片段：表单中嵌套一行按钮
auto *form = new QFormLayout;
form->addRow(tr("名称"), nameEdit);
form->addRow(tr("数量"), countSpin);

auto *buttons = new QHBoxLayout;
buttons->addStretch();
buttons->addWidget(cancelButton);
buttons->addWidget(saveButton);

auto *root = new QVBoxLayout;
root->addLayout(form);
root->addLayout(buttons);
setLayout(root);
~~~

布局会依据控件的 size hint、最小/最大尺寸、size policy 和 stretch factor 分配空间。需要平均排布或让按钮靠边时，用布局 stretch factor；只需要固定空隙时用 `addSpacing()`；需要可伸缩空白时用 `addStretch()` 或 spacer。不要把“伸缩空白”和“固定间距”当成同一种尺寸。

`setContentsMargins(left, top, right, bottom)` 设置布局边缘的内容间距，`setSpacing()` 设置相邻布局项之间的间距。旧代码中的 `setMargin()` 已不应作为新代码的通用写法。自定义控件若没有内部布局，可以通过 `sizeHint()`、`minimumSizeHint()` 和 `setSizePolicy()` 告诉父布局它需要的空间。

当控件需要临时隐藏或显示时，布局会重新计算剩余空间；若相邻控件被挤压，调整 size policy、stretch 或布局分组比用像素坐标补偿更可靠。固定宽高适合图标、进度指示等有明确尺寸的元素，不应作为整个界面的默认布局策略。

## Designer 与 .ui 文件

Qt Widgets Designer 可视化编辑界面，并将结构保存为 XML 格式的 .ui 文件。构建时，User Interface Compiler（UIC）读取该文件并生成 UI 类头文件；通常在窗口构造函数中创建 UI 对象，再调用生成的 `setupUi(this)`。生成头文件是构建产物，不应手工修改。

Designer 的控件树描述界面结构；布局负责运行时几何；业务逻辑由自己的类实现。适合静态表单、菜单和常规控件的页面可先用 Designer 设计，再在代码中连接信号、验证输入或创建动态控件。若要把自定义控件放进 Designer，可将一个已有的基类控件“提升”为自定义派生类；被提升的类应提供可用的构造函数，并让构建系统找到其声明与实现。

Designer 可以按对象名生成自动连接函数，命名形式为 `on_<objectName>_<signalName>(...)`。这个约定便于小型界面快速搭建，但容易受对象名、信号重载和自动槽命名影响。对跨模块行为和需要清楚管理生命周期的连接，显式调用 `connect()` 更容易审查。新增 .ui、头文件、资源文件或源文件后，要确保项目构建系统包含它们。

CMake 项目通常需要 Qt 的 Widgets 模块，以及对应版本的 MOC、UIC、RCC 处理。下面是表达依赖的简化片段；具体自动生成方式随 Qt/CMake 版本而变化：

~~~cmake
# 片段：Qt 6
find_package(Qt6 REQUIRED COMPONENTS Widgets)
target_link_libraries(my_app PRIVATE Qt6::Widgets)

# Qt 5 项目使用 Qt5::Widgets 目标
~~~

如果类声明了 `Q_OBJECT`，应确认 MOC 会处理该头文件；若使用 .ui 和 .qrc 文件，也应确认 UIC 和 RCC 会参与构建。现代 CMake 可采用 AUTOMOC、AUTOUIC、AUTORCC 或相应 Qt CMake 命令。不要把某个 IDE 是否能打开 .ui 文件误当成构建要求；Designer 和命令行构建步骤可以分开使用。

## QMainWindow 组合框架

`QMainWindow` 为桌面应用提供固定的主窗口框架，包含菜单栏、工具栏、中心控件、可停靠窗口和状态栏。中心控件由 `setCentralWidget()` 设置，通常是一个带布局的 QWidget。一个主窗口只有一个中心控件；若需要多个页面，用页面容器放在中心区域，而不是反复设置不同中心对象。

~~~cpp
// 片段：将同一 QAction 放进菜单与工具栏
auto *openAction = new QAction(QIcon(":/icons/open.svg"),
                               tr("打开"), this);
openAction->setShortcut(QKeySequence::Open);

auto *fileMenu = menuBar()->addMenu(tr("文件"));
fileMenu->addAction(openAction);

auto *toolbar = addToolBar(tr("常用操作"));
toolbar->addAction(openAction);

connect(openAction, &QAction::triggered,
        this, &MainWindow::openDocument);
~~~

`QAction` 把一项用户操作与文本、图标、快捷键和状态组合起来，因此可以由菜单、工具栏和快捷键复用。`triggered()` 表示该操作被触发；checkable action 的 `toggled(bool)` 还携带选中状态。菜单项、工具栏按钮和普通按钮的状态应从同一个操作模型更新，避免各处显示互相矛盾。

`QToolBar` 可停靠或浮动，适合放置高频操作。`QDockWidget` 可承载可停靠的辅助面板，如属性、目录或诊断信息。`QStatusBar` 常用于显示短期提示或固定状态；调用 `statusBar()` 时，QMainWindow 会在需要时创建默认状态栏。对停靠方向或浮动能力有约束时，可设置相应 allowed areas 和 floatable 属性。

## 常用控件的职责

| 控件 | 适合用途 | 需要留意 |
| --- | --- | --- |
| `QLabel` | 显示短文本、图标或图片 | 图片缩放可能改变宽高比；用 `QMovie` 可播放支持的动画图像 |
| `QLineEdit` | 单行输入、密码、搜索 | 用 validator、输入掩码或提交时校验约束；可设置 placeholder 和清除按钮 |
| `QPlainTextEdit` | 大段纯文本或日志显示 | 比富文本控件更适合纯文本；可限制文档 block 数量控制日志增长 |
| `QTextEdit` | 富文本编辑和格式化内容 | `toPlainText()` 与 `toHtml()` 返回的语义不同；插入不可信文本时不要把它拼进 HTML |
| `QTextBrowser` | 只读文本与富文本浏览 | 默认富文本解析会解释标记；不可信内容应用纯文本方式呈现 |
| `QComboBox` | 从有限选项中选择 | 当前索引只是列表位置，插入或排序后会变化；稳定实体 ID 可放在 `itemData(index, Qt::UserRole)` 中，显示文本也可能重复 |
| `QSpinBox` / `QDoubleSpinBox` | 整数或浮点量的范围输入 | 显式设置范围、步长、单位和精度 |
| `QSlider` / `QScrollBar` | 范围值调节或内容滚动 | 分清范围、当前值、page step；滚动条不是位置传感器 |
| `QPushButton` | 执行一次操作 | clicked 表示点击完成，pressed/released 描述按下/释放阶段 |
| `QToolButton` | 小型工具操作或图标按钮 | 图标与文字组合方式由 tool button style 决定 |
| `QCheckBox` | 独立开关选择 | 三态复选框的部分选中是额外状态，不等同于布尔真值 |
| `QRadioButton` | 互斥选项 | 用按钮组显式限定一组互斥选择的范围 |

文本框应区分“输入、展示、富文本”需求。行输入从 `QLineEdit::text()` 读取；多行纯文本可用 `QPlainTextEdit::toPlainText()`；富文本编辑器可以用 `QTextCursor` 定位、插入文本并设置字符格式。面向长时间运行日志，可设置文档最大 block 数，避免无限追加导致内存和界面响应时间持续增长。

若把外部数据写进富文本控件，HTML 标签可能被解释为格式或链接。可以用 `insertPlainText()`、`Qt::PlainText` 或合适的 HTML 转义，让用户提供的内容只被当作文本。读取 HTML 和纯文本是两个不同接口，不能互换。

## 输入、选择与文本控件的常用接口

控件的信号表示用户动作或值变化；槽函数读取控件当前值后，应再次校验范围和业务约束。validator 能在输入阶段限制明显无效的字符，但不能替代提交时验证，也不能保证从配置或程序设置来的值有效。

~~~cpp
// 片段：限制输入范围，并在提交时读取和检查
auto *validator = new QIntValidator(0, 100, this);
ui.countEdit->setValidator(validator);

connect(ui.applyButton, &QPushButton::clicked, this, [this] {
    bool ok = false;
    const int count = ui.countEdit->text().toInt(&ok);
    if (!ok || count < 0 || count > 100) {
        showInputError();
        return;
    }
    applyCount(count);
});
~~~

组合框显示标签和持久标识应分开保存。当前索引代表当前列表位置，插入、删除、排序和动态刷新都可能改变它；跨刷新需要识别同一实体时，应把实体 ID 作为 user role 数据保存，并用该数据查找或恢复当前选择。

~~~cpp
// 片段：显示名称，另存可稳定识别项目的 ID
ui.modeBox->addItem(tr("快速"), 10);
ui.modeBox->addItem(tr("精细"), 20);

const QVariant selectedId =
    ui.modeBox->itemData(ui.modeBox->currentIndex(), Qt::UserRole);
~~~

对于纯文本日志，`QPlainTextEdit` 有 `appendPlainText()`，可为文档设置最大 block 数以限制长期增长。对于富文本编辑器，使用 `QTextCursor::insertText()` 插入用户文本；`append()` 会按文本自动识别规则解释内容，外部输入不应未经处理拼成 HTML。

~~~cpp
// 片段：在富文本编辑器末尾以纯文本方式追加一行
QTextCursor cursor = ui.textEdit->textCursor();
cursor.movePosition(QTextCursor::End);
cursor.insertText(line + QLatin1Char('\n'));
ui.textEdit->setTextCursor(cursor);
ui.textEdit->ensureCursorVisible();
~~~

需要在鼠标指定位置编辑时，可用控件的 `cursorForPosition()` 取得 QTextCursor，再通过 cursor 的 `insertText()` 或选择范围完成插入和替换。不要仅凭字符下标猜测可视位置：换行、富文本格式、字体和换行布局都会改变屏幕上的光标位置。

## 容器控件与模型视图

- `QGroupBox` 把一组相关输入放入有标题的区域。
- `QScrollArea` 为较大的子控件提供滚动视口。
- `QTabWidget` 将相关页面按标签页切换。
- `QStackedWidget` 同时保留多个页面，但一次只显示一个；可由导航控件切换 index 或页面指针。
- `QToolBox` 将多个折叠页面纵向堆叠。
- `QListWidget`、`QTreeWidget`、`QTableWidget` 是带内置项目存储的便捷控件，适合简单列表、树或表格。

项目数较大、数据需要排序过滤，或同一数据要在多个视图复用时，应了解 Qt Model/View：数据保存在模型中，视图只负责呈现与交互。`QListView`、`QTreeView`、`QTableView` 可以与自定义模型搭配。不要把每一个表格单元格都当成一个独立 QWidget；大数据量逐项创建控件会增加布局和绘制成本。

通过 `QTableWidget::setItem(row, column, item)` 填表时，先设置行列数与表头，并检查索引边界。Tree 项目则先创建顶层节点，再添加子节点。stack 容器设置默认页可以避免启动时显示非预期页面。

## 对话框：同步与非阻塞使用

对话框可以是模态或非模态。模态窗口限制用户与其他窗口交互；非模态窗口允许用户并行操作主窗口。常见快捷函数有消息框、颜色选择框、字体选择框和文件选择框。文件选择结果应先检查取消情况，再继续读取或写入。

~~~cpp
// 片段：用户取消时不继续处理
const QString path = QFileDialog::getOpenFileName(
    this, tr("打开文件"), {}, tr("文本文件 (*.txt);;所有文件 (*)"));
if (path.isEmpty()) {
    return;
}
~~~

调用 `QDialog::exec()` 会阻塞当前调用路径，并启动嵌套事件循环。对简单的短交互它仍然常见，但 Qt 文档建议优先考虑 `open()`，通过 `accepted()`、`rejected()` 或 `finished(int)` 处理结果。`show()` 和 `open()` 会立即返回，因此对话框不能是即将离开作用域的栈对象；要让父对象或显式的长期指针管理它的生命周期。若希望关闭后自动销毁，可在适用场景设置 `Qt::WA_DeleteOnClose`，销毁后不可继续访问原指针。

静态 `QFileDialog::getOpenFileName()` 返回所选文件路径，用户取消时返回空字符串。过滤器只影响列表显示，不等于文件内容校验。打开文件前还应检查存在性、权限和格式；写入时考虑覆盖确认及错误提示。

## 参考资料

- [Layout Management](https://doc.qt.io/qt-6/layout.html)
- [Application Main Window](https://doc.qt.io/qt-6/mainwindow.html)
- [QMainWindow](https://doc.qt.io/qt-6/qmainwindow.html)
- [Qt Widgets Designer 入门](https://doc.qt.io/qt-6/widgets-getting-started.html)
- [QDialog](https://doc.qt.io/qt-6/qdialog.html)
- [QFileDialog](https://doc.qt.io/qt-6/qfiledialog.html)
