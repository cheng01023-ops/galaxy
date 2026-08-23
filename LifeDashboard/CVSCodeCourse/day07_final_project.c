/* ============================================================
 * day07_final_project.c
 * 第 7 天综合项目：学生成绩管理系统
 * 功能：添加 / 查看 / 排序 / 删除 / 修改 / 保存到文件 / 启动加载
 * 编译运行：clang day07_final_project.c -o day07 && ./day07
 * ============================================================ */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_STUDENTS 100
#define DATA_FILE "students.txt"

typedef struct {
    char name[32];
    int score;
} Student;

/* 全局数据（本项目的简单写法；工程上更推荐传入结构体） */
Student students[MAX_STUDENTS];
int count = 0;

/* ---------- 菜单 ---------- */
void showMenu(void) {
    printf("\n======== 学生成绩管理系统 ========\n");
    printf("  1 添加学生\n");
    printf("  2 查看学生\n");
    printf("  3 按成绩排序\n");
    printf("  4 删除学生\n");
    printf("  5 修改成绩\n");
    printf("  6 保存到文件\n");
    printf("  0 退出\n");
    printf("==================================\n");
    printf("请选择：");
}

/* ---------- 1 添加 ---------- */
void addStudent(void) {
    if (count >= MAX_STUDENTS) {
        printf("人数已满（%d 人）！\n", MAX_STUDENTS);
        return;
    }
    printf("姓名 成绩：");
    scanf("%s %d", students[count].name, &students[count].score);
    count++;
    printf("已添加 %s（成绩 %d），当前共 %d 人\n",
           students[count - 1].name, students[count - 1].score, count);
}

/* ---------- 2 查看 ---------- */
void listStudents(void) {
    if (count == 0) {
        printf("（还没有学生，请先添加）\n");
        return;
    }
    printf("\n%-4s %-16s %s\n", "序号", "姓名", "成绩");
    printf("----------------------------\n");
    for (int i = 0; i < count; i++) {
        printf("%-4d %-16s %d\n", i + 1, students[i].name, students[i].score);
    }
}

/* ---------- 3 排序（冒泡，从高到低） ---------- */
void sortByScore(void) {
    if (count < 2) {
        printf("人数太少，无需排序\n");
        return;
    }
    for (int i = 0; i < count - 1; i++) {
        for (int j = 0; j < count - 1 - i; j++) {
            if (students[j].score < students[j + 1].score) {
                Student t = students[j];
                students[j] = students[j + 1];
                students[j + 1] = t;
            }
        }
    }
    printf("已按成绩从高到低排序\n");
}

/* ---------- 4 删除（按姓名） ---------- */
void deleteStudent(void) {
    char name[32];
    printf("要删除的学生姓名：");
    scanf("%s", name);

    int found = -1;
    for (int i = 0; i < count; i++) {
        if (strcmp(students[i].name, name) == 0) {
            found = i;
            break;
        }
    }
    if (found == -1) {
        printf("没有找到 %s\n", name);
        return;
    }
    for (int i = found; i < count - 1; i++) {
        students[i] = students[i + 1];   // 后面的往前挪
    }
    count--;
    printf("已删除 %s，当前共 %d 人\n", name, count);
}

/* ---------- 5 修改（按姓名） ---------- */
void updateScore(void) {
    char name[32];
    printf("要修改的学生姓名：");
    scanf("%s", name);

    for (int i = 0; i < count; i++) {
        if (strcmp(students[i].name, name) == 0) {
            printf("%s 当前成绩 %d，新成绩：", name, students[i].score);
            scanf("%d", &students[i].score);
            printf("已更新\n");
            return;
        }
    }
    printf("没有找到 %s\n", name);
}

/* ---------- 6 保存 ---------- */
void saveToFile(void) {
    FILE *fp = fopen(DATA_FILE, "w");
    if (fp == NULL) {
        printf("保存失败，无法打开 %s！\n", DATA_FILE);
        return;
    }
    for (int i = 0; i < count; i++) {
        fprintf(fp, "%s %d\n", students[i].name, students[i].score);
    }
    fclose(fp);
    printf("已保存 %d 名学生到 %s\n", count, DATA_FILE);
}

/* ---------- 启动加载 ---------- */
void loadFromFile(void) {
    FILE *fp = fopen(DATA_FILE, "r");
    if (fp == NULL) return;                 // 文件不存在就跳过，不是错误

    while (count < MAX_STUDENTS &&
           fscanf(fp, "%s %d", students[count].name, &students[count].score) == 2) {
        count++;
    }
    fclose(fp);
    printf("已从文件加载 %d 名学生\n", count);
}

/* ---------- 主程序 ---------- */
int main(void) {
    loadFromFile();

    while (1) {
        showMenu();
        int choice;
        scanf("%d", &choice);

        switch (choice) {
            case 1: addStudent();    break;
            case 2: listStudents();  break;
            case 3: sortByScore();   break;
            case 4: deleteStudent(); break;
            case 5: updateScore();   break;
            case 6: saveToFile();    break;
            case 0:
                printf("再见！数据已保存在 %s（可运行 6 手动保存）\n", DATA_FILE);
                return 0;
            default:
                printf("无效选项，请输入 0~6\n");
        }
    }
}
