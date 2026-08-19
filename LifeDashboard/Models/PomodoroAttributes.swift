import ActivityKit
import Foundation

/// 番茄钟阶段。
enum PomodoroPhase: String, Codable, Hashable, Sendable {
    case focus
    case rest

    var title: String {
        switch self {
        case .focus: return "专注"
        case .rest: return "休息"
        }
    }

    var systemImage: String {
        switch self {
        case .focus: return "brain.head.profile"
        case .rest: return "cup.and.saucer"
        }
    }
}

/// ActivityKit 灵动岛 / 锁屏实时活动所需的属性。
/// 该文件同时加入 App 与 Widget Extension 两个 Target。
struct PomodoroAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// 当前阶段结束时间，Widget 用它做自动倒计时。
        var endDate: Date
        var phase: PomodoroPhase
    }

    var taskName: String
}
