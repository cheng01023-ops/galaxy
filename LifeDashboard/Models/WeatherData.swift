import Foundation

/// OpenWeatherMap 当前天气接口的响应模型（部分字段）。
struct OpenWeatherResponse: Decodable {
    let weather: [WeatherCondition]
    let main: MainWeather
    let name: String?

    struct WeatherCondition: Decodable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }

    struct MainWeather: Decodable {
        let temp: Double
        let tempMin: Double
        let tempMax: Double

        enum CodingKeys: String, CodingKey {
            case temp
            case tempMin = "temp_min"
            case tempMax = "temp_max"
        }
    }
}

/// 可供切换的天气地区。
struct WeatherRegion: Identifiable, Hashable {
    /// 显示名称，例如“上海”。
    let name: String
    /// 查询关键字，例如“Shanghai”。
    let query: String

    var id: String { query }
}

/// 供 UI 使用的天气展示模型。
struct WeatherData {
    let city: String
    let temperature: Double
    let feelsLike: Double
    let conditionID: Int
    let condition: String
    let icon: String
    let weatherCode: Int
    let high: Double
    let low: Double
    let humidity: Int?
    let windSpeed: Double?
    let pressure: Double?
    let precipitationProbability: Int?
    let sunrise: Date?
    let sunset: Date?
    let hourly: [WeatherHour]
    let daily: [OpenMeteoDay]

    init(
        city: String,
        temperature: Double,
        feelsLike: Double,
        conditionID: Int,
        condition: String,
        high: Double,
        low: Double,
        weatherCode: Int,
        humidity: Int? = nil,
        windSpeed: Double? = nil,
        pressure: Double? = nil,
        precipitationProbability: Int? = nil,
        sunrise: Date? = nil,
        sunset: Date? = nil,
        hourly: [WeatherHour] = [],
        daily: [OpenMeteoDay] = [],
        icon: String = "cloud.sun.fill"
    ) {
        self.city = city
        self.temperature = temperature
        self.feelsLike = feelsLike
        self.conditionID = conditionID
        self.condition = condition
        self.icon = icon
        self.weatherCode = weatherCode
        self.high = high
        self.low = low
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.pressure = pressure
        self.precipitationProbability = precipitationProbability
        self.sunrise = sunrise
        self.sunset = sunset
        self.hourly = hourly
        self.daily = daily
    }

    init?(from response: OpenWeatherResponse) {
        guard let first = response.weather.first else { return nil }
        self.city = response.name ?? "Shanghai"
        self.temperature = response.main.temp
        self.feelsLike = response.main.temp
        self.conditionID = first.id
        self.condition = first.main
        self.icon = first.icon
        self.weatherCode = -1
        self.high = response.main.tempMax
        self.low = response.main.tempMin
        self.humidity = nil
        self.windSpeed = nil
        self.pressure = nil
        self.precipitationProbability = nil
        self.sunrise = nil
        self.sunset = nil
        self.hourly = []
        self.daily = []
    }

    /// 根据天气代码返回合适的 SF Symbol。
    var symbolName: String {
        if weatherCode >= 0 {
            return OpenMeteoClient.sfSymbol(for: weatherCode)
        }
        switch conditionID {
        case 200...232: return "cloud.bolt.rain.fill"
        case 300...321, 500...531: return "cloud.rain.fill"
        case 600...622: return "cloud.snow.fill"
        case 701...781: return "cloud.fog.fill"
        case 800: return "sun.max.fill"
        case 801...804: return "cloud.sun.fill"
        default: return "cloud.sun.fill"
        }
    }
}
