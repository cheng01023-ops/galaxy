import SwiftUI

struct CalcHomeView: View {
    @EnvironmentObject private var store: CalcAppStore
    @Binding var selectedTab: CalcAppTab

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    trackPicker
                    overviewCard
                    daysSection
                    toolsSection
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("微积分五天课")
        }
    }

    private var trackPicker: some View {
        Picker("板块", selection: $store.track) {
            ForEach(CalcTrack.allCases) { track in
                Text(track.shortName).tag(track)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 4)
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                CalcProgressRing(progress: progressValue)
                    .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 6) {
                    Text("学习总进度（\(store.track.shortName)）")
                        .font(.headline)
                    Text("已完成 \(total.done) / \(total.total) 项打卡")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("每天 4～6 小时，5 天学完微积分核心")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            NavigationLink { CalcDayView(track: store.track, day: nextDay, store: store) } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                    Text("继续学习：\(nextDay.title) · \(nextDay.subtitle)")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var daysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("课程目录")
                .font(.title3.bold())

            VStack(spacing: 0) {
                ForEach(store.days()) { day in
                    NavigationLink { CalcDayView(track: store.track, day: day, store: store) } label: {
                        CalcDayRow(day: day)
                    }
                    .buttonStyle(.plain)

                    if day.id != store.days().last?.id {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("工具与资料")
                .font(.title3.bold())

            VStack(spacing: 0) {
                Button {
                    selectedTab = .code
                } label: {
                    CalcToolRow(icon: "curlybraces.square", title: "代码实验室", subtitle: "5 天详细教程")
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 52)

                Button {
                    selectedTab = .glossary
                } label: {
                    CalcToolRow(icon: "character.book.closed.fill", title: "微积分速查", subtitle: "想不起来就回来查")
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 52)

                Button {
                    selectedTab = .pdf
                } label: {
                    CalcToolRow(icon: "doc.richtext.fill",
                            title: "完整学习方案",
                            subtitle: "5 天学习总览与速查")
                }
                .buttonStyle(.plain)
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var nextDay: CalcCourseDay {
        store.nextIncompleteDay() ?? store.days().first!
    }

    private var total: (done: Int, total: Int) {
        store.totalProgress()
    }

    private var progressValue: Double {
        total.total > 0 ? Double(total.done) / Double(total.total) : 0
    }
}

struct CalcDayRow: View {
    let day: CalcCourseDay
    @EnvironmentObject private var store: CalcAppStore

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: day.systemImage)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(day.title)
                    .font(.headline)
                Text(day.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if progress.total > 0 {
                if progress.done == progress.total {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                } else {
                    Text("\(progress.done)/\(progress.total)")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var progress: (done: Int, total: Int) {
        store.progress(day: day.id)
    }
}

struct CalcToolRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
