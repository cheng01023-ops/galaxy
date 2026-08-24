// 示例 3：用导数的极限定义做数值求导
// 第 2 天 · 导数
// f(x) = x^2，理论导数 f'(x) = 2x
// 编译运行：gcc sample_derivative.c -o deriv -lm && ./deriv

#include <stdio.h>
#include <math.h>

static double f(double x) {
    return x * x;
}

// 中心差商：f'(x) ≈ [f(x+h) - f(x-h)] / (2h)，精度比单侧差商更高
static double derivative(double x, double h) {
    return (f(x + h) - f(x - h)) / (2.0 * h);
}

int main(void) {
    double x = 3.0;
    printf("f(x) = x^2，x = %.1f，理论导数 f'(x) = 2x = %.1f\n", x, 2.0 * x);
    for (int i = 1; i <= 10; i++) {
        double h = pow(10.0, -i);
        printf("h = %-12g  数值导数 = %.12f\n", h, derivative(x, h));
    }
    return 0;
}
