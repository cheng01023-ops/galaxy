import SwiftUI

struct CLGlossaryView: View {
    @EnvironmentObject private var store: CLAppStore

    var body: some View {
        NavigationStack {
            ScrollView {
                CLMarkdownView(blocks: blocks, track: store.track)
                    .padding()
            }
            .navigationTitle("C 术语速查（\(store.track.shortName)）")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var blocks: [CLBlock] {
        CLMarkdownParser.parse(store.loadText("C术语速查.md") ?? "")
    }
}
