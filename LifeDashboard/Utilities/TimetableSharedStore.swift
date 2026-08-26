import Foundation

/// 主 App 与桌面小组件之间共享的轻量课程结构（通过 App Group 的 UserDefaults 传递）。
struct WidgetCourse: Codable, Identifiable, Hashable {
    var id: UUID { courseID }
    let courseID: UUID
    let name: String
    let teacher: String
    let location: String
    /// 星期：1=周一 … 7=周日
    let weekday: Int
    let startMinutes: Int
    let endMinutes: Int
    let startWeek: Int
    let endWeek: Int
    let weeksPatternRaw: String
    let colorHex: String

    /// 某教学周是否上课。
    func isActive(inWeek week: Int) -> Bool {
        guard week >= startWeek && week <= endWeek else { return false }
        switch weeksPatternRaw {
        case "单周": return week % 2 == 1
        case "双周": return week % 2 == 0
        default: return true
        }
    }

    static func timeText(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return String(format: "%02d:%02d", h, m)
    }
}

/// 课程表与小组件共享的数据仓库（App Group）。
enum TimetableSharedStore {
    static let appGroupID = "group.com.k4rulxu3k4.Galaxy"

    private static let coursesKey = "timetable.courses.v1"
    private static let semesterKey = "timetable.semesterStart.v1"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    // MARK: - 课程读写

    static func save(_ courses: [WidgetCourse]) {
        if let data = try? JSONEncoder().encode(courses) {
            defaults.set(data, forKey: coursesKey)
        }
    }

    static func load() -> [WidgetCourse] {
        guard let data = defaults.data(forKey: coursesKey),
              let list = try? JSONDecoder().decode([WidgetCourse].self, from: data) else {
            return []
        }
        return list
    }

    // MARK: - 学期开始日期

    static func saveSemesterStart(_ date: Date) {
        defaults.set(date.timeIntervalSince1970, forKey: semesterKey)
    }

    static func loadSemesterStart() -> Date? {
        guard defaults.object(forKey: semesterKey) != nil else { return nil }
        return Date(timeIntervalSince1970: defaults.double(forKey: semesterKey))
    }

    // MARK: - 教学周计算

    /// 当前教学周（从学期开始日期起算，1 为第 1 周）。
    static func currentWeek(semesterStart: Date?, now: Date = .now) -> Int {
        guard let start = semesterStart else { return 1 }
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let today = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: startDay, to: today).day ?? 0
        return max(1, days / 7 + 1)
    }

    /// 把 iOS 的 weekday（1=周日 … 7=周六）转成课程表使用的星期（1=周一 … 7=周日）。
    static func chineseWeekday(for date: Date) -> Int {
        let weekday = Calendar.current.component(.weekday, from: date)
        return ((weekday + 5) % 7) + 1
    }

    /// 某一天应上的课程（按单双周过滤后，按开始时间排序）。
    static func courses(on date: Date, all: [WidgetCourse], semesterStart: Date?) -> [WidgetCourse] {
        let weekday = chineseWeekday(for: date)
        let week = currentWeek(semesterStart: semesterStart, now: date)
        return all
            .filter { $0.weekday == weekday && $0.isActive(inWeek: week) }
            .sorted { $0.startMinutes < $1.startMinutes }
    }

    /// 构造某门课程在指定日期对应的开始时间。
    static func startDate(for course: WidgetCourse, on date: Date) -> Date {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month, .day], from: date)
        comps.hour = course.startMinutes / 60
        comps.minute = course.startMinutes % 60
        comps.second = 0
        return calendar.date(from: comps) ?? date
    }

    /// 距离 date 最近的下一节课（包含未来 14 天内），返回课程与开始时间。
    static func nextCourse(after date: Date, all: [WidgetCourse], semesterStart: Date?) -> (course: WidgetCourse, date: Date)? {
        let calendar = Calendar.current
        var best: (WidgetCourse, Date)?
        for offset in 0..<14 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: date) else { continue }
            let weekday = chineseWeekday(for: day)
            let week = currentWeek(semesterStart: semesterStart, now: day)
            let candidates = all
                .filter { $0.weekday == weekday && $0.isActive(inWeek: week) }
                .sorted { $0.startMinutes < $1.startMinutes }
            for course in candidates {
                let start = startDate(for: course, on: day)
                if start >= date {
                    if best == nil || start < best!.1 {
                        best = (course, start)
                    }
                    break
                }
            }
        }
        return best
    }
}
