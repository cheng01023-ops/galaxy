import Foundation
import SwiftData

/// 课程表的学期设置与小组件数据同步。
@MainActor
final class TimetableViewModel: ObservableObject {
    static let shared = TimetableViewModel()

    @Published var semesterStart: Date

    private init() {
        semesterStart = TimetableSharedStore.loadSemesterStart()
            ?? TimetableReminderService.defaultSemesterStart()
    }

    var currentWeek: Int {
        TimetableSharedStore.currentWeek(semesterStart: semesterStart)
    }

    /// 更新学期开始日期（自动归一化到周一）并同步到共享容器。
    func updateSemesterStart(_ date: Date) {
        semesterStart = TimetableReminderService.normalizedMonday(date)
        TimetableSharedStore.saveSemesterStart(semesterStart)
    }

    /// 把 SwiftData 课程同步到 App Group，供桌面小组件读取。
    func syncSharedStore(courses: [Course]) {
        let widgets = courses.map { course in
            WidgetCourse(
                courseID: course.courseID,
                name: course.name,
                teacher: course.teacher,
                location: course.location,
                weekday: course.weekday,
                startMinutes: course.startMinutes,
                endMinutes: course.endMinutes,
                startWeek: course.startWeek,
                endWeek: course.endWeek,
                weeksPatternRaw: course.weeksPatternRaw,
                colorHex: course.colorHex
            )
        }
        TimetableSharedStore.save(widgets)
        TimetableReminderService.shared.sync(courses: courses, semesterStart: semesterStart)
    }
}
