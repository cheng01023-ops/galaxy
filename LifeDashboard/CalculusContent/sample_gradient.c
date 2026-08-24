#include <stdio.h>
#include <math.h>

int main(void) {
    // 梯度下降：最小化 f(x,y)=x^2+y^2，理论最小值 (0,0)
    double x = 2.0, y = 2.0, lr = 0.1;
    for (int i = 0; i < 30; i++) {
        x -= lr * 2 * x;   // ∂f/∂x = 2x
        y -= lr * 2 * y;   // ∂f/∂y = 2y
        printf("iter %2d  x=%.5f y=%.5f  f=%.6f\n", i, x, y, x*x + y*y);
    }
    return 0;
}
