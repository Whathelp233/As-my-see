# Linux软链接、硬链接
> 更新时间: 2026年02月27日

# 1. 关系图

<img src="https://xzchsia.github.io/img/in-post/linux-hard-soft-link/linux-soft-hard-link-diff.png" alt="Linux硬链接和软连接的区别" style="zoom: 67%;" />

1. linux使用ext4文件系统，他把磁盘分成两块：小部分为inode、大部分为block
2. inode存储文件的属性（包括文件的权限（r、w、x）、文件的所有者和属组、文件的大小、文件的状态改变时间（ctime）、文件的最近一次读取时间（atime）、文件的最近一次修改时间（mtime）、文件的数据真正保存的 block 编号）
3. 文件的数据真正保存在block中
4. 硬链接与源文件指向同一个inode
5. 软链接指向源文件，可理解成源文件的快捷方式，而源文件指向inode

# 2. 创建

1. 硬链接

```bash
ln file1 file2	#创建file1的硬链接file2
```

2. 软链接

```bash
ln -s file1 file2	#创建file1的软链接file2
```

---

## 📝 文档信息

- **创建时间**: [请补充]
- **最后更新**: 2026-02-27
- **文档类型**: linux
- **优化状态**: ✅ 已标准化

## 🔍 内容概述

> 本文档已由OpenClaw文档优化系统处理，结构已标准化。

## 💡 使用建议

1. 定期回顾和更新内容
2. 补充实际案例和代码
3. 添加相关资源链接

