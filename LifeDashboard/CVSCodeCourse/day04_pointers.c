/* ============================================================
 * day04_pointers.c
 * 第 4 天示例：地址与指针、指针参数、数组与指针、malloc/free
 * 编译运行：clang day04_pointers.c -o day04 && ./day04
 * ============================================================ */

#include <stdio.h>
#include <stdlib.h>

/* ---------- 1. 通过指针修改外部变量 ---------- */
void swap(int *a, int *b) {
    int t = *a;     // *a：a 指向的那个变量
    *a = *b;
    *b = t;
}

/* ---------- 2. 数组做参数：把元素翻倍（修改外面的数组） ---------- */
void doubleAll(int *arr, int n) {
    for (int i = 0; i < n; i++) {
        arr[i] *= 2;            // arr[i] 等价于 *(arr + i)
    }
}

/* ---------- 3. const 指针参数：只读保护 ---------- */
void printArr(const int *arr, int n) {
    for (int i = 0; i < n; i++) {
        printf("%d ", arr[i]);
    }
    printf("\n");
    // arr[0] = 999;   // ❌ 编译错误：const 不能修改
}

int main(void) {
    /* ---------- 地址与指针 ---------- */
    int x = 10;
    int *p = &x;                    // p 保存 x 的地址

    printf("x = %d，x 的地址 = %p\n", x, (void *)&x);
    printf("p 保存的地址 = %p\n", (void *)p);
    printf("*p = %d\n", *p);        // 解引用：取出 p 指向的值

    *p = 20;                        // 等价于 x = 20
    printf("修改后 x = %d\n", x);

    /* ---------- 指针交换 ---------- */
    int a = 10, b = 20;
    printf("交换前：%d %d\n", a, b);
    swap(&a, &b);                   // 传地址
    printf("交换后：%d %d\n", a, b);

    /* ---------- 数组与指针 ---------- */
    int arr[5] = {1, 2, 3, 4, 5};
    int *q = arr;                   // 数组名就是首元素地址

    printf("*(arr+2) = %d，q[3] = %d\n", *(arr + 2), q[3]);

    printf("翻倍前：");
    printArr(arr, 5);
    doubleAll(arr, 5);              // 修改外面的数组
    printf("翻倍后：");
    printArr(arr, 5);

    /* ---------- 指针遍历 ---------- */
    printf("用指针遍历：");
    for (int *r = arr; r < arr + 5; r++) {
        printf("%d ", *r);
    }
    printf("\n");

    /* ---------- 动态内存 malloc / free ---------- */
    int n = 5;
    int *dyn = (int *)malloc(n * sizeof(int));   // 申请 5 个 int
    if (dyn == NULL) {              // ⚠️ 必须判空
        printf("内存分配失败！\n");
        return 1;
    }

    for (int i = 0; i < n; i++) {
        dyn[i] = i * 10;            // 0 10 20 30 40
    }
    printf("动态数组：");
    for (int i = 0; i < n; i++) printf("%d ", dyn[i]);
    printf("\n");

    free(dyn);                      // ⚠️ 用完释放
    dyn = NULL;                     // 置空，避免野指针

    return 0;
}
