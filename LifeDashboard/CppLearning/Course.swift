import Foundation
import SwiftUI

// MARK: - 板块（Xcode / VSCode）

enum Track: String, CaseIterable, Identifiable, Hashable {
    case xcode = "Xcode"
    case vscode = "VSCode"

    var id: String { rawValue }

    /// 课程资源所在的 Bundle 子目录
    var subdirectory: String {
        switch self {
        case .xcode: return "CourseContent"
        case .vscode: return "VSCodeCourse"
        }
    }

    var systemImage: String {
        switch self {
        case .xcode: return "laptopcomputer"
        case .vscode: return "chevron.left.forwardslash.chevron.right"
        }
    }

    var shortName: String {
        switch self {
        case .xcode: return "Xcode"
        case .vscode: return "VSCode"
        }
    }
}

// MARK: - 课程天

struct CourseDay: Identifiable, Hashable {
    let id: Int
    let title: String
    let subtitle: String
    let fileName: String
    let systemImage: String

    static func all(for track: Track) -> [CourseDay] {
        switch track {
        case .xcode:
            return [
                CourseDay(id: 0, title: "预备课", subtitle: "零基础友好入门", fileName: "第0天_预备课_零基础友好入门.md", systemImage: "figure.mind.and.body"),
                CourseDay(id: 1, title: "第 1 天", subtitle: "Xcode 入门 + C++ 基础语法", fileName: "第1天_Xcode入门与C++基础.md", systemImage: "laptopcomputer"),
                CourseDay(id: 2, title: "第 2 天", subtitle: "流程控制与循环", fileName: "第2天_流程控制与循环.md", systemImage: "arrow.triangle.branch"),
                CourseDay(id: 3, title: "第 3 天", subtitle: "函数、数组、字符串", fileName: "第3天_函数与数组字符串.md", systemImage: "function"),
                CourseDay(id: 4, title: "第 4 天", subtitle: "指针、引用、动态内存", fileName: "第4天_指针引用与动态内存.md", systemImage: "memorychip"),
                CourseDay(id: 5, title: "第 5 天", subtitle: "类与对象", fileName: "第5天_类与对象.md", systemImage: "shippingbox"),
                CourseDay(id: 6, title: "第 6 天", subtitle: "继承、多态 + STL", fileName: "第6天_继承多态与STL.md", systemImage: "square.stack.3d.up"),
                CourseDay(id: 7, title: "第 7 天", subtitle: "综合项目 + 查漏补缺", fileName: "第7天_综合项目与查漏补缺.md", systemImage: "hammer")
            ]
        case .vscode:
            return [
                CourseDay(id: 0, title: "预备课", subtitle: "零基础友好入门（VSCode 版）", fileName: "第0天_VSCode预备课_零基础友好入门.md", systemImage: "figure.mind.and.body"),
                CourseDay(id: 1, title: "第 1 天", subtitle: "VSCode 环境搭建 + C++ 基础语法", fileName: "第1天_VSCode入门与C++基础语法.md", systemImage: "chevron.left.forwardslash.chevron.right"),
                CourseDay(id: 2, title: "第 2 天", subtitle: "流程控制与循环", fileName: "第2天_流程控制与循环.md", systemImage: "arrow.triangle.branch"),
                CourseDay(id: 3, title: "第 3 天", subtitle: "函数、数组、字符串", fileName: "第3天_函数与数组字符串.md", systemImage: "function"),
                CourseDay(id: 4, title: "第 4 天", subtitle: "指针、引用、动态内存", fileName: "第4天_指针引用与动态内存.md", systemImage: "memorychip"),
                CourseDay(id: 5, title: "第 5 天", subtitle: "类与对象", fileName: "第5天_类与对象.md", systemImage: "shippingbox"),
                CourseDay(id: 6, title: "第 6 天", subtitle: "继承、多态 + STL", fileName: "第6天_继承多态与STL.md", systemImage: "square.stack.3d.up"),
                CourseDay(id: 7, title: "第 7 天", subtitle: "综合项目 + 查漏补缺", fileName: "第7天_综合项目与查漏补缺.md", systemImage: "hammer")
            ]
        }
    }
}

// MARK: - 全局状态

final class AppStore: ObservableObject {
    /// 全局共享实例：退出卡片再进入时学习进度仍然保留。
    static let shared = AppStore()

    @Published var track: Track {
        didSet {
            defaults.set(track.rawValue, forKey: trackKey)
        }
    }

    @Published private var checked: [String: Bool]

    private(set) var daysByTrack: [Track: [CourseDay]] = [:]
    private(set) var documentsByTrack: [Track: [Int: [Block]]] = [:]
    private(set) var checklistTextsByTrack: [Track: [Int: [String]]] = [:]

    private let defaults: UserDefaults
    private let checkedKey = "cpp-seven-day.checked-v2"
    private let trackKey = "cpp-seven-day.track"

    init() {
        self.defaults = .standard
        self.track = Track(rawValue: defaults.string(forKey: trackKey) ?? "") ?? .xcode

        var loaded = defaults.dictionary(forKey: checkedKey) as? [String: Bool] ?? [:]
        // 迁移旧数据（老版本 key 为 "天数|内容"，默认属于 Xcode 板块）
        var migrated: [String: Bool] = [:]
        for (k, v) in loaded {
            if k.hasPrefix("xcode|") || k.hasPrefix("vscode|") {
                migrated[k] = v
            } else {
                migrated["xcode|" + k] = v
            }
        }
        loaded = migrated
        self.checked = loaded

        for t in Track.allCases {
            let days = CourseDay.all(for: t)
            daysByTrack[t] = days
            var docs: [Int: [Block]] = [:]
            var texts: [Int: [String]] = [:]
            for day in days {
                guard let text = Self.loadText(day.fileName, subdirectory: t.subdirectory) else { continue }
                let blocks = MarkdownParser.parse(text)
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

    func loadText(_ name: String, track: Track? = nil) -> String? {
        let t = track ?? self.track
        return Self.loadText(name, subdirectory: t.subdirectory)
    }

    // MARK: - Track helpers

    func days(for track: Track? = nil) -> [CourseDay] {
        let t = track ?? self.track
        return daysByTrack[t] ?? []
    }

    func blocks(track: Track? = nil, day: Int) -> [Block] {
        let t = track ?? self.track
        return documentsByTrack[t]?[day] ?? []
    }

    func checklistTexts(track: Track? = nil, day: Int) -> [String] {
        let t = track ?? self.track
        return checklistTextsByTrack[t]?[day] ?? []
    }

    // MARK: - Checklist / progress

    func isChecked(track: Track? = nil, day: Int, item: String) -> Bool {
        let t = track ?? self.track
        return checked[key(track: t, day: day, item: item)] ?? false
    }

    func toggle(track: Track? = nil, day: Int, item: String) {
        let t = track ?? self.track
        let k = key(track: t, day: day, item: item)
        checked[k] = !(checked[k] ?? false)
        defaults.set(checked, forKey: checkedKey)
    }

    func progress(track: Track? = nil, day: Int) -> (done: Int, total: Int) {
        let t = track ?? self.track
        let texts = checklistTexts(track: t, day: day)
        let total = texts.count
        let done = texts.filter { isChecked(track: t, day: day, item: $0) }.count
        return (done, total)
    }

    func totalProgress(track: Track? = nil) -> (done: Int, total: Int) {
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

    func nextIncompleteDay(track: Track? = nil) -> CourseDay? {
        let t = track ?? self.track
        for day in days(for: t) {
            let p = progress(track: t, day: day.id)
            if p.done < p.total { return day }
        }
        return days(for: t).last
    }

    private func key(track: Track, day: Int, item: String) -> String {
        "\(track.rawValue)|\(day)|\(item)"
    }

    private static func collectChecklistTexts(_ blocks: [Block]) -> [String] {
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
