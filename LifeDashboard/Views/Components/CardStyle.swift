import SwiftUI

/// 统一的圆角卡片样式，自动适配深色模式。
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
