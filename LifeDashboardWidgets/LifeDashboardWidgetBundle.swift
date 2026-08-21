import ActivityKit
import Foundation
import SwiftUI
import WidgetKit

/// Widget Extension 入口：提供天气、时钟、每日一句小组件，以及番茄钟的灵动岛与锁屏实时活动。
@main
struct LifeDashboardWidgetBundle: WidgetBundle {
    var body: some Widget {
        GalaxyWeatherWidget()
        GalaxyClockWidget()
        GalaxyQuoteWidget()
        PomodoroLiveActivity()
        WaterReminderLiveActivity()
    }
}

struct PomodoroLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color(white: 0.1))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // 展开态只保留「图标 + 倒计时」单行内容，把尺寸压到最小。
                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 6) {
                        Image(systemName: context.state.phase.systemImage)
                            .font(.caption)
                            .foregroundStyle(.yellow)
                        Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.phase.systemImage)
                    .font(.system(size: 12))
            } compactTrailing: {
                Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
            } minimal: {
                Image(systemName: context.state.phase.systemImage)
                    .font(.system(size: 12))
            }
        }
    }
}


/// 喝水提醒灵动岛实时活动。
struct WaterReminderLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WaterReminderAttributes.self) { context in
            HStack(spacing: 12) {
                Image(systemName: "drop.fill")
                    .font(.title2)
                    .foregroundStyle(.cyan)
                VStack(alignment: .leading, spacing: 2) {
                    Text("喝水提醒")
                        .font(.headline)
                    Text(context.state.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .activityBackgroundTint(Color(white: 0.1))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 8) {
                        Image(systemName: "drop.fill")
                            .foregroundStyle(.cyan)
                        Text(context.state.message)
                            .font(.headline)
                    }
                }
            } compactLeading: {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.cyan)
            } compactTrailing: {
                Text("喝水")
                    .font(.caption2)
                    .fontWeight(.semibold)
            } minimal: {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.cyan)
            }
        }
    }
}

/// 锁屏实时活动视图。
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<PomodoroAttributes>

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: context.state.phase.systemImage)
                .font(.title2)
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text("番茄钟 · \(context.attributes.taskName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(context.state.phase.title)
                    .font(.headline)
            }

            Spacer()

            Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .monospacedDigit()
        }
        .padding()
    }
}

// MARK: - 时钟小组件

/// 时钟小组件：模拟表盘 + 公历/农历 + 年度进度。
struct GalaxyClockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "GalaxyClockWidget", provider: ClockTimelineProvider()) { entry in
            ClockWidgetView(entry: entry)
        }
        .configurationDisplayName("Galaxy 时钟")
        .description("模拟时钟、日期与农历。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct ClockEntry: TimelineEntry {
    let date: Date
}

struct ClockTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ClockEntry {
        ClockEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (ClockEntry) -> Void) {
        completion(ClockEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClockEntry>) -> Void) {
        // 只提供一个 entry，指针由 TimelineView 每秒自行刷新
        completion(Timeline(entries: [ClockEntry(date: .now)], policy: .never))
    }
}

struct ClockWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ClockEntry

    var body: some View {
        TimelineView(.periodic(from: entry.date, by: 1)) { context in
            Group {
                switch family {
                case .systemSmall:
                    SmallClockView(date: context.date)
                case .systemLarge:
                    LargeClockView(date: context.date)
                default:
                    MediumClockView(date: context.date)
                }
            }
            .containerBackground(for: .widget) {
                WidgetTheme.clockGradient
            }
        }
    }
}

private struct SmallClockView: View {
    let date: Date

    var body: some View {
        VStack(spacing: 6) {
            AnalogClockDial(date: date)
                .frame(width: 96, height: 96)
            Text(date, format: .dateTime.month().day().weekday(.wide))
                .font(.caption.weight(.semibold))
                .foregroundStyle(WidgetTheme.primaryText)
            Text("农历 \(LunarCalendar.text(for: date))")
                .font(.caption2)
                .foregroundStyle(WidgetTheme.secondaryText)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct MediumClockView: View {
    let date: Date

    var body: some View {
        HStack(spacing: 18) {
            AnalogClockDial(date: date)
                .frame(width: 110, height: 110)

            VStack(alignment: .leading, spacing: 6) {
                Text(date, style: .time)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(WidgetTheme.primaryText)
                Text(date, format: .dateTime.month().day().weekday(.wide))
                    .font(.subheadline)
                    .foregroundStyle(WidgetTheme.secondaryText)
                Text("农历 \(LunarCalendar.text(for: date))")
                    .font(.caption)
                    .foregroundStyle(WidgetTheme.secondaryText)
                YearProgressView(date: date)
            }

            Spacer(minLength: 0)
        }
        .padding()
    }
}

private struct LargeClockView: View {
    let date: Date

    var body: some View {
        VStack(spacing: 10) {
            AnalogClockDial(date: date)
                .frame(width: 148, height: 148)

            Text(date, style: .time)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(WidgetTheme.primaryText)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(date, format: .dateTime.month().day().weekday(.wide))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(WidgetTheme.primaryText.opacity(0.85))
                    Text("农历 \(LunarCalendar.text(for: date))")
                        .font(.caption)
                        .foregroundStyle(WidgetTheme.secondaryText)
                }
                Spacer(minLength: 0)
                YearProgressView(date: date)
                    .frame(width: 120)
            }
        }
        .padding()
    }
}

/// 模拟时钟表盘（Canvas 绘制，秒级刷新）。
private struct AnalogClockDial: View {
    let date: Date
    var showSecondHand = true

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 3
            let comps = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
            let hour = Double(comps.hour ?? 0) + Double(comps.minute ?? 0) / 60
            let minute = Double(comps.minute ?? 0) + Double(comps.second ?? 0) / 60
            let second = Double(comps.second ?? 0)

            // 表盘
            let face = Path(ellipseIn: CGRect(
                x: center.x - radius, y: center.y - radius,
                width: radius * 2, height: radius * 2
            ))
            context.fill(face, with: .color(.white.opacity(0.55)))
            context.stroke(face, with: .color(WidgetTheme.primaryText.opacity(0.3)), lineWidth: max(1, radius * 0.03))

            // 刻度
            for tick in 0..<60 {
                let isHour = tick % 5 == 0
                let rad = Angle.degrees(Double(tick) * 6 - 90).radians
                let inner = isHour ? radius * 0.76 : radius * 0.85
                let outer = radius * 0.93
                var line = Path()
                line.move(to: CGPoint(x: center.x + cos(rad) * inner, y: center.y + sin(rad) * inner))
                line.addLine(to: CGPoint(x: center.x + cos(rad) * outer, y: center.y + sin(rad) * outer))
                context.stroke(
                    line,
                    with: .color(WidgetTheme.primaryText.opacity(isHour ? 0.6 : 0.25)),
                    style: StrokeStyle(lineWidth: isHour ? max(1.5, radius * 0.035) : max(1, radius * 0.02), lineCap: .round)
                )
            }

            // 时针
            drawHand(in: &context, center: center, radius: radius,
                     angle: .degrees(hour * 30 - 90),
                     length: 0.5, width: max(3, radius * 0.07),
                     color: WidgetTheme.primaryText.opacity(0.85))
            // 分针
            drawHand(in: &context, center: center, radius: radius,
                     angle: .degrees(minute * 6 - 90),
                     length: 0.72, width: max(2.5, radius * 0.055),
                     color: WidgetTheme.primaryText.opacity(0.65))
            // 秒针
            if showSecondHand {
                drawHand(in: &context, center: center, radius: radius,
                         angle: .degrees(second * 6 - 90),
                         length: 0.8, width: max(1.5, radius * 0.03),
                         color: .orange.opacity(0.9))
            }

            // 中心点
            let dot = radius * 0.05
            context.fill(
                Path(ellipseIn: CGRect(x: center.x - dot, y: center.y - dot, width: dot * 2, height: dot * 2)),
                with: .color(WidgetTheme.primaryText.opacity(0.85))
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func drawHand(in context: inout GraphicsContext, center: CGPoint, radius: CGFloat, angle: Angle, length: CGFloat, width: CGFloat, color: Color) {
        var path = Path()
        path.move(to: center)
        let rad = angle.radians
        path.addLine(to: CGPoint(
            x: center.x + cos(rad) * radius * length,
            y: center.y + sin(rad) * radius * length
        ))
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }
}

/// 年度进度条。
private struct YearProgressView: View {
    let date: Date

    var body: some View {
        let progress = Self.yearProgress(for: date)
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("今年已过")
                    .font(.caption2)
                    .foregroundStyle(WidgetTheme.secondaryText)
                Spacer()
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(WidgetTheme.primaryText.opacity(0.7))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(WidgetTheme.primaryText.opacity(0.1))
                    Capsule()
                        .fill(Color.orange.opacity(0.75))
                        .frame(width: max(geo.size.width * progress, 4))
                }
            }
            .frame(height: 5)
        }
    }

    private static func yearProgress(for date: Date) -> Double {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let year = calendar.component(.year, from: date)
        guard let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let end = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else {
            return 0
        }
        let total = max(end.timeIntervalSince(start), 1)
        let passed = max(date.timeIntervalSince(start), 0)
        return min(max(passed / total, 0), 1)
    }
}

// MARK: - 每日一句小组件

/// 每日一句小组件：每小时轮换一句温暖的话。
struct GalaxyQuoteWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "GalaxyQuoteWidget", provider: QuoteTimelineProvider()) { entry in
            QuoteWidgetView(entry: entry)
        }
        .configurationDisplayName("Galaxy 每日一句")
        .description("每小时轮换一句温暖的话。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct MotivationalQuote: Hashable {
    let text: String
    let author: String
}

enum QuoteLibrary {
    static let all: [MotivationalQuote] = [
        MotivationalQuote(text: "千里之行，始于足下。", author: "老子"),
        MotivationalQuote(text: "种一棵树最好的时间是十年前，其次是现在。", author: "谚语"),
        MotivationalQuote(text: "星光不问赶路人，时光不负有心人。", author: "佚名"),
        MotivationalQuote(text: "生活不止眼前的苟且，还有诗和远方。", author: "高晓松"),
        MotivationalQuote(text: "日拱一卒，功不唐捐。", author: "胡适"),
        MotivationalQuote(text: "所有的美好，都值得等待。", author: "佚名"),
        MotivationalQuote(text: "慢慢来，比较快。", author: "佚名"),
        MotivationalQuote(text: "热爱可抵岁月漫长。", author: "佚名")
    ]
}

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: MotivationalQuote
}

struct QuoteTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: .now, quote: QuoteLibrary.all[0])
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        completion(QuoteEntry(date: .now, quote: quote(for: .now)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        // 未来 24 小时，每小时一条
        let calendar = Calendar.current
        let start = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: .now) ?? .now
        var entries: [QuoteEntry] = []
        for hour in 0..<24 {
            guard let date = calendar.date(byAdding: .hour, value: hour, to: start) else { continue }
            entries.append(QuoteEntry(date: date, quote: quote(for: date)))
        }
        let nextDay = calendar.date(byAdding: .day, value: 1, to: start) ?? .now.addingTimeInterval(86400)
        completion(Timeline(entries: entries, policy: .after(nextDay)))
    }

    private func quote(for date: Date) -> MotivationalQuote {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        let list = QuoteLibrary.all
        return list[day % list.count]
    }
}

struct QuoteWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: QuoteEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallQuoteView(quote: entry.quote)
            case .systemLarge:
                LargeQuoteView(quote: entry.quote)
            default:
                MediumQuoteView(quote: entry.quote)
            }
        }
        .containerBackground(for: .widget) {
            WidgetTheme.quoteGradient
        }
    }
}

private struct SmallQuoteView: View {
    let quote: MotivationalQuote

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "quote.opening")
                .font(.title2)
                .foregroundStyle(Color.orange.opacity(0.85))
            Spacer(minLength: 2)
            Text(quote.text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(WidgetTheme.primaryText)
                .lineLimit(5)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 2)
            Text("—— \(quote.author)")
                .font(.caption2)
                .foregroundStyle(WidgetTheme.secondaryText)
        }
        .padding()
    }
}

private struct MediumQuoteView: View {
    let quote: MotivationalQuote

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "quote.opening")
                .font(.system(size: 40))
                .foregroundStyle(Color.orange.opacity(0.85))
            VStack(alignment: .leading, spacing: 8) {
                Text("今日一句")
                    .font(.caption)
                    .foregroundStyle(WidgetTheme.secondaryText)
                Text(quote.text)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(WidgetTheme.primaryText)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                Text("—— \(quote.author)")
                    .font(.caption)
                    .foregroundStyle(WidgetTheme.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .padding()
    }
}

private struct LargeQuoteView: View {
    let quote: MotivationalQuote

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "quote.opening")
                    .font(.title)
                    .foregroundStyle(Color.orange.opacity(0.85))
                Spacer()
                Text("今日一句")
                    .font(.caption)
                    .foregroundStyle(WidgetTheme.secondaryText)
            }
            Spacer()
            Text(quote.text)
                .font(.title.weight(.semibold))
                .foregroundStyle(WidgetTheme.primaryText)
                .lineLimit(4)
                .minimumScaleFactor(0.7)
            Spacer()
            HStack {
                Text("—— \(quote.author)")
                    .font(.headline)
                    .foregroundStyle(WidgetTheme.secondaryText)
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.orange.opacity(0.85))
            }
        }
        .padding()
    }
}
