import Foundation

/// 每周小结展示模型。
struct WeeklyReport {
    let weekRangeText: String
    let totalSteps: Double
    let averageSleepHours: Double
    let totalFocusMinutes: Int

    /// 是否为一周结束（周日）生成的完整报告。
    let isWeekComplete: Bool
}
