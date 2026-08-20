import ActivityKit
import Combine
import Foundation

/// 番茄钟状态管理，负责计时、灵动岛实时活动与本地通知。
@MainActor
final class PomodoroViewModel: ObservableObject {
    @Published private(set) var phase: PomodoroPhase = .focus
    @Published private(set) var remainingSeconds: Int
    @Published private(set) var isRunning = false

    /// 自定义倒计时时长（秒），可在详情页调整。
    @Published var focusDurationSeconds: Int
    @Published var restDurationSeconds: Int

    /// 当某个阶段完成时回调（用于把专注时长写入 SwiftData）。
    var onPhaseCompleted: ((PomodoroPhase, Int) -> Void)?

    private var timer: AnyCancellable?
    private var endDate: Date?
    private var activity: Activity<PomodoroAttributes>?

    init() {
        let defaults = UserDefaults.standard
        let focusMinutes: Int
        if defaults.object(forKey: PersistedKey.focusMinutes) != nil {
            focusMinutes = max(1, defaults.integer(forKey: PersistedKey.focusMinutes))
        } else {
            focusMinutes = 25
        }
        let restMinutes: Int
        if defaults.object(forKey: PersistedKey.restMinutes) != nil {
            restMinutes = max(1, defaults.integer(forKey: PersistedKey.restMinutes))
        } else {
            restMinutes = 5
        }
        let focusSeconds = focusMinutes * 60
        focusDurationSeconds = focusSeconds
        restDurationSeconds = restMinutes * 60
        remainingSeconds = focusSeconds
        restoreIfNeeded()
    }

    // MARK: - 对外操作

    func start() {
        guard !isRunning else { return }
        if remainingSeconds <= 0 {
            remainingSeconds = duration(for: phase)
        }

        let now = Date()
        endDate = now.addingTimeInterval(TimeInterval(remainingSeconds))
        isRunning = true

        startTimer()
        startLiveActivity()
        NotificationService.shared.schedulePomodoroNotification(
            after: TimeInterval(remainingSeconds),
            phaseTitle: phase.title
        )
        persistRunningState()
    }

    func pause() {
        guard isRunning else { return }
        isRunning = false
        timer?.cancel()
        timer = nil
        endDate = nil
        NotificationService.shared.cancelPomodoroNotification()
        endLiveActivity()
        persistRunningState()
    }

    func reset() {
        timer?.cancel()
        timer = nil
        isRunning = false
        endDate = nil
        NotificationService.shared.cancelPomodoroNotification()
        endLiveActivity()

        phase = .focus
        remainingSeconds = focusDurationSeconds
        clearPersistedState()
    }

    /// 更新专注时长（分钟），非计时状态下同步刷新剩余时间。
    func setFocusDuration(minutes: Int) {
        focusDurationSeconds = max(1, minutes) * 60
        if !isRunning, phase == .focus {
            remainingSeconds = focusDurationSeconds
        }
        persistDurationSettings()
    }

    /// 更新休息时长（分钟），非计时状态下同步刷新剩余时间。
    func setRestDuration(minutes: Int) {
        restDurationSeconds = max(1, minutes) * 60
        if !isRunning, phase == .rest {
            remainingSeconds = restDurationSeconds
        }
        persistDurationSettings()
    }

    // MARK: - 内部逻辑

    private func startTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        guard isRunning, let endDate else { return }
        let remaining = Int(endDate.timeIntervalSinceNow.rounded(.up))
        if remaining <= 0 {
            finishCurrentPhase()
        } else {
            remainingSeconds = remaining
        }
    }

    private func finishCurrentPhase() {
        let completed = phase
        let completedSeconds = duration(for: completed)

        timer?.cancel()
        timer = nil
        isRunning = false
        NotificationService.shared.cancelPomodoroNotification()

        onPhaseCompleted?(completed, completedSeconds)

        // 自动切换到下一阶段并继续计时。
        phase = (completed == .focus) ? .rest : .focus
        remainingSeconds = duration(for: phase)
        endLiveActivity()
        start()
    }

    private func duration(for phase: PomodoroPhase) -> Int {
        phase == .focus ? focusDurationSeconds : restDurationSeconds
    }

    // MARK: - ActivityKit 实时活动

    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard let endDate else { return }

        let attributes = PomodoroAttributes(taskName: "番茄钟")
        let state = PomodoroAttributes.ContentState(endDate: endDate, phase: phase)
        let content = ActivityContent(state: state, staleDate: endDate.addingTimeInterval(120))

        do {
            activity = try Activity<PomodoroAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            print("启动灵动岛失败：\(error.localizedDescription)")
        }
    }

    private func endLiveActivity() {
        endAllActivities()
    }

    /// 结束本类型的所有实时活动（包括上次进程遗留的残留活动）。
    private func endAllActivities() {
        for leftover in Activity<PomodoroAttributes>.activities {
            let state = PomodoroAttributes.ContentState(endDate: Date(), phase: phase)
            let content = ActivityContent(state: state, staleDate: Date())
            Task {
                await leftover.end(content, dismissalPolicy: .immediate)
            }
        }
        activity = nil
    }

    // MARK: - 状态持久化与恢复

    private enum PersistedKey {
        static let isRunning = "pomodoro.isRunning"
        static let endDate = "pomodoro.endDate"
        static let phaseRawValue = "pomodoro.phaseRawValue"
        static let focusMinutes = "pomodoro.focusMinutes"
        static let restMinutes = "pomodoro.restMinutes"
    }

    /// 将当前计时状态写入 UserDefaults，供 App 被杀后恢复。
    private func persistRunningState() {
        let defaults = UserDefaults.standard
        defaults.set(isRunning, forKey: PersistedKey.isRunning)
        if let endDate {
            defaults.set(endDate, forKey: PersistedKey.endDate)
        } else {
            defaults.removeObject(forKey: PersistedKey.endDate)
        }
        defaults.set(phase.rawValue, forKey: PersistedKey.phaseRawValue)
    }

    private func clearPersistedState() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: PersistedKey.isRunning)
        defaults.removeObject(forKey: PersistedKey.endDate)
        defaults.removeObject(forKey: PersistedKey.phaseRawValue)
    }

    /// 保存自定义的专注/休息时长（分钟），供下次启动时恢复。
    private func persistDurationSettings() {
        let defaults = UserDefaults.standard
        defaults.set(focusDurationSeconds / 60, forKey: PersistedKey.focusMinutes)
        defaults.set(restDurationSeconds / 60, forKey: PersistedKey.restMinutes)
    }

    /// 启动时调用：清理或恢复遗留的实时活动，
    /// 避免「强制退出 App 后灵动岛仍残留倒计时」的问题。
    private func restoreIfNeeded() {
        let defaults = UserDefaults.standard
        let leftovers = Activity<PomodoroAttributes>.activities
        let storedIsRunning = defaults.bool(forKey: PersistedKey.isRunning)
        let storedEndDate = defaults.object(forKey: PersistedKey.endDate) as? Date

        if storedIsRunning, let storedEndDate {
            if storedEndDate > Date() {
                // 计时仍在进行：恢复应用内计时，与灵动岛保持一致。
                phase = PomodoroPhase(
                    rawValue: defaults.string(forKey: PersistedKey.phaseRawValue) ?? ""
                ) ?? .focus
                endDate = storedEndDate
                remainingSeconds = max(1, Int(storedEndDate.timeIntervalSinceNow.rounded(.up)))
                isRunning = true

                startTimer()
                if leftovers.isEmpty {
                    // 例如重启手机后系统清除了实时活动，需要重新创建。
                    startLiveActivity()
                }
                NotificationService.shared.schedulePomodoroNotification(
                    after: TimeInterval(remainingSeconds),
                    phaseTitle: phase.title
                )
                persistRunningState()
            } else {
                // 计时在 App 被杀期间已结束：结束残留活动并复位。
                endAllActivities()
                isRunning = false
                endDate = nil
                remainingSeconds = duration(for: phase)
                clearPersistedState()
            }
        } else {
            // 没有运行中的计时：清理所有残留活动。
            endAllActivities()
        }
    }
}
