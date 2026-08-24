// 示例 6：欧拉法数值求解微分方程
// 第 4 天 · 微分方程
// 求解 y' = y，初值 y(0) = 1（精确解 y = e^x），计算到 x = 1
// 编译运行：gcc sample_euler.c -o euler -lm && ./euler

#include <stdio.h>
#include <math.h>

static double f(double x, double y) {       // 右端函数：y' = y
    (void)x;
    return y;
}

int main(void) {
    double x0 = 0.0, y0 = 1.0, xEnd = 1.0;
    int n = 100;                            // 步数越多越精确
    double h = (xEnd - x0) / n;
    double x = x0, y = y0;

    printf("欧拉法求解 y' = y, y(0) = 1，步长 h = %.3f\n", h);
    for (int i = 1; i <= n; i++) {
        y = y + h * f(x, y);                // y_{k+1} = y_k + h·f(x_k, y_k)
        x = x + h;
    }
    printf("x = %.1f 时：数值解 y ≈ %.8f，精确解 e^1 ≈ %.8f\n", x, y, exp(1.0));
    return 0;
}
