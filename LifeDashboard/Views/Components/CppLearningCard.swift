import SwiftUI
import UIKit

/// 仪表盘上的 C++ 学习卡片：点击直接打开「C++七天学习」App。
struct CppLearningCard: View {
    @State private var showMissingAlert = false

    var body: some View {
        Button {
            openCppLearning()
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
        .alert("无法打开", isPresented: $showMissingAlert) {
            Button("好", role: .cancel) {}
        } message: {
            Text("未检测到 C++七天学习 App，请先安装后再试。")
        }
    }

    private func openCppLearning() {
        guard let url = URL(string: "cpplearn://"),
              UIApplication.shared.canOpenURL(url) else {
            showMissingAlert = true
            return
        }
        UIApplication.shared.open(url)
    }
}
