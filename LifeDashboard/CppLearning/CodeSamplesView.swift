import SwiftUI

struct CodeSample: Identifiable {
    let id: Int
    let fileName: String
    let day: Int
    let title: String
    let summary: String

    static func all(for track: Track) -> [CodeSample] {
        let base: [CodeSample] = [
            CodeSample(id: 1, fileName: "day01_hello.cpp", day: 1, title: "Hello World 与变量", summary: "程序结构、cout/cin、5 种基本类型、运算符"),
            CodeSample(id: 2, fileName: "day02_flow.cpp", day: 2, title: "流程控制与循环", summary: "if/switch、for/while、break/continue"),
            CodeSample(id: 3, fileName: "day03_func_array.cpp", day: 3, title: "函数与数组字符串", summary: "函数、递归、数组、冒泡排序、string"),
            CodeSample(id: 4, fileName: "day04_pointers.cpp", day: 4, title: "指针与动态内存", summary: "地址、指针、引用、new/delete"),
            CodeSample(id: 5, fileName: "day05_class.cpp", day: 5, title: "类与对象", summary: "class、封装、构造/析构、this、静态成员"),
            CodeSample(id: 6, fileName: "day06_oop_stl.cpp", day: 6, title: "继承多态与 STL", summary: "继承、虚函数、vector、sort、map"),
            CodeSample(id: 7, fileName: "day07_final_project.cpp", day: 7, title: "综合项目", summary: "学生成绩管理系统（增删改查 + 文件保存）")
        ]
        _ = track // 两个板块共用同一套 C++ 示例代码
        return base
    }
}

struct CodeSamplesView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            List(CodeSample.all(for: store.track)) { sample in
                NavigationLink {
                    CodeSampleDetail(sample: sample, track: store.track, store: store)
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("\(sample.title)")
                            .font(.headline)
                        Text("第 \(sample.day) 天 · \(sample.summary)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("代码实验室（\(store.track.shortName)）")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CodeSampleDetail: View {
    let sample: CodeSample
    let track: Track
    let store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 1)
                    Text("这是学习用示例代码。iOS 上无法直接编译运行 C++，请把代码复制到电脑的 \(track.shortName) 中运行。")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }

                CodeBlockView(language: "cpp", code: code)
            }
            .padding()
        }
        .navigationTitle(sample.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var code: String {
        store.loadText(sample.fileName, track: track) ?? "// 无法读取文件：\(sample.fileName)"
    }
}
