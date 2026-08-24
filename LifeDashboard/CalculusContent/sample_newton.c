#include <stdio.h>
#include <math.h>

int main(void) {
    // 牛顿迭代求 sqrt(2)：解 x^2-2=0
    double x = 1.5;
    for (int i = 0; i < 10; i++) {
        x = x - (x * x - 2) / (2 * x);
        printf("iter %2d  x=%.12f\n", i, x);
    }
    return 0;
}
