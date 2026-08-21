import SwiftUI
import Foundation

/// 智能天气卡片：当前温度、天气状况、今日最高/最低温与建议，并支持地区切换。
/// 点击卡片可进入天气详情页查看逐小时与未来一周预报。
struct WeatherCard: View {
    @EnvironmentObject private var weatherService: WeatherService

    @State private var showsCustomCityAlert = false
    @State private var customCityText = ""
    @State private var showsDetail = false

    /// 天气氛围：用于给卡片配色。
    private enum WeatherTone {
        case clearDay, clearNight, cloudy, rain, snow, thunder, fog
    }

    var body: some View {
        Button {
            showsDetail = true
        } label: {
            cardContent
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 8) {
                if weatherService.isLoading {
                    ProgressView()
                        .tint(.white)
                }
                regionMenu
            }
            .padding(16)
        }
        .navigationDestination(isPresented: $showsDetail) {
            WeatherDetailView()
        }
        .alert("自定义城市", isPresented: $showsCustomCityAlert) {
            TextField("输入城市名，如 上海 / Shanghai", text: $customCityText)
            Button("确定") {
                weatherService.setCity(customCityText)
                customCityText = ""
            }
            Button("取消", role: .cancel) {
                customCityText = ""
            }
        } message: {
            Text("输入城市名称后，天气卡片会立即切换到该地区。")
        }
    }

    private var activeTone: WeatherTone {
        if let weather = weatherService.weather {
            return Self.tone(for: weather.conditionID)
        }
        return .clearDay
    }

    private static func tone(for conditionID: Int) -> WeatherTone {
        switch conditionID {
        case 200...232: return .thunder
        case 300...321, 500...531: return .rain
        case 600...622: return .snow
        case 701...781: return .fog
        case 800:
            let hour = Calendar.current.component(.hour, from: Date())
            return (hour >= 6 && hour < 19) ? .clearDay : .clearNight
        case 801...804: return .cloudy
        default: return .cloudy
        }
    }

    private var gradientColors: [Color] {
        switch activeTone {
        case .clearDay:
            return [Color(red: 0.24, green: 0.54, blue: 0.95), Color(red: 0.96, green: 0.61, blue: 0.34)]
        case .clearNight:
            return [Color(red: 0.07, green: 0.10, blue: 0.32), Color(red: 0.27, green: 0.22, blue: 0.53)]
        case .cloudy:
            return [Color(red: 0.31, green: 0.42, blue: 0.57), Color(red: 0.56, green: 0.66, blue: 0.78)]
        case .rain:
            return [Color(red: 0.12, green: 0.23, blue: 0.44), Color(red: 0.37, green: 0.55, blue: 0.78)]
        case .snow:
            return [Color(red: 0.36, green: 0.50, blue: 0.70), Color(red: 0.64, green: 0.76, blue: 0.89)]
        case .thunder:
            return [Color(red: 0.21, green: 0.13, blue: 0.41), Color(red: 0.47, green: 0.29, blue: 0.63)]
        case .fog:
            return [Color(red: 0.33, green: 0.39, blue: 0.47), Color(red: 0.54, green: 0.61, blue: 0.69)]
        }
    }

    private var iconColor: Color {
        switch activeTone {
        case .clearDay, .clearNight: return .yellow
        case .rain: return Color(red: 0.78, green: 0.92, blue: 1.0)
        case .snow, .cloudy: return .white
        case .thunder: return .yellow
        case .fog: return .white.opacity(0.9)
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label {
                    Text("天气")
                        .foregroundStyle(.white)
                } icon: {
                    Image(systemName: "cloud.sun.fill")
                        .foregroundStyle(.yellow)
                }
                .font(.headline)
                Spacer()
            }

            if let weather = weatherService.weather {
                Text(weather.city)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Image(systemName: weather.symbolName)
                        .font(.title2)
                        .foregroundStyle(iconColor)
                    Text("\(Int(weather.temperature.rounded()))°")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(weather.condition)
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                }

                HStack(spacing: 12) {
                    Label {
                        Text("最高 \(Int(weather.high.rounded()))°")
                    } icon: {
                        Image(systemName: "arrow.up")
                            .foregroundStyle(.orange)
                    }
                    Label {
                        Text("最低 \(Int(weather.low.rounded()))°")
                    } icon: {
                        Image(systemName: "arrow.down")
                            .foregroundStyle(.cyan)
                    }
                }
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.9))

                HStack(spacing: 14) {
                    Label {
                        Text("体感 \(Int(weather.feelsLike.rounded()))°")
                    } icon: {
                        Image(systemName: "thermometer.medium")
                            .foregroundStyle(.orange)
                    }
                    if let humidity = weather.humidity {
                        Label {
                            Text("湿度 \(humidity)%")
                        } icon: {
                            Image(systemName: "humidity.fill")
                                .foregroundStyle(.cyan)
                        }
                    }
                }
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.9))

                Text(weatherService.advice)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 2)

            } else if let error = weatherService.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("天气数据加载中…")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .shadow(color: .black.opacity(0.16), radius: 8, x: 0, y: 2)
    }

    /// 地区切换菜单：内置常用城市 + 自定义城市入口。
    private var regionMenu: some View {
        Menu {
            ForEach(WeatherService.supportedRegions) { region in
                Button {
                    weatherService.selectRegion(region)
                } label: {
                    if isSelected(region) {
                        Label(region.name, systemImage: "checkmark")
                    } else {
                        Text(region.name)
                    }
                }
            }

            Divider()

            Button {
                customCityText = weatherService.city
                showsCustomCityAlert = true
            } label: {
                Label("自定义城市…", systemImage: "text.cursor")
            }
        } label: {
            Image(systemName: "location.circle")
                .font(.headline)
                .foregroundStyle(.white)
        }
        .accessibilityLabel("切换天气地区")
    }

    private func isSelected(_ region: WeatherRegion) -> Bool {
        weatherService.city == region.query || weatherService.city == region.name
    }
}

/// 天气详情页：当前天气、详细信息、24 小时预报与未来一周预报。
struct WeatherDetailView: View {
    @EnvironmentObject private var weatherService: WeatherService

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let weather = weatherService.weather {
                    currentSection(weather)
                    metricsSection(weather)
                    if !weather.hourly.isEmpty {
                        hourlySection(weather)
                    }
                    if !weather.daily.isEmpty {
                        dailySection(weather)
                    }
                } else if let error = weatherService.errorMessage {
                    ContentUnavailableView {
                        Label("天气加载失败", systemImage: "cloud.slash")
                    } description: {
                        Text(error)
                    }
                    .padding(.top, 80)
                } else {
                    ProgressView("天气数据加载中…")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(weatherService.weather?.city ?? "天气详情")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await weatherService.fetchWeather()
        }
    }

    // MARK: - 当前天气

    private func currentSection(_ weather: WeatherData) -> some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: weather.symbolName)
                    .font(.system(size: 44))
                    .foregroundStyle(.tint)
                Text("\(Int(weather.temperature.rounded()))°")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                VStack(alignment: .leading, spacing: 4) {
                    Text(weather.condition)
                        .font(.headline)
                    Text("最高 \(Int(weather.high.rounded()))° / 最低 \(Int(weather.low.rounded()))°")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text(weatherService.advice)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sectionCard()
    }

    // MARK: - 详细信息

    private func metricsSection(_ weather: WeatherData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("详细信息")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                metricCard("体感温度", "\(Int(weather.feelsLike.rounded()))°", "thermometer.medium")
                metricCard("湿度", weather.humidity.map { "\($0)%" } ?? "--", "humidity.fill")
                metricCard("风速", weather.windSpeed.map { String(format: "%.0f km/h", $0) } ?? "--", "wind")
                metricCard("气压", weather.pressure.map { String(format: "%.0f hPa", $0) } ?? "--", "gauge")
                metricCard("降水概率", weather.precipitationProbability.map { "\($0)%" } ?? "--", "drop.fill")
                metricCard("日出 / 日落", sunriseSunsetText(weather), "sunrise.fill")
            }
        }
        .sectionCard()
    }

    private func metricCard(_ title: String, _ value: String, _ systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func sunriseSunsetText(_ weather: WeatherData) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        let sunrise = weather.sunrise.map { formatter.string(from: $0) } ?? "--"
        let sunset = weather.sunset.map { formatter.string(from: $0) } ?? "--"
        return "\(sunrise) / \(sunset)"
    }

    // MARK: - 24 小时预报

    private func hourlySection(_ weather: WeatherData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("24 小时预报")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(weather.hourly) { hour in
                        VStack(spacing: 8) {
                            Text(hourText(hour.date))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Image(systemName: OpenMeteoClient.sfSymbol(for: hour.weatherCode))
                                .font(.title3)
                                .foregroundStyle(.tint)
                            Text("\(Int(hour.temperature.rounded()))°")
                                .font(.subheadline.weight(.semibold))
                            if let precip = hour.precipitationProbability, precip > 0 {
                                Text("\(precip)%")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                            }
                        }
                        .frame(width: 56)
                        .padding(.vertical, 10)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
        }
        .sectionCard()
    }

    private func hourText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    // MARK: - 未来一周

    private func dailySection(_ weather: WeatherData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("未来一周")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(Array(weather.daily.enumerated()), id: \.element.id) { index, day in
                    HStack(spacing: 12) {
                        Text(dayTitle(day.date, index: index))
                            .font(.subheadline)
                            .frame(width: 64, alignment: .leading)

                        Image(systemName: OpenMeteoClient.sfSymbol(for: day.weatherCode))
                            .foregroundStyle(.tint)
                            .frame(width: 24)

                        if let precip = day.precipitationProbability {
                            Label("\(precip)%", systemImage: "drop.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .frame(width: 52, alignment: .leading)
                        } else {
                            Color.clear
                                .frame(width: 52)
                        }

                        Spacer()

                        Text("\(Int(day.low.rounded()))°")
                            .foregroundStyle(.secondary)
                        Text("/")
                            .foregroundStyle(.secondary)
                        Text("\(Int(day.high.rounded()))°")
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 10)

                    if index < weather.daily.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .sectionCard()
    }

    private func dayTitle(_ date: Date, index: Int) -> String {
        if index == 0 { return "今天" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

// MARK: - 详情页卡片样式

private extension View {
    func sectionCard() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
