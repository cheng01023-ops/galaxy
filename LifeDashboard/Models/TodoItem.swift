import Foundation
import SwiftData

/// 待办事项模型，使用 SwiftData 进行本地持久化。
@Model
final class TodoItem {
    /// 标题
    var title: String
    /// 截止日期（可选）
    var dueDate: Date?
    /// 优先级的原始字符串，便于 SwiftData 持久化
    var priorityRaw: String
    /// 是否完成
    var isCompleted: Bool
    /// 创建时间，用于排序
    var createdAt: Date

    init(
        title: String,
        dueDate: Date? = nil,
        priority: Priority = .medium,
        isCompleted: Bool = false,
        createdAt: Date = .now
    ) {
        self.title = title
        self.dueDate = dueDate
        self.priorityRaw = priority.rawValue
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }

    /// 优先级枚举，中文显示值直接作为 rawValue，方便持久化。
    enum Priority: String, CaseIterable, Codable {
        case high = "高"
        case medium = "中"
        case low = "低"

        var sortRank: Int {
            switch self {
            case .high: return 0
            case .medium: return 1
            case .low: return 2
            }
        }
    }

    /// 从持久化的原始值映射回枚举。
    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }
}
