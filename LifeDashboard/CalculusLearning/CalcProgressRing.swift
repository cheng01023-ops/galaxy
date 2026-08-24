import SwiftUI

struct CalcProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 9

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(uiColor: .systemGray5), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(0.0001, min(progress, 1.0)))
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.4), value: progress)

            Text("\(Int((progress * 100).rounded()))%")
                .font(.system(.caption, design: .rounded).bold())
                .monospacedDigit()
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
