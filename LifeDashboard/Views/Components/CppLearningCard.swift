import SwiftUI

/// 仪表盘上的 C++ 学习卡片：点击进入 Galaxy 内置的 C++ 七天学习板块。
struct CppLearningCard: View {
    var body: some View {
        NavigationLink {
            CppLearningSectionView()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Label("C++学习", systemImage: "chevron.left.forwardslash.chevron.right")
                    .font(.headline)
                    .foregroundStyle(.orange)

                Text("七天学会 C++")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("点击开始学习")
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
