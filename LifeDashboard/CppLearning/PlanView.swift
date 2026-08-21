import SwiftUI

/// 完整学习方案：Xcode 板块显示 PDF，VSCode 板块渲染 README 总览
struct PlanView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            if store.track == .xcode {
                PDFViewer(fileName: "C++七天学习方案.pdf", title: "完整学习方案（Xcode）", subdirectory: Track.xcode.subdirectory)
            } else {
                ScrollView {
                    MarkdownView(blocks: planBlocks, track: store.track)
                        .padding()
                }
                .navigationTitle("完整学习方案（VSCode）")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private var planBlocks: [Block] {
        MarkdownParser.parse(store.loadText("README.md") ?? "")
    }
}
