import Foundation

/// 无需 API Key 的天气数据源（Open-Meteo），供主 App 与 Widget 小组件共用。
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

    func fetchWeather(city: String, forecastDays: Int = 7) async throws -> OpenMeteoWeatherSnapshot {
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
        case 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82: return "cloud.rain.fill"
        case 71, 73, 75, 77, 85, 86: return "cloud.snow.fill"
        case 95, 96, 99: return "cloud.bolt.rain.fill"
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
