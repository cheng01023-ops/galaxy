#include <stdio.h>

int main(void) {
    // if / switch / for / while
    int score = 85;
    if (score >= 90) {
        printf("优秀\n");
    } else if (score >= 60) {
        printf("及格\n");
    } else {
        printf("加油\n");
    }

    for (int i = 1; i <= 5; i++) {
        printf("%d ", i);
    }
    printf("\n");

    int sum = 0, n = 1;
    while (n <= 100) {
        sum += n;
        n++;
    }
    printf("1+...+100 = %d\n", sum);
    return 0;
}
