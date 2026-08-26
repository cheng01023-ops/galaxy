import Foundation
import SwiftData

/// 单双周模式。
enum WeekPattern: String, CaseIterable, Codable, Identifiable {
    case all = "每周"
    case odd = "单周"
    case even = "双周"

    var id: String { rawValue }

    /// 判断某教学周是否匹配当前单双周设置。
    func matches(week: Int) -> Bool {
        switch self {
        case .all: return true
        case .odd: return week % 2 == 1
        case .even: return week % 2 == 0
        }
    }
}

/// 一门课程。使用 SwiftData 持久化。
@Model
final class Course {
    /// 稳定标识，用于通知与小组件同步，不依赖 SwiftData 的 persistentID。
    var courseID: UUID
    var name: String
    var teacher: String
    var location: String
    /// 星期：1=周一 … 7=周日
    var weekday: Int
    /// 从 00:00 开始计算的分钟数
    var startMinutes: Int
    var endMinutes: Int
    /// 起止周次（含）
    var startWeek: Int
    var endWeek: Int
    var weeksPatternRaw: String
    var colorHex: String
    var reminderEnabled: Bool
    var reminderMinutesBefore: Int
    var createdAt: Date

    init(
        name: String,
        teacher: String = "",
        location: String = "",
        weekday: Int = 1,
        startMinutes: Int = 8 * 60,
        endMinutes: Int = 9 * 60 + 40,
        startWeek: Int = 1,
        endWeek: Int = 16,
        weeksPattern: WeekPattern = .all,
        colorHex: String = "0x5AC8FA",
        reminderEnabled: Bool = false,
        reminderMinutesBefore: Int = 15,
        courseID: UUID = UUID(),
        createdAt: Date = .now
    ) {
        self.courseID = courseID
        self.name = name
        self.teacher = teacher
        self.location = location
        self.weekday = weekday
        self.startMinutes = startMinutes
        self.endMinutes = endMinutes
        self.startWeek = startWeek
        self.endWeek = endWeek
        self.weeksPatternRaw = weeksPattern.rawValue
        self.colorHex = colorHex
        self.reminderEnabled = reminderEnabled
        self.reminderMinutesBefore = reminderMinutesBefore
        self.createdAt = createdAt
    }

    var weeksPattern: WeekPattern {
        get { WeekPattern(rawValue: weeksPatternRaw) ?? .all }
        set { weeksPatternRaw = newValue.rawValue }
    }

    var startTimeText: String { Course.timeText(startMinutes) }
    var endTimeText: String { Course.timeText(endMinutes) }
    var durationText: String { "\(startTimeText) - \(endTimeText)" }

    /// 本周是否上课（按教学周与单双周判断）。
    func isActive(inWeek week: Int) -> Bool {
        week >= startWeek && week <= endWeek && weeksPattern.matches(week: week)
    }

    static let weekdays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
    static let shortWeekdays = ["一", "二", "三", "四", "五", "六", "日"]

    static func timeText(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return String(format: "%02d:%02d", h, m)
    }
}
