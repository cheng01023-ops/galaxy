# 第 6 天：继承、多态 + STL 标准库

> 预计用时：5～6 小时 ｜ 今天学完，你就掌握了面向对象的**两大王牌**（继承、多态）
> 和 C++ 最常用的**现成工具**（vector、sort、map）。从今天起，写程序会轻松很多。

---

## 📋 今天学完，你能做到（打卡清单）

- [ ] 用继承复用代码（子类继承父类，理解构造顺序）
- [ ] 用虚函数实现多态（同一句代码，不同对象不同表现）
- [ ] 理解纯虚函数和抽象类
- [ ] 会用 `vector`（动态数组）代替普通数组
- [ ] 会用 `sort` 排序、`map` 做键值对

---

## 🧭 今天的路线图

```
第 1 步 回顾 + 为什么要继承（先看"重复代码"的痛点）
   ↓
第 2 步 继承语法 + protected + 构造顺序
   ↓
第 3 步 方法重写（override）
   ↓
第 4 步 多态：虚函数（virtual）——今天的重头戏
   ↓
第 5 步 纯虚函数与抽象类
   ↓
第 6 步 运算符重载（让自定义类型支持 +、<<）
   ↓
第 7 步 STL 三件套：vector / sort / map
```

---

## 第 1 步：为什么要继承？

**假设你要设计一个动物园程序**，有狗、猫、鸟。它们都有名字、都会"吃东西"，但"叫"的方式不同。不用继承的写法：

```cpp
class Dog {
public:
    string name;
    void eat() { cout << name << " 在吃东西" << endl; }
    void bark() { cout << name << "：汪汪！" << endl; }
};

class Cat {
public:
    string name;
    void eat() { cout << name << " 在吃东西" << endl; }   // ❌ 和 Dog 重复了
    void meow() { cout << name << "：喵喵！" << endl; }
};
```

**痛点**：`name` 和 `eat()` 每个类都写一遍。以后加"游泳"功能，三个类都要改。

**继承的思路**：先写一个通用的 `Animal`（动物）类，狗、猫、鸟**继承**它，只写自己特有的部分：

```
Animal（父类/基类）：name + eat()
   ↑        ↑        ↑
  Dog      Cat      Bird
  bark()   meow()   fly()
```

**术语：** 被继承的叫**父类（基类）**，继承的叫**子类（派生类）**。

---

## 第 2 步：继承语法 + protected + 构造顺序

### 2.1 基本语法

```cpp
class Animal {                  // 父类
public:
    string name;
    Animal(string n) : name(n) {}
    void eat() { cout << name << " 在吃东西" << endl; }
};

class Dog : public Animal {     // 子类继承父类
public:
    Dog(string n) : Animal(n) {}   // 先初始化父类部分
    void bark() { cout << name << "：汪汪！" << endl; }
};
```

```cpp
Dog d("旺财");
d.eat();     // 继承来的方法（父类的能力）
d.bark();    // 自己的方法
```

**注意子类构造函数**：`Dog(string n) : Animal(n) {}` —— **必须先调用父类的构造函数**，把父类的部分初始化好。

### 2.2 protected：给子类开的"后门"

| 权限 | 外部 | 子类 | 场景 |
| --- | --- | --- | --- |
| `public` | ✅ | ✅ | 对外接口 |
| `private` | ❌ | ❌ | 只有自己能用 |
| `protected` | ❌ | ✅ | 希望子类能用、但外部不能用 |

```cpp
class Animal {
protected:
    string name;        // 子类能访问，外部不行
};
class Dog : public Animal {
public:
    void show() { cout << name; }   // ✅ 子类能访问 protected
};
int main() {
    Dog d("旺财");
    // cout << d.name;   // ❌ 外部不能访问 protected
}
```

### 2.3 构造顺序（重点）

**创建子类对象时，先构造父类，再构造子类；销毁时相反（先子类后父类）。**

```cpp
class Animal {
public:
    Animal() { cout << "构造 Animal" << endl; }
    ~Animal() { cout << "析构 Animal" << endl; }
};
class Dog : public Animal {
public:
    Dog() { cout << "构造 Dog" << endl; }
    ~Dog() { cout << "析构 Dog" << endl; }
};
int main() {
    Dog d;
    return 0;
}
// 输出顺序：
// 构造 Animal → 构造 Dog → 析构 Dog → 析构 Animal
```

**马上动手（练习 1）**：定义 `Vehicle`（车：品牌 brand，启动方法 start）和子类 `Car`（额外有后备箱容量 trunkSize），演示继承和构造顺序。

<details><summary>点开看参考答案</summary>

```cpp
#include <iostream>
#include <string>
using namespace std;

class Vehicle {
protected:
    string brand;
public:
    Vehicle(string b) : brand(b) { cout << "构造 Vehicle" << endl; }
    void start() { cout << brand << " 启动了" << endl; }
};

class Car : public Vehicle {
private:
    int trunkSize;
public:
    Car(string b, int t) : Vehicle(b), trunkSize(t) {
        cout << "构造 Car" << endl;
    }
    void showTrunk() { cout << brand << " 后备箱 " << trunkSize << "L" << endl; }
};

int main() {
    Car c("Tesla", 500);
    c.start();
    c.showTrunk();
    return 0;
}
```
</details>

---

## 第 3 步：方法重写（override）

子类可以**重写**父类的方法，改成自己的版本：

```cpp
class Animal {
public:
    void speak() { cout << "动物发出声音" << endl; }
};

class Dog : public Animal {
public:
    void speak() { cout << "汪汪汪！" << endl; }   // 重写
};
```

```cpp
Dog d("旺财");
d.speak();     // 输出"汪汪汪！"（调用的是 Dog 自己的版本）
```

**但这里有个大坑**——如果通过**父类指针**调用呢？

```cpp
Animal *a = new Dog("旺财");
a->speak();    // ❌ 输出"动物发出声音"！（因为 speak 不是虚函数）
```

这就要引出今天的重头戏：**多态**。

---

## 第 4 步：多态——虚函数（virtual）

### 4.1 问题场景

假设有一个"动物列表"，想让每只动物都"叫一声"。用父类指针数组来统一管理：

```cpp
Animal *animals[2];
animals[0] = new Dog("小黑");
animals[1] = new Cat("小橘");
```

我们希望能统一写 `animals[i]->speak()`，让狗叫狗声、猫叫猫声。**不写 virtual 时做不到**（调用的都是 Animal 版本）。

> 🗣️ 大白话：多态 = 同一个"播放"按钮，MP3 放音乐、电视放画面、手机放视频——**同一个动作，不同设备表现不同**。C++ 里就是同一个 `speak()`，狗叫狗声、猫叫猫声。

### 4.2 virtual 解决

在父类方法前加 `virtual`，子类重写时加 `override`：

```cpp
class Animal {
public:
    virtual void speak() {           // virtual：允许子类重写并实现多态
        cout << "动物发出声音" << endl;
    }
};

class Dog : public Animal {
public:
    void speak() override {          // override：明确表示"我重写了父类方法"
        cout << "汪汪汪！" << endl;
    }
};

class Cat : public Animal {
public:
    void speak() override {
        cout << "喵喵喵～" << endl;
    }
};
```

```cpp
Animal *a1 = new Dog("小黑");
Animal *a2 = new Cat("小橘");
a1->speak();   // 汪汪汪！（多态：按"真实类型"调用）
a2->speak();   // 喵喵喵～
delete a1;
delete a2;
```

**多态的精髓一句话**：**用父类指针调用方法，执行的是"对象真实类型"的版本。**

- 不加 `virtual`：编译时按"指针类型"（Animal）决定 → 调 Animal 版
- 加了 `virtual`：运行时按"对象实际类型"（Dog/Cat）决定 → 调对应版本

![多态：同一个 speak()，狗叫狗声、猫叫猫声](demos/demo_polymorphism.gif)
### 4.3 虚析构函数（重要！）

**如果父类析构函数不是虚的，通过父类指针 delete 子类对象时，子类的析构函数不会执行！**

```cpp
class Animal {
public:
    virtual ~Animal() {}   // ✅ 父类析构加 virtual
};

Animal *a = new Dog("小黑");
delete a;    // 不写 virtual：只调 Animal 析构 → Dog 里 new 的内存泄漏！
             // 写了 virtual：先调 Dog 析构，再调 Animal 析构 ✅
```

**规则**：只要类里有虚函数，析构函数就加 `virtual`。这是 C++ 最经典的内存安全规范之一。

**必做调试**：在第 4.2 的代码里，给 `a1->speak()` 打断点，Step Into 进入，观察它进入的是 Dog 的 speak 而不是 Animal 的——**亲眼见证多态**。

**马上动手（练习 2）**：设计 `Shape`（形状，虚函数 area）→ `Rectangle`（宽高）和 `Circle`（半径），用父类指针数组分别计算面积。

<details><summary>点开看参考答案</summary>

```cpp
#include <iostream>
using namespace std;

class Shape {
public:
    virtual double area() { return 0; }
    virtual ~Shape() {}
};

class Rectangle : public Shape {
private:
    double w, h;
public:
    Rectangle(double w_, double h_) : w(w_), h(h_) {}
    double area() override { return w * h; }
};

class Circle : public Shape {
private:
    double r;
public:
    Circle(double r_) : r(r_) {}
    double area() override { return 3.14159 * r * r; }
};

int main() {
    Shape *shapes[2];
    shapes[0] = new Rectangle(3, 4);
    shapes[1] = new Circle(5);

    for (int i = 0; i < 2; i++) {
        cout << "面积：" << shapes[i]->area() << endl;
        delete shapes[i];
    }
    return 0;
}
```
</details>

---

## 第 5 步：纯虚函数与抽象类

### 5.1 问题

`Animal::speak()` 里输出"动物发出声音"其实很尴尬——现实中"动物"是一个抽象概念，没有哪种动物真的这么叫。更合理的做法是：**父类只规定"必须有 speak()"，但不实现，强制子类实现**。

### 5.2 纯虚函数

在函数声明后面加 `= 0`：

```cpp
class Animal {
public:
    virtual void speak() = 0;    // 纯虚函数：只声明，不实现
    virtual ~Animal() {}
};
```

**后果：**
1. `Animal` 变成**抽象类**，**不能创建对象**：`Animal a;` → 编译错误
2. **子类必须实现 `speak()`**，否则子类也是抽象类

```cpp
class Dog : public Animal {
public:
    void speak() override { cout << "汪汪汪" << endl; }   // 必须实现
};
```

### 5.3 为什么有用？

它定义了一个**"标准接口"**：任何 Animal 的子孙，都保证能 `speak()`。写通用代码时就不用关心具体是谁：

```cpp
void makeAllSpeak(Animal *list[], int n) {
    for (int i = 0; i < n; i++) {
        list[i]->speak();     // 不管具体是狗是猫，一定能 speak
    }
}
```

**马上动手（练习 3）**：把第 4.2 的 Animal 改成抽象类（speak 变纯虚），确认 `Animal a;` 会编译报错，然后正常使用 Dog/Cat。

<details><summary>点开看答案</summary>

```cpp
#include <iostream>
using namespace std;

class Animal {
public:
    virtual void speak() = 0;    // 纯虚函数
    virtual ~Animal() {}
};

class Dog : public Animal {
public:
    void speak() override { cout << "汪汪汪" << endl; }
};
class Cat : public Animal {
public:
    void speak() override { cout << "喵喵喵" << endl; }
};

int main() {
    // Animal a;              // ❌ 抽象类不能实例化
    Animal *list[2] = { new Dog(), new Cat() };
    for (int i = 0; i < 2; i++) {
        list[i]->speak();
        delete list[i];
    }
    return 0;
}
```
</details>

---

## 第 6 步：运算符重载——让自定义类型支持 +、<<

**问题**：定义一个分数类型后，`f1 + f2` 能直接用吗？

```cpp
struct Fraction {
    int top;      // 分子
    int bottom;   // 分母
};
Fraction f1{1, 2}, f2{1, 3};
// Fraction f3 = f1 + f2;   // ❌ 编译错误：不会加法
```

**运算符重载**就是教 C++ "这个类型怎么用 +"：

```cpp
struct Fraction {
    int top;
    int bottom;
    Fraction(int t, int b) : top(t), bottom(b) {}
};

// 重载 +
Fraction operator+(const Fraction &a, const Fraction &b) {
    return Fraction(
        a.top * b.bottom + b.top * a.bottom,   // 通分后的分子
        a.bottom * b.bottom                    // 通分后的分母
    );
}

// 重载 << （让 cout 能直接输出分数）
ostream &operator<<(ostream &out, const Fraction &f) {
    out << f.top << "/" << f.bottom;
    return out;
}
```

```cpp
Fraction f1(1, 2), f2(1, 3);
Fraction f3 = f1 + f2;
cout << f1 << " + " << f2 << " = " << f3 << endl;
// 输出：1/2 + 1/3 = 5/6
```

**要点：**
- `operator+` 的写法：`返回类型 operator符号(参数)`
- 参数用 `const &` 避免拷贝、保证不改原对象
- `operator<<` 第一个参数必须是 `ostream &`，返回它才能连续输出

> 运算符重载是"锦上添花"的能力，今天先会用、能看懂即可，不用深挖。

---

## 第 7 步：STL 三件套——vector / sort / map

STL（Standard Template Library）是 C++ 自带的"工具库"，里面最常用的三样，能让你的代码量减半。

> 🗣️ 大白话：vector 像**会自己变长的抽屉柜**——放满了就自动加一层，你永远不用操心"会不会挤不下"。

### 7.1 vector：会自动扩容的"智能数组"

**为什么需要它？** 普通数组大小固定、可能越界、不能随便增删。vector 全部搞定。

```cpp
#include <vector>

vector<int> nums;            // 一个空的"整数动态数组"
nums.push_back(30);          // 尾部添加
nums.push_back(10);
nums.push_back(20);

nums.size();                 // 元素个数：3
nums[0];                     // 按下标访问：30（和数组一样）
nums[0] = 99;                // 修改
nums.erase(nums.begin());    // 删除第一个元素
```

**遍历（两种方式）：**

```cpp
// 方式 1：传统下标
for (size_t i = 0; i < nums.size(); i++) {
    cout << nums[i] << " ";
}

// 方式 2：范围 for（C++11 起，最推荐）
for (int v : nums) {
    cout << v << " ";
}
```

**range-based for 是神器**：`for (类型 变量 : 容器)` 自动从头到尾遍历，不用管下标。

![vector：push_back 逐个加入尾部](demos/demo_vector.gif)
### 7.2 sort：一行排序

```cpp
#include <algorithm>

vector<int> nums = {30, 10, 20, 50, 40};

sort(nums.begin(), nums.end());          // 从小到大
sort(nums.rbegin(), nums.rend());        // 从大到小
```

`begin()` 是第一个元素，`end()` 是"最后一个的后面"（迭代器概念，先记住用法）。

### 7.3 map：键值对"字典"

```cpp
#include <map>

map<string, int> scores;
scores["小明"] = 90;       // 键：小明，值：90
scores["小红"] = 95;
scores["小明"];            // 取值：90

// 遍历（kv.first 是键，kv.second 是值）
for (const auto &kv : scores) {
    cout << kv.first << "=" << kv.second << " ";
}
```

**`auto`**：让编译器自动推断类型，写起来省事。`const auto &kv` = "kv 是自动推断类型的只读引用"。

![map：键值对存储，按键查值](demos/demo_map.gif)
### 7.4 综合小例子

```cpp
#include <iostream>
#include <vector>
#include <algorithm>
using namespace std;

int main() {
    vector<int> nums = {30, 10, 20, 50, 40};
    sort(nums.begin(), nums.end());       // 排序
    for (int v : nums) cout << v << " ";  // 10 20 30 40 50
    cout << endl;

    nums.push_back(25);                   // 动态加一个
    cout << "现在有 " << nums.size() << " 个数" << endl;
    return 0;
}
```

**马上动手（练习 4）**：输入若干个整数（以 -1 结束）存入 vector，去掉重复后从大到小输出。
提示：先 sort，再用 `unique` 配合 `erase` 去重（见答案）。

<details><summary>点开看参考答案</summary>

```cpp
#include <iostream>
#include <vector>
#include <algorithm>
using namespace std;

int main() {
    vector<int> nums;
    int x;
    while (cin >> x && x != -1) nums.push_back(x);

    sort(nums.begin(), nums.end());                                   // 先排序
    nums.erase(unique(nums.begin(), nums.end()), nums.end());         // 去重

    sort(nums.rbegin(), nums.rend());                                 // 降序
    for (int v : nums) cout << v << " ";
    cout << endl;
    return 0;
}
```
</details>

---

## 🏋️ 分级练习

**练习 A（基础）：员工工资体系（多态）**
设计基类 `Employee`（姓名、基础工资，虚函数 salary），派生 `Manager`（加奖金）和 `Salesman`（加提成），用父类指针数组输出每人工资。

<details><summary>点开看答案</summary>

```cpp
#include <iostream>
#include <vector>
using namespace std;

class Employee {
protected:
    string name;
    double base;
public:
    Employee(string n, double b) : name(n), base(b) {}
    virtual double salary() { return base; }
    virtual ~Employee() {}
};

class Manager : public Employee {
private:
    double bonus;
public:
    Manager(string n, double b, double bo) : Employee(n, b), bonus(bo) {}
    double salary() override { return base + bonus; }
};

class Salesman : public Employee {
private:
    double commission;
public:
    Salesman(string n, double b, double c) : Employee(n, b), commission(c) {}
    double salary() override { return base + commission; }
};

int main() {
    vector<Employee*> staff;
    staff.push_back(new Manager("张经理", 10000, 5000));
    staff.push_back(new Salesman("李销售", 3000, 8000));

    for (Employee *e : staff) {
        cout << e->salary() << endl;   // 15000 / 11000（多态！）
        delete e;
    }
    return 0;
}
```
</details>

**练习 B（进阶）：vector 管理学生**
定义一个 `Student` 结构体（姓名、成绩），用 vector 存 3 个学生，按成绩从高到低排序输出。

<details><summary>点开看答案</summary>

```cpp
#include <iostream>
#include <vector>
#include <algorithm>
#include <string>
using namespace std;

struct Student {
    string name;
    double score;
};

int main() {
    vector<Student> stu = {
        {"小明", 88}, {"小红", 95}, {"小刚", 72}
    };

    sort(stu.begin(), stu.end(), [](const Student &a, const Student &b) {
        return a.score > b.score;      // 按成绩降序
    });

    for (const Student &s : stu) {
        cout << s.name << " " << s.score << endl;
    }
    return 0;
}
```
</details>

**练习 C（挑战）：词频统计（map）**
输入一句英文（getline 读整行），统计每个单词出现次数并输出。提示：用 `stringstream` 把句子按空格拆成单词。

<details><summary>点开看答案</summary>

```cpp
#include <iostream>
#include <sstream>
#include <string>
#include <map>
using namespace std;

int main() {
    string line;
    cout << "输入英文句子：";
    getline(cin, line);

    map<string, int> freq;
    stringstream ss(line);        // 把字符串当"输入流"
    string word;
    while (ss >> word) {          // 按空格拆出一个个单词
        freq[word]++;
    }

    for (const auto &kv : freq) {
        cout << kv.first << " : " << kv.second << endl;
    }
    return 0;
}
```
</details>

---

## 📝 自测（10 题）

1. 继承的语法是什么？子类构造函数为什么要先调用父类构造函数？
2. protected 和 private 的区别？
3. 创建子类对象时，构造和析构的顺序？
4. 虚函数的作用？不加 virtual 会怎样？
5. `override` 关键字有什么用？
6. 什么是抽象类？能创建对象吗？
7. 为什么父类析构函数要加 virtual？
8. vector 和普通数组比，最大的优势是什么？
9. `for (int v : nums)` 这种循环叫什么？适合什么场景？
10. map 里的 `kv.first` 和 `kv.second` 分别是什么？

<details><summary>点开看答案</summary>

1. `class 子类 : public 父类`；要先初始化父类部分的成员。
2. private 子类也不能访问，protected 子类可以访问（外部都不行）。
3. 先父类后子类构造；销毁相反，先子类后父类。
4. 实现多态；不加 virtual，父类指针调用的是父类版本。
5. 明确声明"重写父类方法"，编译器帮忙检查写没写错。
6. 含纯虚函数的类；不能创建对象，只能被继承。
7. 否则通过父类指针 delete 子类对象时，子类析构不会执行，可能内存泄漏。
8. 自动扩容、自动管理内存、配合 sort 等算法。
9. 范围 for（range-based for）；遍历容器的每个元素。
10. 键和值。
</details>

---

## ⚠️ 今日坑点汇总

| 坑 | 说明 | 正确做法 |
| --- | --- | --- |
| 忘写 virtual | 多态失效，调父类版本 | 父类方法加 virtual |
| 父类析构不加 virtual | delete 时子类析构不执行 | 有虚函数就加虚析构 |
| 抽象类实例化 | `Animal a;` 编译错误 | 抽象类只能被继承 |
| 子类忘实现纯虚函数 | 子类也是抽象类 | 子类必须实现 |
| vector 越界 | `nums[5]` 越界访问 | 用 `at()` 或先判断 size |
| sort 忘 `#include <algorithm>` | 编译报错 | 用 sort 记得包含头文件 |

---

## 🎯 今日总结 + 明天预告

今天你拿到了三张王牌：**继承**复用代码、**多态**统一处理不同类型、**STL** 让写代码又快又稳。到这里，C++ 的核心语法你已经全部学完了。

**明天（第 7 天）学什么？** 最后一天综合实战：**文件读写 + 学生成绩管理系统**，把 7 天所学全部串成一个大项目，做完它，这 7 天就圆满了。

**睡前打卡：** 用 vector + sort 重写"第 5 天的学生管理器"（把固定数组换成 vector），体会工具带来的轻松感。
