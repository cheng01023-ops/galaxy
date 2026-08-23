/* ============================================================
 * day06_linkedlist.c
 * 第 6 天示例：单链表（创建/头插/尾插/遍历/删除/释放）+ 文件读写 + 宏
 * 编译运行：clang day06_linkedlist.c -o day06 && ./day06
 * ============================================================ */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ---------- 宏：常量与带参宏（参数记得加括号） ---------- */
#define MAX_LEN 32
#define MAX(a, b) ((a) > (b) ? (a) : (b))

/* ---------- 链表节点 ---------- */
typedef struct Node {
    int data;
    struct Node *next;      // typedef 完成前必须写 struct Node
} Node;

/* 创建节点 */
Node *createNode(int v) {
    Node *n = (Node *)malloc(sizeof(Node));
    if (n == NULL) return NULL;
    n->data = v;
    n->next = NULL;
    return n;
}

/* 头插法 */
void insertHead(Node **head, int v) {
    Node *n = createNode(v);
    n->next = *head;
    *head = n;
}

/* 尾插法 */
void insertTail(Node **head, int v) {
    Node *n = createNode(v);
    if (*head == NULL) { *head = n; return; }
    Node *p = *head;
    while (p->next) p = p->next;   // 走到末尾
    p->next = n;
}

/* 遍历打印 */
void printList(Node *head) {
    for (Node *p = head; p; p = p->next) {
        printf("%d -> ", p->data);
    }
    printf("NULL\n");
}

/* 查找 */
int search(Node *head, int v) {
    for (Node *p = head; p; p = p->next) {
        if (p->data == v) return 1;
    }
    return 0;
}

/* 删除第一个值为 v 的节点 */
void deleteNode(Node **head, int v) {
    Node *p = *head, *prev = NULL;
    while (p && p->data != v) { prev = p; p = p->next; }
    if (!p) return;
    if (!prev) *head = p->next;    // 删的是头节点
    else prev->next = p->next;     // 删中间或末尾
    free(p);
}

/* 释放整个链表（必须先保存 next 再 free） */
void freeList(Node *head) {
    Node *p = head;
    while (p) {
        Node *next = p->next;
        free(p);
        p = next;
    }
}

int main(void) {
    /* ---------- 链表操作 ---------- */
    Node *head = NULL;
    insertTail(&head, 10);
    insertTail(&head, 20);
    insertTail(&head, 30);
    insertHead(&head, 5);           // 5 10 20 30
    printf("链表：");
    printList(head);

    printf("找 20：%s\n", search(head, 20) ? "找到了" : "没找到");
    printf("找 99：%s\n", search(head, 99) ? "找到了" : "没找到");

    deleteNode(&head, 20);
    printf("删除 20 后：");
    printList(head);

    freeList(head);                 // 释放所有节点
    head = NULL;

    /* ---------- 宏使用 ---------- */
    printf("MAX(3, 8) = %d，MAX(2+3, 4) = %d\n", MAX(3, 8), MAX(2 + 3, 4));

    /* ---------- 文件读写 ---------- */
    FILE *fp = fopen("day06_data.txt", "w");
    if (fp == NULL) {               // ⚠️ 必须判空
        printf("无法打开文件！\n");
        return 1;
    }
    fprintf(fp, "%d %s\n", 18, "小明");
    fprintf(fp, "%d %s\n", 17, "小红");
    fclose(fp);

    fp = fopen("day06_data.txt", "r");
    if (fp == NULL) {
        printf("文件不存在！\n");
        return 1;
    }
    printf("从文件读回：\n");
    int age;
    char name[MAX_LEN];
    while (fscanf(fp, "%d %s", &age, name) == 2) {
        printf("%s %d 岁\n", name, age);
    }
    fclose(fp);

    return 0;
}
