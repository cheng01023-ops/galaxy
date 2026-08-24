#include <stdio.h>
#include <math.h>

int main(void) {
    // 两个重要极限的数值逼近
    for (int n = 1; n <= 100000; n *= 10) {
        double x = 1.0 / n;
        printf("n=%7d  sin(1/n)/(1/n)=%.6f  (1+1/n)^n=%.6f\n",
               n, sin(x) / x, pow(1 + 1.0 / n, n));
    }
    return 0;
}
