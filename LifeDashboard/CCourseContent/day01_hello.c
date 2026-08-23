/* ============================================================
 * day01_hello.c
 * 第 1 天示例：程序结构、printf/scanf、基本类型、运算符
 * 编译运行：clang day01_hello.c -o day01 && ./day01
 * ============================================================ */

#include <stdio.h>

int main(void) {
    /* ---------- 1. 输出 ---------- */
    printf("Hello, C!\n");          // \n 表示换行
    printf("我 %d 岁，成绩 %.1f 分\n", 18, 92.5);  // %d 整数，%.1f 保留1位小数

    /* ---------- 2. 输入 ---------- */
    int age = 0;
    printf("请输入你的年龄：");
    scanf("%d", &age);              // 注意：普通变量前要加 &
    printf("你 %d 岁，C 语言欢迎你！\n", age);

    /* ---------- 3. 基本类型 ---------- */
    int count = 10;                 // 整数
    double price = 3.14159;         // 双精度小数
    float pi = 3.14f;               // 单精度小数（f 后缀）
    char grade = 'A';               // 单个字符（单引号）
    _Bool ok = 1;                   // 布尔：1 真 0 假

    printf("count=%d price=%.2f pi=%.2f grade=%c ok=%d\n",
           count, price, pi, grade, ok);

    /* ---------- 4. 运算符 ---------- */
    int a = 7, b = 2;
    printf("a+b=%d a-b=%d a*b=%d\n", a + b, a - b, a * b);
    printf("a/b=%d（整数除法丢小数！） a%%b=%d\n", a / b, a % b);

    double r = 7.0 / 2;             // 有一边是小数 → 小数除法
    printf("7.0/2 = %.1f\n", r);

    /* 比较和逻辑运算的结果是 0 或 1 */
    printf("5>3 得 %d，5==5 得 %d，(1&&0) 得 %d\n", 5 > 3, 5 == 5, 1 && 0);

    /* ---------- 5. 变量命名 ---------- */
    int my_age = 18;                // 好名字：小写 + 下划线，见名知义
    printf("my_age = %d\n", my_age);
    // int 2age = 1;                // 错误：不能以数字开头（去掉注释会编译报错）
    // int class = 1;               // 错误：class 是关键字（去掉注释会编译报错）

    return 0;                       // 0 表示程序正常结束
}
