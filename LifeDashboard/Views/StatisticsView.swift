import SwiftUI
import SwiftData
import UIKit

/// 每周小结：聚合本周步数、平均睡眠、专注总时长，并可分享为图片。
struct StatisticsView: View {
    @EnvironmentObject private var healthService: HealthService
    @Query(sort: \FocusSession.startedAt, order: .reverse) private var focusSessions: [FocusSession]

    @State private var shareImage: UIImage?

    private var weekInterval: DateInterval {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 周一为一周开始
        return calendar.dateInterval(of: .weekOfYear, for: .now)
            ?? DateInterval(start: .now, duration: 0)
    }

    private var focusSecondsThisWeek: Int {
        focusSessions
            .filter { weekInterval.contains($0.startedAt) }
            .reduce(0) { $0 + $1.durationSeconds }
    }

    private var report: WeeklyReport {
        WeeklyReport(
            weekRangeText: Formatters.weekRangeText(start: weekInterval.start, end: weekInterval.end),
            totalSteps: healthService.weekSummary.totalSteps,
            averageSleepHours: healthService.weekSummary.averageSleepHours,
            totalFocusMinutes: focusSecondsThisWeek / 60,
            isWeekComplete: Formatters.isSunday()
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if Formatters.isSunday() {
                        Label("本周报告已生成", systemImage: "checkmark.seal.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    }

                    WeeklySummaryCard(report: report)

                    Button {
                        shareImage = generateShareImage(report: report)
                    } label: {
                        Label("分享为图片", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("统计")
            .task {
                await healthService.fetchWeekSummary()
            }
            .sheet(isPresented: shareSheetBinding) {
                if let shareImage {
                    ShareSheet(activityItems: [shareImage])
                }
            }
        }
    }

    private var shareSheetBinding: Binding<Bool> {
        Binding(
            get: { shareImage != nil },
            set: { if !$0 { shareImage = nil } }
        )
    }

    /// 使用 ImageRenderer 将每周小结视图渲染为 UIImage。
    @MainActor
    private func generateShareImage(report: WeeklyReport) -> UIImage? {
        let content = WeeklyReportShareView(report: report)
            .frame(width: 360)
            .padding(20)
        let renderer = ImageRenderer(content: content)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}

/// 统计卡片（App 内展示）。
private struct WeeklySummaryCard: View {
    let report: WeeklyReport

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("本周小结", systemImage: "calendar.badge.checkmark")
                .font(.headline)

            Text(report.weekRangeText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            summaryRow(icon: "figure.walk", label: "本周总步数",
                       value: Formatters.number(report.totalSteps), unit: "步")
            summaryRow(icon: "moon.zzz.fill", label: "平均睡眠",
                       value: Formatters.number(report.averageSleepHours), unit: "小时")
            summaryRow(icon: "timer", label: "专注总时长",
                       value: "\(report.totalFocusMinutes)", unit: "分钟")
        }
        .cardStyle()
    }

    private func summaryRow(icon: String, label: String, value: String, unit: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.title3.weight(.bold))
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

/// 用于分享的每周小结图片内容（固定浅色风格，保证导出清晰）。
struct WeeklyReportShareView: View {
    let report: WeeklyReport

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("智能生活仪表盘")
                    .font(.title3.weight(.bold))
                Spacer()
                Image(systemName: "square.grid.2x2.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }

            Text("本周小结")
                .font(.largeTitle.weight(.bold))

            Text(report.weekRangeText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            shareRow(icon: "figure.walk", label: "本周总步数",
                     value: Formatters.number(report.totalSteps), unit: "步")
            shareRow(icon: "moon.zzz.fill", label: "平均睡眠",
                     value: Formatters.number(report.averageSleepHours), unit: "小时")
            shareRow(icon: "timer", label: "专注总时长",
                     value: "\(report.totalFocusMinutes)", unit: "分钟")

            if report.isWeekComplete {
                Text("已生成于 \(Formatters.shortDate.string(from: .now))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(white: 0.97), Color(white: 0.88)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func shareRow(icon: String, label: String, value: String, unit: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 28)
                .foregroundStyle(.blue)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.title3.weight(.bold))
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
}

/// 系统分享面板封装。
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
