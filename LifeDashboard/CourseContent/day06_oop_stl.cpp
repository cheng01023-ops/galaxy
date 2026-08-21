// ============================================================
// 第 6 天：继承、多态 + STL 标准模板库入门
// 学习重点：继承 / 虚函数 / 纯虚函数 / 运算符重载
//           vector / sort / map / string
// 使用方法：内容复制到 Xcode 的 main.cpp，Cmd + R 运行
// ============================================================

#include <iostream>
#include <string>
#include <vector>      // 动态数组
#include <algorithm>   // sort 排序
#include <map>         // 键值对
using namespace std;

// ---------- 1. 继承与多态：动物体系 ----------
class Animal {
protected:                       // protected：子类可以访问，外部不行
    string name;

public:
    Animal(string n) : name(n) {}

    // 虚函数：允许子类重写（覆盖）
    virtual void speak() {
        cout << name << " 发出声音" << endl;
    }

    // 纯虚函数 = 0：这个类变成抽象类，不能直接创建对象
    // 子类必须实现它。想让"动物"只能被继承时，就这样写。
    // virtual void speak() = 0;

    // 虚析构函数：用基类指针删除子类对象时，保证子类析构函数被执行
    virtual ~Animal() {}
};

class Dog : public Animal {
public:
    Dog(string n) : Animal(n) {}

    void speak() override {      // override：明确表示这是重写
        cout << name << "：汪汪汪！" << endl;
    }
};

class Cat : public Animal {
public:
    Cat(string n) : Animal(n) {}

    void speak() override {
        cout << name << "：喵喵喵～" << endl;
    }
};

// ---------- 2. 运算符重载：让分数能相加、能直接 cout ----------
struct Fraction {                // 结构体：默认公有，适合简单的数据组合
    int top;     // 分子
    int bottom;  // 分母

    Fraction(int t, int b) : top(t), bottom(b) {}
};

Fraction operator+(const Fraction &a, const Fraction &b) {
    return Fraction(
        a.top * b.bottom + b.top * a.bottom,   // 通分后的分子
        a.bottom * b.bottom                    // 通分后的分母
    );
}

ostream &operator<<(ostream &out, const Fraction &f) {
    out << f.top << "/" << f.bottom;
    return out;
}

int main() {

    // ---------- 3. 使用继承与多态 ----------
    Dog dog("旺财");
    Cat cat("咪咪");

    dog.speak();
    cat.speak();

    // 多态：用基类指针调用子类的方法
    Animal *a1 = new Dog("小黑");
    Animal *a2 = new Cat("小橘");
    a1->speak();       // 输出"汪汪汪"，而不是"发出声音"
    a2->speak();
    delete a1;         // 因为有虚析构，这里会正确调用 Dog 的析构
    delete a2;

    cout << "--------------------------------" << endl;

    // ---------- 4. vector：动态数组，自动扩容 ----------
    vector<int> nums;
    nums.push_back(30);   // 尾部添加
    nums.push_back(10);
    nums.push_back(20);
    nums.push_back(50);
    nums.push_back(40);

    cout << "vector 大小：" << nums.size() << endl;
    cout << "遍历：";
    for (size_t i = 0; i < nums.size(); i++) {
        cout << nums[i] << " ";
    }
    cout << endl;

    // range-based for（C++11 起）：遍历神器
    cout << "再遍历一次：";
    for (int v : nums) {
        cout << v << " ";
    }
    cout << endl;

    // ---------- 5. sort 排序 ----------
    sort(nums.begin(), nums.end());          // 从小到大
    cout << "排序后：";
    for (int v : nums) cout << v << " ";
    cout << endl;

    sort(nums.rbegin(), nums.rend());        // 从大到小
    cout << "降序后：";
    for (int v : nums) cout << v << " ";
    cout << endl;

    // ---------- 6. map：键值对，像字典 ----------
    map<string, int> scores;
    scores["小明"] = 90;
    scores["小红"] = 95;
    scores["小刚"] = 78;

    cout << "小红的成绩：" << scores["小红"] << endl;

    cout << "所有成绩：";
    for (const auto &kv : scores) {          // auto 自动推断类型
        cout << kv.first << "=" << kv.second << " ";
    }
    cout << endl;

    // ---------- 7. 运算符重载演示 ----------
    Fraction f1(1, 2);   // 1/2
    Fraction f2(1, 3);   // 1/3
    Fraction f3 = f1 + f2;
    cout << f1 << " + " << f2 << " = " << f3 << endl;

    return 0;
}
