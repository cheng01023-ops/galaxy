import SwiftUI
import SwiftData

/// 课程表设置：学期开始日期（用于计算教学周与单双周）与提醒。
struct TimetableSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: TimetableViewModel
    let courses: [Course]
    let onChanged: () -> Void

    @State private var semesterDate: Date
    @State private var didChange = false

    init(viewModel: TimetableViewModel, courses: [Course], onChanged: @escaping () -> Void) {
        self.viewModel = viewModel
        self.courses = courses
        self.onChanged = onChanged
        _semesterDate = State(initialValue: viewModel.semesterStart)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("学期开始（周一）", selection: $semesterDate, displayedComponents: .date)
                        .onChange(of: semesterDate) { _, _ in
                            didChange = true
                        }
                    Text("当前为第 \(TimetableSharedStore.currentWeek(semesterStart: semesterDate)) 周")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("教学周")
                } footer: {
                    Text("课程表按“学期开始日期”推算当前是第几周，并用它判断单双周。请选择开学第一周的周一。")
                }

                Section("上课提醒") {
                    Label("已开启 \(courses.filter(\.reminderEnabled).count) 门课的课前提醒", systemImage: "bell.badge.fill")
                        .font(.subheadline)
                    Button("重新排布所有提醒") {
                        viewModel.updateSemesterStart(semesterDate)
                        viewModel.syncSharedStore(courses: courses)
                        onChanged()
                        didChange = false
                    }
                }

                Section {
                    Label("小组件会在桌面显示今天与下一节课，无需打开 App。", systemImage: "square.grid.2x2")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("课程表设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        if didChange {
                            viewModel.updateSemesterStart(semesterDate)
                            viewModel.syncSharedStore(courses: courses)
                            onChanged()
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}
