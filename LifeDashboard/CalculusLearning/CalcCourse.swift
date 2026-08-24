import Foundation
import SwiftUI

// MARK: - 板块（Xcode / VSCode）

enum CalcTrack: String, CaseIterable, Identifiable, Hashable {
    case standard = "微积分"

    var id: String { rawValue }

    /// 课程资源所在的 Bundle 子目录
    var subdirectory: String {
        "CalculusContent"
    }

    var systemImage: String {
        "function"
    }

    var shortName: String {
        "微积分"
    }
}

// MARK: - 课程天

struct CalcCourseDay: Identifiable, Hashable {
    let id: Int
    let title: String
    let subtitle: String
    let fileName: String
    let systemImage: String

    static func all(for track: CalcTrack) -> [CalcCourseDay] {
        [
            CalcCourseDay(id: 1, title: "第 1 天", subtitle: "预备基础 · 微积分背景 · 极限", fileName: "第1天_预备基础背景与极限.md", systemImage: "book.closed"),
            CalcCourseDay(id: 2, title: "第 2 天", subtitle: "函数的导数", fileName: "第2天_函数的导数.md", systemImage: "arrow.up.right.square"),
            CalcCourseDay(id: 3, title: "第 3 天", subtitle: "一元积分学", fileName: "第3天_一元积分学.md", systemImage: "square.stack.3d.up"),
            CalcCourseDay(id: 4, title: "第 4 天", subtitle: "微分方程初步 · 概念澄清与常见错误", fileName: "第4天_微分方程与概念澄清.md", systemImage: "waveform.path.ecg"),
            CalcCourseDay(id: 5, title: "第 5 天", subtitle: "空间解析几何 · 多元积分 · 线性变换与曲面", fileName: "第5天_空间解析几何与多元微积分.md", systemImage: "cube.transparent")
        ]
    }
}

// MARK: - 全局状态

final class CalcAppStore: ObservableObject {
    /// 全局共享实例：退出卡片再进入时学习进度仍然保留。
    static let shared = CalcAppStore()

    @Published var track: CalcTrack {
        didSet {
            defaults.set(track.rawValue, forKey: trackKey)
            defaults.synchronize()
        }
    }

    @Published private var checked: [String: Bool]

    private(set) var daysByTrack: [CalcTrack: [CalcCourseDay]] = [:]
    private(set) var documentsByTrack: [CalcTrack: [Int: [CalcBlock]]] = [:]
    private(set) var checklistTextsByTrack: [CalcTrack: [Int: [String]]] = [:]

    private let defaults: UserDefaults
    private let checkedKey = "calc-five-day.checked-v1"
    private let trackKey = "calc-five-day.track"

    init() {
        self.defaults = .standard
        self.track = CalcTrack(rawValue: defaults.string(forKey: trackKey) ?? "") ?? .standard

        let loaded = defaults.dictionary(forKey: checkedKey) as? [String: Bool] ?? [:]
        // 修复历史遗留的重复前缀：把 "xcode|Xcode|..." / "vscode|Xcode|..." 还原为 "Xcode|..."
        var cleaned: [String: Bool] = [:]
        for (k, v) in loaded {
            var key = k
            if key.hasPrefix("xcode|") { key = String(key.dropFirst("xcode|".count)) }
            if key.hasPrefix("vscode|") { key = String(key.dropFirst("vscode|".count)) }
            cleaned[key] = v
        }
        self.checked = cleaned

        for t in CalcTrack.allCases {
            let days = CalcCourseDay.all(for: t)
            daysByTrack[t] = days
            var docs: [Int: [CalcBlock]] = [:]
            var texts: [Int: [String]] = [:]
            for day in days {
                guard let text = Self.loadText(day.fileName, subdirectory: t.subdirectory) else { continue }
                let blocks = CalcMarkdownParser.parse(text)
                docs[day.id] = blocks
                texts[day.id] = Self.collectChecklistTexts(blocks)
            }
            documentsByTrack[t] = docs
            checklistTextsByTrack[t] = texts
        }
    }

    // MARK: - Resource helpers

    static func loadText(_ name: String, subdirectory: String) -> String? {
        guard let url = resourceURL(name, subdirectory: subdirectory) else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    static func resourceURL(_ name: String, subdirectory: String) -> URL? {
        let ns = name as NSString
        let ext = ns.pathExtension
        let base = ns.deletingPathExtension
        return Bundle.main.url(forResource: base,
                               withExtension: ext.isEmpty ? nil : ext,
                               subdirectory: subdirectory)
    }

    func loadText(_ name: String, track: CalcTrack? = nil) -> String? {
        let t = track ?? self.track
        return Self.loadText(name, subdirectory: t.subdirectory)
    }

    // MARK: - CalcTrack helpers

    func days(for track: CalcTrack? = nil) -> [CalcCourseDay] {
        let t = track ?? self.track
        return daysByTrack[t] ?? []
    }

    func blocks(track: CalcTrack? = nil, day: Int) -> [CalcBlock] {
        let t = track ?? self.track
        return documentsByTrack[t]?[day] ?? []
    }

    func checklistTexts(track: CalcTrack? = nil, day: Int) -> [String] {
        let t = track ?? self.track
        return checklistTextsByTrack[t]?[day] ?? []
    }

    // MARK: - Checklist / progress

    func isChecked(track: CalcTrack? = nil, day: Int, item: String) -> Bool {
        let t = track ?? self.track
        return checked[key(track: t, day: day, item: item)] ?? false
    }

    func toggle(track: CalcTrack? = nil, day: Int, item: String) {
        let t = track ?? self.track
        let k = key(track: t, day: day, item: item)
        checked[k] = !(checked[k] ?? false)
        defaults.set(checked, forKey: checkedKey)
        defaults.synchronize()
    }

    func progress(track: CalcTrack? = nil, day: Int) -> (done: Int, total: Int) {
        let t = track ?? self.track
        let texts = checklistTexts(track: t, day: day)
        let total = texts.count
        let done = texts.filter { isChecked(track: t, day: day, item: $0) }.count
        return (done, total)
    }

    func totalProgress(track: CalcTrack? = nil) -> (done: Int, total: Int) {
        let t = track ?? self.track
        var done = 0
        var total = 0
        for day in days(for: t) {
            let p = progress(track: t, day: day.id)
            done += p.done
            total += p.total
        }
        return (done, total)
    }

    func nextIncompleteDay(track: CalcTrack? = nil) -> CalcCourseDay? {
        let t = track ?? self.track
        for day in days(for: t) {
            let p = progress(track: t, day: day.id)
            if p.done < p.total { return day }
        }
        return days(for: t).last
    }

    private func key(track: CalcTrack, day: Int, item: String) -> String {
        "\(track.rawValue)|\(day)|\(item)"
    }

    private static func collectChecklistTexts(_ blocks: [CalcBlock]) -> [String] {
        blocks.flatMap { block -> [String] in
            switch block {
            case .checklist(let items):
                return items
            case .details(_, let inner):
                return collectChecklistTexts(inner)
            default:
                return []
            }
        }
    }
}
