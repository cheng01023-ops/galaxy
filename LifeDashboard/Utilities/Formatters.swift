import Foundation

/// 集中管理日期格式化，避免在视图中重复创建 DateFormatter。
enum Formatters {
    /// 短时间，如 09:30
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    /// 短日期，如 8月19日
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    /// 周几，如 周日
    static let weekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()

    /// 数字格式化：整数不显示小数，其余保留一位。
    static func number(_ value: Double, maximumFractionDigits: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// 本周日期范围文案，如 8月19日 - 8月25日。
    static func weekRangeText(start: Date, end: Date) -> String {
        "\(shortDate.string(from: start)) - \(shortDate.string(from: end))"
    }

    /// 判断某天是否为周日（每周小结的生成日）。
    static func isSunday(_ date: Date = .now) -> Bool {
        Calendar.current.component(.weekday, from: date) == 1
    }
}
