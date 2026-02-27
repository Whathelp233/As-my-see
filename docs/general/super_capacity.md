# super capacity
> 更新时间: 2026年02月27日

*读取超电数据流程**

- Referee::read()中调用super_capacitor_.read(rx_buffer_)
  - 遍历rx_buffer中每个字节，并调用dtpReceivedCallBack(k_i)
    - 调用SuperCapacitor::receiveCallBack



**some knowledge**

- [serial类](http://docs.ros.org/en/indigo/api/serial/html/classserial_1_1Serial.html)
  - avaliable()：返回buffer中的字节数
  - read()：从串口读取指定数量的字节到指定的缓冲区，返回的读取到的字节数

## 内容优化建议

> 此文档内容较为简略，建议补充以下内容：

1. **代码示例**: 添加实际可运行的代码
2. **应用场景**: 说明在实际项目中的用途
3. **最佳实践**: 分享经验教训和技巧
4. **扩展阅读**: 链接到相关学习资源

*最后检查: 2026-02-27 14:17:13*
