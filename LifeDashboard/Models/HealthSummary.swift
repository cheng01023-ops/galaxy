import Foundation

/// 今日健康摘要数据。
struct HealthSummary {
    var stepCount: Double = 0
    var sleepHours: Double = 0
    var restingHeartRate: Double = 0

    /// 步数是否为有效数据（无数据时为 false）。
    var hasStepData: Bool { stepCount > 0 }
    /// 睡眠时长是否为有效数据。
    var hasSleepData: Bool { sleepHours > 0 }
    /// 静息心率是否为有效数据。
    var hasHeartRateData: Bool { restingHeartRate > 0 }
}

/// 单日步数，用于绘制 7 天趋势图。
struct DailySteps: Identifiable {
    let date: Date
    let steps: Double

    var id: Date { date }
}

/// 本周健康聚合结果。
struct WeekHealthSummary {
    var totalSteps: Double = 0
    var averageSleepHours: Double = 0
}
