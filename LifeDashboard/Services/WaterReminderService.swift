import ActivityKit
import Foundation
@preconcurrency import UserNotifications

/// 负责喝水提醒时间的本地持久化、每日通知与到点灵动岛提醒。
@MainActor
final class WaterReminderService: ObservableObject {
    static let shared = WaterReminderService()

    @Published private(set) var reminders: [WaterReminder]

    private let defaultsKey = "water.reminders.v1"
    private var waterActivity: Activity<WaterReminderAttributes>?
    private var nextCheckTimer: Timer?
    private var lastShownMinute: Int?

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
        scheduleNextCheck()
    }

    func save(_ newReminders: [WaterReminder]) {
        reminders = Self.sorted(newReminders)
        if let data = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
        scheduleNotifications()
        scheduleNextCheck()
    }

    /// 下一个提醒时间点。
    func nextReminder(after date: Date = .now) -> WaterReminder? {
        let calendar = Calendar.current
        let minutes = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
        return reminders.first { $0.hour * 60 + $0.minute > minutes } ?? reminders.first
    }

    // MARK: - 到点灵动岛提醒

    /// 检查当前时间是否到达提醒点，到达则弹出灵动岛。
    func checkReminderNow() {
        let calendar = Calendar.current
        let now = Date()
        let minuteValue = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)

        guard reminders.contains(where: { $0.hour * 60 + $0.minute == minuteValue }),
              lastShownMinute != minuteValue else { return }

        triggerLiveActivity()
        lastShownMinute = minuteValue
    }

    /// 立即弹出一个 8 秒的喝水灵动岛（用于测试）。
    @discardableResult
    func triggerLiveActivity() -> Bool {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return false }
        showDrinkWaterLiveActivity()
        return true
    }

    /// 精确调度：到下一个提醒时间点时自动弹出灵动岛。
    private func scheduleNextCheck() {
        nextCheckTimer?.invalidate()
        nextCheckTimer = nil

        guard let next = reminders.first else { return }
        var comps = DateComponents()
        comps.hour = next.hour
        comps.minute = next.minute

        guard let fireDate = Calendar.current.nextDate(
            after: Date(),
            matching: comps,
            matchingPolicy: .nextTime
        ) else { return }

        let timer = Timer(fire: fireDate, interval: 0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.triggerLiveActivity()
                self?.scheduleNextCheck()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        nextCheckTimer = timer
    }

    /// 立即结束正在显示的喝水灵动岛（离开 App 时调用）。
    func endActiveLiveActivity() {
        guard let activity = waterActivity else { return }
        waterActivity = nil
        let state = WaterReminderAttributes.ContentState()
        Task {
            await activity.end(
                ActivityContent(state: state, staleDate: Date()),
                dismissalPolicy: .immediate
            )
        }
    }

    /// 启动喝水提醒灵动岛，约 8 秒后由系统自动结束（即使退出 App 也会按时消失）。
    private func showDrinkWaterLiveActivity() {
        // 先结束上一次可能残留的灵动岛，避免叠加
        endActiveLiveActivity()

        let attributes = WaterReminderAttributes()
        let state = WaterReminderAttributes.ContentState()
        let endDate = Date().addingTimeInterval(8)

        do {
            let content = ActivityContent(state: state, staleDate: endDate)
            let activity = try Activity<WaterReminderAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            waterActivity = activity
            // 用系统策略在 8 秒后自动消失，App 被杀也不影响
            Task {
                await activity.end(
                    ActivityContent(state: state, staleDate: endDate),
                    dismissalPolicy: .after(endDate)
                )
            }
        } catch {
            print("喝水提醒灵动岛启动失败：\(error.localizedDescription)")
        }
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
