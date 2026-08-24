import SwiftUI

struct CalcGlossaryView: View {
    @EnvironmentObject private var store: CalcAppStore

    var body: some View {
        NavigationStack {
            ScrollView {
                CalcMarkdownView(blocks: blocks, track: store.track)
                    .padding()
            }
            .navigationTitle("微积分速查")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var blocks: [CalcBlock] {
        CalcMarkdownParser.parse(store.loadText("微积分速查.md") ?? "")
    }
}
