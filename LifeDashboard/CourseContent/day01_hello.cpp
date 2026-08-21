// ============================================================
// 第 1 天：Xcode 入门 + 第一个 C++ 程序
// 学习重点：cout 输出 / cin 输入 / 变量 / 基本类型 / 运算符
// 使用方法：把这个文件的内容复制到 Xcode 项目的 main.cpp 里，
//           然后按 Cmd + R 运行。
// ============================================================

#include <iostream>   // 输入输出库，cout/cin 都来自这里
#include <string>     // string 字符串类型
using namespace std;  // 方便直接写 cout，而不用 std::cout

int main() {   // 程序的入口，所有程序都从这里开始

    // ---------- 1. 向屏幕输出文字 ----------
    cout << "你好，C++！" << endl;          // endl = 换行
    cout << "我正在用 Xcode 学习 C++。" << endl;
    cout << "--------------------------------" << endl;

    // ---------- 2. 变量与基本数据类型 ----------
    int age = 18;              // 整数
    double height = 1.75;      // 小数（双精度）
    char grade = 'A';          // 单个字符，用单引号
    bool isHappy = true;       // 布尔：true(真) / false(假)
    string name = "小明";       // 字符串，用双引号

    cout << "年龄：" << age << endl;
    cout << "身高：" << height << " 米" << endl;
    cout << "等级：" << grade << endl;
    cout << "开心吗：" << isHappy << "（1 表示真）" << endl;
    cout << "名字：" << name << endl;

    // ---------- 3. 从键盘输入 ----------
    cout << "请输入你的名字：";
    cin >> name;               // 把键盘输入存进 name
    cout << "请输入你的年龄：";
    cin >> age;

    cout << "你好，" << name << "！你今年 " << age << " 岁。" << endl;

    // ---------- 4. 运算符：做一个简单计算器 ----------
    double a, b;
    cout << "请输入两个数字（用空格隔开）：";
    cin >> a >> b;

    cout << a << " + " << b << " = " << a + b << endl;
    cout << a << " - " << b << " = " << a - b << endl;
    cout << a << " * " << b << " = " << a * b << endl;
    if (b != 0) {
        cout << a << " / " << b << " = " << a / b << endl;
    } else {
        cout << "除数不能为 0！" << endl;
    }

    // ---------- 5. 经典坑点：整数除法 ----------
    int x = 7, y = 2;
    cout << "7 / 2 = " << x / y << "      （整数除法，结果还是整数）" << endl;
    cout << "7.0 / 2 = " << 7.0 / y << "  （只要有一边是小数，就是小数除法）" << endl;

    return 0;   // 返回 0 表示程序正常结束
}
