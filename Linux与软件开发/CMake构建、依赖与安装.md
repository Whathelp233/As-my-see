# CMake 构建、依赖与安装

CMake 描述目标及其关系，再由生成器把描述转换成 Ninja、Make 或 IDE 工程。它把配置、生成、编译、链接和安装分成不同阶段；每阶段失败的原因不同，排查时应先定位阶段。

## 从源代码到可运行程序

- **配置**：读取 `CMakeLists.txt`，检查编译器、选项和依赖，创建构建目录中的缓存和目标图。
- **生成**：选择生成器并产生底层构建文件。
- **编译**：把源文件翻译成对象文件；常见问题是 include 路径、宏、编译器选项或语言标准。
- **链接**：把对象文件与库组合成可执行文件或库；常见问题是缺少定义、库顺序、ABI 或目标架构不一致。
- **安装**：按安装规则把产物、头文件和导出配置放入暂存目录或前缀；安装成功不代表运行时能找到动态库。

将源树与构建树分开，便于清理生成文件并切换编译器或构建选项。不要把某个构建目录复用于不同工具链：CMake 缓存保存编译器和路径信息，改用另一工具链时应新建干净构建目录。

以下是**项目文件示例**，用于说明目标关系；不是在当前主机执行的命令：

```cmake
cmake_minimum_required(VERSION 3.16)
project(sensor_demo LANGUAGES CXX)

find_package(Threads REQUIRED)

add_library(sensor_core src/sensor.cpp)
target_compile_features(sensor_core PUBLIC cxx_std_17)
target_include_directories(sensor_core
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
)
target_link_libraries(sensor_core PRIVATE Threads::Threads)

add_executable(sensor_app src/main.cpp)
target_link_libraries(sensor_app PRIVATE sensor_core)

install(TARGETS sensor_core sensor_app
    EXPORT sensorTargets
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)
install(DIRECTORY include/ DESTINATION include)
```

`add_library` 和 `add_executable` 声明目标；后续命令围绕目标添加编译需求、头文件目录和链接依赖。目标表达比全局设置更清楚，也更容易传播给依赖方。

## 目标属性与依赖传播

`PRIVATE` 表示需求只用于当前目标；`PUBLIC` 表示当前目标和使用者都需要；`INTERFACE` 表示只提供给使用者。比如库实现文件使用某个库时，通常是 `PRIVATE`；如果公开头文件暴露该依赖的类型，消费者也需要它，才使用 `PUBLIC` 或 `INTERFACE`。不要把所有 include 路径和编译定义都设为全局属性，否则容易让无关目标意外依赖它们。

使用 `target_include_directories`、`target_compile_definitions`、`target_compile_options`、`target_link_libraries` 等目标级命令表达要求。库目标可以传递 include 目录、宏、编译特性和其他依赖；这组信息称为 usage requirements。链接库目标通常优于手动拼接库文件名和搜索目录，因为 CMake 能跟踪目标产物和依赖关系。

## 查找外部包

`find_package(Pkg REQUIRED)` 可采用两类发现方式：Config 模式读取包自身导出的配置文件，通常提供 `Pkg::Target` 这样的导入目标；Module 模式查找 `FindPkg.cmake`，其行为由查找模块实现。配置模式更适合由依赖包提供精确的目标及属性；模块模式则可能需要项目或 CMake 提供适配逻辑。包名、目标名和支持的组件由具体依赖决定，不能只根据目录里存在某个头文件就假设配置完成。

优先链接依赖包提供的导入目标，而不是自行硬编码 `/usr/lib/...`。目标可以携带头文件目录、编译定义、链接库和配置差异。交叉编译时，主机工具与目标设备库属于不同环境，必须检查 toolchain 文件、包搜索根目录和目标架构，避免误找到宿主机依赖。

## 安装与下游使用

安装规则定义二进制、库、头文件和资源的目的地。`install(TARGETS ...)` 能按目标类型指定目的地；库若要供其他 CMake 项目使用，还需要安装导出文件和包配置，公开头文件目录也应使用区分构建树与安装树的生成器表达式。示例中 `EXPORT` 只是关联导出集；真正生成并安装可供 `find_package` 读取的包，还需配套 `install(EXPORT ...)` 和包配置文件。

使用 `DESTDIR` 或独立暂存前缀可以先检查安装清单，确认文件不会散落到系统路径。运行时动态库搜索由平台加载器规则决定，与 CMake 配置期找到库不是一回事；部署时还要说明动态依赖、插件路径和环境要求。

## 按失败阶段排查

1. **配置失败**：检查首个 `CMake Error`、编译器识别、包名、版本、组件、搜索路径与缓存值。需要验证时在干净构建目录重新配置，不要先删除源文件或全局安装包。
2. **编译失败**：从报错文件和编译命令检查头文件路径、C++ 标准、宏定义、生成头文件和目标平台。`compile_commands.json` 可用于查看每个翻译单元的实际编译参数（是否生成取决于生成器支持）。
3. **链接失败**：区分 undefined reference、找不到库与架构不匹配；检查实现是否编入目标、依赖是否链接到正确目标，以及 Debug/Release、静态/动态库和 ABI 是否一致。
4. **运行失败**：核对可执行文件架构、动态加载器、运行环境变量、工作目录、配置文件和权限；构建阶段通过不代表部署环境一致。
5. **安装后下游失败**：查看安装树中的头文件、导出配置和库路径，确认公开接口没有暴露仅在构建树中存在的路径。

构建日志应保留 CMake 版本、生成器、编译器版本、配置选项、依赖版本和失败阶段。可复现构建还需要固定依赖来源与版本；仅记录“本机能编译”不足以描述构建条件。

## 参考资料

- [CMake Buildsystem](https://cmake.org/cmake/help/latest/manual/cmake-buildsystem.7.html)：目标、构建需求与 usage requirements。
- [find_package](https://cmake.org/cmake/help/latest/command/find_package.html)：Config 与 Module 包查找。
- [target_link_libraries](https://cmake.org/cmake/help/latest/command/target_link_libraries.html)：目标链接及 `PRIVATE`、`PUBLIC`、`INTERFACE` 传播。
- [CMake install](https://cmake.org/cmake/help/latest/command/install.html)：安装规则与导出目标。
