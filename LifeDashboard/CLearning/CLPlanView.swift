import SwiftUI

/// 完整学习方案：Xcode 板块显示 PDF，VSCode 板块渲染 README 总览
struct CLPlanView: View {
    @EnvironmentObject private var store: CLAppStore

    var body: some View {
        NavigationStack {
            ScrollView {
                CLMarkdownView(blocks: planBlocks, track: store.track)
                    .padding()
            }
            .navigationTitle("完整学习方案（\(store.track.shortName)）")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var planBlocks: [CLBlock] {
        CLMarkdownParser.parse(store.loadText("README.md") ?? "")
    }
}
