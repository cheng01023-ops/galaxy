import SwiftUI

extension Color {
    /// 卡片背景色，自动适配深色模式。
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    /// 柔和的应用强调色。
    static let appAccent = Color.accentColor

    /// 根据待办优先级返回颜色。
    static func priorityColor(_ rank: Int) -> Color {
        switch rank {
        case 0: return .red
        case 1: return .orange
        default: return .blue
        }
    }
}
