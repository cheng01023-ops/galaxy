import Foundation
import HealthKit

/// 负责 HealthKit 权限申请与健康数据读取。
/// 所有 UI 更新均发生在主线程（@MainActor）。
@MainActor
final class HealthService: ObservableObject {
    @Published var summary = HealthSummary()
    @Published var last7DaysSteps: [DailySteps] = []
    @Published var last7DaysSleep: [DailySleep] = []
    @Published var sleepStages: [SleepStageBreakdown] = []
    @Published var last7DaysHeartRate: [DailyHeartRate] = []
    @Published var weekSummary = WeekHealthSummary()
    @Published var isAuthorized = false
    @Published var errorMessage: String?

    private let store = HKHealthStore()

    /// HealthKit 是否可用（真机可用，模拟器通常不可用）。
    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// 需要读取的数据类型。
    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        if let step = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            types.insert(step)
        }
        if let heart = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(heart)
        }
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        return types
    }

    /// 请求 HealthKit 读取权限（首次启动时调用）。
    func requestAuthorization() async {
        guard isHealthDataAvailable else {
            errorMessage = "当前设备不可用 HealthKit（模拟器不支持），请在真机上运行。"
            return
        }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
        } catch {
            errorMessage = "HealthKit 授权失败：\(error.localizedDescription)"
        }
    }

    /// 请求授权并刷新全部健康数据。
    func requestAuthorizationAndFetch() async {
        await requestAuthorization()
        guard isAuthorized, isHealthDataAvailable else { return }
        await fetchTodaySummary()
        await fetchStepTrend(days: 7)
        await fetchWeekSummary()
    }

    /// 读取今日步数、昨晚睡眠时长、静息心率。
    func fetchTodaySummary() async {
        guard isAuthorized, isHealthDataAvailable else { return }
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday) ?? startOfToday

        async let steps = fetchStepCount(from: startOfToday, to: now)
        async let sleep = fetchSleepDuration(from: startOfYesterday, to: startOfToday)
        async let heartRate = fetchRestingHeartRate()

        var newSummary = HealthSummary()
        newSummary.stepCount = (try? await steps) ?? 0
        newSummary.sleepHours = ((try? await sleep) ?? 0) / 3600.0
        newSummary.restingHeartRate = (try? await heartRate) ?? 0
        summary = newSummary
    }

    /// 读取最近 n 天（含今天）的每日步数，用于折线图。
    func fetchStepTrend(days: Int = 7) async {
        guard isAuthorized, isHealthDataAvailable else { return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var result: [DailySteps] = []

        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let count = (try? await fetchStepCount(from: day, to: nextDay)) ?? 0
            result.append(DailySteps(date: day, steps: count))
        }
        last7DaysSteps = result
    }

    /// 聚合本周（周一至今日）总步数与平均睡眠。
    func fetchWeekSummary() async {
        guard isAuthorized, isHealthDataAvailable else { return }
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 周一作为一周开始
        guard let week = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return }

        let now = Date()
        var totalSteps = 0.0
        var totalSleepSeconds = 0.0
        var day = week.start

        while day < now {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day.addingTimeInterval(86_400)
            let end = min(nextDay, now)
            totalSteps += (try? await fetchStepCount(from: day, to: end)) ?? 0
            totalSleepSeconds += (try? await fetchSleepDuration(from: day, to: end)) ?? 0
            day = nextDay
        }

        let dayCount = max(1, calendar.dateComponents([.day], from: week.start, to: now).day ?? 1)
        weekSummary = WeekHealthSummary(
            totalSteps: totalSteps,
            averageSleepHours: totalSleepSeconds / 3600.0 / Double(dayCount)
        )
    }

    // MARK: - 详情页数据

    /// 刷新健康详情页所需的全部数据（睡眠趋势、睡眠阶段、心率趋势）。
    func fetchDetailData() async {
        guard isAuthorized, isHealthDataAvailable else { return }
        await fetchSleepTrend(days: 7)
        await fetchSleepStageBreakdown()
        await fetchHeartRateTrend(days: 7)
    }

    /// 读取最近 n 天（含今天）的每日睡眠时长。
    func fetchSleepTrend(days: Int = 7) async {
        guard isAuthorized, isHealthDataAvailable else { return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var result: [DailySleep] = []

        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let seconds = (try? await fetchSleepDuration(from: day, to: nextDay)) ?? 0
            result.append(DailySleep(date: day, hours: seconds / 3600.0))
        }
        last7DaysSleep = result
    }

    /// 读取昨晚各睡眠阶段时长（分钟），仅保留有数据的阶段。
    func fetchSleepStageBreakdown() async {
        guard isAuthorized, isHealthDataAvailable else { return }
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday) ?? startOfToday

        let samples = (try? await fetchSleepSamples(from: startOfYesterday, to: startOfToday)) ?? []
        var minutesByStage: [SleepStage: Double] = [:]

        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate) / 60.0
            guard duration > 0 else { continue }
            switch sample.value {
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                minutesByStage[.rem, default: 0] += duration
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                minutesByStage[.deep, default: 0] += duration
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                 HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                minutesByStage[.core, default: 0] += duration
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                minutesByStage[.awake, default: 0] += duration
            default:
                break
            }
        }

        sleepStages = SleepStage.allCases.compactMap { stage in
            guard let minutes = minutesByStage[stage], minutes > 0 else { return nil }
            return SleepStageBreakdown(stage: stage, minutes: minutes)
        }
    }

    /// 读取最近 n 天（含今天）每日静息心率（每天取最新一条）。
    func fetchHeartRateTrend(days: Int = 7) async {
        guard isAuthorized, isHealthDataAvailable else { return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var result: [DailyHeartRate] = []

        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let bpm = (try? await fetchRestingHeartRate(from: day, to: nextDay)) ?? 0
            result.append(DailyHeartRate(date: day, bpm: bpm))
        }
        last7DaysHeartRate = result
    }

    // MARK: - Private helpers

    private func fetchStepCount(from start: Date, to end: Date) async throws -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let sum = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: sum)
            }
            store.execute(query)
        }
    }

    /// 读取时间段内的原始睡眠样本。
    private func fetchSleepSamples(from start: Date, to end: Date) async throws -> [HKCategorySample] {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let samples = try await fetchSamples(sampleType: type, predicate: predicate, sort: [sort], limit: 0)
        return samples.compactMap { $0 as? HKCategorySample }
    }

    private func fetchSleepDuration(from start: Date, to end: Date) async throws -> Double {
        let samples = try await fetchSleepSamples(from: start, to: end)

        // 仅统计真正的“睡着”阶段，排除卧床/清醒。
        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue
        ]

        return samples
            .filter { asleepValues.contains($0.value) }
            .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
    }

    /// 读取指定时间段内最近一条静息心率；不传时间段时读取全部记录中的最近一条。
    private func fetchRestingHeartRate(from start: Date? = nil, to end: Date? = nil) async throws -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return 0 }
        var predicate: NSPredicate?
        if let start, let end {
            predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let samples = try await fetchSamples(sampleType: type, predicate: predicate, sort: [sort], limit: 1)
        guard let sample = samples.first as? HKQuantitySample else { return 0 }
        let unit = HKUnit.count().unitDivided(by: .minute())
        return sample.quantity.doubleValue(for: unit)
    }

    private func fetchSamples(
        sampleType: HKSampleType,
        predicate: NSPredicate?,
        sort: [NSSortDescriptor]?,
        limit: Int
    ) async throws -> [HKSample] {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: sort
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples ?? [])
            }
            store.execute(query)
        }
    }
}
