import SwiftUI

struct CalcCodeSample: Identifiable {
    let id: Int
    let fileName: String
    let day: Int
    let title: String
    let summary: String

    static func all(for track: CalcTrack) -> [CalcCodeSample] {
        _ = track // 微积分板块的 C 示例代码
        return [
            CalcCodeSample(id: 1, fileName: "sample_limit.c", day: 1,
                           title: "两个重要极限的数值逼近",
                           summary: "观察 (sin x)/x → 1 与 (1+1/n)ⁿ → e"),
            CalcCodeSample(id: 2, fileName: "sample_bisection.c", day: 1,
                           title: "二分法求方程根",
                           summary: "零点定理：解 x³−3x+1=0 在 (0,1) 内的根"),
            CalcCodeSample(id: 3, fileName: "sample_derivative.c", day: 2,
                           title: "用极限定义做数值求导",
                           summary: "中心差商逼近 f'(x)，观察 h→0 的收敛"),
            CalcCodeSample(id: 4, fileName: "sample_newton.c", day: 2,
                           title: "牛顿迭代法求根",
                           summary: "用导数迭代逼近 √2"),
            CalcCodeSample(id: 5, fileName: "sample_integral.c", day: 3,
                           title: "数值积分：梯形法与辛普森法",
                           summary: "计算 ∫₀¹ x² dx = 1/3，比较两种方法精度"),
            CalcCodeSample(id: 6, fileName: "sample_euler.c", day: 4,
                           title: "欧拉法解微分方程",
                           summary: "数值求解 y'=y, y(0)=1，与精确解 eˣ 对比"),
            CalcCodeSample(id: 7, fileName: "sample_gradient.c", day: 5,
                           title: "梯度下降求多元函数极小值",
                           summary: "沿负梯度方向迭代，最小化 f(x,y)=x²+y²")
        ]
    }
}

struct CalcCodeSamplesView: View {
    @EnvironmentObject private var store: CalcAppStore

    var body: some View {
        NavigationStack {
            List(CalcCodeSample.all(for: store.track)) { sample in
                NavigationLink {
                    CalcCodeSampleDetail(sample: sample, track: store.track, store: store)
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("\(sample.title)")
                            .font(.headline)
                        Text("第 \(sample.day) 天 · \(sample.summary)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("代码实验室（\(store.track.shortName)）")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CalcCodeSampleDetail: View {
    let sample: CalcCodeSample
    let track: CalcTrack
    let store: CalcAppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 1)
                    Text("这是学习用示例代码。iOS 上无法直接编译运行 C，请把代码复制到电脑上，用 Xcode 或终端（gcc/clang）编译运行。")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }

                CalcCodeBlockView(language: "c", code: code)
            }
            .padding()
        }
        .navigationTitle(sample.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var code: String {
        store.loadText(sample.fileName, track: track) ?? "// 无法读取文件：\(sample.fileName)"
    }
}
