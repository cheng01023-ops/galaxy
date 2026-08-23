#include <stdio.h>

int main(void) {
    // 基本输出与输入
    printf("Hello, C!\n");

    int age = 0;
    printf("请输入你的年龄：");
    scanf("%d", &age);
    printf("你 %d 岁，C 语言欢迎你！\n", age);

    double price = 3.14;
    char grade = 'A';
    printf("价格 %.2f，等级 %c\n", price, grade);
    return 0;
}
