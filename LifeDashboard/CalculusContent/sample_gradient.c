// 示例 7：梯度下降法求多元函数极小值
// 第 5 天 · 多元微积分
// 求 f(x,y) = x^2 + y^2 的极小值（显然在 (0,0)，梯度为 (2x, 2y)）
// 编译运行：gcc sample_gradient.c -o gradient && ./gradient

#include <stdio.h>
#include <math.h>

int main(void) {
    double x = 3.0, y = 4.0;                // 初始点
    double alpha = 0.1;                     // 学习率（步长）
    int n = 50;

    printf("梯度下降最小化 f(x,y) = x^2 + y^2：\n");
    for (int i = 0; i < n; i++) {
        // 梯度：∇f = (2x, 2y)，沿负梯度方向更新
        double gx = 2.0 * x;
        double gy = 2.0 * y;
        x = x - alpha * gx;
        y = y - alpha * gy;
        if (i % 10 == 9 || i < 3) {
            printf("第 %2d 步：(x, y) = (%.6f, %.6f)  f = %.8f\n",
                   i + 1, x, y, x * x + y * y);
        }
    }
    printf("收敛到 (%.6f, %.6f)，最小值 f ≈ %.8f\n", x, y, x * x + y * y);
    return 0;
}
