import SwiftUI
import SwiftData

/// 番茄钟卡片：开始 / 暂停 / 重置。
struct PomodoroCard: View {
    @EnvironmentObject private var viewModel: PomodoroViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("番茄钟", systemImage: "timer")
                .font(.headline)

            HStack(spacing: 6) {
                Image(systemName: viewModel.phase.systemImage)
                Text(viewModel.phase.title)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Text(timeString(viewModel.remainingSeconds))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())

            HStack(spacing: 10) {
                Button {
                    viewModel.isRunning ? viewModel.pause() : viewModel.start()
                } label: {
                    Label(viewModel.isRunning ? "暂停" : "开始",
                          systemImage: viewModel.isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    viewModel.reset()
                } label: {
                    Label("重置", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .font(.subheadline)
        }
        .cardStyle()
        .onAppear {
            // 每个专注阶段完成时，将专注时长写入 SwiftData，供每周小结使用。
            viewModel.onPhaseCompleted = { [modelContext] phase, seconds in
                guard phase == .focus else { return }
                let session = FocusSession(
                    startedAt: .now,
                    durationSeconds: seconds,
                    phase: "专注"
                )
                modelContext.insert(session)
            }
        }
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
