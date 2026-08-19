import SwiftUI
import WidgetKit

/// 天气小组件：无需登录、无需 Key，直接读取 Open-Meteo 数据。
struct GalaxyWeatherWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "GalaxyWeatherWidget", provider: WeatherTimelineProvider()) { entry in
            WeatherWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WeatherWidgetBackground()
                }
        }
        .configurationDisplayName("Galaxy 天气")
        .description("显示当前天气与未来预报。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
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

    var body: some View {
        if let snapshot = entry.snapshot {
            switch family {
            case .systemSmall:
                SmallWeatherView(snapshot: snapshot)
            case .systemLarge:
                LargeWeatherView(snapshot: snapshot)
            default:
                MediumWeatherView(snapshot: snapshot)
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "cloud.sun.fill")
                    .font(.title)
                Text(entry.errorMessage ?? "天气加载中")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding()
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
                    .foregroundStyle(.yellow)
                Spacer()
                Text(snapshot.city)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("\(Int(snapshot.temperature.rounded()))°")
                .font(.system(size: 40, weight: .bold, design: .rounded))
            Text(snapshot.conditionText)
                .font(.subheadline)
            Text("H:\(Int(snapshot.high.rounded()))°  L:\(Int(snapshot.low.rounded()))°")
                .font(.caption)
                .foregroundStyle(.secondary)
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
                        .foregroundStyle(.yellow)
                    Text(snapshot.city)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text("\(Int(snapshot.temperature.rounded()))°")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                Text(snapshot.conditionText)
                    .font(.subheadline)
                Text("最高 \(Int(snapshot.high.rounded()))° · 最低 \(Int(snapshot.low.rounded()))°")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)

            HStack(spacing: 14) {
                ForEach(snapshot.days.prefix(3)) { day in
                    VStack(spacing: 4) {
                        Text(day.date, format: .dateTime.weekday(.narrow))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Image(systemName: OpenMeteoClient.sfSymbol(for: day.weatherCode))
                            .font(.body)
                            .foregroundStyle(.yellow)
                        Text("\(Int(day.high.rounded()))°")
                            .font(.caption.weight(.semibold))
                        Text("\(Int(day.low.rounded()))°")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
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
                        .foregroundStyle(.secondary)
                    Text("\(Int(snapshot.temperature.rounded()))°")
                        .font(.system(size: 54, weight: .bold, design: .rounded))
                    Text(snapshot.conditionText)
                        .font(.title3)
                }
                Spacer()
                Image(systemName: OpenMeteoClient.sfSymbol(for: currentCode))
                    .font(.system(size: 52))
                    .foregroundStyle(.yellow)
            }

            HStack(spacing: 16) {
                ForEach(snapshot.days.prefix(3)) { day in
                    VStack(spacing: 6) {
                        Text(day.date, format: .dateTime.weekday(.wide))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Image(systemName: OpenMeteoClient.sfSymbol(for: day.weatherCode))
                            .font(.title3)
                            .foregroundStyle(.yellow)
                        Text(day.conditionText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(Int(day.high.rounded()))° / \(Int(day.low.rounded()))°")
                            .font(.caption.weight(.semibold))
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

private struct WeatherWidgetBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.06, blue: 0.22),
                Color(red: 0.12, green: 0.10, blue: 0.38),
                Color(red: 0.18, green: 0.12, blue: 0.50)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
