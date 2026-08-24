// 示例 2：二分法求方程根（零点定理的应用）
// 第 1 天 · 连续性
// 求解 f(x) = x^3 - 3x + 1 = 0 在 (0,1) 内的根
// 编译运行：gcc sample_bisection.c -o bisect && ./bisect

#include <stdio.h>
#include <math.h>

static double f(double x) {
    return x * x * x - 3.0 * x + 1.0;
}

int main(void) {
    double a = 0.0, b = 1.0;
    // 零点定理前提：f(a) 与 f(b) 异号
    if (f(a) * f(b) >= 0) {
        printf("区间两端函数值同号，无法使用二分法。\n");
        return 1;
    }

    for (int i = 0; i < 50; i++) {          // 迭代 50 次，精度足够
        double mid = (a + b) / 2.0;
        if (f(a) * f(mid) <= 0) {
            b = mid;                        // 根在 [a, mid]
        } else {
            a = mid;                        // 根在 [mid, b]
        }
    }

    double root = (a + b) / 2.0;
    printf("方程 x^3 - 3x + 1 = 0 在 (0,1) 内的根 ≈ %.10f\n", root);
    printf("检验 f(root) = %.2e\n", f(root));
    return 0;
}
