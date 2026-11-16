# 点云结构搜索与 kd 树

点云邻域操作通常要反复回答“离查询点最近的样本是哪一个”或“半径范围内有哪些样本”。逐点线性扫描每次要计算 $N$ 个距离；
kd 树通过轴对齐空间划分跳过不可能更近的区域，适合低维坐标的精确近邻查询。

## 建树与查询

每个内部节点选一个坐标轴和切分值。常见做法是轮换轴，按该轴坐标取中位数作为节点；中位数左侧放入左子树，右侧放入右子树。
递归后树高约为 $O(\log N)$。若各向异性明显，也可按当前子集的最大方差轴切分，但须保证切分后仍有合理平衡。

查询时先沿查询点所在的一侧递归，并计算当前节点距离。设当前节点切分坐标为 $c$、查询坐标为 $q_a$、已知最近距离为 $d_{best}$，
到切分超平面的距离是 $|q_a-c|$。如果：

$$
|q_a-c|\le d_{best},
$$

球形最近邻区域仍可能跨过切分平面，因此另一侧不能被排除，必须回溯搜索。实现可以全程比较平方距离，避免开平方：

$$
(q_a-c)^2\le d_{best}^2.
$$

边界相等时也应检查另一侧；若任务只返回一个最近邻，跳过等距候选可能仍给出最小距离，但会影响稳定的平局规则。输入包含非有限坐标时比较和切分次序不再可靠，
建树与查询前应拒绝 NaN/Inf。

```cpp
// 核心递归片段，需与 Node/Point 结构和距离函数配合使用。
void search(const Node* node, const Point& query,
            const Node*& best, double& best_distance_sq) {
    if (node == nullptr) {
        return;
    }

    const double current = squaredDistance(node->point, query);
    if (best == nullptr || current < best_distance_sq ||
        (current == best_distance_sq &&
         node->point.id < best->point.id)) {
        best = node;
        best_distance_sq = current;
    }

    const std::size_t axis = node->split_axis;
    const double delta = query.xyz[axis] - node->point.xyz[axis];
    const Node* near_side = delta < 0.0 ? node->left.get()
                                        : node->right.get();
    const Node* far_side = delta < 0.0 ? node->right.get()
                                       : node->left.get();

    search(near_side, query, best, best_distance_sq);
    if (delta * delta <= best_distance_sq) {
        search(far_side, query, best, best_distance_sq);
    }
}
```

## 为什么必须按当前分割维度回溯

分割维度每层变化。若节点按 $y$ 切分且查询点落在左侧，先走左子树，回溯时应检查右子树；若按 $z$ 切分，规则完全相同。
另一侧由“本次实际走过的 near child”决定，不能根据写死的 `x/y/z` 分支分别选择固定方向。

错误的回溯会漏掉最近邻：查询点距切分平面很近，但真最近点可能在另一侧，甚至在不同坐标轴分支下。正确条件是比较当前最佳欧氏距离与到切分平面的距离，
而不是只看查询点位于切分面的哪一边。

## 复杂度和适用边界

- 使用中位数递归切分时，树高约 $O(\log N)$。若每层完整排序，建树通常约为 $O(N\log^2N)$；
  用 `nth_element` 一类选择算法，期望可降到 $O(N\log N)$。
- 低维且点分布较均匀时，近邻查询平均接近 $O(\log N)$；极端退化或高维情况下，回溯可能扩展到 $O(N)$。
- 点云三维坐标是 kd 树的常见输入；距离度量、坐标尺度和过滤条件仍需由应用决定。若各轴单位或尺度不同，普通欧氏距离不再代表所需的物理邻近。
- kd 树做的是邻域搜索，不执行点云配准。ICP/GICP/NDT 的目标函数、
  对应关系筛选和优化归[SLAM与定位](../SLAM与定位/扫描匹配与点云配准.md)。
- 对连续变化的点云反复查询时，树构建成本可能高于单次搜索节省；应测量建树、查询总耗时和数据更新频率。

完整、自检的 [C++17 实现](assets/test_kd_tree.cpp)使用中位数切分、平方距离和切分平面回溯。
程序以固定随机种子生成多组小点云，将每个查询与逐点穷举比较，并覆盖空树、重复坐标、三轴远侧回溯和查询点恰落在树中等边界样例。

## 参考资料

- [PCL：kd 树最近邻和半径搜索教程](https://pointclouds.org/documentation/tutorials/kdtree_search.html)，说明三维点云 k 近邻和半径搜索接口。
- [PCL：表面法向估计教程](https://pointclouds.org/documentation/tutorials/normal_estimation.html)，展示 kd 树为邻域协方差估计提供 k/半径搜索，并讨论邻域尺度。
