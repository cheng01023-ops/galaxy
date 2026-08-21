// ============================================================
// 第 3 天：函数、数组、字符串
// 学习重点：函数的定义与调用 / 值传递 / 递归
//           一维二维数组 / 冒泡排序 / string 常用操作
// 使用方法：内容复制到 Xcode 的 main.cpp，Cmd + R 运行
// ============================================================

#include <iostream>
#include <string>
using namespace std;

// ---------- 1. 函数：返回两个数中的较大值 ----------
int max2(int a, int b) {
    return a > b ? a : b;     // 三目运算符：条件 ? 真值 : 假值
}

// ---------- 2. 默认参数：打招呼 ----------
void greet(string name, string prefix = "你好") {
    cout << prefix << "，" << name << "！" << endl;
}

// ---------- 3. 函数重载：同名不同参 ----------
void greet(string name, int times) {     // 打印 times 次
    for (int i = 0; i < times; i++) {
        cout << "Hi, " << name << " ";
    }
    cout << endl;
}

// ---------- 4. 值传递的坑：换不掉！ ----------
void trySwap(int a, int b) {             // 这里 a、b 是副本
    int t = a;
    a = b;
    b = t;
}

// ---------- 5. 递归：阶乘 ----------
long long factorial(int n) {
    if (n <= 1) return 1;                // 递归出口（必须要有！）
    return n * factorial(n - 1);         // 自己调用自己
}

int main() {

    // ---------- 6. 调用函数 ----------
    cout << "max2(3, 7) = " << max2(3, 7) << endl;
    greet("小明");                       // 用默认前缀
    greet("小红", "早上好");             // 自定义前缀
    greet("小李", 3);                    // 走重载版本
    cout << "5! = " << factorial(5) << endl;

    // ---------- 7. 值传递演示 ----------
    int x = 1, y = 2;
    trySwap(x, y);
    cout << "调用 trySwap 后：x = " << x << ", y = " << y
         << "（没变！因为传进去的是副本，第 4 天学指针/引用再解决）" << endl;

    // ---------- 8. 一维数组 ----------
    int scores[5] = {88, 92, 76, 85, 90};
    int sum = 0;
    for (int i = 0; i < 5; i++) {
        sum += scores[i];
    }
    cout << "平均分：" << sum / 5.0 << endl;

    // ---------- 9. 冒泡排序 ----------
    int arr[] = {5, 2, 9, 1, 7, 3};
    int len = sizeof(arr) / sizeof(arr[0]);   // 数组元素个数
    for (int i = 0; i < len - 1; i++) {
        for (int j = 0; j < len - 1 - i; j++) {
            if (arr[j] > arr[j + 1]) {        // 大的往后冒
                int t = arr[j];
                arr[j] = arr[j + 1];
                arr[j + 1] = t;
            }
        }
    }
    cout << "排序结果：";
    for (int i = 0; i < len; i++) {
        cout << arr[i] << " ";
    }
    cout << endl;

    // ---------- 10. 二维数组：3 行 4 列 ----------
    int table[3][4] = {
        {1, 2, 3, 4},
        {5, 6, 7, 8},
        {9, 10, 11, 12}
    };
    cout << "table[1][2] = " << table[1][2] << endl;

    // ---------- 11. string 常用操作 ----------
    string s1 = "Hello";
    string s2 = "C++";
    string s3 = s1 + " " + s2;          // 拼接
    cout << "拼接结果：" << s3 << endl;
    cout << "长度：" << s3.length() << endl;
    cout << "取子串 s3.substr(6, 3) = " << s3.substr(6, 3) << endl;  // 从下标6开始取3个

    size_t pos = s3.find("C++");       // 查找，找不到返回 npos
    if (pos != string::npos) {
        cout << "找到 C++，位置在 " << pos << endl;
    }

    // 读取带空格的整行：用 getline
    cout << "请输入一句话（可含空格）：";
    string line;
    cin.ignore();                      // 清掉缓冲区里残留的换行符
    getline(cin, line);
    cout << "你输入的是：" << line << endl;

    return 0;
}
