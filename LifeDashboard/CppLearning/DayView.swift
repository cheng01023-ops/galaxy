import SwiftUI

struct DayView: View {
    let track: Track
    let day: CourseDay
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                MarkdownView(blocks: store.blocks(track: track, day: day.id), dayID: day.id, track: track)
                footer
            }
            .padding()
        }
        .navigationTitle(day.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: 16) {
            ProgressRing(progress: progressValue)
                .frame(width: 68, height: 68)

            VStack(alignment: .leading, spacing: 6) {
                Text(day.title)
                    .font(.title3.bold())
                Text(day.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("打卡 \(progress.done)/\(progress.total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private var footer: some View {
        if let previous = previousDay {
            NavigationLink(value: Route.day(track, previous)) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("上一课：\(previous.title)")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.bordered)
        }

        if let next = nextDay {
            NavigationLink(value: Route.day(track, next)) {
                HStack(spacing: 8) {
                    Spacer(minLength: 0)
                    Text("下一课：\(next.title) · \(next.subtitle)")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(nil)
                        .multilineTextAlignment(.trailing)
                    Image(systemName: "chevron.right")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
        }
    }

    private var previousDay: CourseDay? {
        let days = store.days(for: track)
        guard let index = days.firstIndex(of: day), index > 0 else { return nil }
        return days[index - 1]
    }

    private var nextDay: CourseDay? {
        let days = store.days(for: track)
        guard let index = days.firstIndex(of: day), index < days.count - 1 else { return nil }
        return days[index + 1]
    }

    private var progress: (done: Int, total: Int) {
        store.progress(track: track, day: day.id)
    }

    private var progressValue: Double {
        progress.total > 0 ? Double(progress.done) / Double(progress.total) : 0
    }
}
