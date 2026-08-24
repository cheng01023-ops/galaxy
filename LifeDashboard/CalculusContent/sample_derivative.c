#include <stdio.h>
#include <math.h>

double f(double x) { return x * x; }

int main(void) {
    // 中心差商逼近 f'(x)=2x
    double x = 3.0;
    double h = 0.1;
    for (int i = 0; i < 8; i++) {
        double d = (f(x + h) - f(x - h)) / (2 * h);
        printf("h=%.1e  f'(%.0f)≈%.6f\n", h, x, d);
        h /= 10;
    }
    return 0;
}
