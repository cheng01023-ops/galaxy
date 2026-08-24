import SwiftUI

/// 仪表盘上的微积分学习卡片：丰富封面 + 点击进入微积分五天课。
struct CalculusLearningCard: View {
    var body: some View {
        NavigationLink {
            CalculusSectionView()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "function")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Text("微积分学习")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chart.xyaxis.line")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Text("五天学微积分")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text("从极限到多元积分")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))

                HStack(spacing: 6) {
                    chip("极限")
                    chip("导数")
                    chip("积分")
                    chip("微分方程")
                }

                Spacer(minLength: 0)

                HStack(spacing: 4) {
                    Text("点击开始学习")
                        .font(.caption.weight(.semibold))
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.white.opacity(0.22), in: Capsule())
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.55, green: 0.30, blue: 0.80),
                        Color(red: 0.42, green: 0.25, blue: 0.75),
                        Color(red: 0.20, green: 0.25, blue: 0.65)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .shadow(color: Color(red: 0.35, green: 0.20, blue: 0.65).opacity(0.4), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
