import Foundation

/// 负责获取当前天气。
/// - 已填入 OpenWeatherMap Key 时使用 OpenWeatherMap。
/// - 未填 Key 时自动回退到 Open-Meteo（免费、无需注册），保证开箱即用。
@MainActor
final class WeatherService: ObservableObject {
    @Published var weather: WeatherData?
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// 当前选中的地区（城市查询关键字）。
    @Published private(set) var city: String

    /// 内置的常用地区列表，用户可在天气卡片中直接切换。
    static let supportedRegions: [WeatherRegion] = [
        WeatherRegion(name: "上海", query: "Shanghai"),
        WeatherRegion(name: "北京", query: "Beijing"),
        WeatherRegion(name: "广州", query: "Guangzhou"),
        WeatherRegion(name: "深圳", query: "Shenzhen"),
        WeatherRegion(name: "成都", query: "Chengdu"),
        WeatherRegion(name: "杭州", query: "Hangzhou"),
        WeatherRegion(name: "武汉", query: "Wuhan"),
        WeatherRegion(name: "南京", query: "Nanjing"),
        WeatherRegion(name: "西安", query: "Xi'an"),
        WeatherRegion(name: "重庆", query: "Chongqing")
    ]

    private static let cityDefaultsKey = "weather.selectedCity"

    // TODO: 填入你的 OpenWeatherMap API Key（可选）
    // 申请地址：https://home.openweathermap.org/api_keys
    // 留空时应用会自动使用无需 Key 的 Open-Meteo 数据源。
    private let apiKey = ""

    init(city: String = "Shanghai") {
        let saved = UserDefaults.standard.string(forKey: Self.cityDefaultsKey)
        if let saved, !saved.isEmpty {
            self.city = saved
        } else {
            self.city = city
        }
    }

    /// 切换地区并刷新天气。
    func selectRegion(_ region: WeatherRegion) {
        setCity(region.query)
    }

    /// 设置为自定义城市并刷新天气。
    func setCity(_ newCity: String) {
        let trimmed = newCity.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != city else { return }
        city = trimmed
        UserDefaults.standard.set(trimmed, forKey: Self.cityDefaultsKey)
        Task { await fetchWeather() }
    }

    /// 获取当前天气。
    func fetchWeather() async {
        isLoading = true
        defer { isLoading = false }

        if !apiKey.isEmpty && apiKey != "YOUR_API_KEY" {
            await fetchOpenWeatherMap()
        } else {
            await fetchOpenMeteo()
        }
    }

    // MARK: - OpenWeatherMap

    private func fetchOpenWeatherMap() async {
        var components = URLComponents(string: "https://api.openweathermap.org/data/2.5/weather")
        components?.queryItems = [
            URLQueryItem(name: "q", value: city),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "lang", value: "zh_cn")
        ]

        guard let url = components?.url else {
            errorMessage = "天气请求 URL 无效。"
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                errorMessage = "天气服务返回异常状态。"
                return
            }
            let decoded = try JSONDecoder().decode(OpenWeatherResponse.self, from: data)
            weather = WeatherData(from: decoded)
            errorMessage = nil
        } catch {
            errorMessage = "天气数据加载失败：\(error.localizedDescription)"
        }
    }

    // MARK: - Open-Meteo（无需 Key 的免费回退）

    private func fetchOpenMeteo() async {
        do {
            let snapshot = try await OpenMeteoClient.shared.fetchWeather(city: city, forecastDays: 1)
            weather = WeatherData(
                city: snapshot.city,
                temperature: snapshot.temperature,
                conditionID: snapshot.conditionID,
                condition: snapshot.conditionText,
                high: snapshot.high,
                low: snapshot.low
            )
            errorMessage = nil
        } catch {
            errorMessage = "天气数据加载失败：\(error.localizedDescription)"
        }
    }

    // MARK: - 建议

    /// 根据当前天气与本地时间生成建议文案。
    var advice: String {
        guard let weather else { return "暂无天气建议" }
        let hour = Calendar.current.component(.hour, from: Date())
        return WeatherAdvice.advice(
            conditionID: currentConditionID,
            condition: weather.condition,
            hour: hour,
            high: weather.high
        )
    }

    /// 当前天气代码。
    private var currentConditionID: Int {
        weather?.conditionID ?? -1
    }
}
