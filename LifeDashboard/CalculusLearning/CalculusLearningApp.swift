import SwiftUI

/// 微积分学习板块的标签页。
enum CalcAppTab: Hashable {
    case learn, code, glossary, pdf
}

/// 嵌入 Galaxy 的微积分五天课主界面（学习 / 代码 / 速查 / 方案）。
struct CalcRootTabView: View {
    @State private var selection: CalcAppTab = .learn

    var body: some View {
        TabView(selection: $selection) {
            CalcHomeView(selectedTab: $selection)
                .tabItem { Label("学习", systemImage: "book.fill") }
                .tag(CalcAppTab.learn)

            CalcCodeSamplesView()
                .tabItem { Label("代码", systemImage: "curlybraces.square") }
                .tag(CalcAppTab.code)

            CalcGlossaryView()
                .tabItem { Label("速查", systemImage: "character.book.closed.fill") }
                .tag(CalcAppTab.glossary)

            CalcPlanView()
                .tabItem { Label("方案", systemImage: "doc.richtext.fill") }
                .tag(CalcAppTab.pdf)
        }
    }
}

/// Galaxy 仪表盘「微积分学习」卡片进入的完整学习板块。
struct CalculusSectionView: View {
    @StateObject private var store = CalcAppStore.shared

    var body: some View {
        CalcRootTabView()
            .environmentObject(store)
            .toolbar(.hidden, for: .tabBar)
    }
}
