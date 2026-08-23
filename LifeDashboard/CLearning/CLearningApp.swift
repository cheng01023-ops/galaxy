import SwiftUI

/// C 语言学习板块的标签页。
enum CLAppTab: Hashable {
    case learn, code, glossary, pdf
}

/// 嵌入 Galaxy 的 C 语言七天学习主界面（学习 / 代码 / 速查 / 方案）。
struct CLRootTabView: View {
    @State private var selection: CLAppTab = .learn

    var body: some View {
        TabView(selection: $selection) {
            CLHomeView(selectedTab: $selection)
                .tabItem { Label("学习", systemImage: "book.fill") }
                .tag(CLAppTab.learn)

            CLCodeSamplesView()
                .tabItem { Label("代码", systemImage: "curlybraces.square") }
                .tag(CLAppTab.code)

            CLGlossaryView()
                .tabItem { Label("速查", systemImage: "character.book.closed.fill") }
                .tag(CLAppTab.glossary)

            CLPlanView()
                .tabItem { Label("方案", systemImage: "doc.richtext.fill") }
                .tag(CLAppTab.pdf)
        }
    }
}

/// Galaxy 仪表盘「C语言学习」卡片进入的完整学习板块。
struct CLearningSectionView: View {
    @StateObject private var store = CLAppStore.shared

    var body: some View {
        CLRootTabView()
            .environmentObject(store)
            .toolbar(.hidden, for: .tabBar)
    }
}
