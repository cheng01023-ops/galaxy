// ============================================================
// 第 5 天：类与对象（面向对象编程入门）
// 学习重点：class / 访问权限 / 构造函数 / 析构函数 / this / 封装
// 今天用两个小例子：Student 学生类 和 BankAccount 银行账户类
// 使用方法：内容复制到 Xcode 的 main.cpp，Cmd + R 运行
// ============================================================

#include <iostream>
#include <string>
using namespace std;

// ---------- 例子 1：学生类 ----------
class Student {
private:                          // 私有：外部不能直接访问
    string name;
    int age;
    double score;

public:                           // 公有：外部可以调用
    // 构造函数：创建对象时自动执行，用来初始化
    Student(string n, int a, double s) {
        name = n;
        age = a;
        score = s;
        cout << "创建学生：" << name << endl;
    }

    // 析构函数：对象销毁时自动执行（前面加 ~）
    ~Student() {
        cout << "销毁学生：" << name << endl;
    }

    // 封装：通过公有方法访问私有数据（getter / setter）
    string getName() { return name; }
    void setScore(double s) {
        if (s >= 0 && s <= 100) {
            score = s;
        } else {
            cout << "成绩必须在 0~100 之间！" << endl;
        }
    }
    double getScore() { return score; }

    void printInfo() {
        cout << "姓名：" << name << "，年龄：" << age
             << "，成绩：" << score << endl;
    }
};

// ---------- 例子 2：银行账户类（使用 this 和静态成员） ----------
class BankAccount {
private:
    string owner;
    double balance;
    static int totalAccounts;     // 静态成员：所有对象共享一份

public:
    BankAccount(string o, double b) {
        owner = o;
        balance = b;
        totalAccounts++;
    }

    void deposit(double money) {          // 存款
        if (money > 0) {
            this->balance += money;       // this 指向当前对象
            cout << owner << " 存入 " << money << " 元" << endl;
        }
    }

    bool withdraw(double money) {         // 取款
        if (money > 0 && money <= balance) {
            balance -= money;
            cout << owner << " 取出 " << money << " 元" << endl;
            return true;
        }
        cout << owner << " 取款失败：余额不足或金额无效" << endl;
        return false;
    }

    void show() {
        cout << owner << " 的余额：" << balance << " 元" << endl;
    }

    static int getTotal() {               // 静态成员函数
        return totalAccounts;
    }
};

// 静态成员必须在类外定义并初始化
int BankAccount::totalAccounts = 0;

int main() {

    // ---------- 3. 使用 Student 类 ----------
    Student s1("小明", 18, 88.5);
    Student s2("小红", 19, 95.0);

    s1.printInfo();
    s2.printInfo();

    s1.setScore(120);     // 非法值，会被拦截
    s1.setScore(92);
    cout << s1.getName() << " 的最新成绩：" << s1.getScore() << endl;

    cout << "--------------------------------" << endl;

    // ---------- 4. 使用 BankAccount 类 ----------
    BankAccount acc1("小明", 1000);
    BankAccount acc2("小红", 500);

    acc1.deposit(200);
    acc1.withdraw(150);
    acc1.show();

    cout << "目前共有账户：" << BankAccount::getTotal() << " 个" << endl;

    // 对象数组
    cout << "--------------------------------" << endl;
    Student classRoom[2] = {
        Student("张三", 20, 78),
        Student("李四", 21, 85)
    };
    for (int i = 0; i < 2; i++) {
        classRoom[i].printInfo();
    }

    return 0;
}
