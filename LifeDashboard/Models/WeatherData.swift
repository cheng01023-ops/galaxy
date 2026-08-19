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

/// 供 UI 使用的天气展示模型。
struct WeatherData {
    let temperature: Double
    let conditionID: Int
    let condition: String
    let icon: String
    init(city: String, temperature: Double, conditionID: Int, condition: String, high: Double, low: Double, icon: String = "sun.max.fill") {
        self.city = city
        self.temperature = temperature
        self.conditionID = conditionID
        self.condition = condition
        self.high = high
        self.low = low
        self.icon = icon
    }

    let high: Double
    let low: Double
    let city: String

    init?(from response: OpenWeatherResponse) {
        guard let first = response.weather.first else { return nil }
        self.temperature = response.main.temp
        self.conditionID = first.id
        self.condition = first.main
        self.icon = first.icon
        self.high = response.main.tempMax
        self.low = response.main.tempMin
        self.city = response.name ?? "Shanghai"
    }
}
