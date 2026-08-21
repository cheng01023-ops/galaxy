import Charts
import SwiftUI

/// 近 7 天步数详情页。
struct StepTrendDetailView: View {
    @EnvironmentObject private var healthService: HealthService

    private var totalSteps: Double {
        healthService.last7DaysSteps.reduce(0) { $0 + $1.steps }
    }

    private var averageSteps: Double {
        healthService.last7DaysSteps.isEmpty ? 0 : totalSteps / Double(healthService.last7DaysSteps.count)
    }

    private var bestDay: DailySteps? {
        healthService.last7DaysSteps.max { $0.steps < $1.steps }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                todayCard
                chartCard
                statsGrid
                dayList
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("步数详情")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 今日步数

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日步数")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(Formatters.number(healthService.summary.stepCount))
                .font(.system(size: 48, weight: .bold, design: .rounded))
            Text("近 7 天累计 \(Formatters.number(totalSteps)) 步")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - 7 天图表

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("近 7 天趋势")
                .font(.headline)

            if healthService.last7DaysSteps.isEmpty {
                Text("暂无步数数据")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                Chart(healthService.last7DaysSteps) { item in
                    LineMark(
                        x: .value("日期", item.date, unit: .day),
                        y: .value("步数", item.steps)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.green)

                    PointMark(
                        x: .value("日期", item.date, unit: .day),
                        y: .value("步数", item.steps)
                    )
                    .foregroundStyle(.green)
                    .symbolSize(28)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    }
                }
                .frame(height: 200)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - 统计

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            statCell(title: "7 天总计", value: Formatters.number(totalSteps), unit: "步")
            statCell(title: "日均步数", value: Formatters.number(averageSteps), unit: "步")
            statCell(title: "最好一天", value: bestDay.map { Formatters.number($0.steps) } ?? "--", unit: "步")
            statCell(title: "最好日期", value: bestDay.map { Formatters.shortDate.string(from: $0.date) } ?? "--", unit: "")
        }
    }

    private func statCell(title: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.title2.weight(.bold))
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - 每日明细

    private var dayList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("每日明细")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(Array(healthService.last7DaysSteps.reversed().enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 12) {
                        Text(Formatters.weekday.string(from: item.date))
                            .font(.subheadline)
                            .frame(width: 44, alignment: .leading)

                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.green.opacity(0.75))
                                .frame(width: max(8, geo.size.width * CGFloat(item.steps / max(1, bestDay?.steps ?? 1))))
                        }
                        .frame(height: 16)

                        Text(Formatters.number(item.steps))
                            .font(.subheadline.monospacedDigit())
                            .frame(width: 72, alignment: .trailing)
                    }
                    .padding(.vertical, 10)

                    if index < healthService.last7DaysSteps.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
