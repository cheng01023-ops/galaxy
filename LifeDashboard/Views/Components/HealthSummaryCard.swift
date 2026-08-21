import SwiftUI
import Charts

/// 健康摘要卡片：今日步数、昨晚睡眠、静息心率。
/// 点击整张卡片可进入健康详情页查看更丰富的数据。
struct HealthSummaryCard: View {
    @EnvironmentObject private var healthService: HealthService

    var body: some View {
        NavigationLink {
            HealthDetailView()
        } label: {
            summaryContent
        }
        .buttonStyle(.plain)
    }

    private var summaryContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 顶部三色渐变条，呼应下方三项指标的配色。
            LinearGradient(
                colors: [.green, .indigo, .pink],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 4)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("健康", systemImage: "heart.fill")
                        .font(.headline)
                        .foregroundStyle(.pink)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.pink.opacity(0.5))
                }

                metricRow(icon: "figure.walk", label: "今日步数",
                          value: Formatters.number(healthService.summary.stepCount), unit: "步",
                          tint: .green)

                metricRow(icon: "moon.zzz.fill", label: "昨晚睡眠",
                          value: Formatters.number(healthService.summary.sleepHours), unit: "小时",
                          tint: .indigo)

                metricRow(icon: "heart.text.square.fill", label: "静息心率",
                          value: Formatters.number(healthService.summary.restingHeartRate), unit: "次/分",
                          tint: .pink)

                if !healthService.isHealthDataAvailable {
                    Text("模拟器无法读取 HealthKit，请在真机运行")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let error = healthService.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    /// 单行指标：彩色图标底片 + 彩色数值。
    private func metricRow(icon: String, label: String, value: String, unit: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(tint)
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

/// 健康详情页：今日概览、步数目标、近 7 天步数/睡眠/心率趋势、
/// 昨晚睡眠阶段明细与本周总结。
struct HealthDetailView: View {
    @EnvironmentObject private var healthService: HealthService
    @State private var showingStepGoalEditor = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if !healthService.isHealthDataAvailable {
                    placeholderCard(
                        icon: "iphone.gen3.radiowaves.left.and.right",
                        text: "模拟器无法读取 HealthKit\n请在真机上运行以查看健康详情"
                    )
                } else if let error = healthService.errorMessage, !healthService.summary.hasAnyData {
                    placeholderCard(icon: "exclamationmark.triangle.fill", text: error)
                } else {
                    todayOverviewCard
                    stepGoalCard
                    stepTrendCard
                    sleepStageCard
                    sleepTrendCard
                    heartRateTrendCard
                    weekSummaryCard
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("健康详情")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadDetailData()
        }
        .refreshable {
            await loadDetailData()
        }
    }

    private func loadDetailData() async {
        if !healthService.isAuthorized {
            await healthService.requestAuthorizationAndFetch()
        }
        await healthService.fetchDetailData()
    }

    // MARK: - 卡片

    /// 今日三大指标概览。
    private var todayOverviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("今日概览", systemImage: "sun.max.fill", tint: .orange)

            HStack(spacing: 12) {
                overviewMetric(icon: "figure.walk", title: "步数",
                               value: Formatters.number(healthService.summary.stepCount, maximumFractionDigits: 0),
                               unit: "步")
                Divider()
                overviewMetric(icon: "moon.zzz.fill", title: "睡眠",
                               value: Formatters.number(healthService.summary.sleepHours),
                               unit: "小时")
                Divider()
                overviewMetric(icon: "heart.text.square.fill", title: "心率",
                               value: Formatters.number(healthService.summary.restingHeartRate),
                               unit: "次/分")
            }
        }
        .cardStyle()
    }

    private func overviewMetric(icon: String, title: String, value: String, unit: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.pink)
            Text(value)
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text("\(title) · \(unit)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    /// 今日步数目标进度（目标值可自定义）。
    private var stepGoalCard: some View {
        let steps = healthService.summary.stepCount
        let goal = healthService.dailyStepGoal
        let progress = goal > 0 ? min(steps / goal, 1.0) : 0

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader("今日步数目标", systemImage: "flag.checkered", tint: .green)
                Spacer()
                Button {
                    showingStepGoalEditor = true
                } label: {
                    Label("自定义", systemImage: "slider.horizontal.3")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                .buttonStyle(.borderless)
            }

            ProgressView(value: progress)
                .tint(.green)

            HStack(alignment: .firstTextBaseline) {
                Text("\(Formatters.number(steps, maximumFractionDigits: 0)) / \(Formatters.number(goal, maximumFractionDigits: 0)) 步")
                Spacer()
                Text(goalText)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .cardStyle()
        .sheet(isPresented: $showingStepGoalEditor) {
            StepGoalEditorView(currentGoal: healthService.dailyStepGoal) { newGoal in
                healthService.dailyStepGoal = newGoal
            }
        }
    }

    private var goalText: String {
        let steps = healthService.summary.stepCount
        let goal = healthService.dailyStepGoal
        if steps >= goal { return "已达成目标 🎉" }
        return "还差 \(Formatters.number(goal - steps, maximumFractionDigits: 0)) 步"
    }

    /// 近 7 天步数柱状图（含日均参考线）。
    private var stepTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("近 7 天步数", systemImage: "chart.bar.fill", tint: .green)

            if healthService.last7DaysSteps.isEmpty || !healthService.last7DaysSteps.contains(where: { $0.steps > 0 }) {
                emptyText("暂无步数数据")
            } else {
                let average = healthService.last7DaysSteps.map(\.steps).reduce(0, +) / Double(healthService.last7DaysSteps.count)

                Chart {
                    ForEach(healthService.last7DaysSteps) { item in
                        BarMark(
                            x: .value("日期", item.date, unit: .day),
                            y: .value("步数", item.steps)
                        )
                        .foregroundStyle(.green.opacity(0.85))
                        .cornerRadius(4)
                    }
                    if average > 0 {
                        RuleMark(y: .value("日均", average))
                            .foregroundStyle(.secondary.opacity(0.6))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("日均 \(Formatters.number(average, maximumFractionDigits: 0))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .chartYAxis { AxisMarks(position: .leading) }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    }
                }
                .frame(height: 180)
            }
        }
        .cardStyle()
    }

    /// 昨晚睡眠总时长与阶段明细。
    private var sleepStageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("昨晚睡眠", systemImage: "moon.zzz.fill", tint: .indigo)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(Formatters.number(healthService.summary.sleepHours))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.indigo)
                Text("小时")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if healthService.sleepStages.isEmpty {
                emptyText("暂无睡眠阶段数据")
            } else {
                Chart(healthService.sleepStages) { item in
                    BarMark(
                        x: .value("阶段", item.stage.shortName),
                        y: .value("时长", item.minutes)
                    )
                    .foregroundStyle(item.stage.color)
                    .cornerRadius(4)
                }
                .chartYAxis { AxisMarks(position: .leading) }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .frame(height: 160)

                ForEach(healthService.sleepStages) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(item.stage.color)
                            .frame(width: 8, height: 8)
                        Text(item.stage.rawValue)
                            .font(.subheadline)
                        Spacer()
                        Text("\(Formatters.number(item.minutes, maximumFractionDigits: 0)) 分钟")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .cardStyle()
    }

    /// 近 7 天睡眠时长折线图。
    private var sleepTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("近 7 天睡眠", systemImage: "chart.xyaxis.line", tint: .indigo)

            if healthService.last7DaysSleep.isEmpty || !healthService.last7DaysSleep.contains(where: { $0.hours > 0 }) {
                emptyText("暂无睡眠数据")
            } else {
                Chart(healthService.last7DaysSleep) { item in
                    LineMark(
                        x: .value("日期", item.date, unit: .day),
                        y: .value("小时", item.hours)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.indigo)

                    PointMark(
                        x: .value("日期", item.date, unit: .day),
                        y: .value("小时", item.hours)
                    )
                    .symbolSize(24)
                    .foregroundStyle(.indigo)
                }
                .chartYAxis { AxisMarks(position: .leading) }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    }
                }
                .frame(height: 160)
            }
        }
        .cardStyle()
    }

    /// 近 7 天静息心率折线图。
    private var heartRateTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("近 7 天静息心率", systemImage: "heart.fill", tint: .pink)

            if healthService.last7DaysHeartRate.isEmpty || !healthService.last7DaysHeartRate.contains(where: { $0.bpm > 0 }) {
                emptyText("暂无心率数据")
            } else {
                Chart(healthService.last7DaysHeartRate) { item in
                    LineMark(
                        x: .value("日期", item.date, unit: .day),
                        y: .value("心率", item.bpm)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.pink)

                    PointMark(
                        x: .value("日期", item.date, unit: .day),
                        y: .value("心率", item.bpm)
                    )
                    .symbolSize(24)
                    .foregroundStyle(.pink)
                }
                .chartYAxis { AxisMarks(position: .leading) }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    }
                }
                .frame(height: 160)
            }
        }
        .cardStyle()
    }

    /// 本周总结：总步数与平均睡眠。
    private var weekSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("本周总结", systemImage: "calendar", tint: .blue)

            if healthService.weekSummary.totalSteps == 0 && healthService.weekSummary.averageSleepHours == 0 {
                emptyText("本周暂无数据")
            } else {
                HStack(spacing: 12) {
                    weekMetric(title: "总步数",
                               value: Formatters.number(healthService.weekSummary.totalSteps, maximumFractionDigits: 0),
                               unit: "步")
                    Divider()
                    weekMetric(title: "平均睡眠",
                               value: Formatters.number(healthService.weekSummary.averageSleepHours),
                               unit: "小时/天")
                }

                Text(weekRangeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }

    private func weekMetric(title: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.weight(.semibold))
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var weekRangeText: String {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 与 HealthService 保持一致，周一作为一周开始
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return "" }
        return Formatters.weekRangeText(start: interval.start, end: interval.end)
    }

    // MARK: - 通用小部件

    private func sectionHeader(_ title: String, systemImage: String, tint: Color) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(tint)
    }

    private func emptyText(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 60)
    }

    private func placeholderCard(icon: String, text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .cardStyle()
    }
}

/// 步数目标编辑弹窗：支持数字输入、步进器与快捷预设。
private struct StepGoalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Double) -> Void

    @State private var goalText: String
    @State private var showInvalidInput = false

    private let presets: [Double] = [3_000, 5_000, 8_000, 10_000, 15_000, 20_000]

    init(currentGoal: Double, onSave: @escaping (Double) -> Void) {
        self.onSave = onSave
        _goalText = State(initialValue: Formatters.number(currentGoal, maximumFractionDigits: 0))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("请输入每日步数目标", text: $goalText)
                            .keyboardType(.numberPad)
                            .font(.title3.monospacedDigit())
                        Text("步")
                            .foregroundStyle(.secondary)
                    }

                    Stepper(
                        "步进调整：\(Formatters.number(parsedGoal, maximumFractionDigits: 0)) 步",
                        value: Binding(
                            get: { parsedGoal },
                            set: { goalText = Formatters.number($0, maximumFractionDigits: 0) }
                        ),
                        in: 1_000...100_000,
                        step: 500
                    )
                } header: {
                    Text("每日目标")
                } footer: {
                    if showInvalidInput {
                        Text("请输入大于 0 的数字")
                            .foregroundStyle(.red)
                    } else {
                        Text("保存后立即生效并自动记住")
                    }
                }

                Section("快捷预设") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
                        ForEach(presets, id: \.self) { preset in
                            Button {
                                goalText = Formatters.number(preset, maximumFractionDigits: 0)
                            } label: {
                                Text(Formatters.number(preset, maximumFractionDigits: 0))
                                    .font(.subheadline.monospacedDigit())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(parsedGoal == preset ? Color.green.opacity(0.15) : Color(.secondarySystemBackground))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("设置步数目标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var parsedGoal: Double {
        Double(goalText.filter { $0.isNumber }) ?? 0
    }

    private func save() {
        let value = parsedGoal.rounded()
        guard value > 0 else {
            showInvalidInput = true
            return
        }
        onSave(value)
        dismiss()
    }
}

// MARK: - SleepStage 展示扩展

extension SleepStage {
    /// 各睡眠阶段对应的主题色。
    var color: Color {
        switch self {
        case .awake: return .orange
        case .core: return .blue
        case .deep: return .indigo
        case .rem: return .purple
        }
    }

    /// 图表坐标轴上使用的短名称。
    var shortName: String {
        switch self {
        case .awake: return "清醒"
        case .core: return "核心"
        case .deep: return "深睡"
        case .rem: return "REM"
        }
    }
}

#Preview("健康摘要卡片") {
    NavigationStack {
        HealthSummaryCard()
            .environmentObject(HealthService())
            .padding()
    }
}
