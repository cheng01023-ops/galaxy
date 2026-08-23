/* ============================================================
 * day02_flow.c
 * 第 2 天示例：if/switch 判断、for/while/do-while 循环、猜数字
 * 编译运行：clang day02_flow.c -o day02 && ./day02
 * ============================================================ */

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(void) {
    /* ---------- 1. if / else if / else ---------- */
    int score = 85;
    if (score >= 90) {
        printf("优秀\n");
    } else if (score >= 80) {
        printf("良好\n");           // 85 命中这里
    } else if (score >= 60) {
        printf("及格\n");
    } else {
        printf("不及格\n");
    }

    /* ---------- 2. switch（记得每个 case 后 break） ---------- */
    int day = 3;
    switch (day) {
        case 1: printf("周一\n"); break;
        case 2: printf("周二\n"); break;
        case 3: printf("周三\n"); break;   // day=3 命中这里
        case 4: printf("周四\n"); break;
        case 5: printf("周五\n"); break;
        default: printf("周末\n"); break;
    }

    /* ---------- 3. for 循环：知道次数 ---------- */
    printf("for: ");
    for (int i = 1; i <= 5; i++) {
        printf("%d ", i);
    }
    printf("\n");

    /* ---------- 4. while 循环：先判断 ---------- */
    int n = 1, sum = 0;
    while (n <= 100) {
        sum += n;
        n++;                        // 别忘了更新，否则死循环
    }
    printf("1+2+...+100 = %d\n", sum);

    /* ---------- 5. do-while：至少执行一次（输入校验） ---------- */
    int x;
    do {
        printf("请输入一个正数：");
        scanf("%d", &x);
    } while (x <= 0);
    printf("你输入了 %d\n", x);

    /* ---------- 6. break 与 continue ---------- */
    printf("break 跳过 5 之后：");
    for (int i = 1; i <= 10; i++) {
        if (i == 5) break;          // 遇到 5 立刻退出整个循环
        printf("%d ", i);
    }
    printf("\n");

    printf("continue 跳过 3：");
    for (int i = 1; i <= 5; i++) {
        if (i == 3) continue;       // 跳过本次，进入下一轮
        printf("%d ", i);
    }
    printf("\n");

    /* ---------- 7. 综合：猜数字游戏 ---------- */
    srand((unsigned)time(NULL));    // 用当前时间做随机种子
    int secret = rand() % 100 + 1;  // 1~100 的随机数
    int guess, tries = 0;

    printf("我已想好一个 1~100 的数字，来猜吧！\n");
    do {
        printf("你的猜测：");
        scanf("%d", &guess);
        tries++;
        if (guess > secret) {
            printf("太大了！\n");
        } else if (guess < secret) {
            printf("太小了！\n");
        } else {
            printf("恭喜！答案是 %d，你用了 %d 次\n", secret, tries);
        }
    } while (guess != secret);

    return 0;
}
