#include <stdio.h>
#include <string.h>

typedef struct {
    char name[32];
    int age;
    double score;
} Student;

void printStudent(const Student *s) {
    printf("%s %d 岁 成绩 %.1f\n", s->name, s->age, s->score);
}

int main(void) {
    Student s1;
    strcpy(s1.name, "小明");
    s1.age = 18;
    s1.score = 92.5;
    printStudent(&s1);
    return 0;
}
