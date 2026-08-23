import Foundation
import SwiftUI

// MARK: - 板块（Xcode / VSCode）

enum CLTrack: String, CaseIterable, Identifiable, Hashable {
    case xcode = "Xcode"
    case vscode = "VSCode"

    var id: String { rawValue }

    /// 课程资源所在的 Bundle 子目录
    var subdirectory: String {
        switch self {
        case .xcode: return "CCourseContent"
        case .vscode: return "CVSCodeCourse"
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

struct CLCourseDay: Identifiable, Hashable {
    let id: Int
    let title: String
    let subtitle: String
    let fileName: String
    let systemImage: String

    static func all(for track: CLTrack) -> [CLCourseDay] {
        switch track {
        case .xcode:
            return [
                CLCourseDay(id: 0, title: "预备课", subtitle: "零基础友好入门", fileName: "第0天_预备课_零基础友好入门.md", systemImage: "figure.mind.and.body"),
                CLCourseDay(id: 1, title: "第 1 天", subtitle: "Xcode 入门 + C 基础语法", fileName: "第1天_Xcode入门与C基础语法.md", systemImage: "laptopcomputer"),
                CLCourseDay(id: 2, title: "第 2 天", subtitle: "流程控制与循环", fileName: "第2天_流程控制与循环.md", systemImage: "arrow.triangle.branch"),
                CLCourseDay(id: 3, title: "第 3 天", subtitle: "函数、数组、字符串", fileName: "第3天_函数数组与字符串.md", systemImage: "function"),
                CLCourseDay(id: 4, title: "第 4 天", subtitle: "指针与动态内存", fileName: "第4天_指针与动态内存.md", systemImage: "memorychip"),
                CLCourseDay(id: 5, title: "第 5 天", subtitle: "结构体与枚举", fileName: "第5天_结构体与枚举.md", systemImage: "shippingbox"),
                CLCourseDay(id: 6, title: "第 6 天", subtitle: "链表、文件与预处理", fileName: "第6天_链表文件与预处理.md", systemImage: "square.stack.3d.up"),
                CLCourseDay(id: 7, title: "第 7 天", subtitle: "综合项目 + 查漏补缺", fileName: "第7天_综合项目与查漏补缺.md", systemImage: "hammer")
            ]
        case .vscode:
            return [
                CLCourseDay(id: 0, title: "预备课", subtitle: "零基础友好入门（VSCode 版）", fileName: "第0天_VSCode预备课_零基础友好入门.md", systemImage: "figure.mind.and.body"),
                CLCourseDay(id: 1, title: "第 1 天", subtitle: "VSCode 环境搭建 + C 基础语法", fileName: "第1天_VSCode入门与C基础语法.md", systemImage: "chevron.left.forwardslash.chevron.right"),
                CLCourseDay(id: 2, title: "第 2 天", subtitle: "流程控制与循环", fileName: "第2天_流程控制与循环.md", systemImage: "arrow.triangle.branch"),
                CLCourseDay(id: 3, title: "第 3 天", subtitle: "函数、数组、字符串", fileName: "第3天_函数数组与字符串.md", systemImage: "function"),
                CLCourseDay(id: 4, title: "第 4 天", subtitle: "指针与动态内存", fileName: "第4天_指针与动态内存.md", systemImage: "memorychip"),
                CLCourseDay(id: 5, title: "第 5 天", subtitle: "结构体与枚举", fileName: "第5天_结构体与枚举.md", systemImage: "shippingbox"),
                CLCourseDay(id: 6, title: "第 6 天", subtitle: "链表、文件与预处理", fileName: "第6天_链表文件与预处理.md", systemImage: "square.stack.3d.up"),
                CLCourseDay(id: 7, title: "第 7 天", subtitle: "综合项目 + 查漏补缺", fileName: "第7天_综合项目与查漏补缺.md", systemImage: "hammer")
            ]
        }
    }
}

// MARK: - 全局状态

final class CLAppStore: ObservableObject {
    /// 全局共享实例：退出卡片再进入时学习进度仍然保留。
    static let shared = CLAppStore()

    @Published var track: CLTrack {
        didSet {
            defaults.set(track.rawValue, forKey: trackKey)
        }
    }

    @Published private var checked: [String: Bool]

    private(set) var daysByTrack: [CLTrack: [CLCourseDay]] = [:]
    private(set) var documentsByTrack: [CLTrack: [Int: [CLBlock]]] = [:]
    private(set) var checklistTextsByTrack: [CLTrack: [Int: [String]]] = [:]

    private let defaults: UserDefaults
    private let checkedKey = "c-seven-day.checked-v1"
    private let trackKey = "c-seven-day.track"

    init() {
        self.defaults = .standard
        self.track = CLTrack(rawValue: defaults.string(forKey: trackKey) ?? "") ?? .xcode

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

        for t in CLTrack.allCases {
            let days = CLCourseDay.all(for: t)
            daysByTrack[t] = days
            var docs: [Int: [CLBlock]] = [:]
            var texts: [Int: [String]] = [:]
            for day in days {
                guard let text = Self.loadText(day.fileName, subdirectory: t.subdirectory) else { continue }
                let blocks = CLMarkdownParser.parse(text)
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

    func loadText(_ name: String, track: CLTrack? = nil) -> String? {
        let t = track ?? self.track
        return Self.loadText(name, subdirectory: t.subdirectory)
    }

    // MARK: - CLTrack helpers

    func days(for track: CLTrack? = nil) -> [CLCourseDay] {
        let t = track ?? self.track
        return daysByTrack[t] ?? []
    }

    func blocks(track: CLTrack? = nil, day: Int) -> [CLBlock] {
        let t = track ?? self.track
        return documentsByTrack[t]?[day] ?? []
    }

    func checklistTexts(track: CLTrack? = nil, day: Int) -> [String] {
        let t = track ?? self.track
        return checklistTextsByTrack[t]?[day] ?? []
    }

    // MARK: - Checklist / progress

    func isChecked(track: CLTrack? = nil, day: Int, item: String) -> Bool {
        let t = track ?? self.track
        return checked[key(track: t, day: day, item: item)] ?? false
    }

    func toggle(track: CLTrack? = nil, day: Int, item: String) {
        let t = track ?? self.track
        let k = key(track: t, day: day, item: item)
        checked[k] = !(checked[k] ?? false)
        defaults.set(checked, forKey: checkedKey)
    }

    func progress(track: CLTrack? = nil, day: Int) -> (done: Int, total: Int) {
        let t = track ?? self.track
        let texts = checklistTexts(track: t, day: day)
        let total = texts.count
        let done = texts.filter { isChecked(track: t, day: day, item: $0) }.count
        return (done, total)
    }

    func totalProgress(track: CLTrack? = nil) -> (done: Int, total: Int) {
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

    func nextIncompleteDay(track: CLTrack? = nil) -> CLCourseDay? {
        let t = track ?? self.track
        for day in days(for: t) {
            let p = progress(track: t, day: day.id)
            if p.done < p.total { return day }
        }
        return days(for: t).last
    }

    private func key(track: CLTrack, day: Int, item: String) -> String {
        "\(track.rawValue)|\(day)|\(item)"
    }

    private static func collectChecklistTexts(_ blocks: [CLBlock]) -> [String] {
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
