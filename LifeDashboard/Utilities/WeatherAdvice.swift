import Foundation

/// 根据天气状况、天气代码和本地时间生成简短生活建议。
enum WeatherAdvice {
    static func advice(conditionID: Int, condition: String, hour: Int, high: Double) -> String {
        // OpenWeatherMap 天气代码分组参考：
        // 2xx 雷雨，3xx 毛毛雨，5xx 雨，6xx 雪，7xx 雾/霾，800 晴，80x 多云。
        switch conditionID {
        case 200...232:
            return "有雷雨，出门记得带伞，注意安全"
        case 300...321, 500...531:
            return "有降雨，出门记得带伞"
        case 600...622:
            return "有降雪，注意保暖和防滑"
        case 701...781:
            return "能见度较低，出行注意安全"
        case 800:
            if hour >= 10 && hour <= 16 && high >= 28 {
                return "阳光强烈，注意防晒补水"
            }
            return "天气晴好，适合外出活动"
        case 801...804:
            return "多云天气，体感舒适"
        default:
            return "关注天气变化，适当增减衣物"
        }
    }
}
