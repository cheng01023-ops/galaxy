import SwiftUI

struct GlossaryView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            ScrollView {
                MarkdownView(blocks: blocks, track: store.track)
                    .padding()
            }
            .navigationTitle("C++ 术语速查（\(store.track.shortName)）")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var blocks: [Block] {
        MarkdownParser.parse(store.loadText("C++术语速查.md") ?? "")
    }
}
