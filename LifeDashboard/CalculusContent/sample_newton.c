// 示例 4：牛顿迭代法求根（导数在求近似解中的应用）
// 第 2 天 · 导数的应用
// 求 sqrt(2)（即解 x^2 - 2 = 0）：x_{n+1} = x_n - f(x_n)/f'(x_n)
// 编译运行：gcc sample_newton.c -o newton -lm && ./newton

#include <stdio.h>
#include <math.h>

static double f(double x)  { return x * x - 2.0; }
static double df(double x) { return 2.0 * x; }

int main(void) {
    double x = 1.0;                         // 初始猜测
    printf("牛顿迭代求 sqrt(2)：\n");
    for (int i = 0; i < 8; i++) {
        x = x - f(x) / df(x);
        printf("第 %d 步：x = %.12f\n", i + 1, x);
    }
    printf("sqrt(2) ≈ %.12f\n", sqrt(2.0));
    return 0;
}
