import Foundation
import UserNotifications

/// 负责本地通知的授权与调度。
@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    /// 请求通知授权（首次启动时调用）。
    func requestAuthorization() async {
        do {
            _ = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("通知授权失败：\(error.localizedDescription)")
        }
    }

    /// 在计时结束时发送本地通知。
    func schedulePomodoroNotification(after seconds: TimeInterval, phaseTitle: String) {
        guard seconds > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "番茄钟"
        content.body = "\(phaseTitle)时间结束啦，休息一下吧。"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: "pomodoro-end", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// 取消尚未触发的番茄钟通知。
    func cancelPomodoroNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["pomodoro-end"])
    }
}
