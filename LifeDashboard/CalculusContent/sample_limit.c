// 示例 1：用数值逼近观察两个重要极限
// 第 1 天 · 极限
// 编译运行：gcc sample_limit.c -o limit && ./limit

#include <stdio.h>
#include <math.h>

int main(void) {
    printf("== 重要极限 (1)：lim_{x->0} (sin x)/x = 1 ==\n");
    for (int i = 1; i <= 8; i++) {
        double x = pow(10.0, -i);          // x = 0.1, 0.01, 0.001, ...
        printf("x = %-12g  (sin x)/x = %.10f\n", x, sin(x) / x);
    }

    printf("\n== 重要极限 (2)：lim_{n->inf} (1 + 1/n)^n = e ==\n");
    for (int i = 1; i <= 8; i++) {
        long n = (long)pow(10.0, i);       // n = 10, 100, 1000, ...
        double v = pow(1.0 + 1.0 / n, (double)n);
        printf("n = %-10ld  (1+1/n)^n = %.10f\n", n, v);
    }

    printf("\n参考：e = %.10f\n", exp(1.0));
    return 0;
}
