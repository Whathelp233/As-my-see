# Cmake install
> 更新时间: 2026年02月27日

- > purpose: **distribute a ROS package without sharing the sources**

它的目的是将运行应用程序所需的所有文件分离到一个目录结构中，该目录结构包含运行应用程序所需的所有内容。例如，如果你打算给某人一份你的应用程序的副本，但你不希望他单纯地进行拷贝——因为那里有大量的文件.

install的工作也可以靠手动的复制粘贴来实现，但install命令的使用将会使Cmake的命令更加井然有序并具有结构性。



# In your package CMakelists.txt, add the install directives.

> ``` c 
> > install( TARGETS
> >  #list of nodes
> >  DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
> > )
> >
> > install(TARGETS
> >  #list of shared libraries
> >  ARCHIVE DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
> >  LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
> > )
> >
> > install(FILES 
> > #list of necessary files (xml...)
> > DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}
> > )
> >
> > install(DIRECTORY 
> > include/${PROJECT_NAME}/
> > DESTINATION ${CATKIN_PACKAGE_INCLUDE_DESTINATION}
> > PATTERN ".svn" EXCLUDE
> > PATTERN ".git" EXCLUDE
> > )
> ```

​    then，using

> ``` c
> $ catkin_make 
> $ catkin_make install
> ```



 这将在您的catkin工作区中创建除通常的/devel和/build之外的另一个文件夹/install 
