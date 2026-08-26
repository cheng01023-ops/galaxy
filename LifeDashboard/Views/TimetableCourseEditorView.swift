import SwiftUI
import SwiftData

/// 课程新增 / 编辑表单。
struct TimetableCourseEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    /// 编辑时传入已有课程；新增时为 nil。
    private let editing: Course?
    private let onSaved: () -> Void

    @State private var name: String
    @State private var teacher: String
    @State private var location: String
    @State private var weekday: Int
    @State private var startMinutes: Int
    @State private var endMinutes: Int
    @State private var startWeek: Int
    @State private var endWeek: Int
    @State private var weeksPattern: WeekPattern
    @State private var colorHex: String
    @State private var reminderEnabled: Bool
    @State private var reminderMinutesBefore: Int

    init(course: Course? = nil, onSaved: @escaping () -> Void = {}) {
        self.editing = course
        self.onSaved = onSaved
        _name = State(initialValue: course?.name ?? "")
        _teacher = State(initialValue: course?.teacher ?? "")
        _location = State(initialValue: course?.location ?? "")
        _weekday = State(initialValue: course?.weekday ?? 1)
        _startMinutes = State(initialValue: course?.startMinutes ?? 8 * 60)
        _endMinutes = State(initialValue: course?.endMinutes ?? 9 * 60 + 40)
        _startWeek = State(initialValue: course?.startWeek ?? 1)
        _endWeek = State(initialValue: course?.endWeek ?? 16)
        _weeksPattern = State(initialValue: course?.weeksPattern ?? .all)
        _colorHex = State(initialValue: course?.colorHex ?? "0x5AC8FA")
        _reminderEnabled = State(initialValue: course?.reminderEnabled ?? false)
        _reminderMinutesBefore = State(initialValue: course?.reminderMinutesBefore ?? 15)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("课程信息") {
                    TextField("课程名称（必填）", text: $name)
                    TextField("授课老师", text: $teacher)
                    TextField("上课地点", text: $location)
                }

                Section("上课时间") {
                    Picker("星期", selection: $weekday) {
                        ForEach(1...7, id: \.self) { day in
                            Text(Course.weekdays[day - 1]).tag(day)
                        }
                    }

                    DatePicker("开始时间", selection: minutesBinding(for: $startMinutes), displayedComponents: .hourAndMinute)
                    DatePicker("结束时间", selection: minutesBinding(for: $endMinutes), displayedComponents: .hourAndMinute)
                }

                Section("周次安排") {
                    Stepper("开始周：第 \(startWeek) 周", value: $startWeek, in: 1...30)
                    Stepper("结束周：第 \(endWeek) 周", value: $endWeek, in: startWeek...30)
                    Picker("单双周", selection: $weeksPattern) {
                        ForEach(WeekPattern.allCases) { pattern in
                            Text(pattern.rawValue).tag(pattern)
                        }
                    }
                }

                Section("课程颜色") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 10)], spacing: 10) {
                        ForEach(TimetablePalette.colors, id: \.hex) { item in
                            Button {
                                colorHex = item.hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: item.hex))
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if colorHex == item.hex {
                                            Image(systemName: "checkmark")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("上课提醒") {
                    Toggle("开启上课提醒", isOn: $reminderEnabled)
                    if reminderEnabled {
                        Picker("提前提醒", selection: $reminderMinutesBefore) {
                            Text("准时").tag(0)
                            Text("提前 5 分钟").tag(5)
                            Text("提前 10 分钟").tag(10)
                            Text("提前 15 分钟").tag(15)
                            Text("提前 20 分钟").tag(20)
                            Text("提前 30 分钟").tag(30)
                            Text("提前 1 小时").tag(60)
                        }
                    }
                }

                if editing != nil {
                    Section {
                        Button(role: .destructive) {
                            delete()
                        } label: {
                            Label("删除这门课", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle(editing == nil ? "添加课程" : "编辑课程")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: - 分钟数与 DatePicker 的桥接

    private func minutesBinding(for minutes: Binding<Int>) -> Binding<Date> {
        Binding<Date>(
            get: {
                let h = minutes.wrappedValue / 60
                let m = minutes.wrappedValue % 60
                var comps = Calendar.current.dateComponents([.year, .month, .day], from: .now)
                comps.hour = h
                comps.minute = m
                return Calendar.current.date(from: comps) ?? .now
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                minutes.wrappedValue = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            }
        )
    }

    // MARK: - 保存 / 删除

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if endMinutes <= startMinutes {
            endMinutes = startMinutes + 40
        }

        if let course = editing {
            course.name = trimmedName
            course.teacher = teacher
            course.location = location
            course.weekday = weekday
            course.startMinutes = startMinutes
            course.endMinutes = endMinutes
            course.startWeek = startWeek
            course.endWeek = endWeek
            course.weeksPattern = weeksPattern
            course.colorHex = colorHex
            course.reminderEnabled = reminderEnabled
            course.reminderMinutesBefore = reminderMinutesBefore
        } else {
            let course = Course(
                name: trimmedName,
                teacher: teacher,
                location: location,
                weekday: weekday,
                startMinutes: startMinutes,
                endMinutes: endMinutes,
                startWeek: startWeek,
                endWeek: endWeek,
                weeksPattern: weeksPattern,
                colorHex: colorHex,
                reminderEnabled: reminderEnabled,
                reminderMinutesBefore: reminderMinutesBefore
            )
            modelContext.insert(course)
        }

        try? modelContext.save()
        onSaved()
        dismiss()
    }

    private func delete() {
        guard let course = editing else { return }
        modelContext.delete(course)
        try? modelContext.save()
        onSaved()
        dismiss()
    }
}
