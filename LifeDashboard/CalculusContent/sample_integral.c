// 示例 5：数值积分（梯形法 + 辛普森法）
// 第 3 天 · 定积分
// 计算 ∫_0^1 x^2 dx，精确值 = 1/3
// 编译运行：gcc sample_integral.c -o integral && ./integral

#include <stdio.h>

static double f(double x) {
    return x * x;
}

// 梯形法：把 [a,b] 分成 n 等份，每份用梯形近似
static double trapezoid(double a, double b, int n) {
    double h = (b - a) / n;
    double s = 0.5 * (f(a) + f(b));
    for (int i = 1; i < n; i++) {
        s += f(a + i * h);
    }
    return s * h;
}

// 辛普森法：每两份用一个二次曲线近似，精度更高
static double simpson(double a, double b, int n) {
    double h = (b - a) / n;
    double s = f(a) + f(b);
    for (int i = 1; i < n; i++) {
        s += (i % 2 == 0 ? 2.0 : 4.0) * f(a + i * h);
    }
    return s * h / 3.0;
}

int main(void) {
    double a = 0.0, b = 1.0;
    printf("计算 ∫_0^1 x^2 dx，精确值 = 1/3 ≈ %.10f\n", 1.0 / 3.0);
    for (int n = 10; n <= 1000; n *= 10) {
        printf("n = %-6d  梯形法 = %.10f   辛普森法 = %.10f\n",
               n, trapezoid(a, b, n), simpson(a, b, n));
    }
    return 0;
}
