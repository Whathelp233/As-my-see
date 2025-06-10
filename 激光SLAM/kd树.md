kd树的思想可以看作是，在多维下，同时对维度和值的二分算法。常用于多维键值搜索应用，kd树通过递归将数据点按照某个维度进行划分，从而构建一种属性结构。

kd树的构建原理：
1、选择一个分割维度，一般是选择方差最大的维度。
2、选择分割点，一般是中位数
3、递归构建子树，将数据集分为两个子集，直到子集中的点数量小于等于1。

搜索最邻原理
1、递归搜索：从根节点开始，根据目标点在当前分割维度上的值，递归向下，直到叶子节点。
2、回溯检查：在叶子节点处回溯，检查是否可能有更近的点

构建kd树的代码如下
```
#include<iostream>
#include<vector>
#include<cmath>
#include<limits>
#include<algorithm>
//这里是kd树上的节点的定义
using namespace std;

struct Point{
	vector<double> coordinates;
	int id;

	Point(const vector<double>& coords,int id) : coordinates(coords),id(id) {}//这里的作用是定义两个结构体Point的函数
};

struct Node {
	Point* point;//当前点（？）
	Node* left;//右子集
	Node* right;//左子集
	int splitDim;//分割维度

	Node(Point *p,int dim): point(p),left(nullptr),right(nullptr),splitDim(dim){}
};

//接下来是kd树类的定义
#include <iostream>
#include <vector>
#include <cmath>
#include <limits>
#include <memory>

using namespace std;

struct Point {
    double x, y, z;
    int id;

    Point(double x_, double y_, double z_, int id_) : x(x_), y(y_), z(z_), id(id_) {}
};

struct Node {
    shared_ptr<Point> point;
    shared_ptr<Node> left;
    shared_ptr<Node> right;
    int splitDim;

    Node(shared_ptr<Point> p, int dim) : point(p), left(nullptr), right(nullptr), splitDim(dim) {}
};

class KDTree {
private:
    shared_ptr<Node> root;

    shared_ptr<Node> buildTree(vector<shared_ptr<Point>>& points, int depth) {
        if (points.empty()) {
            return nullptr;
        }

        int k = 3; // 三维空间
        int splitDim = depth % k; // 当前分割维度

        // 按当前分割维度排序
        sort(points.begin(), points.end(), [splitDim](const shared_ptr<Point>& a, const shared_ptr<Point>& b) {
            if (splitDim == 0) return a->x < b->x;
            else if (splitDim == 1) return a->y < b->y;
            else return a->z < b->z;
        });

        // 找到中位数
        int median = points.size() / 2;
        shared_ptr<Node> node = make_shared<Node>(points[median], splitDim);

        // 递归构建左右子树
        vector<shared_ptr<Point>> leftPoints(points.begin(), points.begin() + median);
        vector<shared_ptr<Point>> rightPoints(points.begin() + median + 1, points.end());
        node->left = buildTree(leftPoints, depth + 1);
        node->right = buildTree(rightPoints, depth + 1);

        return node;
    }

    double euclideanDistance(const shared_ptr<Point>& a, const shared_ptr<Point>& b) {
        double dx = a->x - b->x;
        double dy = a->y - b->y;
        double dz = a->z - b->z;
        return sqrt(dx * dx + dy * dy + dz * dz);
    }

    void nearestNeighbor(shared_ptr<Node> node, const shared_ptr<Point>& target, shared_ptr<Node>& best, double& minDist, int depth) {
        if (!node) return;

        // 计算当前节点与目标点的距离
        double currentDist = euclideanDistance(node->point, target);
        if (currentDist < minDist) {
            minDist = currentDist;
            best = node;
        }

        // 确定下一个要访问的子树
        int splitDim = node->splitDim;
        shared_ptr<Node> nextNode;
        if (target->x < node->point->x && splitDim == 0) {
            nextNode = node->left;
        } else if (target->y < node->point->y && splitDim == 1) {
            nextNode = node->left;
        } else if (target->z < node->point->z && splitDim == 2) {
            nextNode = node->left;
        } else {
            nextNode = node->right;
        }

        // 搜索功能测试索要回测的子树
        nearestNeighbor(nextNode, target, best, minDist, depth + 1);

        // 检查另一个子树是否可能包含更近的点
        if (minDist > abs(target->x - node->point->x) && splitDim == 0) {
            nearestNeighbor(node->right, target, best, minDist, depth + 1);
        } else if (minDist > abs(target->y - node->point->y) && splitDim == 1) {
            nearestNeighbor(node->left, target, best, minDist, depth + 1);
        } else if (minDist > abs(target->z - node->point->z) && splitDim == 2) {
            nearestNeighbor(node->left, target, best, minDist, depth + 1);
        }
    }

public:
    KDTree(vector<shared_ptr<Point>>& points) {
        root = buildTree(points, 0);
    }

    ~KDTree() {}

    shared_ptr<Point> findNearestNeighbor(const shared_ptr<Point>& target) {
        shared_ptr<Node> best;
        double minDist = numeric_limits<double>::max();
        nearestNeighbor(root, target, best, minDist, 0);
        return best ? best->point : nullptr;
    }
};

int main() {
    vector<shared_ptr<Point>> points = {
        make_shared<Point>(2, 3, 5, 0),
        make_shared<Point>(5, 4, 1, 1),
        make_shared<Point>(9, 6, 2, 2),
        make_shared<Point>(4, 7, 3, 3),
        make_shared<Point>(8, 1, 4, 4),
        make_shared<Point>(7, 2, 6, 5)
    };

    KDTree kdTree(points);

    auto target = make_shared<Point>(6, 5, 0, -1);
    auto nearest = kdTree.findNearestNeighbor(target);

    if (nearest) {
        cout << "最近邻点是: (" << nearest->x << ", " << nearest->y << ", " << nearest->z << "), ID: " << nearest->id << endl;
    } else {
        cout << "未找到最近邻点" << endl;
    }

    return 0;
}
	

}
```

