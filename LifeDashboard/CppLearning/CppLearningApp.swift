import SwiftUI

/// C++ 学习板块的标签页。
enum AppTab: Hashable {
    case learn, code, glossary, pdf
}

/// 嵌入 Galaxy 的 C++ 七天学习主界面（学习 / 代码 / 速查 / 方案）。
struct CppRootTabView: View {
    @State private var selection: AppTab = .learn

    var body: some View {
        TabView(selection: $selection) {
            HomeView(selectedTab: $selection)
                .tabItem { Label("学习", systemImage: "book.fill") }
                .tag(AppTab.learn)

            CodeSamplesView()
                .tabItem { Label("代码", systemImage: "curlybraces.square") }
                .tag(AppTab.code)

            GlossaryView()
                .tabItem { Label("速查", systemImage: "character.book.closed.fill") }
                .tag(AppTab.glossary)

            PlanView()
                .tabItem { Label("方案", systemImage: "doc.richtext.fill") }
                .tag(AppTab.pdf)
        }
    }
}

/// Galaxy 仪表盘「C++学习」卡片进入的完整学习板块。
struct CppLearningSectionView: View {
    @StateObject private var store = AppStore()

    var body: some View {
        CppRootTabView()
            .environmentObject(store)
    }
}
