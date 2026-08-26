import Foundation
@preconcurrency import UserNotifications

/// 课程表上课提醒：按“学期开始日期 + 星期 + 周次 + 单双周”精确排期。
@MainActor
final class TimetableReminderService {
    static let shared = TimetableReminderService()
    private init() {}

    /// 根据课程列表与学期开始日期重新排布所有上课提醒通知。
    func sync(courses: [Course], semesterStart: Date?) {
        let center = UNUserNotificationCenter.current()
        let prefix = "timetable-"

        center.getPendingNotificationRequests { [weak self] requests in
            guard let self else { return }
            let stale = requests
                .filter { $0.identifier.hasPrefix(prefix) }
                .map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: stale)

            let semester = Self.normalizedMonday(semesterStart ?? Self.defaultSemesterStart())
            var pending: [UNNotificationRequest] = []

            for course in courses where course.reminderEnabled {
                for week in course.startWeek...course.endWeek {
                    guard course.weeksPattern.matches(week: week) else { continue }
                    guard let fireDate = Self.fireDate(
                        course: course,
                        week: week,
                        semesterMonday: semester
                    ), fireDate > Date() else { continue }

                    var comps = Calendar.current.dateComponents(
                        [.year, .month, .day, .hour, .minute],
                        from: fireDate
                    )

                    let content = UNMutableNotificationContent()
                    content.title = "上课提醒 · \(course.name)"
                    var parts: [String] = []
                    if !course.location.isEmpty { parts.append(course.location) }
                    if !course.teacher.isEmpty { parts.append("老师：\(course.teacher)") }
                    content.body = parts.isEmpty
                        ? "\(course.startTimeText) 上课，记得提前准备"
                        : "\(course.startTimeText) 上课 · " + parts.joined(separator: " · ")
                    content.sound = .default

                    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                    let request = UNNotificationRequest(
                        identifier: "\(prefix)\(course.courseID.uuidString)-\(week)",
                        content: content,
                        trigger: trigger
                    )
                    pending.append(request)
                }
            }

            for request in pending {
                center.add(request)
            }
        }
    }

    /// 计算第 `week` 周该课程提醒的触发时间。
    private static func fireDate(course: Course, week: Int, semesterMonday: Date) -> Date? {
        let calendar = Calendar.current
        // 第 1 周星期 d 的日期 = semesterMonday + (d - 1) 天
        guard let courseDay = calendar.date(
            byAdding: .day,
            value: (week - 1) * 7 + (course.weekday - 1),
            to: semesterMonday
        ) else { return nil }

        let remindMinutes = max(0, course.startMinutes - course.reminderMinutesBefore)
        var comps = calendar.dateComponents([.year, .month, .day], from: courseDay)
        comps.hour = remindMinutes / 60
        comps.minute = remindMinutes % 60
        comps.second = 0
        return calendar.date(from: comps)
    }

    /// 把任意日期归一化到其所在周的周一。
    static func normalizedMonday(_ date: Date) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date) // 1=周日
        let daysFromMonday = (weekday + 5) % 7 // 周一=0 … 周日=6
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: calendar.startOfDay(for: date)) ?? date
    }

    /// 默认学期开始 = 本周周一（即当前为第 1 周）。
    static func defaultSemesterStart() -> Date {
        normalizedMonday(.now)
    }
}
