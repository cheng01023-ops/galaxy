import Foundation

/// 默认天气数据源（供主 App 与 Widget 小组件共用）。
///
/// 优先使用「中国天气网（weather.com.cn，数据来自中央气象台）」：
/// - 无需 API Key；
/// - 国内城市与系统「天气预报」同源，温度、天气现象与预报更精准；
/// - 中国天气网不可用或查不到城市时，自动回退到 Open-Meteo（免费、全球通用）。
struct OpenMeteoWeatherSnapshot {
    let city: String
    let temperature: Double
    let conditionText: String
    let conditionID: Int
    let high: Double
    let low: Double
    let days: [OpenMeteoDay]

    // 以下为详情页所需的扩展字段，旧调用方（如 Widget）可省略。
    var weatherCode: Int = -1
    var feelsLike: Double = 0
    var humidity: Int? = nil
    var windSpeed: Double? = nil
    var pressure: Double? = nil
    var precipitationProbability: Int? = nil
    var sunrise: Date? = nil
    var sunset: Date? = nil
    var hourly: [WeatherHour] = []
}

struct OpenMeteoDay: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let high: Double
    let low: Double
    let weatherCode: Int
    let conditionText: String
    let conditionID: Int
    var precipitationProbability: Int? = nil
}

/// 逐小时天气预报。
struct WeatherHour: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let temperature: Double
    let weatherCode: Int
    let conditionText: String
    let conditionID: Int
    let humidity: Int?
    let precipitationProbability: Int?
}

struct OpenMeteoClient {
    static let shared = OpenMeteoClient()

    /// 获取天气：优先中国天气网（中央气象台），失败时回退 Open-Meteo。
    func fetchWeather(city: String, forecastDays: Int = 7) async throws -> OpenMeteoWeatherSnapshot {
        do {
            return try await ChinaWeatherProvider.fetch(city: city, forecastDays: forecastDays)
        } catch {
            // 中国天气网不可用 / 查不到城市（如海外城市）时，回退 Open-Meteo
            return try await fetchOpenMeteo(city: city, forecastDays: forecastDays)
        }
    }

    // MARK: - Open-Meteo（免费兜底数据源）

    private func fetchOpenMeteo(city: String, forecastDays: Int = 7) async throws -> OpenMeteoWeatherSnapshot {
        // 1. 城市名 -> 经纬度
        var geoComponents = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")
        geoComponents?.queryItems = [
            URLQueryItem(name: "name", value: city),
            URLQueryItem(name: "count", value: "1"),
            URLQueryItem(name: "language", value: "zh"),
            URLQueryItem(name: "format", value: "json")
        ]
        guard let geoURL = geoComponents?.url else {
            throw URLError(.badURL)
        }
        let (geoData, _) = try await URLSession.shared.data(from: geoURL)
        let geo = try JSONDecoder().decode(OpenMeteoGeocodingResponse.self, from: geoData)
        guard let place = geo.results.first else {
            throw OpenMeteoError.cityNotFound
        }

        // 2. 经纬度 -> 当前天气 + 逐小时 + 多日预报
        var forecastComponents = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        forecastComponents?.queryItems = [
            URLQueryItem(name: "latitude", value: String(place.latitude)),
            URLQueryItem(name: "longitude", value: String(place.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,surface_pressure"),
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_probability_max"),
            URLQueryItem(name: "hourly", value: "temperature_2m,relative_humidity_2m,weather_code,precipitation_probability"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: String(max(1, forecastDays))),
            URLQueryItem(name: "forecast_hours", value: "24")
        ]
        guard let forecastURL = forecastComponents?.url else {
            throw URLError(.badURL)
        }
        let (forecastData, _) = try await URLSession.shared.data(from: forecastURL)
        let forecast = try JSONDecoder().decode(OpenMeteoForecastResponse.self, from: forecastData)

        let currentCode = forecast.current.weather_code
        let currentCondition = Self.condition(for: currentCode)

        let daily = forecast.daily
        let dayFormatter = Self.dayFormatter
        let timeFormatter = Self.timeFormatter
        let dailyPrecip = daily.precipitation_probability_max ?? []

        let days = daily.time.enumerated().compactMap { index, dateString -> OpenMeteoDay? in
            guard let date = dayFormatter.date(from: dateString) else { return nil }
            let code = index < daily.weather_code.count ? daily.weather_code[index] : 0
            let condition = Self.condition(for: code)
            let high = index < daily.temperature_2m_max.count ? daily.temperature_2m_max[index] : forecast.current.temperature_2m
            let low = index < daily.temperature_2m_min.count ? daily.temperature_2m_min[index] : forecast.current.temperature_2m
            let precip = index < dailyPrecip.count ? dailyPrecip[index] : nil
            return OpenMeteoDay(
                date: date,
                high: high,
                low: low,
                weatherCode: code,
                conditionText: condition.text,
                conditionID: condition.id,
                precipitationProbability: precip
            )
        }

        let hourlyHumidity = forecast.hourly.relative_humidity_2m ?? []
        let hourlyPrecip = forecast.hourly.precipitation_probability ?? []
        let hourly = forecast.hourly.time.enumerated().compactMap { index, dateString -> WeatherHour? in
            guard let date = timeFormatter.date(from: dateString) else { return nil }
            let code = index < forecast.hourly.weather_code.count ? forecast.hourly.weather_code[index] : 0
            let condition = Self.condition(for: code)
            let temperature = index < forecast.hourly.temperature_2m.count ? forecast.hourly.temperature_2m[index] : forecast.current.temperature_2m
            let humidity = index < hourlyHumidity.count ? Int(hourlyHumidity[index].rounded()) : nil
            let precip = index < hourlyPrecip.count ? hourlyPrecip[index] : nil
            return WeatherHour(
                date: date,
                temperature: temperature,
                weatherCode: code,
                conditionText: condition.text,
                conditionID: condition.id,
                humidity: humidity,
                precipitationProbability: precip
            )
        }

        let high = daily.temperature_2m_max.first ?? forecast.current.temperature_2m
        let low = daily.temperature_2m_min.first ?? forecast.current.temperature_2m
        let feelsLike = forecast.current.apparent_temperature ?? forecast.current.temperature_2m
        let sunrise = daily.sunrise?.first.flatMap { timeFormatter.date(from: $0) }
        let sunset = daily.sunset?.first.flatMap { timeFormatter.date(from: $0) }
        let todayPrecip = dailyPrecip.first
        let cityName = place.name.isEmpty ? city : place.name

        return OpenMeteoWeatherSnapshot(
            city: cityName,
            temperature: forecast.current.temperature_2m,
            conditionText: currentCondition.text,
            conditionID: currentCondition.id,
            high: high,
            low: low,
            days: days,
            weatherCode: currentCode,
            feelsLike: feelsLike,
            humidity: forecast.current.relative_humidity_2m.map { Int($0.rounded()) },
            windSpeed: forecast.current.wind_speed_10m,
            pressure: forecast.current.surface_pressure,
            precipitationProbability: todayPrecip,
            sunrise: sunrise,
            sunset: sunset,
            hourly: hourly
        )
    }

    // MARK: - WMO 天气代码映射

    static func condition(for code: Int) -> (text: String, id: Int) {
        switch code {
        case 0: return ("晴", 800)
        case 1: return ("大部晴朗", 800)
        case 2: return ("多云", 801)
        case 3: return ("阴", 804)
        case 45, 48: return ("雾", 701)
        case 51, 53, 55, 56, 57: return ("毛毛雨", 300)
        case 61, 63, 65, 66, 67: return ("雨", 500)
        case 71, 73, 75, 77: return ("雪", 600)
        case 80, 81, 82: return ("阵雨", 500)
        case 85, 86: return ("阵雪", 600)
        case 95, 96, 99: return ("雷雨", 200)
        default: return ("多云", 801)
        }
    }

    static func sfSymbol(for code: Int) -> String {
        switch code {
        case 0, 1: return "sun.max.fill"
        case 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55, 56, 57, 61, 63, 65, 80, 81, 82: return "cloud.rain.fill"
        case 66, 67: return "cloud.sleet.fill"
        case 71, 73, 75, 77, 85, 86: return "cloud.snow.fill"
        case 95, 96, 99: return "cloud.bolt.rain.fill"
        case 741: return "cloud.haze.fill"
        case 761, 762: return "sun.dust.fill"
        default: return "cloud.sun.fill"
        }
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter
    }()
}

enum OpenMeteoError: Error {
    case cityNotFound
}

// MARK: - 响应模型

struct OpenMeteoGeocodingResponse: Decodable {
    let results: [Place]

    struct Place: Decodable {
        let name: String
        let latitude: Double
        let longitude: Double
    }
}

struct OpenMeteoForecastResponse: Decodable {
    let current: Current
    let daily: Daily
    let hourly: Hourly

    struct Current: Decodable {
        let temperature_2m: Double
        let weather_code: Int
        let relative_humidity_2m: Double?
        let apparent_temperature: Double?
        let precipitation: Double?
        let wind_speed_10m: Double?
        let surface_pressure: Double?
    }

    struct Daily: Decodable {
        let time: [String]
        let weather_code: [Int]
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
        let sunrise: [String]?
        let sunset: [String]?
        let precipitation_probability_max: [Int]?
    }

    struct Hourly: Decodable {
        let time: [String]
        let temperature_2m: [Double]
        let weather_code: [Int]
        let relative_humidity_2m: [Double]?
        let precipitation_probability: [Int]?
    }
}

// MARK: - 中国天气网（中央气象台）数据源

/// 中国天气网（weather.com.cn）数据源，数据来自中央气象台，无需 API Key。
/// 国内城市与系统「天气预报」同源，温度、天气现象更精准。
/// 请求失败时由 `OpenMeteoClient.fetchWeather` 自动回退到 Open-Meteo。
enum ChinaWeatherProvider {

    // MARK: 常量

    private static let searchURL = "https://toy1.weather.com.cn/search"
    private static let realtimeURL = "https://d1.weather.com.cn/sk_2d"
    private static let todayURL = "https://d1.weather.com.cn/dingzhi"
    private static let forecastURL = "https://www.weather.com.cn/weather1d"

    /// 内置城市英文名 -> 中文名，避免英文搜索串号（如 Hangzhou / Xi'an 会匹配到错误地区）。
    static let knownEnglishQueries: [String: String] = [
        "Shanghai": "上海", "Beijing": "北京", "Guangzhou": "广州",
        "Shenzhen": "深圳", "Chengdu": "成都", "Hangzhou": "杭州",
        "Wuhan": "武汉", "Nanjing": "南京", "Xi'an": "西安", "Chongqing": "重庆"
    ]

    // MARK: 入口

    static func fetch(city: String, forecastDays: Int = 7) async throws -> OpenMeteoWeatherSnapshot {
        // 1. 城市 -> 城市 ID
        let query = knownEnglishQueries[city] ?? city
        let (cityID, cityName) = try await resolveCity(query)

        // 2. 并行获取：实时天气、今日预报、一周逐 3 小时预报
        async let realtime = fetchRealtime(cityID: cityID)
        async let today = fetchToday(cityID: cityID)
        async let week = fetchWeek(cityID: cityID)
        let (current, todayInfo, weekInfo) = try await (realtime, today, week)

        // 今日最高/最低：以中央气象台今日预报为准；缺失时回退到逐小时推算值
        let todayHigh = todayInfo.high ?? weekInfo.days.first?.high ?? current.temperature
        let todayLow = todayInfo.low ?? weekInfo.days.first?.low ?? current.temperature

        var days = weekInfo.days
        if let first = days.first {
            let todayCondition = Self.condition(forChinaCode: todayInfo.dayCode)
            days[0] = OpenMeteoDay(
                date: first.date,
                high: todayHigh,
                low: todayLow,
                weatherCode: todayCondition.code,
                conditionText: todayInfo.conditionText.isEmpty ? todayCondition.text : todayInfo.conditionText,
                conditionID: todayCondition.id
            )
        }

        let currentCondition = Self.condition(forChinaCode: current.weatherCode)

        return OpenMeteoWeatherSnapshot(
            city: cityName,
            temperature: current.temperature,
            conditionText: current.conditionText.isEmpty ? currentCondition.text : current.conditionText,
            conditionID: currentCondition.id,
            high: todayHigh,
            low: todayLow,
            days: Array(days.prefix(max(1, forecastDays))),
            weatherCode: currentCondition.code,
            feelsLike: current.temperature,
            humidity: current.humidity,
            windSpeed: current.windSpeed,
            pressure: current.pressure,
            precipitationProbability: nil,
            sunrise: weekInfo.sunrise,
            sunset: weekInfo.sunset,
            hourly: weekInfo.hourly
        )
    }

    // MARK: 城市搜索

    /// 搜索城市，返回（城市ID, 中文城市名）。
    static func resolveCity(_ query: String) async throws -> (cityID: String, cityName: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ChinaWeatherError.cityNotFound }

        var components = URLComponents(string: searchURL)
        components?.queryItems = [
            URLQueryItem(name: "cityname", value: trimmed),
            URLQueryItem(name: "callback", value: "success_jsonpCallback"),
            URLQueryItem(name: "_", value: String(Int(Date().timeIntervalSince1970 * 1000)))
        ]
        guard let url = components?.url else { throw URLError(.badURL) }

        let body = try await getString(url.absoluteString)
        guard let array = extractJSONArray(body) else { throw ChinaWeatherError.cityNotFound }

        // 优先取第一个 9 位数字城市 ID 的结果（跳过景点等特殊 ID）
        for item in array {
            guard let ref = item["ref"] as? String else { continue }
            let parts = ref.split(separator: "~").map(String.init)
            guard let first = parts.first,
                  first.count == 9,
                  first.allSatisfy({ $0.isNumber }) else { continue }
            let name = parts.count > 2 ? parts[2] : trimmed
            return (first, name)
        }
        throw ChinaWeatherError.cityNotFound
    }

    // MARK: 实时天气

    private struct ChinaRealtime {
        let temperature: Double
        let conditionText: String
        let weatherCode: String
        let humidity: Int?
        let windSpeed: Double?
        let pressure: Double?
    }

    private static func fetchRealtime(cityID: String) async throws -> ChinaRealtime {
        let body = try await getString("\(realtimeURL)/\(cityID).html")
        guard let dict = extractJSONObject(body, after: "var dataSK=") else {
            throw ChinaWeatherError.invalidResponse
        }
        return ChinaRealtime(
            temperature: numberPrefix(dict["temp"] as? String) ?? 0,
            conditionText: (dict["weather"] as? String) ?? "",
            weatherCode: (dict["weathercode"] as? String) ?? "01",
            humidity: numberPrefix(dict["SD"] as? String).map { Int($0.rounded()) },
            windSpeed: numberPrefix(dict["wse"] as? String),
            pressure: numberPrefix(dict["qy"] as? String)
        )
    }

    // MARK: 今日预报

    private struct ChinaToday {
        let high: Double?
        let low: Double?
        let dayCode: String
        let conditionText: String
    }

    private static func fetchToday(cityID: String) async throws -> ChinaToday {
        let body = try await getString("\(todayURL)/\(cityID).html")
        guard let wrapper = extractJSONObject(body, after: "var cityDZ"),
              let info = wrapper["weatherinfo"] as? [String: Any] else {
            throw ChinaWeatherError.invalidResponse
        }
        return ChinaToday(
            high: temperatureValue(info["temp"] as? String),
            low: temperatureValue(info["tempn"] as? String),
            dayCode: (info["weathercode"] as? String) ?? "01",
            conditionText: (info["weather"] as? String) ?? ""
        )
    }

    // MARK: 一周预报 + 逐小时 + 日出日落

    private struct ChinaWeek {
        let days: [OpenMeteoDay]
        let hourly: [WeatherHour]
        let sunrise: Date?
        let sunset: Date?
    }

    private struct ChinaHourEntry {
        let date: Date
        let code: String
        let text: String
        let temperature: Double
    }

    private static func fetchWeek(cityID: String) async throws -> ChinaWeek {
        let body = try await getString("\(forecastURL)/\(cityID).shtml")
        guard let dict = extractJSONObject(body, after: "var hour3data=") else {
            throw ChinaWeatherError.invalidResponse
        }

        let hourlyRaw = (dict["1d"] as? [String]) ?? []
        let weekRaw = ((dict["7d"] as? [[String]]) ?? []).flatMap { $0 }

        let hourly = parseHourEntries(hourlyRaw).map { entry in
            let condition = Self.condition(forChinaCode: entry.code)
            return WeatherHour(
                date: entry.date,
                temperature: entry.temperature,
                weatherCode: condition.code,
                conditionText: entry.text.isEmpty ? condition.text : entry.text,
                conditionID: condition.id,
                humidity: nil,
                precipitationProbability: nil
            )
        }

        let days = aggregateDays(parseHourEntries(weekRaw))
        return ChinaWeek(
            days: days,
            hourly: hourly,
            sunrise: time(from: body, label: "日出"),
            sunset: time(from: body, label: "日落")
        )
    }

    /// 解析 "21日23时,d07,小雨,28℃,东风,<3级,0" 格式的逐 3 小时条目。
    private static func parseHourEntries(_ raw: [String]) -> [ChinaHourEntry] {
        let calendar = Calendar.current
        let now = Date()
        var year = calendar.component(.year, from: now)
        var month = calendar.component(.month, from: now)
        var prevDay = 0
        var entries: [ChinaHourEntry] = []

        for line in raw {
            let parts = line.split(separator: ",").map(String.init)
            guard parts.count >= 4, let dayHour = parseDayHour(parts[0]) else { continue }
            let code = parts.count > 1 ? parts[1] : "01"
            let text = parts.count > 2 ? parts[2] : ""
            let temperature = temperatureValue(parts[3]) ?? 0

            // 数据只有“日”，跨月时需要推断月份/年份
            if prevDay > 0 && dayHour.day < prevDay {
                month += 1
                if month > 12 {
                    month = 1
                    year += 1
                }
            }
            prevDay = dayHour.day

            guard let date = calendar.date(from: DateComponents(
                year: year, month: month, day: dayHour.day, hour: dayHour.hour
            )) else { continue }
            entries.append(ChinaHourEntry(date: date, code: code, text: text, temperature: temperature))
        }
        return entries
    }

    /// 解析 "21日23时" 为 (日, 时)。
    private static func parseDayHour(_ label: String) -> (day: Int, hour: Int)? {
        guard let dayRange = label.range(of: "日"),
              let hourRange = label.range(of: "时"),
              dayRange.upperBound < hourRange.lowerBound else { return nil }
        let dayText = label[..<dayRange.lowerBound]
        let hourText = label[dayRange.upperBound..<hourRange.lowerBound]
        guard let day = Int(dayText), let hour = Int(hourText) else { return nil }
        return (day, hour)
    }

    /// 按自然日聚合逐小时条目，得到每日最高/最低温与代表天气。
    private static func aggregateDays(_ entries: [ChinaHourEntry]) -> [OpenMeteoDay] {
        let calendar = Calendar.current
        var grouped: [Date: [ChinaHourEntry]] = [:]
        var order: [Date] = []

        for entry in entries {
            let day = calendar.startOfDay(for: entry.date)
            if grouped[day] == nil { order.append(day) }
            grouped[day, default: []].append(entry)
        }

        return order.prefix(7).compactMap { day in
            guard let items = grouped[day], let first = items.first else { return nil }
            let high = items.map(\.temperature).max() ?? first.temperature
            let low = items.map(\.temperature).min() ?? first.temperature
            // 用 11 时（正午）的天气代表当日；没有则取第一条
            let representative = items.first(where: { calendar.component(.hour, from: $0.date) == 11 }) ?? first
            let condition = Self.condition(forChinaCode: representative.code)
            return OpenMeteoDay(
                date: day,
                high: high,
                low: low,
                weatherCode: condition.code,
                conditionText: representative.text.isEmpty ? condition.text : representative.text,
                conditionID: condition.id
            )
        }
    }

    // MARK: 中国天气网天气代码映射

    /// 中国天气网天气代码（如 d00/d07/n04）-> 展示用天气。
    struct ChinaCondition {
        let text: String
        let id: Int
        let code: Int
    }

    static func condition(forChinaCode raw: String) -> ChinaCondition {
        let code = raw
            .lowercased()
            .replacingOccurrences(of: "d", with: "")
            .replacingOccurrences(of: "n", with: "")
        switch code {
        case "00": return ChinaCondition(text: "晴", id: 800, code: 0)
        case "01": return ChinaCondition(text: "多云", id: 801, code: 2)
        case "02": return ChinaCondition(text: "阴", id: 804, code: 3)
        case "03": return ChinaCondition(text: "阵雨", id: 500, code: 80)
        case "04", "05": return ChinaCondition(text: "雷阵雨", id: 200, code: 95)
        case "06": return ChinaCondition(text: "雨夹雪", id: 611, code: 66)
        case "07": return ChinaCondition(text: "小雨", id: 500, code: 61)
        case "08": return ChinaCondition(text: "中雨", id: 500, code: 63)
        case "09", "10", "11", "12": return ChinaCondition(text: "大雨", id: 500, code: 65)
        case "13": return ChinaCondition(text: "阵雪", id: 600, code: 85)
        case "14": return ChinaCondition(text: "小雪", id: 600, code: 71)
        case "15": return ChinaCondition(text: "中雪", id: 600, code: 73)
        case "16", "17": return ChinaCondition(text: "大雪", id: 600, code: 75)
        case "18": return ChinaCondition(text: "雾", id: 701, code: 45)
        case "19": return ChinaCondition(text: "冻雨", id: 611, code: 66)
        case "20", "29", "30", "31": return ChinaCondition(text: "沙尘", id: 761, code: 761)
        case "21": return ChinaCondition(text: "小到中雨", id: 500, code: 61)
        case "22": return ChinaCondition(text: "中到大雨", id: 500, code: 63)
        case "23", "24", "25": return ChinaCondition(text: "大到暴雨", id: 500, code: 65)
        case "26": return ChinaCondition(text: "小雪到中雪", id: 600, code: 71)
        case "27": return ChinaCondition(text: "中到大雪", id: 600, code: 73)
        case "28": return ChinaCondition(text: "大到暴雪", id: 600, code: 75)
        case "32": return ChinaCondition(text: "霾", id: 741, code: 741)
        case "33", "49": return ChinaCondition(text: "浓雾", id: 701, code: 45)
        case "53", "54", "55", "56", "57", "58": return ChinaCondition(text: "霾", id: 741, code: 741)
        default: return ChinaCondition(text: "多云", id: 801, code: 2)
        }
    }

    // MARK: 解析工具

    /// 解析 "32℃"、"85%"、"1km/h" 这类字符串开头的数字。
    private static func numberPrefix(_ string: String?) -> Double? {
        guard let string else { return nil }
        let digits = string.prefix { $0.isNumber || $0 == "." || $0 == "-" }
        guard !digits.isEmpty, let value = Double(String(digits)) else { return nil }
        return value
    }

    /// 解析温度字符串；中国天气网用 999 表示“未知”。
    private static func temperatureValue(_ string: String?) -> Double? {
        guard let value = numberPrefix(string), value < 990 else { return nil }
        return value
    }

    /// 从页面文本中提取形如 "日出 05:23" / "日落 18:31" 的时间，并拼到今天。
    private static func time(from text: String, label: String) -> Date? {
        let pattern = "\(label)\\s*(\\d{1,2}:\\d{2})"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return nil }
        let timeText = String(text[range])

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        guard let base = formatter.date(from: timeText) else { return nil }

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = calendar.component(.hour, from: base)
        components.minute = calendar.component(.minute, from: base)
        return calendar.date(from: components)
    }

    /// 从文本中提取 `var xxx={...};` 形式的 JSON 对象。
    private static func extractJSONObject(_ text: String, after marker: String) -> [String: Any]? {
        guard let markerRange = text.range(of: marker) else { return nil }
        var cursor = markerRange.upperBound
        while cursor < text.endIndex, text[cursor] != "{" {
            cursor = text.index(after: cursor)
        }
        guard cursor < text.endIndex, text[cursor] == "{" else { return nil }

        let start = cursor
        var depth = 0
        var inString = false
        while cursor < text.endIndex {
            let character = text[cursor]
            if inString {
                if character == "\\" {
                    cursor = text.index(cursor, offsetBy: 2, limitedBy: text.endIndex) ?? text.endIndex
                    continue
                }
                if character == "\"" { inString = false }
            } else {
                switch character {
                case "\"": inString = true
                case "{": depth += 1
                case "}":
                    depth -= 1
                    if depth == 0 {
                        let json = String(text[start...cursor])
                        return try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]
                    }
                default: break
                }
            }
            cursor = text.index(after: cursor)
        }
        return nil
    }

    /// 提取 JSONP 包裹的 JSON 数组，如 `callback([{...}])`。
    private static func extractJSONArray(_ text: String) -> [[String: Any]]? {
        guard let open = text.firstIndex(of: "["),
              let close = text.lastIndex(of: "]"),
              open < close else { return nil }
        let json = String(text[open...close])
        return try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [[String: Any]]
    }

    // MARK: 网络

    private static func getString(_ urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("https://www.weather.com.cn/", forHTTPHeaderField: "Referer")
        request.setValue("application/json, text/javascript, */*; q=0.01", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        guard let string = String(data: data, encoding: .utf8) else {
            throw ChinaWeatherError.invalidResponse
        }
        return string
    }
}

enum ChinaWeatherError: Error {
    case cityNotFound
    case invalidResponse
}
