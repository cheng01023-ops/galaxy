import SwiftUI

/// 喝水提醒详情页：今日进度概览、自定义提醒时间、快捷添加与喝水小贴士。
struct WaterReminderDetailView: View {
    @ObservedObject private var service = WaterReminderService.shared
    @State private var isAdding = false
    @State private var newDate = Date()

    /// 快捷添加的常用时间点。
    private let quickPresets: [WaterReminder] = [
        WaterReminder(hour: 7, minute: 0),
        WaterReminder(hour: 9, minute: 0),
        WaterReminder(hour: 10, minute: 30),
        WaterReminder(hour: 12, minute: 0),
        WaterReminder(hour: 14, minute: 0),
        WaterReminder(hour: 15, minute: 0),
        WaterReminder(hour: 17, minute: 0),
        WaterReminder(hour: 18, minute: 0),
        WaterReminder(hour: 21, minute: 0)
    ]

    /// 喝水小贴士。
    private let tips = [
        "每天喝够 1500-2000ml 水，少量多次比一次猛喝更有效。",
        "起床后先喝一杯温水，帮助唤醒身体。",
        "运动后、空调房内记得及时补充水分。"
    ]

    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                todayOverviewCard
                remindersCard
                quickAddCard
                tipCard
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("喝水提醒")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isAdding) {
            NavigationStack {
                DatePicker("提醒时间", selection: $newDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
                    .navigationTitle("添加提醒时间")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("取消") { isAdding = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("添加") {
                                addReminder()
                                isAdding = false
                            }
                        }
                    }
            }
            .presentationDetents([.height(320)])
        }
    }

    // MARK: - 今日概览

    private var todayOverviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("今日概览", systemImage: "drop.circle.fill")
                .font(.headline)
                .foregroundStyle(.blue)

            HStack(spacing: 18) {
                progressRing

                VStack(alignment: .leading, spacing: 6) {
                    if service.reminders.isEmpty {
                        Text("还没有提醒")
                            .font(.title3.weight(.semibold))
                        Text("先添加一个喝水提醒吧")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(nextLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let next = service.nextReminder() {
                            Text(String(format: "%02d:%02d", next.hour, next.minute))
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(
                                    LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
                                )
                        }
                        countdownText
                            .font(.footnote)
                            .foregroundStyle(.blue)
                        summaryText
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }

            Divider()

            timeRangeRow
        }
        .cardStyle()
    }

    private var progressRing: some View {
        let passed = service.passedRemindersCount()
        let total = service.reminders.count
        let progress = total > 0 ? Double(passed) / Double(total) : 0

        return ZStack {
            Circle()
                .stroke(Color(.tertiarySystemFill), lineWidth: 10)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [.cyan, .blue, .indigo],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: .blue.opacity(0.45), radius: 4, x: 0, y: 1)
                .animation(.snappy, value: progress)

            VStack(spacing: 4) {
                Image(systemName: "drop.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom))
                Text(total > 0 ? "\(passed)/\(total)" : "0")
                    .font(.headline)
                    .monospacedDigit()
            }
        }
        .frame(width: 88, height: 88)
    }

    private var nextLabel: String {
        if let date = service.nextReminderDate(),
           Calendar.current.isDateInTomorrow(date) {
            return "下次提醒 · 明天"
        }
        return "下次提醒"
    }

    @ViewBuilder
    private var countdownText: some View {
        if let nextDate = service.nextReminderDate() {
            let minutes = Int(max(0, nextDate.timeIntervalSinceNow) / 60)
            if minutes < 1 {
                Label("马上就到", systemImage: "bell.badge.fill")
            } else if minutes < 60 {
                Label("还有 \(minutes) 分钟", systemImage: "clock")
            } else {
                Label("还有 \(minutes / 60) 小时 \(minutes % 60) 分", systemImage: "clock")
            }
        }
    }

    private var summaryText: some View {
        let total = service.reminders.count
        let passed = service.passedRemindersCount()
        let remaining = total - passed
        if remaining > 0 {
            return Text("今日已完成 \(passed)/\(total) 次 · 剩余 \(remaining) 次")
        }
        return Text("今日已全部完成，喝得不错！")
    }

    private var timeRangeRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.subheadline)
                .foregroundStyle(.blue)
            if let first = service.reminders.first, let last = service.reminders.last {
                Text(String(format: "提醒时段 %02d:%02d - %02d:%02d",
                            first.hour, first.minute, last.hour, last.minute))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            } else {
                Text("暂无提醒时段")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - 提醒时间

    private var remindersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("提醒时间", systemImage: "bell.badge.fill")
                    .font(.headline)
                    .foregroundStyle(.blue)
                Spacer()
                Button {
                    isAdding = true
                } label: {
                    Label("添加", systemImage: "plus")
                }
                .font(.subheadline.weight(.semibold))
            }

            if service.reminders.isEmpty {
                Text("还没有提醒，点右上角添加或使用下方快捷添加")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ForEach(service.reminders) { reminder in
                    reminderRow(reminder)
                }
            }
        }
        .cardStyle()
    }

    private func reminderRow(_ reminder: WaterReminder) -> some View {
        let passed = service.isPassed(reminder)
        return HStack(spacing: 10) {
            Image(systemName: passed ? "checkmark.circle.fill" : "bell.fill")
                .foregroundStyle(passed ? .green : .blue)

            Text(String(format: "%02d:%02d", reminder.hour, reminder.minute))
                .font(.body.weight(.semibold))
                .monospacedDigit()

            Text(passed ? "已到点" : "待提醒")
                .font(.caption)
                .foregroundStyle(passed ? .green : .blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background((passed ? Color.green : Color.blue).opacity(0.12), in: Capsule())

            Spacer()

            Button {
                delete(reminder)
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - 快捷添加

    private var quickAddCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("快捷添加", systemImage: "plus.circle.fill")
                .font(.headline)
                .foregroundStyle(.blue)

            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(quickPresets) { preset in
                    let exists = service.reminders.contains {
                        $0.hour == preset.hour && $0.minute == preset.minute
                    }
                    Button {
                        addPreset(preset)
                    } label: {
                        Text(String(format: "%02d:%02d", preset.hour, preset.minute))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                exists ? Color.blue.opacity(0.14) : Color(.tertiarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                            .foregroundStyle(exists ? Color.blue : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - 喝水小贴士

    private var tipCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("喝水小贴士", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            ForEach(tips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    Text(tip)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - 操作

    private func addReminder() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
        let reminder = WaterReminder(hour: comps.hour ?? 9, minute: comps.minute ?? 0)
        service.save(service.reminders + [reminder])
    }

    private func addPreset(_ preset: WaterReminder) {
        guard !service.reminders.contains(where: { $0.hour == preset.hour && $0.minute == preset.minute }) else {
            return
        }
        service.save(service.reminders + [preset])
    }

    private func delete(_ reminder: WaterReminder) {
        var list = service.reminders
        list.removeAll { $0.id == reminder.id }
        service.save(list)
    }
}
