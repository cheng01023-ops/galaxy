import SwiftUI

/// 仪表盘：两列圆角卡片网格。
struct DashboardView: View {
    @EnvironmentObject private var healthService: HealthService
    @EnvironmentObject private var weatherService: WeatherService

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    WeatherCard()
                    PomodoroCard()
                    HealthSummaryCard()
                    StepTrendCard()
                        .gridCellColumns(2)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("仪表盘")
            .task {
                await refresh()
            }
            .refreshable {
                await refresh()
            }
        }
    }

    private func refresh() async {
        await healthService.requestAuthorizationAndFetch()
        await weatherService.fetchWeather()
    }
}
