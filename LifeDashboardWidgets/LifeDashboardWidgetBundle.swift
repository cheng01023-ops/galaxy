import ActivityKit
import SwiftUI
import WidgetKit

/// Widget Extension 入口：提供番茄钟的灵动岛与锁屏实时活动。
@main
struct LifeDashboardWidgetBundle: WidgetBundle {
    var body: some Widget {
        GalaxyWeatherWidget()
        PomodoroLiveActivity()
    }
}

struct PomodoroLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color(white: 0.1))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // 展开态只保留「图标 + 倒计时」单行内容，把尺寸压到最小。
                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 6) {
                        Image(systemName: context.state.phase.systemImage)
                            .font(.caption)
                            .foregroundStyle(.yellow)
                        Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.phase.systemImage)
                    .font(.system(size: 12))
            } compactTrailing: {
                Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
            } minimal: {
                Image(systemName: context.state.phase.systemImage)
                    .font(.system(size: 12))
            }
        }
    }
}

/// 锁屏实时活动视图。
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<PomodoroAttributes>

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: context.state.phase.systemImage)
                .font(.title2)
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text("番茄钟 · \(context.attributes.taskName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(context.state.phase.title)
                    .font(.headline)
            }

            Spacer()

            Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .monospacedDigit()
        }
        .padding()
    }
}
