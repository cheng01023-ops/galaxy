import Foundation
import SwiftUI
import WidgetKit

// MARK: - 共享主题（淡雅配色）

/// 小组件共用配色：清淡柔和。
enum WidgetTheme {
    /// 浅色背景上的主文字
    static let primaryText = Color.black.opacity(0.72)
    /// 浅色背景上的次要文字
    static let secondaryText = Color.black.opacity(0.45)

    /// 天气：晴空淡蓝 → 浅紫 → 柔粉
    static let weatherGradient = LinearGradient(
        colors: [
            Color(red: 0.85, green: 0.93, blue: 1.00),
            Color(red: 0.90, green: 0.88, blue: 1.00),
            Color(red: 1.00, green: 0.91, blue: 0.89)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 时钟：薄荷 → 天蓝 → 浅紫
    static let clockGradient = LinearGradient(
        colors: [
            Color(red: 0.88, green: 0.98, blue: 0.94),
            Color(red: 0.87, green: 0.94, blue: 1.00),
            Color(red: 0.93, green: 0.88, blue: 1.00)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 每日一句：奶油 → 蜜桃 → 浅粉
    static let quoteGradient = LinearGradient(
        colors: [
            Color(red: 1.00, green: 0.96, blue: 0.87),
            Color(red: 1.00, green: 0.92, blue: 0.90),
            Color(red: 0.96, green: 0.90, blue: 1.00)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - 农历

enum LunarCalendar {
    private static let chinese = Calendar(identifier: .chinese)

    private static let monthNames = [
        "正月", "二月", "三月", "四月", "五月", "六月",
        "七月", "八月", "九月", "十月", "冬月", "腊月"
    ]

    private static let dayNames = [
        "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
    ]

    /// 例如：七月十七 / 闰二月廿五
    static func text(for date: Date) -> String {
        let comps = chinese.dateComponents([.year, .month, .day, .isLeapMonth], from: date)
        let month = comps.month ?? 1
        let day = comps.day ?? 1
        let leap = comps.isLeapMonth ?? false
        let monthText: String
        if monthNames.indices.contains(month - 1) {
            monthText = (leap ? "闰" : "") + monthNames[month - 1]
        } else {
            monthText = "\(month)月"
        }
        let dayText = dayNames.indices.contains(day - 1) ? dayNames[day - 1] : "\(day)"
        return monthText + dayText
    }
}

// MARK: - 天气小组件

/// 天气小组件：无需登录、无需 Key，直接读取 Open-Meteo 数据。
struct GalaxyWeatherWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "GalaxyWeatherWidget", provider: WeatherTimelineProvider()) { entry in
            WeatherWidgetView(entry: entry)
        }
        .configurationDisplayName("Galaxy 天气")
        .description("显示当前天气与未来预报。")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
    }
}

// MARK: - Timeline

struct WeatherEntry: TimelineEntry {
    let date: Date
    let snapshot: OpenMeteoWeatherSnapshot?
    let errorMessage: String?
}

struct WeatherTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: .now, snapshot: .sample, errorMessage: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> Void) {
        if context.isPreview {
            completion(WeatherEntry(date: .now, snapshot: .sample, errorMessage: nil))
            return
        }
        Task {
            do {
                let snapshot = try await OpenMeteoClient.shared.fetchWeather(city: "Shanghai", forecastDays: 3)
                completion(WeatherEntry(date: .now, snapshot: snapshot, errorMessage: nil))
            } catch {
                completion(WeatherEntry(date: .now, snapshot: nil, errorMessage: error.localizedDescription))
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        Task {
            do {
                let snapshot = try await OpenMeteoClient.shared.fetchWeather(city: "Shanghai", forecastDays: 3)
                let entry = WeatherEntry(date: .now, snapshot: snapshot, errorMessage: nil)
                // 每小时自动刷新一次
                let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now.addingTimeInterval(3600)
                completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
            } catch {
                let entry = WeatherEntry(date: .now, snapshot: nil, errorMessage: error.localizedDescription)
                let retry = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now.addingTimeInterval(900)
                completion(Timeline(entries: [entry], policy: .after(retry)))
            }
        }
    }
}

// MARK: - Views

struct WeatherWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WeatherEntry

    private var isAccessory: Bool {
        family == .accessoryCircular || family == .accessoryRectangular || family == .accessoryInline
    }

    var body: some View {
        if let snapshot = entry.snapshot {
            if isAccessory {
                accessoryView(snapshot)
            } else {
                systemView(snapshot)
                    .containerBackground(for: .widget) {
                        WeatherWidgetBackground()
                    }
            }
        } else if isAccessory {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "cloud.sun.fill")
                    .font(.headline)
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "cloud.sun.fill")
                    .font(.title)
                    .foregroundStyle(WidgetTheme.primaryText)
                Text(entry.errorMessage ?? "天气加载中")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(WidgetTheme.secondaryText)
            }
            .padding()
            .containerBackground(for: .widget) {
                WeatherWidgetBackground()
            }
        }
    }

    @ViewBuilder
    private func systemView(_ snapshot: OpenMeteoWeatherSnapshot) -> some View {
        switch family {
        case .systemSmall:
            SmallWeatherView(snapshot: snapshot)
        case .systemLarge:
            LargeWeatherView(snapshot: snapshot)
        default:
            MediumWeatherView(snapshot: snapshot)
        }
    }

    @ViewBuilder
    private func accessoryView(_ snapshot: OpenMeteoWeatherSnapshot) -> some View {
        switch family {
        case .accessoryCircular:
            AccessoryCircularWeatherView(snapshot: snapshot)
        case .accessoryRectangular:
            AccessoryRectangularWeatherView(snapshot: snapshot)
        default:
            AccessoryInlineWeatherView(snapshot: snapshot)
        }
    }
}

private struct SmallWeatherView: View {
    let snapshot: OpenMeteoWeatherSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: OpenMeteoClient.sfSymbol(for: currentCode))
                    .font(.title2)
                    .foregroundStyle(.orange)
                Spacer()
                Text(snapshot.city)
                    .font(.caption)
                    .foregroundStyle(WidgetTheme.secondaryText)
            }
            Text("\(Int(snapshot.temperature.rounded()))°")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(WidgetTheme.primaryText)
            Text(snapshot.conditionText)
                .font(.subheadline)
                .foregroundStyle(WidgetTheme.primaryText.opacity(0.8))
            Text("H:\(Int(snapshot.high.rounded()))°  L:\(Int(snapshot.low.rounded()))°")
                .font(.caption)
                .foregroundStyle(WidgetTheme.secondaryText)
            Spacer(minLength: 0)
        }
        .padding()
    }

    private var currentCode: Int {
        snapshot.days.first?.weatherCode ?? 0
    }
}

private struct MediumWeatherView: View {
    let snapshot: OpenMeteoWeatherSnapshot

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: OpenMeteoClient.sfSymbol(for: currentCode))
                        .foregroundStyle(.orange)
                    Text(snapshot.city)
                        .font(.subheadline)
                        .foregroundStyle(WidgetTheme.secondaryText)
                }
                Text("\(Int(snapshot.temperature.rounded()))°")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetTheme.primaryText)
                Text(snapshot.conditionText)
                    .font(.subheadline)
                    .foregroundStyle(WidgetTheme.primaryText.opacity(0.8))
                Text("最高 \(Int(snapshot.high.rounded()))° · 最低 \(Int(snapshot.low.rounded()))°")
                    .font(.caption)
                    .foregroundStyle(WidgetTheme.secondaryText)
            }
            Spacer(minLength: 0)

            HStack(spacing: 14) {
                ForEach(snapshot.days.prefix(3)) { day in
                    VStack(spacing: 4) {
                        Text(day.date, format: .dateTime.weekday(.narrow))
                            .font(.caption2)
                            .foregroundStyle(WidgetTheme.secondaryText)
                        Image(systemName: OpenMeteoClient.sfSymbol(for: day.weatherCode))
                            .font(.body)
                            .foregroundStyle(.orange)
                        Text("\(Int(day.high.rounded()))°")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(WidgetTheme.primaryText)
                        Text("\(Int(day.low.rounded()))°")
                            .font(.caption2)
                            .foregroundStyle(WidgetTheme.secondaryText)
                    }
                }
            }
        }
        .padding()
    }

    private var currentCode: Int {
        snapshot.days.first?.weatherCode ?? 0
    }
}

private struct LargeWeatherView: View {
    let snapshot: OpenMeteoWeatherSnapshot

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(snapshot.city)
                        .font(.headline)
                        .foregroundStyle(WidgetTheme.secondaryText)
                    Text("\(Int(snapshot.temperature.rounded()))°")
                        .font(.system(size: 54, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetTheme.primaryText)
                    Text(snapshot.conditionText)
                        .font(.title3)
                        .foregroundStyle(WidgetTheme.primaryText.opacity(0.8))
                }
                Spacer()
                Image(systemName: OpenMeteoClient.sfSymbol(for: currentCode))
                    .font(.system(size: 52))
                    .foregroundStyle(.orange)
            }

            HStack(spacing: 16) {
                ForEach(snapshot.days.prefix(3)) { day in
                    VStack(spacing: 6) {
                        Text(day.date, format: .dateTime.weekday(.wide))
                            .font(.caption)
                            .foregroundStyle(WidgetTheme.secondaryText)
                        Image(systemName: OpenMeteoClient.sfSymbol(for: day.weatherCode))
                            .font(.title3)
                            .foregroundStyle(.orange)
                        Text(day.conditionText)
                            .font(.caption)
                            .foregroundStyle(WidgetTheme.secondaryText)
                        Text("\(Int(day.high.rounded()))° / \(Int(day.low.rounded()))°")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(WidgetTheme.primaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
    }

    private var currentCode: Int {
        snapshot.days.first?.weatherCode ?? 0
    }
}

private struct AccessoryCircularWeatherView: View {
    let snapshot: OpenMeteoWeatherSnapshot

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: OpenMeteoClient.sfSymbol(for: currentCode))
                    .font(.headline)
                    .widgetAccentable()
                Text("\(Int(snapshot.temperature.rounded()))°")
                    .font(.headline)
            }
        }
    }

    private var currentCode: Int {
        snapshot.days.first?.weatherCode ?? 0
    }
}

private struct AccessoryRectangularWeatherView: View {
    let snapshot: OpenMeteoWeatherSnapshot

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: OpenMeteoClient.sfSymbol(for: currentCode))
                .font(.title2)
                .widgetAccentable()
            VStack(alignment: .leading, spacing: 1) {
                Text("\(snapshot.city) \(Int(snapshot.temperature.rounded()))° \(snapshot.conditionText)")
                    .font(.headline)
                Text("最高 \(Int(snapshot.high.rounded()))° · 最低 \(Int(snapshot.low.rounded()))°")
                    .font(.caption)
            }
            Spacer(minLength: 0)
        }
    }

    private var currentCode: Int {
        snapshot.days.first?.weatherCode ?? 0
    }
}

private struct AccessoryInlineWeatherView: View {
    let snapshot: OpenMeteoWeatherSnapshot

    var body: some View {
        Label {
            Text("\(Int(snapshot.temperature.rounded()))° \(snapshot.conditionText) · \(snapshot.city)")
        } icon: {
            Image(systemName: OpenMeteoClient.sfSymbol(for: currentCode))
        }
    }

    private var currentCode: Int {
        snapshot.days.first?.weatherCode ?? 0
    }
}

private struct WeatherWidgetBackground: View {
    var body: some View {
        WidgetTheme.weatherGradient
    }
}

// MARK: - 示例数据

private extension OpenMeteoWeatherSnapshot {
    static let sample = OpenMeteoWeatherSnapshot(
        city: "上海",
        temperature: 28,
        conditionText: "晴",
        conditionID: 800,
        high: 31,
        low: 26,
        days: [
            OpenMeteoDay(date: .now, high: 31, low: 26, weatherCode: 0, conditionText: "晴", conditionID: 800),
            OpenMeteoDay(date: .now.addingTimeInterval(86400), high: 30, low: 25, weatherCode: 2, conditionText: "多云", conditionID: 801),
            OpenMeteoDay(date: .now.addingTimeInterval(172800), high: 29, low: 24, weatherCode: 61, conditionText: "雨", conditionID: 500)
        ]
    )
}
