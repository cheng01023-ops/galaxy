#include <stdio.h>
#include <math.h>

int main(void) {
    // 欧拉法解 y'=y, y(0)=1，解析解 y=e^x
    double y = 1.0, h = 0.1;
    for (int i = 0; i <= 10; i++) {
        double t = i * h;
        printf("t=%.1f  y=%.6f  e^t=%.6f\n", t, y, exp(t));
        y += h * y;
    }
    return 0;
}
