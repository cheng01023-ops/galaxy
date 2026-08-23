/* ============================================================
 * day03_func_array.c
 * 第 3 天示例：函数、递归、数组、字符串
 * 编译运行：clang day03_func_array.c -o day03 && ./day03
 * ============================================================ */

#include <stdio.h>
#include <string.h>

/* ---------- 1. 函数：返回两个数中较大的 ---------- */
int max(int a, int b) {
    return (a > b) ? a : b;
}

/* ---------- 2. 递归：阶乘 ---------- */
int factorial(int n) {
    if (n <= 1) return 1;           // 出口（base case），必须有
    return n * factorial(n - 1);    // 规模缩小，递归调用
}

/* ---------- 3. 递归：斐波那契 ---------- */
int fib(int n) {
    if (n <= 1) return n;           // fib(0)=0, fib(1)=1
    return fib(n - 1) + fib(n - 2);
}

/* ---------- 4. 冒泡排序（数组做参数退化成指针，能改到外面） ---------- */
void bubbleSort(int arr[], int n) {
    for (int i = 0; i < n - 1; i++) {
        for (int j = 0; j < n - 1 - i; j++) {
            if (arr[j] > arr[j + 1]) {
                int t = arr[j];
                arr[j] = arr[j + 1];
                arr[j + 1] = t;
            }
        }
    }
}

/* ---------- 5. 二维数组打印 ---------- */
void printMatrix(int m[][4], int rows) {
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < 4; j++) {
            printf("%3d ", m[i][j]);
        }
        printf("\n");
    }
}

int main(void) {
    /* 函数 */
    printf("max(3, 8) = %d\n", max(3, 8));
    printf("5! = %d\n", factorial(5));
    printf("fib(10) = %d\n", fib(10));   // 0 1 1 2 3 5 8 13 21 34 55

    /* 数组 */
    int nums[] = {5, 2, 8, 1, 9};
    int n = sizeof(nums) / sizeof(nums[0]);   // 数组元素个数

    bubbleSort(nums, n);
    printf("排序后：");
    for (int i = 0; i < n; i++) printf("%d ", nums[i]);
    printf("\n");

    /* 二维数组 */
    int matrix[3][4] = {
        {1, 2, 3, 4},
        {5, 6, 7, 8},
        {9, 10, 11, 12}
    };
    printf("二维数组：\n");
    printMatrix(matrix, 3);

    /* 字符串 */
    char name[32] = "C语言";
    printf("%s 的字节长度 = %zu\n", name, strlen(name));  // 中文按 UTF-8 每字 3 字节

    char copy[32];
    strcpy(copy, "新名字");          // 复制
    printf("复制后：%s\n", copy);

    if (strcmp(copy, "新名字") == 0) {   // 相等返回 0
        printf("strcmp 判断相等 ✅\n");
    }

    strcat(copy, "-C");              // 拼接
    printf("拼接后：%s\n", copy);

    /* 手写 strlen：理解 \0 */
    int len = 0;
    while (copy[len] != '\0') len++;
    printf("手写 strlen 结果 = %d\n", len);

    return 0;
}
