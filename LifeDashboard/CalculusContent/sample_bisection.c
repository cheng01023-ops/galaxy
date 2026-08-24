#include <stdio.h>

double f(double x) { return x*x*x - 3*x + 1; }

int main(void) {
    // 二分法求 f(x)=0 在 (0,1) 的根（零点定理保证有根）
    double a = 0, b = 1;
    for (int i = 0; i < 50; i++) {
        double m = (a + b) / 2;
        if (f(a) * f(m) < 0) b = m; else a = m;
    }
    printf("root ≈ %.10f\n", (a + b) / 2);
    return 0;
}
