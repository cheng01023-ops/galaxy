/* ============================================================
 * day05_struct.c
 * 第 5 天示例：struct、typedef、结构体数组、结构体指针、enum
 * 编译运行：clang day05_struct.c -o day05 && ./day05
 * ============================================================ */

#include <stdio.h>
#include <string.h>

/* ---------- 1. 定义结构体 + typedef 简化 ---------- */
typedef struct {
    char name[32];
    int age;
    double score;
} Student;

/* ---------- 2. 结构体指针 + const：高效且只读 ---------- */
void printStudent(const Student *s) {
    printf("%s  %d 岁  %.1f 分\n", s->name, s->age, s->score);
    // s-> 等价于 (*s).
}

/* ---------- 3. 通过指针修改结构体 ---------- */
void birthday(Student *s) {
    s->age++;
}

/* ---------- 4. 按成绩排序（结构体整体交换） ---------- */
void sortByScore(Student students[], int n) {
    for (int i = 0; i < n - 1; i++) {
        for (int j = 0; j < n - 1 - i; j++) {
            if (students[j].score < students[j + 1].score) {
                Student t = students[j];
                students[j] = students[j + 1];
                students[j + 1] = t;
            }
        }
    }
}

/* ---------- 5. 枚举：值是整数，默认从 0 开始 ---------- */
typedef enum { RED, GREEN, BLUE } Color;

void printColor(Color c) {
    switch (c) {
        case RED:   printf("红色\n"); break;
        case GREEN: printf("绿色\n"); break;
        case BLUE:  printf("蓝色\n"); break;
        default:    printf("未知\n"); break;
    }
}

int main(void) {
    /* 创建结构体变量并初始化 */
    Student s1;
    strcpy(s1.name, "小明");        // 字符数组用 strcpy 赋值
    s1.age = 18;
    s1.score = 92.5;

    Student s2 = {"小红", 17, 98.0};   // 按顺序初始化
    printf("s2 姓名：%s\n", s2.name);

    printf("s1 大小（含对齐填充）: %zu 字节\n", sizeof(Student));

    printStudent(&s1);
    birthday(&s1);                  // 年龄 +1
    printf("过完生日：");
    printStudent(&s1);

    /* 结构体数组 */
    Student classRoom[3] = {
        {"小明", 18, 92.5},
        {"小红", 17, 98.0},
        {"小刚", 19, 76.0}
    };

    printf("\n排序前：\n");
    for (int i = 0; i < 3; i++) printStudent(&classRoom[i]);

    sortByScore(classRoom, 3);

    printf("\n按成绩从高到低：\n");
    for (int i = 0; i < 3; i++) printStudent(&classRoom[i]);

    /* 枚举 */
    Color c = GREEN;
    printf("\nGREEN 的整数值 = %d\n", c);
    printColor(c);

    return 0;
}
