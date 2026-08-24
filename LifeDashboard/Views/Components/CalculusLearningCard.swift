import SwiftUI

/// 仪表盘上的微积分学习卡片：点击进入 Galaxy 内置的微积分五天课。
struct CalculusLearningCard: View {
    var body: some View {
        NavigationLink {
            CalculusSectionView()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Label("微积分学习", systemImage: "function")
                    .font(.headline)
                    .foregroundStyle(.purple)

                Text("五天学微积分")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("极限 · 导数 · 积分 · 微分方程")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
