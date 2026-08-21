// ============================================================
// 第 4 天：指针、引用、动态内存（C++ 最难也最重要的一天！）
// 学习重点：地址 / 指针 / 解引用 / 引用 / new 与 delete / 内存泄漏
// 使用方法：内容复制到 Xcode 的 main.cpp，Cmd + R 运行
// ============================================================

#include <iostream>
using namespace std;

// ---------- 1. 用引用交换（推荐写法） ----------
void swapByRef(int &a, int &b) {      // & 表示引用：直接用原变量，不复制
    int t = a;
    a = b;
    b = t;
}

// ---------- 2. 用指针交换 ----------
void swapByPtr(int *a, int *b) {      // 传入地址
    int t = *a;                        // *a 解引用：拿到地址里的值
    *a = *b;
    *b = t;
}

// ---------- 3. 用引用参数返回多个结果 ----------
void minMax(int arr[], int n, int &minV, int &maxV) {
    minV = arr[0];
    maxV = arr[0];
    for (int i = 1; i < n; i++) {
        if (arr[i] < minV) minV = arr[i];
        if (arr[i] > maxV) maxV = arr[i];
    }
}

int main() {

    // ---------- 4. 地址是什么 ----------
    int age = 25;
    cout << "age 的值：" << age << endl;
    cout << "age 的地址：" << &age << endl;   // & 取地址符，输出一串十六进制数

    // ---------- 5. 指针：存地址的变量 ----------
    int *p = &age;        // p 指向 age
    cout << "p 存的值（就是 age 的地址）：" << p << endl;
    cout << "解引用 *p（就是 age 的值）：" << *p << endl;

    *p = 30;              // 通过指针修改 age
    cout << "改完后 age = " << age << endl;

    // ---------- 6. 空指针与野指针（重点坑点） ----------
    int *q = nullptr;     // 空指针，安全
    if (q == nullptr) {
        cout << "q 是空指针，还没指向任何地方。" << endl;
    }
    // 千万不要用未初始化的指针（野指针）：int *r; *r = 10; 会崩溃！

    // ---------- 7. 指针与数组 ----------
    int arr[] = {10, 20, 30, 40, 50};
    int *pa = arr;        // 数组名本身就是首元素地址，等价于 &arr[0]
    cout << "arr[0] 的值（用指针取）：" << *pa << endl;
    cout << "arr[1] 的值（指针+1）：" << *(pa + 1) << endl;   // 指针运算按类型大小移动

    // ---------- 8. 交换函数对比 ----------
    int x = 1, y = 2;
    swapByRef(x, y);
    cout << "swapByRef 后：x = " << x << ", y = " << y << endl;

    int m = 3, n = 4;
    swapByPtr(&m, &n);
    cout << "swapByPtr 后：m = " << m << ", n = " << n << endl;

    // ---------- 9. 引用参数返回多个结果 ----------
    int nums[] = {7, 3, 9, 1, 5};
    int minV, maxV;
    minMax(nums, 5, minV, maxV);
    cout << "最小值：" << minV << "，最大值：" << maxV << endl;

    // ---------- 10. 动态内存：new / delete ----------
    int *big = new int;        // 在堆上申请一个 int
    *big = 99;
    cout << "动态分配的 *big = " << *big << endl;
    delete big;                // 用完必须释放！否则内存泄漏
    big = nullptr;             // 释放后置空，防止"悬空指针"

    // 动态数组
    int size = 3;
    int *dyn = new int[size];
    for (int i = 0; i < size; i++) {
        dyn[i] = (i + 1) * 10;
    }
    cout << "动态数组：";
    for (int i = 0; i < size; i++) {
        cout << dyn[i] << " ";
    }
    cout << endl;
    delete[] dyn;              // 数组要用 delete[]

    return 0;
}
