import SwiftUI

/// 主界面：三个标签页（仪表盘、待办、统计）。
struct RootTabView: View {
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("仪表盘", systemImage: "square.grid.2x2.fill")
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
            // 首次启动时请求通知授权，并启动喝水提醒服务（用于到点弹灵动岛）。
            _ = WaterReminderService.shared
            await NotificationService.shared.requestAuthorization()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                WaterReminderService.shared.checkReminderNow()
            } else if phase == .background {
                // 离开 App 时立即结束喝水灵动岛，避免残留
                WaterReminderService.shared.endActiveLiveActivity()
            }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [TodoItem.self, FocusSession.self], inMemory: true)
}
