#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    char name[32];
    int score;
} Student;

int main(void) {
    Student students[100];
    int count = 0;

    FILE *fp = fopen("students.txt", "r");
    if (fp) {
        while (count < 100 && fscanf(fp, "%s %d", students[count].name, &students[count].score) == 2) {
            count++;
        }
        fclose(fp);
    }

    while (1) {
        int choice;
        printf("\n1 添加 2 查看 3 保存 0 退出：");
        scanf("%d", &choice);
        if (choice == 0) break;
        if (choice == 1 && count < 100) {
            printf("姓名 成绩：");
            scanf("%s %d", students[count].name, &students[count].score);
            count++;
        } else if (choice == 2) {
            for (int i = 0; i < count; i++) {
                printf("%s %d\n", students[i].name, students[i].score);
            }
        } else if (choice == 3) {
            fp = fopen("students.txt", "w");
            if (fp) {
                for (int i = 0; i < count; i++) fprintf(fp, "%s %d\n", students[i].name, students[i].score);
                fclose(fp);
                printf("已保存\n");
            }
        }
    }
    return 0;
}
