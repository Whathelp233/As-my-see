# Cmake 结构
> 更新时间: 2026年02月27日



# Cmakelist文件的必要结构

``` cmake
project(XXX)                                                             #项目名称
 add_subdirectory(子目录名)                                               #父目录必需
 	#进行操作 1.子文件夹编译并链接库（link_directories) 
 	#        2.该语句前的set（）变量可在子目录使用
 add_library(库名 选项 文件)                                               #子目录必需，生成库文件
 
 include_directories(路径)                                               #必需  包含头文件
 link_directories(路径)                                                  #包含库文件（.so .a) 
 																		#可用find_package()  find_library()取代
 
 target_link_libraries(库名/可执行文件名 链接的库名)
```





******

# find_package()命令

用于查找依赖包，有Module模式(基本用法，basic signature)和Config模式(full signature，完全用法），其中Module模式是基础，Config模式更复杂。

![img](https://upload-images.jianshu.io/upload_images/2062739-dcee23e62c67828d.png?imageMogr2/auto-orient/strip|imageView2/2/w/604/format/webp)

​                                                                                                                            $$模式检查流程$$

# module模式下用法

``` cmake
find_package(<PackageName>      #包名
			[version]           #可选，用于指定版本，如果指定就必须检查找到的包的版本是否和version兼容
			[EXACT]             #可选，与version区别在于版本必须一致
			[QUIET]             #可选，表示如果查找失败，不会在屏幕进行输出
			[MODULE]            #可选，要求Module模式下查找失败并不回落到Config模式查找
			
			REQUIRED            #可选，要求必须要找到包，找不到则停止cmake
			OPTIONAL_COMPONENTS #可选，要求找到包，但找不到也不会停止执行
			COMPONENTS          #可选，表示查找的包中必须要找到的组件，找不到则停止cmake
			components          #可选，要求找到组件，但找不到也不hi停止执行					
			)
```

**module模式的查找顺序**

目标在于找到PackageName.cmake文件

先在`CMAKE_MODULE_PATH`变量对应的路径中查找。如果路径为空，或者路径中查找失败，则在cmake module directory（cmake安装时的Modules目录，比如`/usr/local/share/cmake/Modules`）查找。



# config模式

......





*****

# catkin_package()命令

告诉 catkin 需要将你程序包的哪些依赖项传递给使用 `find_package(...)` 查找你的程序包的程序包。



**与find_package()**

> find_package  是针对当前包的，寻找当前包需要依赖的库；catkin_package()是针对依赖当前包的包，声明一些库，这些库是当前包依赖的库，也是依赖当前包的包所依赖的库。这样，在catkin依赖当前包的包时，就不用显示的find_package()这些库了。



``` cmake
catkin_package(
			INCLUDE_DIRS     #声明给其它package的include路径
            LIBRARIES        #声明给其它package的库
            
            CATKIN_DEPENDS   #本包依赖的catkin package  与DEPENDS类似
            DEPENDS          #本包依赖的非catkin package    
                                #DEPENS包含了库，当其他功能包调用这个功能包也需要该库的时候，就可以不需要find_package()
                                
            CFG_EXTRAS       #其它配置参数
               )
               
#例               
  catkin_package(      
   INCLUDE_DIRS include ${OPENGL_INCLUDE_DIR}
   LIBRARIES foo ${OPENGL_LIBRARIES}
   CATKIN_DEPENDS roscpp
   DEPENDS Boost
  )
```



****

# file()命令

>  文件操作命令

# READ命令

将文件内容储存在变量filename中

``` cmake
file(read <filename>         #必选项 为要读取的文件，可以带绝对路径
          <variable>         #必选项，将文件内容读取到varible变量中。
          [OFFSET <offset>]  #可选项，从文件中偏移位置offset 开始读取文件内容
          [LIMIT <max-in>]   #可选项，可以将读取文件内容转换成十六进制。
          [HEX]
     )
```


 #### STRINGS命令

将文件的内容读取成一串ASCII字符串到变量中，其中二进制文件将会被忽略，在读取文件中回车及\r将会被忽略

``` cmake
file(STRINGS <filename> 
             <variable> 
             [<options> ...]
    )
```

> > options支持的可选项有以下：
> >
> >     LENGTH_MAXMUN <max-len>: 最多从文件<filename>中读取<max-len>长度字符串到变量<variable>中
> >     LENGTH_MINIMUN <min-len>:至少要从文件<filename>读取<min_len>长度的字符串到变量<variable>中
> >     LIMIT_COUNT <max-num>: 限制要去读的字符串数量
> >     LIMIT_OUTPUT <max-out>:限制读取到<variable>变量总长度单位字节
> >     NEWLINE_CONSUME: 读取文件时不忽略换行符(\n,LF），将其视为字符串的内容
> >     NO_HEX_CONVERSION:  如果不给出此选项英特尔十六进制和摩托罗拉s记录文件在读取时自动转换为二进制文件。
> >     REGX <regex>: 使用正则匹配，只将匹配的结果保存到变量中
> >     ENCODING <encoding-type>: 指定字符串的编码格式，目前支持UTF-8, UTF-16LE, UTF-16BE, UTF-32LE, UTF-32BE。如果没有指定，按照文件中字节顺序标记。

# HASH命令

将文件的字符串内容经过加密读取到变量中

``` cmake
file(<HASH> <filename> <variable>)
```

> > 支持的HASH 加密算法 有如下：
> >
> >     MD5、SHA!、SHA224、SHA256、SHA384、SHA512、SHA3_224、SHA3_256、SHA3_384、SHA3_512等

# TIMESTAMP

读取文件最后修改的时间戳

``` cmake
file(TIMESTAMP <filename> <variable> 
              [<format>]            #可选项，选择支持的时间格式             
              [UTC]                 #可选项 采用的世界时间，而不是当地时间         
    )
```

# WRITE命令

把<content>内容写入到文件<filename>中，如果文件不存在，则创建该文件将<content>写入到文件中。如果该文件存在则将该文件内容清空并将<content>写入到文件中。

``` cmake
file(WRITE <filename> <content> ... )
```

# APPEND命令

file APPEND用于向文件中追加内容，如果文件不存在，会创建该文件，如果该文件存在不会覆盖文件中的旧内容，将内容<content>追加到文件末尾.

```cmake
file(APPEND  <filename> <content> ... )
```

# TOUCH命令

file TOUCH命令用于创建一个空文件,命令行格式如下：

```cmake
file(TOUCH [<files> ...])
```

```cmake
file(TOUCH_NOCREATE [<files> ...])                   #当文件不存在时，不创建新的文件。
```

# GENERATE命令

用于每次构建时将一些所需要过程信息或者调试变量等信息输出到文件中，与其他命令区是支持cmake generator生成器，而且保证是本次构建生成的内容.

```cmake
file（GENERATE OUTPUT output-file <INPUT input-file|CONTENT content> [CONDITION expression])                                         #更多请见文献参考
```
# GLOB命令

主要用于匹配规则在指定的目录内匹配到所需要的文件

```cmake
file(GLOB <variable> [LIST_DIRECTORIES true[false] 
                     [RELAVTIVE <path> ] 
                     [CONFIGURE_DEPENDS] 
                     [<globbing-expression> ...])
```
> >  LIST_DIRECTORIES true[false]: 如果为false，目录将会被省略，默认情况下返回是带目录
> > RELAVTIVE <path>: 相对路径<path> 返回的结果将不是绝对路径，而是将绝对路径中的<path>部分去掉，返回相对路径
> > CONFIGURE_DEPENDS:如果该标记位设置，在主构建系统检查目标添加逻辑，必便在构建时重新运行标记的GLOB命令
> > <globbing-expression>：匹配表达式 例如"src/*.cpp" "src/decision/*.cpp"

GLOB_RECURSE命令不仅可以遍历当前路径，还可以遍历路径下面的所有子目录

```cmake
file(GLOB_RECURSE <variable> [LIST_DIRECTORIES true[false] [RELAVTIVE <path> ] [CONFIGURE_DEPENDS] [<globbing-expression> ...])
```
# RENAME命令

RENAME命令将文件重新命名：

```cmake
file(RENAME <oldname> <newname>)
```

RENAME_RECURSE 命令不仅可以删除文件还可以删除目录，当目录里面没有包含该文件也会被删除：

```cmake
file(RENAME_RECURES [<files> ...])
```

# MAKE_DIRECTORY命令

 MAKE_DIRECTORY创建目录命令：

```cmake
file(MAKE_DIRECTORY [<directories> ...])
```

 #### COPY命令

file COPY命令用于将文件copy到目标目录中，命令行格式如下：

```cmake
file(COPY <files> ...                                 #要拷贝的源文件
         DESTINATION <dir>                            #要将源文件拷贝到目的目录<dir>中
         [FILE_PERMISSIONS <permissions> ...]         #修改源文件权限
         [DIRECTORY_PERMISSIONS <permissions> ... ]   #目录权限
         [NO_SOURCE_PERMISSIONS]                      #不使用源文件权限，对文件权限重新指定
         [USE_SOURCE_PERMISSIONS]                     #使用源文件权限，当该选项设置时，不能再使用FILE_PERMISSIONS权限
         [FILES_MATCHING]
         [ [PATTERN <pattern> | REGEX <regex>]        #制定一些匹配规则
         [EXCLUDE] [PERMISSIONS <permissions> ... ] ] #不包括或排除调一些特殊文件
         [...]
      )

```
。。。。。



****







# 其他命令及扩展

``` cmake
#要求cmake的最低版本号
cmake_minimum_required(VERSION 3.0.2)

#创建可执行文件
add_executable (main main.cpp)         # 通过main.cpp指定生成的可执行文件main
target_link_libraries (main sum minor) # 执行可执行文件main需要依赖的库（sum minor）

#设置变量
set(变量名 内容)                         #除了设置自己的变量，还可以通过设置系统变量来配置运行方式，如：set(CMAKE_BUILD_TYPE "Debug")

#查找在某个路径下的所有源文件
aux_source_directory(. SRC_LIST)       #搜集所有在指定路径 ./ 下的源文件的文件名，将输出结果列表储存在指定的变量SRC_LIST中 
                                       #通过set( SRC_LIST ./main.cpp ./test.cpp)也可完成类似操作

#将指定目录（dir2..）添加到编译器的头文件搜索路径之下，指定的目录被解释成当前源码路径的相对路径。
include_directories ([AFTER|BEFORE] [SYSTEM] dir1 [dir2 ...])
                                       #命令set(CMAKE_INCLUDE_DIRECTORIES_BEFORE ON) 改变默认行为(添加到列表后面)，默认添加到列表前面
                                       #例include_directories(BEFORE sub3) 临时改变行为，添加到列表最前面

#设置依赖关系
add_dependencies(<target> [<target-dependency>]...)
                   #两个targets有依赖关系（通过target_link_libraries解决）并且依赖库也是通过编译源码产生的。此时add_dependencies可以在直接编译上层target时，自动检查下层依赖库是否已经生成。没有的话先编译下层依赖库，然后再编译上层target，最后link depend target。
                   

```









# Cmake常用预定义变量

> Make常用的预定义变量：
> PROJECT_NAME : 通过 project() 指定项目名称
> PROJECT_SOURCE_DIR : 工程的根目录
> PROJECT_BINARY_DIR : 执行 cmake 命令的目录
> CMAKE_CURRENT_SOURCE_DIR : 当前 CMakeList.txt 文件所在的目录
> CMAKE_CURRENT_BINARY_DIR : 编译目录,可使用 add subdirectory 来修改
> EXECUTABLE_OUTPUT_PATH : 二进制可执行文件输出位置
> LIBRARY_OUTPUT_PATH : 库文件输出位置
> BUILD_SHARED_LIBS : 默认的库编译方式 ( shared 或 static ) ,默认为 static
> CMAKE_C_FLAGS : 设置 C 编译选项
> CMAKE_CXX_FLAGS : 设置 C++ 编译选项
> CMAKE_CXX_FLAGS_DEBUG : 设置编译类型 Debug 时的编译选项
> CMAKE_CXX_FLAGS_RELEASE : 设置编译类型 Release 时的编译选项
> CMAKE_GENERATOR : 编译器名称
> CMAKE_COMMAND : CMake 可执行文件本身的全路径
> CMAKE_BUILD_TYPE : 工程编译生成的版本, Debug / Release
