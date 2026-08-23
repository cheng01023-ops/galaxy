#include <stdio.h>
#include <stdlib.h>

void swap(int *a, int *b) {
    int t = *a;
    *a = *b;
    *b = t;
}

int main(void) {
    int x = 10, y = 20;
    printf("交换前 %d %d\n", x, y);
    swap(&x, &y);
    printf("交换后 %d %d\n", x, y);

    // 动态内存
    int n = 5;
    int *arr = (int *)malloc(n * sizeof(int));
    if (arr == NULL) return 1;
    for (int i = 0; i < n; i++) arr[i] = i * 2;
    for (int i = 0; i < n; i++) printf("%d ", arr[i]);
    printf("\n");
    free(arr);
    return 0;
}
