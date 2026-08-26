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

    /// 从 "0xRRGGBB" / "#RRGGBB" / "RRGGBB" 解析颜色；解析失败返回 accent。
    init(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("0x") || value.hasPrefix("0X") {
            value.removeFirst(2)
        } else if value.hasPrefix("#") {
            value.removeFirst()
        }
        var rgb: UInt64 = 0
        if value.count == 6, Scanner(string: value).scanHexInt64(&rgb) {
            self.init(
                red: Double((rgb >> 16) & 0xFF) / 255.0,
                green: Double((rgb >> 8) & 0xFF) / 255.0,
                blue: Double(rgb & 0xFF) / 255.0
            )
        } else {
            self.init(uiColor: .systemBlue)
        }
    }
}

/// 课程表可选配色（柔和、适配深色模式）。
enum TimetablePalette {
    static let colors: [(name: String, hex: String)] = [
        ("天蓝", "0x5AC8FA"),
        ("薄荷", "0x2DD4BF"),
        ("紫罗兰", "0x8E7CF3"),
        ("蜜桃", "0xFF9F7A"),
        ("柠檬", "0xF6C445"),
        ("玫瑰", "0xF472B6"),
        ("青绿", "0x34D399"),
        ("珊瑚", "0xFB7185"),
        ("靛蓝", "0x6366F1"),
        ("橄榄", "0x84CC16")
    ]

    static func color(for hex: String) -> Color {
        Color(hex: hex)
    }
}
