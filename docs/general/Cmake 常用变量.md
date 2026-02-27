# Cmake 常用变量
> 更新时间: 2026年02月27日

CMake常用的预定义变量：
PROJECT_NAME : 通过 project() 指定项目名称
PROJECT_SOURCE_DIR : 工程的根目录
PROJECT_BINARY_DIR : 执行 cmake 命令的目录
CMAKE_CURRENT_SOURCE_DIR : 当前 CMakeList.txt 文件所在的目录
CMAKE_CURRENT_BINARY_DIR : 编译目录,可使用 add subdirectory 来修改
EXECUTABLE_OUTPUT_PATH : 二进制可执行文件输出位置
LIBRARY_OUTPUT_PATH : 库文件输出位置
BUILD_SHARED_LIBS : 默认的库编译方式 ( shared 或 static ) ,默认为 static
CMAKE_C_FLAGS : 设置 C 编译选项
CMAKE_CXX_FLAGS : 设置 C++ 编译选项
CMAKE_CXX_FLAGS_DEBUG : 设置编译类型 Debug 时的编译选项
CMAKE_CXX_FLAGS_RELEASE : 设置编译类型 Release 时的编译选项
CMAKE_GENERATOR : 编译器名称
CMAKE_COMMAND : CMake 可执行文件本身的全路径
CMAKE_BUILD_TYPE : 工程编译生成的版本, Debug / Release







CMAKE_BUILD_TYPE:包含Debug, Release, RelWithDebInfo,MinSizeRel

``` c
set(CMAKE_BUILD_TYPE "Debug")                                                        //usage
```

默认值是一个空字符串，但这通常不可取

> Debug:调试版本，包含断言机制，用于代码调试时较为精准地查找非法区域
>
> Release：量产版本，代码经过了调试，省略断言等检查步骤，更高速地完成编译等操作
>
> RelWithDebInfo：realese基础上的一个特殊版本，用于代码bug的跟踪，它包含了调试信息，需要更长的时间下载
