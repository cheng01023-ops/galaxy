import SwiftUI

/// 完整学习方案：Xcode 板块显示 PDF，VSCode 板块渲染 README 总览
struct CalcPlanView: View {
    @EnvironmentObject private var store: CalcAppStore

    var body: some View {
        NavigationStack {
            ScrollView {
                CalcMarkdownView(blocks: planBlocks, track: store.track)
                    .padding()
            }
            .navigationTitle("完整学习方案（\(store.track.shortName)）")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var planBlocks: [CalcBlock] {
        CalcMarkdownParser.parse(store.loadText("README.md") ?? "")
    }
}
