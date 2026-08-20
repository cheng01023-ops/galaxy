import Foundation

/// 一个喝水提醒时间点。
struct WaterReminder: Codable, Identifiable, Hashable {
    var id = UUID()
    var hour: Int
    var minute: Int
}
