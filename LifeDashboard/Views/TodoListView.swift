import SwiftUI
import SwiftData

/// 待办清单筛选状态。
enum TodoFilter: String, CaseIterable {
    case all = "全部"
    case active = "未完成"
    case completed = "已完成"
}

/// 待办清单：支持按优先级排序、按状态筛选、滑动删除、点击切换完成状态。
struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.createdAt, order: .reverse) private var todos: [TodoItem]

    @State private var isShowingAdd = false
    @State private var editingTodo: TodoItem?
    @State private var filter: TodoFilter = .all

    /// 按优先级（高 > 中 > 低）排序，同优先级按创建时间倒序。
    private var sortedTodos: [TodoItem] {
        todos.sorted { lhs, rhs in
            if lhs.priority.sortRank != rhs.priority.sortRank {
                return lhs.priority.sortRank < rhs.priority.sortRank
            }
            return lhs.createdAt > rhs.createdAt
        }
    }

    /// 根据当前筛选条件过滤待办。
    private var filteredTodos: [TodoItem] {
        switch filter {
        case .all: return sortedTodos
        case .active: return sortedTodos.filter { !$0.isCompleted }
        case .completed: return sortedTodos.filter { $0.isCompleted }
        }
    }

    /// 未完成数量。
    private var activeCount: Int {
        todos.filter { !$0.isCompleted }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("筛选", selection: $filter) {
                    ForEach(TodoFilter.allCases, id: \.self) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)

                Group {
                    if filteredTodos.isEmpty {
                        ContentUnavailableView(
                            "暂无待办",
                            systemImage: "checklist",
                            description: Text("点击右上角加号添加一条待办")
                        )
                    } else {
                        List {
                            ForEach(filteredTodos) { todo in
                                TodoRow(todo: todo)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingTodo = todo
                                    }
                            }
                            .onDelete(perform: delete)
                        }
                        .listStyle(.insetGrouped)
                    }
                }
            }
            .navigationTitle("待办")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("未完成 \(activeCount)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAdd) {
                TodoEditorView()
            }
            .sheet(item: $editingTodo) { todo in
                TodoEditorView(todo: todo)
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredTodos[index])
        }
    }
}

/// 单条待办行。
private struct TodoRow: View {
    let todo: TodoItem

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.snappy) {
                    todo.isCompleted.toggle()
                }
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(todo.isCompleted ? Color.green : Color.secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.body)
                    .strikethrough(todo.isCompleted, color: .secondary)
                    .foregroundStyle(todo.isCompleted ? Color.secondary : Color.primary)

                HStack(spacing: 8) {
                    Text(todo.priority.rawValue)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.priorityColor(todo.priority.sortRank).opacity(0.18), in: Capsule())
                        .foregroundStyle(Color.priorityColor(todo.priority.sortRank))

                    if let dueDate = todo.dueDate {
                        Label(Formatters.time.string(from: dueDate), systemImage: "calendar")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}
