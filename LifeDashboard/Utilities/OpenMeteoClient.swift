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
}

struct OpenMeteoDay: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let high: Double
    let low: Double
    let weatherCode: Int
    let conditionText: String
    let conditionID: Int
}

struct OpenMeteoClient {
    static let shared = OpenMeteoClient()

    func fetchWeather(city: String, forecastDays: Int = 3) async throws -> OpenMeteoWeatherSnapshot {
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

        // 2. 经纬度 -> 当前天气 + 多日预报
        var forecastComponents = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        forecastComponents?.queryItems = [
            URLQueryItem(name: "latitude", value: String(place.latitude)),
            URLQueryItem(name: "longitude", value: String(place.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code"),
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: String(max(1, forecastDays)))
        ]
        guard let forecastURL = forecastComponents?.url else {
            throw URLError(.badURL)
        }
        let (forecastData, _) = try await URLSession.shared.data(from: forecastURL)
        let forecast = try JSONDecoder().decode(OpenMeteoForecastResponse.self, from: forecastData)

        let currentCode = forecast.current.weather_code
        let currentCondition = Self.condition(for: currentCode)

        let daily = forecast.daily
        let formatter = Self.dayFormatter
        let days = daily.time.enumerated().compactMap { index, dateString -> OpenMeteoDay? in
            guard let date = formatter.date(from: dateString) else { return nil }
            let code = index < daily.weather_code.count ? daily.weather_code[index] : 0
            let condition = Self.condition(for: code)
            let high = index < daily.temperature_2m_max.count ? daily.temperature_2m_max[index] : forecast.current.temperature_2m
            let low = index < daily.temperature_2m_min.count ? daily.temperature_2m_min[index] : forecast.current.temperature_2m
            return OpenMeteoDay(date: date, high: high, low: low, weatherCode: code, conditionText: condition.text, conditionID: condition.id)
        }

        let high = daily.temperature_2m_max.first ?? forecast.current.temperature_2m
        let low = daily.temperature_2m_min.first ?? forecast.current.temperature_2m
        let cityName = place.name.isEmpty ? city : place.name

        return OpenMeteoWeatherSnapshot(
            city: cityName,
            temperature: forecast.current.temperature_2m,
            conditionText: currentCondition.text,
            conditionID: currentCondition.id,
            high: high,
            low: low,
            days: days
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

    struct Current: Decodable {
        let temperature_2m: Double
        let weather_code: Int
    }

    struct Daily: Decodable {
        let time: [String]
        let weather_code: [Int]
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
    }
}
