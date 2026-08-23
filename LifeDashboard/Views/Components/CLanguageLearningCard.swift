import SwiftUI

/// 仪表盘上的 C 语言学习卡片：丰富封面 + 点击进入 C 语言七天学习板块。
struct CLanguageLearningCard: View {
    var body: some View {
        NavigationLink {
            CLearningSectionView()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Text("C语言学习")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "book.closed.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Text("七天学会 C")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text("Xcode · VSCode 双板块")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))

                HStack(spacing: 6) {
                    chip("指针")
                    chip("内存")
                    chip("链表")
                    chip("项目")
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
                        Color(red: 0.05, green: 0.55, blue: 0.60),
                        Color(red: 0.02, green: 0.38, blue: 0.62),
                        Color(red: 0.04, green: 0.22, blue: 0.50)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .shadow(color: Color(red: 0.02, green: 0.35, blue: 0.55).opacity(0.4), radius: 10, x: 0, y: 4)
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
