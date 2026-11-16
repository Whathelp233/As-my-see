#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <iostream>
#include <limits>
#include <memory>
#include <optional>
#include <random>
#include <stdexcept>
#include <utility>
#include <vector>

struct Point {
    std::array<double, 3> xyz{};
    int id = -1;
};

struct Node {
    Point point;
    std::size_t split_axis;
    std::unique_ptr<Node> left;
    std::unique_ptr<Node> right;

    Node(const Point& point_in, std::size_t axis_in)
        : point(point_in), split_axis(axis_in) {}
};

class KDTree {
public:
    explicit KDTree(std::vector<Point> points)
    {
        for (const Point& point : points) {
            validatePoint(point);
        }
        root_ = build(points, 0, points.size(), 0);
    }

    std::optional<Point> findNearest(const Point& query) const {
        validatePoint(query);

        const Node* best = nullptr;
        double best_distance_sq = std::numeric_limits<double>::infinity();
        search(root_.get(), query, best, best_distance_sq);
        if (best == nullptr) {
            return std::nullopt;
        }
        return best->point;
    }

private:
    static void validatePoint(const Point& point) {
        for (const double coordinate : point.xyz) {
            if (!std::isfinite(coordinate)) {
                throw std::invalid_argument("point coordinates must be finite");
            }
        }
    }

    static bool lessOnAxis(const Point& lhs,
                           const Point& rhs,
                           std::size_t axis) {
        if (lhs.xyz[axis] != rhs.xyz[axis]) {
            return lhs.xyz[axis] < rhs.xyz[axis];
        }
        for (std::size_t offset = 1; offset < lhs.xyz.size(); ++offset) {
            const std::size_t other_axis = (axis + offset) % lhs.xyz.size();
            if (lhs.xyz[other_axis] != rhs.xyz[other_axis]) {
                return lhs.xyz[other_axis] < rhs.xyz[other_axis];
            }
        }
        return lhs.id < rhs.id;
    }

    static std::unique_ptr<Node> build(std::vector<Point>& points,
                                       std::size_t first,
                                       std::size_t last,
                                       std::size_t depth) {
        if (first >= last) {
            return nullptr;
        }

        const std::size_t axis = depth % Point{}.xyz.size();
        const std::size_t middle = first + (last - first) / 2;
        auto begin = points.begin() + static_cast<std::ptrdiff_t>(first);
        auto mid = points.begin() + static_cast<std::ptrdiff_t>(middle);
        auto end = points.begin() + static_cast<std::ptrdiff_t>(last);
        std::nth_element(begin, mid, end, [axis](const Point& lhs,
                                                const Point& rhs) {
            return lessOnAxis(lhs, rhs, axis);
        });

        auto node = std::make_unique<Node>(points[middle], axis);
        node->left = build(points, first, middle, depth + 1);
        node->right = build(points, middle + 1, last, depth + 1);
        return node;
    }

    static double squaredDistance(const Point& lhs, const Point& rhs) {
        double distance_sq = 0.0;
        for (std::size_t axis = 0; axis < lhs.xyz.size(); ++axis) {
            const double delta = lhs.xyz[axis] - rhs.xyz[axis];
            distance_sq += delta * delta;
        }
        return distance_sq;
    }

    static void search(const Node* node,
                       const Point& query,
                       const Node*& best,
                       double& best_distance_sq) {
        if (node == nullptr) {
            return;
        }

        const double current_distance_sq = squaredDistance(node->point, query);
        if (best == nullptr || current_distance_sq < best_distance_sq ||
            (current_distance_sq == best_distance_sq &&
             node->point.id < best->point.id)) {
            best = node;
            best_distance_sq = current_distance_sq;
        }

        const double delta =
            query.xyz[node->split_axis] - node->point.xyz[node->split_axis];
        const Node* near_side = delta < 0.0 ? node->left.get()
                                            : node->right.get();
        const Node* far_side = delta < 0.0 ? node->right.get()
                                           : node->left.get();

        search(near_side, query, best, best_distance_sq);
        if (delta * delta <= best_distance_sq) {
            search(far_side, query, best, best_distance_sq);
        }
    }

    std::unique_ptr<Node> root_;
};

static double bruteForceDistanceSq(const std::vector<Point>& points,
                                   const Point& query) {
    double best_distance_sq = std::numeric_limits<double>::infinity();
    for (const Point& point : points) {
        const double distance_sq = [&]() {
            double sum = 0.0;
            for (std::size_t axis = 0; axis < point.xyz.size(); ++axis) {
                const double delta = point.xyz[axis] - query.xyz[axis];
                sum += delta * delta;
            }
            return sum;
        }();
        best_distance_sq = std::min(best_distance_sq, distance_sq);
    }
    return best_distance_sq;
}

static bool matchesBruteForce(const std::vector<Point>& points,
                              const Point& query) {
    const KDTree tree(points);
    const std::optional<Point> nearest = tree.findNearest(query);
    if (points.empty()) {
        return !nearest.has_value();
    }
    if (!nearest.has_value()) {
        return false;
    }

    const double actual_distance_sq = bruteForceDistanceSq(
        std::vector<Point>{*nearest}, query);
    const double expected_distance_sq = bruteForceDistanceSq(points, query);
    return std::abs(actual_distance_sq - expected_distance_sq) <= 1e-12;
}

static std::vector<Point> appendOuterXGroups(std::vector<Point> points) {
    points.push_back(Point{{0.0, 0.0, 100.0}, 7});
    for (int index = 0; index < 7; ++index) {
        points.push_back(Point{{10.0 + static_cast<double>(index),
                                20.0 + static_cast<double>(index), 100.0},
                               8 + index});
    }
    return points;
}

int main() {
    const std::vector<Point> empty_points;
    if (KDTree(empty_points).findNearest(Point{{0.0, 0.0, 0.0}, -1})) {
        std::cerr << "FAIL: empty tree returned a point\n";
        return 1;
    }

    const std::vector<Point> duplicate_points = {
        Point{{1.0, 2.0, 3.0}, 0},
        Point{{1.0, 2.0, 3.0}, 1},
        Point{{1.0, 2.0, 4.0}, 2},
    };
    if (!matchesBruteForce(duplicate_points,
                           Point{{1.0, 2.0, 3.0}, -1})) {
        std::cerr << "FAIL: duplicate-point boundary case\n";
        return 1;
    }

    const std::vector<Point> axis_x_points = {
        Point{{-0.01, 0.0, 0.0}, 0},
        Point{{0.0, 0.0, 100.0}, 1},
        Point{{0.02, 100.0, 100.0}, 2},
    };
    if (!matchesBruteForce(axis_x_points,
                           Point{{0.001, 0.0, 0.0}, -1})) {
        std::cerr << "FAIL: axis-x far-side case\n";
        return 1;
    }

    std::vector<Point> axis_y_points = {
        Point{{-70.0, -10.0, 100.0}, 0},
        Point{{-60.0, -4.0, 100.0}, 1},
        Point{{-50.0, -3.0, 100.0}, 2},
        Point{{-40.0, 0.0, 100.0}, 3},
        Point{{-30.0, 0.01, 0.01}, 4},
        Point{{-20.0, 0.1, 100.0}, 5},
        Point{{-10.0, 0.2, 100.0}, 6},
    };
    axis_y_points = appendOuterXGroups(std::move(axis_y_points));
    if (!matchesBruteForce(axis_y_points,
                           Point{{-30.001, -0.001, 0.0}, -1})) {
        std::cerr << "FAIL: axis-y far-side case\n";
        return 1;
    }

    std::vector<Point> axis_z_points = {
        Point{{-70.0, -0.3, -100.0}, 0},
        Point{{-60.0, -0.2, 0.0}, 1},
        Point{{-50.0, -0.1, 0.01}, 2},
        Point{{-40.0, 0.0, 100.0}, 3},
        Point{{-30.0, 0.1, 100.0}, 4},
        Point{{-20.0, 0.2, 100.0}, 5},
        Point{{-10.0, 0.3, 100.0}, 6},
    };
    axis_z_points = appendOuterXGroups(std::move(axis_z_points));
    if (!matchesBruteForce(axis_z_points,
                           Point{{-50.001, -0.1, -0.001}, -1})) {
        std::cerr << "FAIL: axis-z far-side case\n";
        return 1;
    }

    std::mt19937 generator(20261116);
    std::uniform_int_distribution<int> size_distribution(1, 90);
    std::uniform_real_distribution<double> coordinate_distribution(-4.0, 4.0);

    constexpr int dataset_count = 300;
    constexpr int queries_per_dataset = 60;
    for (int dataset_index = 0; dataset_index < dataset_count;
         ++dataset_index) {
        const int point_count = size_distribution(generator);
        std::vector<Point> points;
        points.reserve(static_cast<std::size_t>(point_count));
        for (int id = 0; id < point_count; ++id) {
            points.push_back(Point{
                {coordinate_distribution(generator),
                 coordinate_distribution(generator),
                 coordinate_distribution(generator)},
                id});
        }

        if (point_count > 1 && dataset_index % 5 == 0) {
            points[1].xyz = points[0].xyz;
        }

        const KDTree tree(points);
        for (int query_index = 0; query_index < queries_per_dataset;
             ++query_index) {
            Point query{{coordinate_distribution(generator),
                         coordinate_distribution(generator),
                         coordinate_distribution(generator)},
                        -1};
            if (query_index % 7 == 0) {
                const std::size_t point_index =
                    static_cast<std::size_t>(query_index) % points.size();
                query.xyz = points[point_index].xyz;
            }

            const std::optional<Point> nearest = tree.findNearest(query);
            if (!nearest.has_value()) {
                std::cerr << "FAIL: nonempty tree returned no point\n";
                return 1;
            }
            const double actual_distance_sq = bruteForceDistanceSq(
                std::vector<Point>{*nearest}, query);
            const double expected_distance_sq = bruteForceDistanceSq(
                points, query);
            if (std::abs(actual_distance_sq - expected_distance_sq) > 1e-12) {
                std::cerr << "FAIL: kd-tree disagrees with exhaustive search\n";
                return 1;
            }
        }
    }

    std::cout << "PASS: 300 random point sets x 60 queries (18,000 queries), "
              << "explicit x/y/z far-side cases, duplicate points, "
              << "exact-point queries, and empty-tree case\n";
    return 0;
}
