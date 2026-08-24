#include <stdio.h>

double f(double x) { return x * x; }

double trapezoid(double a, double b, int n) {
    double h = (b - a) / n, s = (f(a) + f(b)) / 2;
    for (int i = 1; i < n; i++) s += f(a + i * h);
    return s * h;
}

int main(void) {
    // 数值积分：梯形法计算 ∫_0^1 x^2 dx = 1/3
    for (int n = 2; n <= 1000; n *= 10) {
        printf("n=%5d  I≈%.8f\n", n, trapezoid(0, 1, n));
    }
    return 0;
}
