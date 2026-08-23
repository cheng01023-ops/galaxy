#include <stdio.h>
#include <string.h>

int add(int a, int b) { return a + b; }

int factorial(int n) {
    if (n <= 1) return 1;
    return n * factorial(n - 1);
}

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

int main(void) {
    printf("3 + 5 = %d\n", add(3, 5));
    printf("5! = %d\n", factorial(5));

    int nums[] = {5, 2, 8, 1};
    bubbleSort(nums, 4);
    for (int i = 0; i < 4; i++) printf("%d ", nums[i]);
    printf("\n");

    char name[32] = "C语言";
    printf("%s 长度 %zu\n", name, strlen(name));
    return 0;
}
