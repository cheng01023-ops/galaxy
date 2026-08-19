import SwiftUI
import Charts

/// 近 7 天步数趋势折线图。
struct StepTrendCard: View {
    @EnvironmentObject private var healthService: HealthService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("近 7 天步数", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)

            if healthService.last7DaysSteps.isEmpty {
                Text("暂无步数数据")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 140)
            } else {
                Chart(healthService.last7DaysSteps) { item in
                    LineMark(
                        x: .value("日期", item.date, unit: .day),
                        y: .value("步数", item.steps)
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("日期", item.date, unit: .day),
                        y: .value("步数", item.steps)
                    )
                    .symbolSize(24)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    }
                }
                .frame(height: 160)
            }
        }
        .cardStyle()
    }
}
