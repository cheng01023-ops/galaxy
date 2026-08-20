import SwiftUI
import SwiftData

/// 番茄钟卡片：保持原有外观，点击整张卡片进入详情页自定义倒计时时长。
struct PomodoroCard: View {
    var body: some View {
        NavigationLink {
            PomodoroDetailView()
        } label: {
            PomodoroTimerView(showsNavigationHint: true)
                .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

/// 番茄钟计时内容：阶段、剩余时间与开始/暂停/重置按钮。
/// 卡片与详情页共用，保证两处外观一致。
struct PomodoroTimerView: View {
    @EnvironmentObject private var viewModel: PomodoroViewModel
    @Environment(\.modelContext) private var modelContext

    /// 是否在标题右侧显示「可进入详情」的箭头提示。
    var showsNavigationHint = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("番茄钟", systemImage: "timer")
                    .font(.headline)
                Spacer()
                if showsNavigationHint {
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }

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

/// 番茄钟详情页：保留卡片全部功能，并支持自定义专注/休息倒计时时长。
struct PomodoroDetailView: View {
    @EnvironmentObject private var viewModel: PomodoroViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PomodoroTimerView()
                    .cardStyle()

                settingsCard
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("番茄钟")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("倒计时设置", systemImage: "slider.horizontal.3")
                .font(.headline)

            Stepper(value: focusMinutes, in: 1...180) {
                durationRow(title: "专注时长", icon: "brain.head.profile",
                            minutes: viewModel.focusDurationSeconds / 60)
            }

            Stepper(value: restMinutes, in: 1...90) {
                durationRow(title: "休息时长", icon: "cup.and.saucer",
                            minutes: viewModel.restDurationSeconds / 60)
            }

            if viewModel.isRunning {
                Label("计时进行中，新时长将在下一轮生效", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var focusMinutes: Binding<Int> {
        Binding(
            get: { viewModel.focusDurationSeconds / 60 },
            set: { viewModel.setFocusDuration(minutes: $0) }
        )
    }

    private var restMinutes: Binding<Int> {
        Binding(
            get: { viewModel.restDurationSeconds / 60 },
            set: { viewModel.setRestDuration(minutes: $0) }
        )
    }

    private func durationRow(title: String, icon: String, minutes: Int) -> some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text("\(minutes) 分钟")
                .font(.body.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
}
