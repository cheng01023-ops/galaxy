import SwiftUI

/// 主界面：三个标签页（仪表盘、待办、统计）。
struct RootTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Galaxy", systemImage: "square.grid.2x2.fill")
                }

            TodoListView()
                .tabItem {
                    Label("待办", systemImage: "checklist")
                }

            StatisticsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.xaxis")
                }
        }
        .task {
            // 首次启动时请求通知授权。
            await NotificationService.shared.requestAuthorization()
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [TodoItem.self, FocusSession.self], inMemory: true)
}
