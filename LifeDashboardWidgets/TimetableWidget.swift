import Foundation
import SwiftUI
import WidgetKit

// MARK: - Widget 端颜色解析（Widget target 不编译 Color+App.swift）

extension Color {
    init(widgetHex: String) {
        var value = widgetHex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("0x") || value.hasPrefix("0X") { value.removeFirst(2) }
        else if value.hasPrefix("#") { value.removeFirst() }
        var rgb: UInt64 = 0
        if value.count == 6, Scanner(string: value).scanHexInt64(&rgb) {
            self.init(
                red: Double((rgb >> 16) & 0xFF) / 255.0,
                green: Double((rgb >> 8) & 0xFF) / 255.0,
                blue: Double(rgb & 0xFF) / 255.0
            )
        } else {
            self.init(.systemBlue)
        }
    }
}

/// 课程表桌面小组件：显示今天与下一节课。
struct TimetableWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TimetableWidget", provider: TimetableTimelineProvider()) { entry in
            TimetableWidgetView(entry: entry)
        }
        .configurationDisplayName("Galaxy 课程表")
        .description("在桌面查看今天与下一节课，无需打开 App。")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryRectangular, .accessoryInline
        ])
    }
}

// MARK: - Timeline

struct TimetableEntry: TimelineEntry {
    let date: Date
    let courses: [WidgetCourse]
    let semesterStart: Date?
}

struct TimetableTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimetableEntry {
        TimetableEntry(date: .now, courses: TimetableSharedStore.load(), semesterStart: TimetableSharedStore.loadSemesterStart())
    }

    func getSnapshot(in context: Context, completion: @escaping (TimetableEntry) -> Void) {
        if context.isPreview {
            completion(TimetableEntry(date: .now, courses: .sample, semesterStart: nil))
        } else {
            completion(TimetableEntry(date: .now, courses: TimetableSharedStore.load(), semesterStart: TimetableSharedStore.loadSemesterStart()))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimetableEntry>) -> Void) {
        let courses = TimetableSharedStore.load()
        let semester = TimetableSharedStore.loadSemesterStart()

        var entries: [TimetableEntry] = [
            TimetableEntry(date: .now, courses: courses, semesterStart: semester)
        ]

        // 在下一节课开始 / 结束时刷新一次，保证倒计时与“当前课”显示准确。
        var refreshDates: [Date] = []
        if let next = TimetableSharedStore.nextCourse(after: .now, all: courses, semesterStart: semester) {
            refreshDates.append(next.date)
            let end = TimetableSharedStore.startDate(for: next.course, on: next.date)
                .addingTimeInterval(TimeInterval(max(1, next.course.endMinutes - next.course.startMinutes) * 60))
            refreshDates.append(end)
        }
        refreshDates.append(Date().addingTimeInterval(30 * 60))
        let nextRefresh = refreshDates.filter { $0 > Date() }.min() ?? Date().addingTimeInterval(30 * 60)

        completion(Timeline(entries: entries, policy: .after(nextRefresh)))
    }
}

// MARK: - 视图

struct TimetableWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TimetableEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallTimetableView(entry: entry)
            case .systemLarge:
                LargeTimetableView(entry: entry)
            case .accessoryRectangular:
                RectangularTimetableView(entry: entry)
            case .accessoryInline:
                InlineTimetableView(entry: entry)
            default:
                MediumTimetableView(entry: entry)
            }
        }
    }
}

private struct SmallTimetableView: View {
    let entry: TimetableEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                Text("课程表")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
            }

            Spacer(minLength: 0)

            if let next = TimetableSharedStore.nextCourse(after: .now, all: entry.courses, semesterStart: entry.semesterStart) {
                Text(next.course.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text(WidgetCourse.timeText(next.course.startMinutes))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                if !next.course.location.isEmpty {
                    Text(next.course.location)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                }
            } else {
                Text("今天没课")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("好好休息")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(widgetHex: "0x7167E8"),
                    Color(widgetHex: "0x5B8DEF")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct MediumTimetableView: View {
    let entry: TimetableEntry

    var body: some View {
        let today = TimetableSharedStore.courses(on: .now, all: entry.courses, semesterStart: entry.semesterStart)
        let week = TimetableSharedStore.currentWeek(semesterStart: entry.semesterStart)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("今天课程")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("第 \(week) 周")
                        .font(.headline)
                }
                Spacer()
                if let next = TimetableSharedStore.nextCourse(after: .now, all: entry.courses, semesterStart: entry.semesterStart) {
                    Text(next.course.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(widgetHex: next.course.colorHex), in: Capsule())
                        .lineLimit(1)
                }
            }

            if today.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "sun.max.fill")
                            .foregroundStyle(.yellow)
                        Text("今天没课")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                VStack(spacing: 6) {
                    ForEach(today.prefix(4)) { course in
                        HStack(spacing: 8) {
                            Text(WidgetCourse.timeText(course.startMinutes))
                                .font(.caption.weight(.bold))
                                .monospacedDigit()
                                .foregroundStyle(Color(widgetHex: course.colorHex))
                                .frame(width: 44, alignment: .leading)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(widgetHex: course.colorHex))
                                .frame(width: 3, height: 26)
                            Text(course.name)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text(course.location)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color(.secondarySystemBackground)
        }
    }
}

private struct LargeTimetableView: View {
    let entry: TimetableEntry

    var body: some View {
        let today = TimetableSharedStore.courses(on: .now, all: entry.courses, semesterStart: entry.semesterStart)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日课程")
                    .font(.headline)
                Spacer()
                if let next = TimetableSharedStore.nextCourse(after: .now, all: entry.courses, semesterStart: entry.semesterStart) {
                    Label("下一节 \(WidgetCourse.timeText(next.course.startMinutes))", systemImage: "bell.fill")
                        .font(.caption)
                        .foregroundStyle(Color(widgetHex: next.course.colorHex))
                }
            }

            if today.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "sun.max.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.yellow)
                    Text("今天没课，好好休息")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(today) { course in
                    HStack(spacing: 12) {
                        VStack(spacing: 1) {
                            Text(WidgetCourse.timeText(course.startMinutes))
                                .font(.caption.weight(.bold))
                                .monospacedDigit()
                            Text(WidgetCourse.timeText(course.endMinutes))
                                .font(.caption2)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 46)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(widgetHex: course.colorHex))
                            .frame(width: 6)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(course.name)
                                .font(.subheadline.weight(.semibold))
                            HStack(spacing: 6) {
                                if !course.location.isEmpty {
                                    Text(course.location)
                                }
                                if !course.teacher.isEmpty {
                                    Text("· \(course.teacher)")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(8)
                    .background(Color(widgetHex: course.colorHex).opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(16)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

private struct RectangularTimetableView: View {
    let entry: TimetableEntry

    var body: some View {
        if let next = TimetableSharedStore.nextCourse(after: .now, all: entry.courses, semesterStart: entry.semesterStart) {
            HStack(spacing: 8) {
                Image(systemName: "bell.fill")
                    .font(.headline)
                    .widgetAccentable()
                VStack(alignment: .leading, spacing: 1) {
                    Text(next.course.name)
                        .font(.headline)
                        .lineLimit(1)
                    Text("\(WidgetCourse.timeText(next.course.startMinutes)) · \(next.course.location)")
                        .font(.caption)
                }
                Spacer(minLength: 0)
            }
        } else {
            Label("今天没课", systemImage: "sun.max.fill")
                .font(.headline)
        }
    }
}

private struct InlineTimetableView: View {
    let entry: TimetableEntry

    var body: some View {
        if let next = TimetableSharedStore.nextCourse(after: .now, all: entry.courses, semesterStart: entry.semesterStart) {
            Label {
                Text("\(next.course.name) \(WidgetCourse.timeText(next.course.startMinutes))")
            } icon: {
                Image(systemName: "calendar.badge.clock")
            }
        } else {
            Label("今天没课", systemImage: "sun.max")
        }
    }
}

// MARK: - 示例数据

private extension [WidgetCourse] {
    static let sample: [WidgetCourse] = [
        WidgetCourse(courseID: UUID(), name: "高等数学", teacher: "张老师", location: "教一 101", weekday: 1, startMinutes: 8 * 60, endMinutes: 9 * 60 + 40, startWeek: 1, endWeek: 16, weeksPatternRaw: "每周", colorHex: "0x5AC8FA"),
        WidgetCourse(courseID: UUID(), name: "大学英语", teacher: "李老师", location: "外语楼 205", weekday: 1, startMinutes: 10 * 60, endMinutes: 11 * 60 + 40, startWeek: 1, endWeek: 16, weeksPatternRaw: "每周", colorHex: "0xF472B6")
    ]
}
