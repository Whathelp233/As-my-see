# gazebo中运行相机
> 更新时间: 2026年02月27日

# 1. 编写URDF

1. 编写相机的link
2. 添加插件

```markup
<robot>
  ... robot description ...
  <link name="camera_link">
    ... link description ...
  </link>

  <gazebo reference="camera_link">
    <sensor type="camera" name="camera">
      ... sensor parameters ...
      <plugin name="camera_controller" filename="libgazebo_ros_camera.so">
        ... plugin parameters ..
      </plugin>
    </sensor>
  </gazebo>

</robot>
```

## 内容优化建议

> 此文档内容较为简略，建议补充以下内容：

1. **代码示例**: 添加实际可运行的代码
2. **应用场景**: 说明在实际项目中的用途
3. **最佳实践**: 分享经验教训和技巧
4. **扩展阅读**: 链接到相关学习资源

*最后检查: 2026-02-27 14:17:13*
