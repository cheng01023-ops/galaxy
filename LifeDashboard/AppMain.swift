import SwiftUI
import SwiftData

@main
struct LifeDashboardApp: App {
    @StateObject private var healthService = HealthService()
    @StateObject private var weatherService = WeatherService()
    @StateObject private var pomodoroViewModel = PomodoroViewModel()

    /// SwiftData 模型容器，包含待办与专注记录。
    private let modelContainer: ModelContainer = {
        let schema = Schema([
            TodoItem.self,
            FocusSession.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("无法创建 SwiftData 容器：\(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(healthService)
                .environmentObject(weatherService)
                .environmentObject(pomodoroViewModel)
                .modelContainer(modelContainer)
        }
    }
}
