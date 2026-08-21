import Foundation
@preconcurrency import UserNotifications

/// 负责喝水提醒时间的本地持久化与每日通知。
@MainActor
final class WaterReminderService: ObservableObject {
    static let shared = WaterReminderService()

    @Published private(set) var reminders: [WaterReminder]

    private let defaultsKey = "water.reminders.v1"

    private init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let saved = try? JSONDecoder().decode([WaterReminder].self, from: data) {
            reminders = Self.sorted(saved)
        } else {
            reminders = [
                WaterReminder(hour: 9, minute: 0),
                WaterReminder(hour: 12, minute: 0),
                WaterReminder(hour: 15, minute: 0),
                WaterReminder(hour: 18, minute: 0)
            ]
        }
    }

    func save(_ newReminders: [WaterReminder]) {
        reminders = Self.sorted(newReminders)
        if let data = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
        scheduleNotifications()
    }

    /// 下一个提醒时间点。
    func nextReminder(after date: Date = .now) -> WaterReminder? {
        let calendar = Calendar.current
        let minutes = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
        return reminders.first { $0.hour * 60 + $0.minute > minutes } ?? reminders.first
    }

    /// 下一个提醒对应的具体日期；若今天所有提醒都已过点，则顺延到明天。
    func nextReminderDate(after date: Date = .now) -> Date? {
        guard let next = nextReminder(after: date) else { return nil }
        let calendar = Calendar.current
        var candidate = calendar.date(
            bySettingHour: next.hour,
            minute: next.minute,
            second: 0,
            of: date
        ) ?? date
        if candidate <= date {
            candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
        }
        return candidate
    }

    /// 今天已经到点的提醒个数。
    func passedRemindersCount(on date: Date = .now) -> Int {
        let minutes = Calendar.current.component(.hour, from: date) * 60
            + Calendar.current.component(.minute, from: date)
        return reminders.filter { $0.hour * 60 + $0.minute <= minutes }.count
    }

    // MARK: - 每日通知

    private static func sorted(_ list: [WaterReminder]) -> [WaterReminder] {
        list.sorted { $0.hour * 60 + $0.minute < $1.hour * 60 + $1.minute }
    }

    private func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()
        let reminders = self.reminders
        center.getPendingNotificationRequests { requests in
            let stale = requests
                .filter { $0.identifier.hasPrefix("water-reminder-") }
                .map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: stale)

            for (index, reminder) in reminders.enumerated() {
                var comps = DateComponents()
                comps.hour = reminder.hour
                comps.minute = reminder.minute

                let content = UNMutableNotificationContent()
                content.title = "喝水提醒"
                content.body = "该喝水啦，补充一下水分吧。"
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "water-reminder-\(index)",
                    content: content,
                    trigger: trigger
                )
                center.add(request)
            }
        }
    }
}
