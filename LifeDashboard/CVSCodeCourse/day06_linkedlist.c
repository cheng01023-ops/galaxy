#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct Node {
    int data;
    struct Node *next;
} Node;

Node *createNode(int v) {
    Node *n = (Node *)malloc(sizeof(Node));
    n->data = v;
    n->next = NULL;
    return n;
}

void append(Node **head, int v) {
    Node *n = createNode(v);
    if (*head == NULL) { *head = n; return; }
    Node *p = *head;
    while (p->next) p = p->next;
    p->next = n;
}

void printList(Node *head) {
    while (head) {
        printf("%d -> ", head->data);
        head = head->next;
    }
    printf("NULL\n");
}

int main(void) {
    Node *head = NULL;
    append(&head, 1);
    append(&head, 2);
    append(&head, 3);
    printList(head);
    return 0;
}
