# Qt 资源与文件读写

> 本文代码是 Qt API 片段，不包含可独立构建的项目；按目标 Qt 版本补齐工程上下文后使用。

## 静态资源与 .qrc

图标、默认配置、翻译文件等随程序发布且不需要运行时修改的内容，可以编入 Qt 资源系统。资源清单 `.qrc` 用 XML 列出磁盘文件，并可通过 prefix 和 alias 决定程序内的资源路径：

~~~xml
<RCC>
  <qresource prefix="/icons">
    <file alias="open.svg">assets/open-document.svg</file>
  </qresource>
</RCC>
~~~

程序使用 `:/icons/open.svg` 访问资源；`QIcon(":/icons/open.svg")`、`QFile(":/config/default.json")` 都可接受资源路径。资源路径是 Qt 虚拟文件系统中的路径，不是当前工作目录下的磁盘路径。资源由 RCC（Resource Compiler）在构建时处理，因此要把 `.qrc` 纳入项目构建；CMake 可启用 AUTORCC，或显式使用 Qt 的资源编译命令。资源适合不可变的内置内容，不适合写用户数据、缓存或需要独立替换的大文件。

## 文件路径、选择和错误处理

`QFileDialog` 负责让用户选择路径，`QFile` 执行读写。选择器返回空路径通常表示用户取消，必须在打开文件前处理该分支。对本地路径也要检查 `open()` 返回值和 `errorString()`；文件过滤器只辅助选择，不保证文件格式正确。

~~~cpp
// 片段：处理取消和打开错误
const QString path = QFileDialog::getOpenFileName(
    this, tr("选择文本文件"), QString(),
    tr("文本文件 (*.txt);;所有文件 (*)"));
if (path.isEmpty()) {
    return;
}

QFile file(path);
if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
    showError(file.errorString());
    return;
}
~~~

相对路径的含义取决于进程当前工作目录，启动器、IDE 和终端可能给出不同工作目录。需要定位随程序安装的配置或资源时，应明确使用 Qt 资源、应用目录或平台提供的标准数据目录；用户选择的文档则使用对话框返回的绝对路径。不要把工作目录中的同名文件误认为应用资源。

流式接口 `QTextStream` 适合逐行解析文本；`QIODevice::readAll()` 可一次读取较小文件，但对任意大文件会造成内存峰值。二进制数据则通过 `QFile::read()` / `write()` 以字节处理。解析配置时还要校验结构、范围和必需字段，不能因扩展名匹配就信任内容。

## 文件元数据与时间格式

`QFileInfo` 可检查路径是否存在、是文件还是目录、文件大小，以及修改时间。对符号链接等路径应先明确自己要检查链接本身还是目标；需要进一步读取文件时仍应检查 `QFile::open()` 是否成功，因为元数据查询和实际读写之间可能发生变化。

~~~cpp
// 片段：读取文件基本信息并生成面向界面的时间文本
QFileInfo info(path);
if (!info.exists() || !info.isFile()) {
    showError(tr("所选路径不是现有文件"));
    return;
}

const qint64 sizeBytes = info.size();
const QString modifiedText =
    info.lastModified().toString("yyyy-MM-dd HH:mm:ss");
~~~

`QDateTime::toString(format)` 使用 Qt 的日期格式符号生成文本；例如 `yyyy-MM-dd HH:mm:ss`。这是面向显示的格式化，界面本地化可考虑 `QLocale`。若时间要写入文件或跨设备交换，应选择明确的时区和机器可读格式（例如 ISO 8601），不要把本地显示字符串当作规范化时间戳。Qt 6.6 增加了接收 `QTimeZone` 的 QFileInfo 修改时间重载；跨版本代码应确认目标 Qt 最低版本。

## 字符编码与 Qt 5 / Qt 6

文本文件的字节编码需要显式处理。UTF-8 可用 `QStringDecoder`（Qt 6）或 `QTextStream` 的相应设置解码；Qt 5 的 `QTextCodec` 位于 Core 模块。Qt 6 移除了 Qt Core 中的 `QTextCodec`，迁移旧代码时可按需求使用 `QStringDecoder`，或在依赖旧接口时检查 Qt Core5Compat 组件。不要假设任意文件字节都能无损地按系统本地编码转换。

~~~cpp
// Qt 6 片段：把字节缓冲区按 UTF-8 解码
QByteArray bytes = file.readAll();
QStringDecoder decoder(QStringDecoder::Utf8);
const QString text = decoder(bytes);
if (decoder.hasError()) {
    showError(tr("文件不是有效的 UTF-8 文本"));
}
~~~

当需要流式读取、逐行解析或控制输出编码时，用 `QTextStream` 并显式设置编码。检查目标 Qt 小版本的 API：Qt 5 和 Qt 6 的编码设置接口发生过变化。无论采用何种解码器，遇到错误字节时都应定义行为，例如拒绝文件、显示诊断或按明确的替代策略恢复，而不是静默把错误文本当有效数据。

## 安全写入与原子替换

直接以 `QIODevice::WriteOnly` 打开文件可能会先截断已有内容。若写入中途失败，磁盘上可能只剩不完整的新文件。`QSaveFile` 提供临时文件写入并在 `commit()` 时提交的模式，适合保存小型配置或文档：先检查 `open()`，检查 `write()` 是否完整，再检查 `commit()` 返回值。

~~~cpp
// 片段：提交前检查写入结果
QSaveFile file(path);
if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
    showError(file.errorString());
    return;
}

QTextStream stream(&file);
stream << text;
stream.flush();
if (stream.status() != QTextStream::Ok || !file.commit()) {
    showError(file.errorString());
}
~~~

原子替换能力依赖文件系统与平台支持，也不等于内容格式正确、权限安全或永不掉电损坏。写入用户指定路径前要确认覆盖语义；若使用 `QSaveFile` 的直接写入回退选项，需理解它会弱化原子替换保证。对于高频大文件、数据库和复杂并发存储，应选择合适的数据存储方案，而不是把所有问题都交给文本文件写入。

## 参考资料

- [The Qt Resource System](https://doc.qt.io/qt-6/resources.html)
- [QFile](https://doc.qt.io/qt-6/qfile.html)
- [QSaveFile](https://doc.qt.io/qt-6/qsavefile.html)
- [QTextCodec (Qt 6 Core5Compat)](https://doc.qt.io/qt-6/qtextcodec.html)
- [QStringDecoder](https://doc.qt.io/qt-6/qstringdecoder.html)
