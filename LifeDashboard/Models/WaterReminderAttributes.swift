import ActivityKit
import Foundation

/// 喝水提醒的 ActivityKit 属性（灵动岛 / 锁屏实时活动）。
struct WaterReminderAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var message: String = "该喝水啦"
    }
}
