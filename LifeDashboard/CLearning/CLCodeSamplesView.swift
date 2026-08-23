import SwiftUI

struct CLCodeSample: Identifiable {
    let id: Int
    let fileName: String
    let day: Int
    let title: String
    let summary: String

    static func all(for track: CLTrack) -> [CLCodeSample] {
        let base: [CLCodeSample] = [
            CLCodeSample(id: 1, fileName: "day01_hello.c", day: 1, title: "Hello World 与变量", summary: "程序结构、printf/scanf、基本类型、运算符"),
            CLCodeSample(id: 2, fileName: "day02_flow.c", day: 2, title: "流程控制与循环", summary: "if/switch、for/while、break/continue"),
            CLCodeSample(id: 3, fileName: "day03_func_array.c", day: 3, title: "函数与数组字符串", summary: "函数、递归、数组、字符数组与字符串函数"),
            CLCodeSample(id: 4, fileName: "day04_pointers.c", day: 4, title: "指针与动态内存", summary: "地址、指针、malloc/free、数组与指针"),
            CLCodeSample(id: 5, fileName: "day05_struct.c", day: 5, title: "结构体与枚举", summary: "struct、typedef、枚举、结构体指针"),
            CLCodeSample(id: 6, fileName: "day06_linkedlist.c", day: 6, title: "链表、文件与预处理", summary: "单链表、文件读写、宏定义"),
            CLCodeSample(id: 7, fileName: "day07_final_project.c", day: 7, title: "综合项目", summary: "学生成绩管理系统（增删改查 + 文件保存）")
        ]
        _ = track // 两个板块共用同一套 C 示例代码
        return base
    }
}

struct CLCodeSamplesView: View {
    @EnvironmentObject private var store: CLAppStore

    var body: some View {
        NavigationStack {
            List(CLCodeSample.all(for: store.track)) { sample in
                NavigationLink {
                    CLCodeSampleDetail(sample: sample, track: store.track)
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

struct CLCodeSampleDetail: View {
    let sample: CLCodeSample
    let track: CLTrack
    @EnvironmentObject private var store: CLAppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 1)
                    Text("这是学习用示例代码。iOS 上无法直接编译运行 C，请把代码复制到电脑的 \(track.shortName) 中运行。")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }

                CLCodeBlockView(language: "c", code: code)
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
