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
                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 8) {
                        Image(systemName: context.state.phase.systemImage)
                            .foregroundStyle(.yellow)
                        Text(context.state.phase.title)
                        Spacer()
                        Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .monospacedDigit()
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.phase.systemImage)
            } compactTrailing: {
                Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: context.state.phase.systemImage)
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

/// 每日一句小组件：每天凌晨 00:00 联网更新一句温暖的话。
struct GalaxyQuoteWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "GalaxyQuoteWidget", provider: QuoteTimelineProvider()) { entry in
            QuoteWidgetView(entry: entry)
        }
        .configurationDisplayName("Galaxy 每日一句")
        .description("每天凌晨 00:00 联网更新一句温暖的话。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct MotivationalQuote: Hashable {
    let text: String
    let author: String
}

// MARK: - 精选语录库（离线兜底）

enum QuoteLibrary {
    /// 励志
    static let motivation: [MotivationalQuote] = [
        MotivationalQuote(text: "千里之行，始于足下。", author: "老子"),
        MotivationalQuote(text: "种一棵树最好的时间是十年前，其次是现在。", author: "谚语"),
        MotivationalQuote(text: "星光不问赶路人，时光不负有心人。", author: "佚名"),
        MotivationalQuote(text: "生活不止眼前的苟且，还有诗和远方。", author: "高晓松"),
        MotivationalQuote(text: "日拱一卒，功不唐捐。", author: "胡适"),
        MotivationalQuote(text: "所有的美好，都值得等待。", author: "佚名"),
        MotivationalQuote(text: "慢慢来，比较快。", author: "佚名"),
        MotivationalQuote(text: "热爱可抵岁月漫长。", author: "佚名"),
        MotivationalQuote(text: "行动是治愈恐惧的良药，而犹豫拖延将不断滋养恐惧。", author: "佚名"),
        MotivationalQuote(text: "把每一天都当作生命中的最后一天来过。", author: "史蒂夫·乔布斯"),
        MotivationalQuote(text: "成功不是终点，失败也不是末日，重要的是继续前行的勇气。", author: "温斯顿·丘吉尔"),
        MotivationalQuote(text: "你现在的努力，是为了将来拥有更多选择的权利。", author: "佚名"),
        MotivationalQuote(text: "不积跬步，无以至千里；不积小流，无以成江海。", author: "荀子"),
        MotivationalQuote(text: "只要路是对的，就不怕路远。", author: "佚名"),
        MotivationalQuote(text: "逆风的方向，更适合飞翔。", author: "佚名"),
        MotivationalQuote(text: "世上无难事，只怕有心人。", author: "谚语")
    ]

    /// 诗词
    static let poetry: [MotivationalQuote] = [
        MotivationalQuote(text: "会当凌绝顶，一览众山小。", author: "杜甫"),
        MotivationalQuote(text: "长风破浪会有时，直挂云帆济沧海。", author: "李白"),
        MotivationalQuote(text: "海内存知己，天涯若比邻。", author: "王勃"),
        MotivationalQuote(text: "沉舟侧畔千帆过，病树前头万木春。", author: "刘禹锡"),
        MotivationalQuote(text: "山重水复疑无路，柳暗花明又一村。", author: "陆游"),
        MotivationalQuote(text: "天生我材必有用，千金散尽还复来。", author: "李白"),
        MotivationalQuote(text: "千磨万击还坚劲，任尔东西南北风。", author: "郑燮"),
        MotivationalQuote(text: "莫愁前路无知己，天下谁人不识君。", author: "高适"),
        MotivationalQuote(text: "纸上得来终觉浅，绝知此事要躬行。", author: "陆游"),
        MotivationalQuote(text: "不畏浮云遮望眼，自缘身在最高层。", author: "王安石"),
        MotivationalQuote(text: "宝剑锋从磨砺出，梅花香自苦寒来。", author: "《警世贤文》"),
        MotivationalQuote(text: "路漫漫其修远兮，吾将上下而求索。", author: "屈原")
    ]

    /// 生活
    static let life: [MotivationalQuote] = [
        MotivationalQuote(text: "生活明朗，万物可爱。", author: "佚名"),
        MotivationalQuote(text: "人间值得，未来可期。", author: "佚名"),
        MotivationalQuote(text: "心之所向，素履以往。", author: "佚名"),
        MotivationalQuote(text: "愿所有美好，如期而至。", author: "佚名"),
        MotivationalQuote(text: "简单生活，快乐至上。", author: "佚名"),
        MotivationalQuote(text: "且将新火试新茶，诗酒趁年华。", author: "苏轼"),
        MotivationalQuote(text: "一花一世界，一叶一菩提。", author: "《华严经》"),
        MotivationalQuote(text: "世界以痛吻我，我要报之以歌。", author: "泰戈尔")
    ]

    /// 成长
    static let growth: [MotivationalQuote] = [
        MotivationalQuote(text: "学而不思则罔，思而不学则殆。", author: "孔子"),
        MotivationalQuote(text: "温故而知新，可以为师矣。", author: "孔子"),
        MotivationalQuote(text: "书山有路勤为径，学海无涯苦作舟。", author: "韩愈"),
        MotivationalQuote(text: "知之者不如好之者，好之者不如乐之者。", author: "孔子"),
        MotivationalQuote(text: "三人行，必有我师焉。", author: "孔子"),
        MotivationalQuote(text: "锲而不舍，金石可镂。", author: "荀子"),
        MotivationalQuote(text: "业精于勤，荒于嬉；行成于思，毁于随。", author: "韩愈")
    ]

    /// 全部精选（43 条）
    static let all: [MotivationalQuote] = motivation + poetry + life + growth

    /// 按日期确定性地挑选一条本地金句，保证同一天展示相同内容。
    static func quote(for date: Date) -> MotivationalQuote {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return all[day % all.count]
    }
}

// MARK: - 互联网语录源

enum QuoteError: Error {
    case empty
}

/// 从公开语录接口拉取当日金句；多个源依次尝试，全部失败返回 nil。
enum QuoteClient {
    static func fetchDailyQuote() async -> MotivationalQuote? {
        // 一言：哲学 → 诗词 → 文学
        for category in ["k", "i", "d"] {
            if let quote = try? await fetchHitokoto(category: category) {
                return quote
            }
        }
        // 今日诗词
        if let quote = try? await fetchJinrishici() {
            return quote
        }
        return nil
    }

    private static func fetchHitokoto(category: String) async throws -> MotivationalQuote {
        var components = URLComponents(string: "https://v1.hitokoto.cn/")
        components?.queryItems = [
            URLQueryItem(name: "c", value: category),
            URLQueryItem(name: "encode", value: "json"),
            URLQueryItem(name: "max_length", value: "60")
        ]
        guard let url = components?.url else { throw URLError(.badURL) }
        let response = try JSONDecoder().decode(HitokotoResponse.self, from: try await data(from: url))
        let text = response.hitokoto.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw QuoteError.empty }
        let author = (response.fromWho ?? response.from ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return MotivationalQuote(text: text, author: author.isEmpty ? "一言" : author)
    }

    private static func fetchJinrishici() async throws -> MotivationalQuote {
        guard let url = URL(string: "https://v1.jinrishici.com/all.json") else { throw URLError(.badURL) }
        let response = try JSONDecoder().decode(JinrishiciResponse.self, from: try await data(from: url))
        let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw QuoteError.empty }
        let author = (response.author ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let origin = (response.origin ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let authorText = !author.isEmpty ? author : (!origin.isEmpty ? origin : "今日诗词")
        return MotivationalQuote(text: text, author: authorText)
    }

    /// 带超时的请求，避免拖慢小组件刷新。
    private static func data(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
}

private struct HitokotoResponse: Decodable {
    let hitokoto: String
    let from: String?
    let fromWho: String?

    enum CodingKeys: String, CodingKey {
        case hitokoto
        case from
        case fromWho = "from_who"
    }
}

private struct JinrishiciResponse: Decodable {
    let content: String
    let origin: String?
    let author: String?
}

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: MotivationalQuote
}

struct QuoteTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: .now, quote: QuoteLibrary.quote(for: .now))
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        if context.isPreview {
            completion(QuoteEntry(date: .now, quote: QuoteLibrary.quote(for: .now)))
            return
        }
        Task {
            let quote = await QuoteClient.fetchDailyQuote() ?? QuoteLibrary.quote(for: .now)
            completion(QuoteEntry(date: .now, quote: quote))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        Task {
            let calendar = Calendar.current
            // 次日凌晨 00:00：到点后系统会唤醒小组件，拉取新一天的句子
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now) ?? .now.addingTimeInterval(86400)
            let nextMidnight = calendar.startOfDay(for: tomorrow)

            if let quote = await QuoteClient.fetchDailyQuote() {
                let entry = QuoteEntry(date: .now, quote: quote)
                completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
            } else {
                // 联网失败：先用本地精选展示，30 分钟后重试
                let entry = QuoteEntry(date: .now, quote: QuoteLibrary.quote(for: .now))
                let retry = calendar.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)
                completion(Timeline(entries: [entry], policy: .after(retry)))
            }
        }
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
