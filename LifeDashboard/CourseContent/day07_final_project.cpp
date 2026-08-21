// ============================================================
// 第 7 天：综合项目 —— 学生成绩管理系统
// 这是验收整个星期学习成果的项目，要求：
//   ✔ 会写类/结构体、会用 vector、会写函数
//   ✔ 会循环、分支、字符串处理
//   ✔ 会用 fstream 读写文件（数据保存到 students.txt）
//   ✔ 会用 sort 排序
// 使用方法：内容复制到 Xcode 的 main.cpp，Cmd + R 运行
// 项目运行后按菜单操作，退出时会自动保存到文件。
// ============================================================

#include <iostream>
#include <fstream>     // 文件读写：ifstream / ofstream
#include <string>
#include <vector>
#include <algorithm>
#include <iomanip>     // setw 控制对齐
using namespace std;

// ---------- 1. 学生结构体 ----------
struct Student {
    string id;        // 学号
    string name;      // 姓名
    double chinese;   // 语文
    double math;      // 数学
    double english;   // 英语

    // 计算总分
    double total() const {
        return chinese + math + english;
    }
};

// ---------- 2. 全局数据 ----------
vector<Student> students;
const string FILE_NAME = "students.txt";

// ---------- 3. 文件操作 ----------
void saveToFile() {
    ofstream out(FILE_NAME);       // 打开文件写
    if (!out) {
        cout << "保存失败：无法打开文件 " << FILE_NAME << endl;
        return;
    }
    out << students.size() << endl;             // 第一行写人数
    for (const Student &s : students) {
        out << s.id << " " << s.name << " "
            << s.chinese << " " << s.math << " " << s.english << endl;
    }
    out.close();
    cout << "已保存 " << students.size() << " 条记录到 " << FILE_NAME << endl;
}

void loadFromFile() {
    ifstream in(FILE_NAME);        // 打开文件读
    if (!in) {
        cout << "没有找到存档文件，从空名单开始。" << endl;
        return;
    }
    int count = 0;
    in >> count;
    students.clear();
    for (int i = 0; i < count; i++) {
        Student s;
        in >> s.id >> s.name >> s.chinese >> s.math >> s.english;
        students.push_back(s);
    }
    in.close();
    cout << "已从文件载入 " << students.size() << " 条记录。" << endl;
}

// ---------- 4. 业务功能 ----------
bool idExists(const string &id) {
    for (const Student &s : students) {
        if (s.id == id) return true;
    }
    return false;
}

void addStudent() {
    Student s;
    cout << "请输入学号：";
    cin >> s.id;
    if (idExists(s.id)) {
        cout << "该学号已存在，添加失败！" << endl;
        return;
    }
    cout << "请输入姓名：";
    cin >> s.name;
    cout << "请输入语文成绩：";
    cin >> s.chinese;
    cout << "请输入数学成绩：";
    cin >> s.math;
    cout << "请输入英语成绩：";
    cin >> s.english;

    students.push_back(s);
    cout << "添加成功！" << endl;
}

void showAll() {
    if (students.empty()) {
        cout << "目前没有学生记录。" << endl;
        return;
    }
    cout << "------------------------------------------------------------" << endl;
    cout << left << setw(10) << "学号" << setw(10) << "姓名"
         << setw(8) << "语文" << setw(8) << "数学"
         << setw(8) << "英语" << setw(8) << "总分" << endl;
    cout << "------------------------------------------------------------" << endl;
    for (const Student &s : students) {
        cout << left << setw(10) << s.id << setw(10) << s.name
             << setw(8) << s.chinese << setw(8) << s.math
             << setw(8) << s.english << setw(8) << s.total() << endl;
    }
    cout << "------------------------------------------------------------" << endl;
}

int findIndexById(const string &id) {
    for (size_t i = 0; i < students.size(); i++) {
        if (students[i].id == id) return (int)i;
    }
    return -1;
}

void findStudent() {
    string id;
    cout << "请输入要查找的学号：";
    cin >> id;
    int idx = findIndexById(id);
    if (idx == -1) {
        cout << "没有找到该学号的学生。" << endl;
        return;
    }
    Student &s = students[idx];
    cout << "姓名：" << s.name
         << "，语文：" << s.chinese
         << "，数学：" << s.math
         << "，英语：" << s.english
         << "，总分：" << s.total() << endl;
}

void modifyStudent() {
    string id;
    cout << "请输入要修改的学号：";
    cin >> id;
    int idx = findIndexById(id);
    if (idx == -1) {
        cout << "没有找到该学号的学生。" << endl;
        return;
    }
    Student &s = students[idx];
    cout << "当前成绩：语文 " << s.chinese << "，数学 " << s.math
         << "，英语 " << s.english << endl;
    cout << "请输入新的语文成绩：";
    cin >> s.chinese;
    cout << "请输入新的数学成绩：";
    cin >> s.math;
    cout << "请输入新的英语成绩：";
    cin >> s.english;
    cout << "修改成功！" << endl;
}

void deleteStudent() {
    string id;
    cout << "请输入要删除的学号：";
    cin >> id;
    int idx = findIndexById(id);
    if (idx == -1) {
        cout << "没有找到该学号的学生。" << endl;
        return;
    }
    cout << "确定要删除 " << students[idx].name << " 吗？(y/n)：";
    char ch;
    cin >> ch;
    if (ch == 'y' || ch == 'Y') {
        students.erase(students.begin() + idx);   // vector 删除
        cout << "已删除。" << endl;
    } else {
        cout << "已取消删除。" << endl;
    }
}

void sortByTotal() {
    // 按总分从高到低排序
    sort(students.begin(), students.end(),
         [](const Student &a, const Student &b) {
             return a.total() > b.total();
         });
    cout << "已按总分从高到低排序。" << endl;
    showAll();
}

// ---------- 5. 主菜单 ----------
void showMenu() {
    cout << "\n======== 学生成绩管理系统 ========" << endl;
    cout << "  1. 添加学生" << endl;
    cout << "  2. 显示所有学生" << endl;
    cout << "  3. 按学号查找" << endl;
    cout << "  4. 修改成绩" << endl;
    cout << "  5. 删除学生" << endl;
    cout << "  6. 按总分排序" << endl;
    cout << "  0. 保存并退出" << endl;
    cout << "=================================" << endl;
    cout << "请选择操作：";
}

int main() {
    loadFromFile();      // 启动时读取存档

    int choice = -1;
    while (choice != 0) {
        showMenu();
        cin >> choice;

        switch (choice) {
            case 1: addStudent();      break;
            case 2: showAll();         break;
            case 3: findStudent();     break;
            case 4: modifyStudent();   break;
            case 5: deleteStudent();   break;
            case 6: sortByTotal();     break;
            case 0: saveToFile();      break;
            default: cout << "无效选项，请重新输入。" << endl; break;
        }
    }

    cout << "感谢使用，再见！" << endl;
    return 0;
}
