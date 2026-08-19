import SwiftUI

/// 健康摘要卡片：今日步数、昨晚睡眠、静息心率。
struct HealthSummaryCard: View {
    @EnvironmentObject private var healthService: HealthService

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("健康", systemImage: "heart.fill")
                .font(.headline)
                .foregroundStyle(.pink)

            metricRow(icon: "figure.walk", label: "今日步数",
                      value: Formatters.number(healthService.summary.stepCount), unit: "步")

            metricRow(icon: "moon.zzz.fill", label: "昨晚睡眠",
                      value: Formatters.number(healthService.summary.sleepHours), unit: "小时")

            metricRow(icon: "heart.text.square.fill", label: "静息心率",
                      value: Formatters.number(healthService.summary.restingHeartRate), unit: "次/分")

            if !healthService.isHealthDataAvailable {
                Text("模拟器无法读取 HealthKit，请在真机运行")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let error = healthService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }

    private func metricRow(icon: String, label: String, value: String, unit: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title2.weight(.semibold))
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
