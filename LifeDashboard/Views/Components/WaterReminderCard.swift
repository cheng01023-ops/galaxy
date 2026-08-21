import SwiftUI

/// 仪表盘上的喝水提醒卡片，点击进入详情页。
struct WaterReminderCard: View {
    @ObservedObject private var service = WaterReminderService.shared

    /// 时间轴最多展示的提醒个数，超出部分用 "+N" 表示。
    private let maxDots = 8

    /// 卡片主渐变：青 → 蓝，贯穿标题、进度环与时间轴。
    private let waterGradient = LinearGradient(
        colors: [.cyan, .blue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        NavigationLink {
            WaterReminderDetailView()
        } label: {
            content
        }
        .buttonStyle(.plain)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            if service.reminders.isEmpty {
                emptyState
            } else {
                nextReminderRow
                timelineRow
                timeRangeText
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(cardBackground)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - 背景与装饰

    /// 水蓝色渐变背景 + 底部气泡装饰，自动适配深色模式。
    private var cardBackground: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.cardBackground

            LinearGradient(
                colors: [Color.blue.opacity(0.16), Color.cyan.opacity(0.08), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            bubbleDecorations
                .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var bubbleDecorations: some View {
        ZStack {
            Circle()
                .fill(Color.cyan.opacity(0.16))
                .frame(width: 46, height: 46)
                .offset(x: -8, y: -4)
            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 30, height: 30)
                .offset(x: -30, y: 16)
            Circle()
                .fill(Color.teal.opacity(0.14))
                .frame(width: 18, height: 18)
                .offset(x: -2, y: 24)
            Circle()
                .fill(Color.blue.opacity(0.08))
                .frame(width: 12, height: 12)
                .offset(x: -22, y: 30)
        }
        .allowsHitTesting(false)
    }

    // MARK: - 标题

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "drop.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(waterGradient, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: .blue.opacity(0.35), radius: 4, x: 0, y: 2)

            Text("喝水提醒")
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "drop.degreesign.slash")
                .font(.title)
                .foregroundStyle(.blue.opacity(0.6))
            Text("还没有设置提醒")
                .font(.subheadline)
                .foregroundStyle(.primary)
            Text("点击添加每天的喝水提醒")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - 下次提醒

    private var nextReminderRow: some View {
        HStack(spacing: 12) {
            progressRing

            VStack(alignment: .leading, spacing: 3) {
                Text(nextLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let next = service.nextReminder() {
                    Text(String(format: "%02d:%02d", next.hour, next.minute))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(waterGradient)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .contentTransition(.numericText())
                }
                countdownText
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
    }

    private var nextLabel: String {
        if let date = service.nextReminderDate(),
           Calendar.current.isDateInTomorrow(date) {
            return "下次提醒 · 明天"
        }
        return "下次提醒"
    }

    @ViewBuilder
    private var countdownText: some View {
        if let nextDate = service.nextReminderDate() {
            let minutes = Int(max(0, nextDate.timeIntervalSinceNow) / 60)
            if minutes < 1 {
                Label("马上就到", systemImage: "bell.badge.fill")
            } else if minutes < 60 {
                Label("还有 \(minutes) 分钟", systemImage: "clock")
            } else {
                Label("还有 \(minutes / 60) 小时 \(minutes % 60) 分", systemImage: "clock")
            }
        }
    }

    // MARK: - 今日完成进度环

    private var progressRing: some View {
        let passed = service.passedRemindersCount()
        let total = service.reminders.count
        let progress = total > 0 ? Double(passed) / Double(total) : 0

        return ZStack {
            Circle()
                .stroke(Color(.tertiarySystemFill), lineWidth: 8)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [.cyan, .blue, .indigo],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: .blue.opacity(0.45), radius: 3, x: 0, y: 1)
                .animation(.snappy, value: progress)

            VStack(spacing: 2) {
                Image(systemName: "drop.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(waterGradient)
                Text("\(passed)/\(total)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.blue)
                    .monospacedDigit()
            }
        }
        .frame(width: 58, height: 58)
    }

    // MARK: - 今日提醒时间轴

    private var timelineRow: some View {
        HStack(spacing: 4) {
            ForEach(Array(service.reminders.prefix(maxDots).enumerated()), id: \.element.id) { index, reminder in
                let isPassed = index < service.passedRemindersCount()
                Group {
                    if isPassed {
                        Circle().fill(waterGradient)
                    } else {
                        Circle().fill(Color(.tertiarySystemFill))
                    }
                }
                .frame(width: 8, height: 8)
            }
            if service.reminders.count > maxDots {
                Text("+\(service.reminders.count - maxDots)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Text(remainingText)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    private var remainingText: String {
        let remaining = service.reminders.count - service.passedRemindersCount()
        if remaining > 0 {
            return "剩余 \(remaining) 次"
        }
        return "今日已全部完成"
    }

    // MARK: - 提醒时段

    private var timeRangeText: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.caption2)
                .foregroundStyle(.blue)
            if let first = service.reminders.first, let last = service.reminders.last {
                Text(String(format: "提醒时段 %02d:%02d - %02d:%02d",
                            first.hour, first.minute, last.hour, last.minute))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
    }
}
