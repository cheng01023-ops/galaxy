import Foundation
import SwiftData

/// 一次已完成的专注记录，用于统计每周专注总时长。
@Model
final class FocusSession {
    var startedAt: Date
    var durationSeconds: Int
    var phase: String

    init(startedAt: Date = .now, durationSeconds: Int, phase: String = "专注") {
        self.startedAt = startedAt
        self.durationSeconds = durationSeconds
        self.phase = phase
    }
}
