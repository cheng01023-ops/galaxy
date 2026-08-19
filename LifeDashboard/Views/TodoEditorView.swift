import SwiftUI
import SwiftData

/// 新建 / 编辑待办的表单。
struct TodoEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let todo: TodoItem?

    @State private var title: String
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var priority: TodoItem.Priority

    init(todo: TodoItem? = nil) {
        self.todo = todo
        _title = State(initialValue: todo?.title ?? "")
        _hasDueDate = State(initialValue: todo?.dueDate != nil)
        _dueDate = State(initialValue: todo?.dueDate ?? Date())
        _priority = State(initialValue: todo?.priority ?? .medium)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("标题") {
                    TextField("例如：买牛奶", text: $title)
                }

                Section("截止日期") {
                    Toggle("设置截止日期", isOn: $hasDueDate.animation())
                    if hasDueDate {
                        DatePicker("截止日期", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }

                Section("优先级") {
                    Picker("优先级", selection: $priority) {
                        ForEach(TodoItem.Priority.allCases, id: \.self) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(todo == nil ? "新建待办" : "编辑待办")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                        dismiss()
                    }
                    .disabled(trimmedTitle.isEmpty)
                }
            }
        }
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        let finalTitle = trimmedTitle
        guard !finalTitle.isEmpty else { return }

        if let todo {
            todo.title = finalTitle
            todo.dueDate = hasDueDate ? dueDate : nil
            todo.priority = priority
        } else {
            let item = TodoItem(
                title: finalTitle,
                dueDate: hasDueDate ? dueDate : nil,
                priority: priority
            )
            modelContext.insert(item)
        }
    }
}
