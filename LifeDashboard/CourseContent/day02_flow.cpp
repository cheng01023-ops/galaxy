// ============================================================
// 第 2 天：流程控制 —— 分支与循环
// 学习重点：if / switch / for / while / do-while / break / continue
// 今天的重头戏：猜数字游戏！
// 使用方法：内容复制到 Xcode 的 main.cpp，Cmd + R 运行
// ============================================================

#include <iostream>
#include <cstdlib>   // rand() 随机数、srand() 随机种子
#include <ctime>     // time() 当前时间
using namespace std;

int main() {

    // ---------- 1. if / else if / else 分支 ----------
    int score;
    cout << "请输入考试成绩：";
    cin >> score;

    if (score >= 90) {
        cout << "优秀！" << endl;
    } else if (score >= 70) {
        cout << "良好" << endl;
    } else if (score >= 60) {
        cout << "及格" << endl;
    } else {
        cout << "不及格，继续加油" << endl;
    }

    // ---------- 2. switch 多分支 ----------
    int week;
    cout << "请输入星期几（1~7）：";
    cin >> week;
    switch (week) {
        case 1: cout << "星期一" << endl; break;
        case 2: cout << "星期二" << endl; break;
        case 3: cout << "星期三" << endl; break;
        case 4: cout << "星期四" << endl; break;
        case 5: cout << "星期五" << endl; break;
        case 6: cout << "星期六" << endl; break;
        case 7: cout << "星期日" << endl; break;
        default: cout << "输入无效" << endl; break;
    }

    // ---------- 3. for 循环：求 1~100 的和 ----------
    int sum = 0;
    for (int i = 1; i <= 100; i++) {
        sum += i;              // 等价于 sum = sum + i;
    }
    cout << "1+2+...+100 = " << sum << endl;

    // ---------- 4. while 循环 ----------
    int n = 1;
    while (n <= 10) {
        cout << n << " ";
        n++;
    }
    cout << endl;

    // ---------- 5. 嵌套循环：打印九九乘法表 ----------
    for (int i = 1; i <= 9; i++) {
        for (int j = 1; j <= i; j++) {
            cout << j << "x" << i << "=" << i * j << "\t";
        }
        cout << endl;   // 每行结束换行
    }

    // ---------- 6. do-while + 随机数：猜数字游戏 ----------
    srand((unsigned)time(nullptr));     // 用当前时间做随机种子，每次运行都不同
    int target = rand() % 100 + 1;      // 生成 1~100 的随机数
    int guess = 0, times = 0;

    cout << "\n【猜数字游戏】我心里想了一个 1~100 的数，你来猜：" << endl;
    do {
        cin >> guess;                   // 读入猜测
        times++;
        if (guess > target) {
            cout << "大了！再试：";
        } else if (guess < target) {
            cout << "小了！再试：";
        }
    } while (guess != target);

    cout << "恭喜你猜对了！你一共猜了 " << times << " 次。" << endl;

    return 0;
}
