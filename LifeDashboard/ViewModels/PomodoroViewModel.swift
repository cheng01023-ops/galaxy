import ActivityKit
import Combine
import Foundation

/// 番茄钟状态管理，负责计时、灵动岛实时活动与本地通知。
@MainActor
final class PomodoroViewModel: ObservableObject {
    @Published private(set) var phase: PomodoroPhase = .focus
    @Published private(set) var remainingSeconds: Int
    @Published private(set) var isRunning = false

    let focusDurationSeconds = 25 * 60
    let restDurationSeconds = 5 * 60

    /// 当某个阶段完成时回调（用于把专注时长写入 SwiftData）。
    var onPhaseCompleted: ((PomodoroPhase, Int) -> Void)?

    private var timer: AnyCancellable?
    private var endDate: Date?
    private var activity: Activity<PomodoroAttributes>?

    init() {
        remainingSeconds = focusDurationSeconds
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
    }

    func pause() {
        guard isRunning else { return }
        isRunning = false
        timer?.cancel()
        timer = nil
        NotificationService.shared.cancelPomodoroNotification()
        endLiveActivity()
    }

    func reset() {
        timer?.cancel()
        timer = nil
        isRunning = false
        NotificationService.shared.cancelPomodoroNotification()
        endLiveActivity()

        phase = .focus
        remainingSeconds = focusDurationSeconds
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
        guard let current = activity else { return }
        activity = nil

        let state = PomodoroAttributes.ContentState(endDate: Date(), phase: phase)
        let content = ActivityContent(state: state, staleDate: Date())
        Task {
            await current.end(content, dismissalPolicy: .immediate)
        }
    }
}
