import Foundation

/// 今日健康摘要数据。
struct HealthSummary {
    var stepCount: Double = 0
    var sleepHours: Double = 0
    var restingHeartRate: Double = 0

    /// 默认每日步数目标（用户未自定义时使用），用于详情页目标进度展示。
    static let defaultDailyStepGoal: Double = 10_000

    /// 步数是否为有效数据（无数据时为 false）。
    var hasStepData: Bool { stepCount > 0 }
    /// 睡眠时长是否为有效数据。
    var hasSleepData: Bool { sleepHours > 0 }
    /// 静息心率是否为有效数据。
    var hasHeartRateData: Bool { restingHeartRate > 0 }
    /// 是否存在任何有效数据（任一指标有值）。
    var hasAnyData: Bool { hasStepData || hasSleepData || hasHeartRateData }
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

/// 睡眠阶段类型（仅统计有数据的阶段）。
enum SleepStage: String, CaseIterable, Identifiable {
    case awake = "清醒"
    case core = "核心睡眠"
    case deep = "深睡"
    case rem = "快速眼动"

    var id: String { rawValue }
}

/// 单晚某个睡眠阶段的时长（分钟）。
struct SleepStageBreakdown: Identifiable {
    let stage: SleepStage
    let minutes: Double

    var id: SleepStage { stage }
}

/// 单日睡眠时长，用于绘制近 7 天睡眠趋势。
struct DailySleep: Identifiable {
    let date: Date
    let hours: Double

    var id: Date { date }
}

/// 单日静息心率，用于绘制近 7 天心率趋势。
struct DailyHeartRate: Identifiable {
    let date: Date
    let bpm: Double

    var id: Date { date }
}
