import SwiftUI

/// 仪表盘上的 C++ 学习卡片：点击进入 Galaxy 内置的 C++ 七天学习板块。
struct CppLearningCard: View {
    @StateObject private var store = AppStore()

    var body: some View {
        NavigationLink {
            CppLearningSectionView()
        } label: {
            content
        }
        .buttonStyle(.plain)
    }

    // MARK: - 主体

    private var content: some View {
        ZStack {
            decorations

            VStack(alignment: .leading, spacing: 0) {
                header

                Spacer(minLength: 10)

                titleBlock

                Text("从零基础到独立写出程序")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.top, 4)

                Spacer(minLength: 12)

                bottomSection
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.14, green: 0.10, blue: 0.24),
                    Color(red: 0.30, green: 0.13, blue: 0.33)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 4)
    }

    // MARK: - 头部

    private var header: some View {
        HStack(spacing: 6) {
            Label("C++学习", systemImage: "chevron.left.forwardslash.chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(.white.opacity(0.14), in: Capsule())

            Spacer(minLength: 0)

            Text("7 天")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .background(.white.opacity(0.10), in: Capsule())
        }
    }

    // MARK: - 标题

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("七天学会")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("C++")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.72, blue: 0.25),
                            Color(red: 1.0, green: 0.92, blue: 0.45)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
    }

    // MARK: - 底部：进度 + 继续学习

    private var bottomSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ProgressBarView(value: progressValue)
                Text("\(done)/\(total)")
                    .font(.caption2.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.80))
            }

            HStack(spacing: 6) {
                Image(systemName: "play.fill")
                    .font(.caption2.weight(.bold))
                Text(ctaText)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 4)
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            }
        }
    }

    // MARK: - 装饰

    private var decorations: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.28))
                .frame(width: 180, height: 180)
                .blur(radius: 50)
                .offset(x: 80, y: -90)

            Circle()
                .fill(Color.purple.opacity(0.25))
                .frame(width: 140, height: 140)
                .blur(radius: 45)
                .offset(x: -90, y: 110)

            Text("#include <iostream>")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.16))
                .rotationEffect(.degrees(-8))
                .padding(.top, 42)
                .padding(.trailing, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            Text("return 0;")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.18))
                .rotationEffect(.degrees(6))
                .padding(.bottom, 70)
                .padding(.trailing, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 70, weight: .bold))
                .foregroundStyle(.white.opacity(0.06))
                .padding(.bottom, 6)
                .padding(.leading, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }

    // MARK: - 数据

    private var done: Int { progress.done }
    private var total: Int { progress.total }

    private var progress: (done: Int, total: Int) {
        store.totalProgress()
    }

    private var progressValue: Double {
        total > 0 ? Double(done) / Double(total) : 0
    }

    private var ctaText: String {
        if total > 0, done >= total {
            return "已完成 🎉"
        }
        let day = store.nextIncompleteDay()?.title.replacingOccurrences(of: " ", with: "") ?? "第1天"
        return "继续 · \(day)"
    }
}

/// 卡片底部使用的圆角进度条。
private struct ProgressBarView: View {
    let value: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.16))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color(red: 1.0, green: 0.85, blue: 0.35)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(6, proxy.size.width * min(max(value, 0), 1)))
            }
        }
        .frame(height: 6)
    }
}

#Preview("C++学习卡片") {
    NavigationStack {
        CppLearningCard()
            .padding()
    }
}
