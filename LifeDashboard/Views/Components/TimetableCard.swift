import SwiftUI
import SwiftData

/// 仪表盘上的课程表卡片：点击进入完整课程表。
struct TimetableCard: View {
    @Query(sort: \Course.createdAt) private var courses: [Course]
    @StateObject private var viewModel = TimetableViewModel.shared

    private let gradient = LinearGradient(
        colors: [
            Color(red: 0.42, green: 0.38, blue: 0.95),
            Color(red: 0.33, green: 0.45, blue: 0.98),
            Color(red: 0.28, green: 0.58, blue: 0.92)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        NavigationLink {
            TimetableHomeView()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                header

                weekRow

                semesterProgress

                if let next = nextClass() {
                    nextClassCard(next)
                } else if courses.isEmpty {
                    noCourseState
                } else {
                    noClassState
                }

                todayRow

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(gradient, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color(red: 0.35, green: 0.35, blue: 0.90).opacity(0.4), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 标题

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text("课程表")
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(1)
            Spacer(minLength: 4)
            Text(dateText)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }

    // MARK: - 周次 / 学期进度

    private var weekRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("第 \(viewModel.currentWeek) 周")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text(currentWeekPatternText)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            Spacer(minLength: 0)
        }
    }

    private var semesterProgress: some View {
        HStack(spacing: 8) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.22))
                    Capsule()
                        .fill(.white)
                        .frame(width: proxy.size.width * semesterProgressRatio)
                }
            }
            .frame(height: 5)

            Text("\(viewModel.currentWeek)/\(totalWeeks) 周")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.85))
                .monospacedDigit()
                .lineLimit(1)
        }
    }

    private var totalWeeks: Int {
        max(courses.map(\.endWeek).max() ?? 16, 1)
    }

    private var semesterProgressRatio: Double {
        min(1.0, Double(viewModel.currentWeek) / Double(totalWeeks))
    }

    private var currentWeekPatternText: String {
        viewModel.currentWeek % 2 == 1 ? "单周" : "双周"
    }

    private var dateText: String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: .now)
        let day = calendar.component(.day, from: .now)
        let weekday = Course.weekdays[TimetableSharedStore.chineseWeekday(for: .now) - 1]
        return "\(month)/\(day) \(weekday)"
    }

    // MARK: - 下一节 / 当前课

    private func nextClassCard(_ next: (course: Course, date: Date)) -> some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                .fill(Color(hex: next.course.colorHex))
                .frame(width: 4)
                .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(next.date > .now ? "下一节" : "当前课程")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))
                    Spacer(minLength: 4)
                    countdownText(next)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Text(next.course.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(nextMeta(next.course))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func countdownText(_ next: (course: Course, date: Date)) -> some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            Text(countdownString(interval: next.date.timeIntervalSince(context.date)))
        }
    }

    private func countdownString(interval: TimeInterval) -> String {
        if interval <= 0 { return "正在上课" }
        let minutes = Int(interval / 60)
        if minutes < 60 {
            return minutes < 1 ? "马上开始" : "还有 \(minutes) 分钟"
        }
        return "还有 \(minutes / 60) 小时 \(minutes % 60) 分"
    }

    private func nextMeta(_ course: Course) -> String {
        var parts = [course.durationText]
        if !course.location.isEmpty { parts.append(course.location) }
        if !course.teacher.isEmpty { parts.append(course.teacher) }
        return parts.joined(separator: " · ")
    }

    // MARK: - 空状态

    private var noCourseState: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("还没有课程")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Text("点击添加第一门课")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var noClassState: some View {
        HStack(spacing: 8) {
            Image(systemName: "sun.max.fill")
                .font(.subheadline)
                .foregroundStyle(.yellow)
            Text("近期没课，好好休息")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - 今日概览

    private var todayRow: some View {
        let today = todayCourses()
        return HStack(spacing: 6) {
            Image(systemName: today.isEmpty ? "sun.max" : "list.bullet")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))

            if today.isEmpty {
                Text("今天没课")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
            } else {
                Text("今日 \(today.count) 节")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                    .monospacedDigit()
                HStack(spacing: 5) {
                    ForEach(Array(today.enumerated()), id: \.element.id) { _, course in
                        Circle()
                            .fill(isCourseDone(course) ? Color(hex: course.colorHex) : .white.opacity(0.35))
                            .frame(width: 7, height: 7)
                    }
                }
            }

            Spacer(minLength: 0)
            chip("\(courses.count) 门课")
        }
    }

    private func isCourseDone(_ course: Course) -> Bool {
        course.startMinutes <= minutesSinceMidnight
    }

    private var minutesSinceMidnight: Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: .now)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    // MARK: - 数据

    private func todayCourses() -> [Course] {
        let day = TimetableSharedStore.chineseWeekday(for: .now)
        return courses
            .filter { $0.weekday == day && $0.isActive(inWeek: viewModel.currentWeek) }
            .sorted { $0.startMinutes < $1.startMinutes }
    }

    private func nextClass() -> (course: Course, date: Date)? {
        let calendar = Calendar.current
        var best: (Course, Date)?
        for offset in 0..<14 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: .now) else { continue }
            let weekday = TimetableSharedStore.chineseWeekday(for: day)
            let week = TimetableSharedStore.currentWeek(semesterStart: viewModel.semesterStart, now: day)
            let dayCourses = courses
                .filter { $0.weekday == weekday && $0.isActive(inWeek: week) }
                .sorted { $0.startMinutes < $1.startMinutes }
            for course in dayCourses {
                let start = TimetableSharedStore.startDate(
                    for: WidgetCourse(courseID: course.courseID, name: course.name, teacher: course.teacher, location: course.location, weekday: course.weekday, startMinutes: course.startMinutes, endMinutes: course.endMinutes, startWeek: course.startWeek, endWeek: course.endWeek, weeksPatternRaw: course.weeksPatternRaw, colorHex: course.colorHex),
                    on: day
                )
                if start >= .now {
                    if best == nil || start < best!.1 {
                        best = (course, start)
                    }
                    break
                }
            }
        }
        return best
    }
}
