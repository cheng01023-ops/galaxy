import SwiftUI

struct CalcCodeSample: Identifiable {
    let id: Int
    let fileName: String
    let day: Int
    let title: String
    let summary: String

    static func all(for track: CalcTrack) -> [CalcCodeSample] {
        let base: [CalcCodeSample] = []
        _ = track // 两个板块共用同一套 C 示例代码
        return base
    }
}

struct CalcCodeSamplesView: View {
    @EnvironmentObject private var store: CalcAppStore

    var body: some View {
        NavigationStack {
            List(CalcCodeSample.all(for: store.track)) { sample in
                NavigationLink {
                    CalcCodeSampleDetail(sample: sample, track: store.track)
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

struct CalcCodeSampleDetail: View {
    let sample: CalcCodeSample
    let track: CalcTrack
    @EnvironmentObject private var store: CalcAppStore

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

                CalcCodeBlockView(language: "c", code: code)
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
