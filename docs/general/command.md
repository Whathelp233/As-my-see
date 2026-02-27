# command
> 更新时间: 2026年02月27日

rosdep check --from-path src --ignore-src -r -y
rosdep install --from-path src --ignore-src -r -y
这两个命令主要是对整个工作空间下所有package 进行检查依赖和建立依赖，更方便一些。
