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
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Text("课程表")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }

                Text("第 \(viewModel.currentWeek) 周")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                if let next = nextClass() {
                    Text("下一节 \(next.course.startTimeText) · \(next.course.name)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                } else if !todayCourses().isEmpty {
                    Text("今天 \(todayCourses().count) 节课")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                } else {
                    Text("今天没课")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }

                HStack(spacing: 6) {
                    chip("\(courses.count) 门课")
                    chip(viewModel.currentWeek % 2 == 1 ? "单周" : "双周")
                    let today = todayCourses()
                    if !today.isEmpty {
                        chip("今日 \(today.count) 节")
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(gradient, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color(red: 0.35, green: 0.35, blue: 0.90).opacity(0.4), radius: 10, x: 0, y: 4)
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
