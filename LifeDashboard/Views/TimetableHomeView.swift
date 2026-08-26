import SwiftUI
import SwiftData

/// 课程表主界面：今日 / 周课表 / 全部课程 + 学期设置。
struct TimetableHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.createdAt) private var courses: [Course]

    @StateObject private var viewModel = TimetableViewModel.shared

    private enum Tab: String, CaseIterable {
        case today = "今日"
        case week = "周课表"
        case all = "全部课程"
    }

    @State private var tab: Tab = .today
    @State private var isShowingAdd = false
    @State private var editingCourse: Course?
    @State private var isShowingSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                weekHeader

                Picker("视图", selection: $tab) {
                    ForEach(Tab.allCases, id: \.self) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                switch tab {
                case .today: todayView
                case .week: weekGridView
                case .all: allCoursesView
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("课程表")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    isShowingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingAdd) {
            TimetableCourseEditorView { sync() }
        }
        .sheet(item: $editingCourse) { course in
            TimetableCourseEditorView(course: course) { sync() }
        }
        .sheet(isPresented: $isShowingSettings) {
            TimetableSettingsView(viewModel: viewModel, courses: courses) { sync() }
        }
        .onAppear { sync() }
    }

    // MARK: - 顶部周次信息

    private var weekHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: "0x8E7CF3").opacity(0.16))
                VStack(spacing: 2) {
                    Text("第 \(viewModel.currentWeek) 周")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color(hex: "0x6D5BE8"))
                    Text(currentWeekPatternText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
            .fixedSize()

            VStack(alignment: .leading, spacing: 3) {
                Text("本学期 \(totalWeeks) 周")
                    .font(.subheadline.weight(.semibold))
                Text("共 \(courses.count) 门课程")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let next = nextClass() {
                    Text("下一节：\(next.course.name) \(next.course.startTimeText)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color(hex: next.course.colorHex))
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var totalWeeks: Int {
        courses.map(\.endWeek).max() ?? 16
    }

    private var currentWeekPatternText: String {
        viewModel.currentWeek % 2 == 1 ? "单周" : "双周"
    }

    // MARK: - 今日

    private var todayView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let next = nextClass(on: .now) {
                countdownCard(next)
            }

            let list = todayCourses()
            if list.isEmpty {
                ContentUnavailableView(
                    "今天没课",
                    systemImage: "sun.max",
                    description: Text("好好休息，或者去自习吧")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(list) { course in
                    courseRow(course)
                }
            }
        }
    }

    private func countdownCard(_ next: (course: Course, date: Date)) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let interval = next.date.timeIntervalSince(now)
            VStack(spacing: 6) {
                Text("下一节课")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if interval > 0 {
                    Text(timerInterval: now...next.date, countsDown: true)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color(hex: next.course.colorHex))
                } else {
                    Text("正在上课")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.green)
                }
                HStack(spacing: 6) {
                    Text(next.course.name)
                    if !next.course.location.isEmpty {
                        Text("· \(next.course.location)")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    private func courseRow(_ course: Course) -> some View {
        Button {
            editingCourse = course
        } label: {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color(hex: course.colorHex))
                    .frame(width: 5)
                    .frame(maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(course.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(course.durationText)
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(Color(hex: course.colorHex))
                    }
                    HStack(spacing: 8) {
                        if !course.location.isEmpty {
                            Label(course.location, systemImage: "mappin.and.ellipse")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if !course.teacher.isEmpty {
                            Label(course.teacher, systemImage: "person")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if course.reminderEnabled {
                            Image(systemName: "bell.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 周课表（7 列网格）

    private var weekGridView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 8) {
                ForEach(1...7, id: \.self) { day in
                    dayColumn(day)
                }
            }
        }
        .padding(10)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func dayColumn(_ day: Int) -> some View {
        let dayCourses = coursesFor(weekday: day)
        let isToday = day == TimetableSharedStore.chineseWeekday(for: .now)
        return VStack(alignment: .leading, spacing: 6) {
            Text(Course.weekdays[day - 1])
                .font(.caption.weight(isToday ? .bold : .semibold))
                .foregroundStyle(isToday ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(
                    isToday ? Color(hex: "0x8E7CF3") : Color(.tertiarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )

            if dayCourses.isEmpty {
                VStack(spacing: 4) {
                    Text("—")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(width: 66, height: 40)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                ForEach(dayCourses) { course in
                    Button {
                        editingCourse = course
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(course.name)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            Text(course.startTimeText)
                                .font(.system(size: 10, weight: .medium))
                                .monospacedDigit()
                            if !course.location.isEmpty {
                                Text(course.location)
                                    .font(.system(size: 9))
                                    .lineLimit(1)
                            }
                        }
                        .foregroundStyle(.white)
                        .padding(6)
                        .frame(width: 66, alignment: .leading)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(hex: course.colorHex),
                                    Color(hex: course.colorHex).opacity(0.75)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(width: 66)
    }

    // MARK: - 全部课程

    private var allCoursesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if courses.isEmpty {
                ContentUnavailableView(
                    "还没有课程",
                    systemImage: "calendar.badge.plus",
                    description: Text("点右上角加号添加第一门课")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                let sorted = courses.sorted { lhs, rhs in
                    if lhs.weekday != rhs.weekday { return lhs.weekday < rhs.weekday }
                    return lhs.startMinutes < rhs.startMinutes
                }
                ForEach(sorted) { course in
                    HStack {
                        Image(systemName: "square.fill")
                            .font(.caption)
                            .foregroundStyle(Color(hex: course.colorHex))
                        Text("\(Course.weekdays[course.weekday - 1]) \(course.durationText)")
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 104, alignment: .leading)
                        Text(course.name)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                    .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .contentShape(Rectangle())
                    .onTapGesture { editingCourse = course }
                }
            }
        }
    }

    // MARK: - 数据与同步

    private func coursesFor(weekday: Int) -> [Course] {
        courses
            .filter { $0.weekday == weekday && $0.isActive(inWeek: viewModel.currentWeek) }
            .sorted { $0.startMinutes < $1.startMinutes }
    }

    private func todayCourses() -> [Course] {
        let day = TimetableSharedStore.chineseWeekday(for: .now)
        return coursesFor(weekday: day)
    }

    private func nextClass(on date: Date = .now) -> (course: Course, date: Date)? {
        let calendar = Calendar.current
        var best: (Course, Date)?
        for offset in 0..<14 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: date) else { continue }
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
                if start >= date {
                    if best == nil || start < best!.1 {
                        best = (course, start)
                    }
                    break
                }
            }
        }
        return best
    }

    private func sync() {
        viewModel.syncSharedStore(courses: courses)
    }
}
