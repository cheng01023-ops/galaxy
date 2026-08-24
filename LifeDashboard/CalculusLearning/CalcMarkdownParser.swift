import Foundation

enum CalcInline: Equatable {
    case text(String)
    case bold([CalcInline])
    case italic([CalcInline])
    case code(String)
    case link(text: String, url: String)
}

indirect enum CalcBlock: Equatable {
    case heading(level: Int, inlines: [CalcInline])
    case paragraph([CalcInline])
    case codeBlock(language: String?, code: String)
    case bulletList([[CalcInline]])
    case orderedList([[CalcInline]])
    case checklist([String])
    case blockquote([CalcInline])
    case table(headers: [String], rows: [[String]])
    case details(summary: String, blocks: [CalcBlock])
    case image(alt: String, filename: String)
    case horizontalRule
}

enum CalcMarkdownParser {

    // MARK: - CalcBlock-level parsing

    static func parse(_ text: String) -> [CalcBlock] {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized.components(separatedBy: "\n")
        var blocks: [CalcBlock] = []
        var i = 0

        while i < lines.count {
            let t = lines[i].trimmingCharacters(in: .whitespaces)
            if t.isEmpty { i += 1; continue }

            // Fenced code block
            if t.hasPrefix("```") {
                let lang = String(t.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var code: [String] = []
                i += 1
                while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    code.append(lines[i])
                    i += 1
                }
                i += 1 // skip closing fence
                blocks.append(.codeBlock(language: lang.isEmpty ? nil : lang, code: code.joined(separator: "\n")))
                continue
            }

            // Collapsible <details><summary>…</summary>…</details>
            if t.hasPrefix("<details>") {
                let summary = extractSummary(from: t)
                var inner: [String] = []
                i += 1
                while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("</details>") {
                    inner.append(lines[i])
                    i += 1
                }
                i += 1 // skip </details>
                blocks.append(.details(summary: summary, blocks: parse(inner.joined(separator: "\n"))))
                continue
            }

            // Heading
            if let heading = parseHeading(t) {
                blocks.append(heading); i += 1; continue
            }

            // Horizontal rule
            if isHorizontalRule(t) {
                blocks.append(.horizontalRule); i += 1; continue
            }

            // Table
            if t.hasPrefix("|") {
                var tableLines: [String] = []
                while i < lines.count && lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("|") {
                    tableLines.append(lines[i].trimmingCharacters(in: .whitespaces))
                    i += 1
                }
                blocks.append(parseTable(tableLines))
                continue
            }

            // Image
            if let image = parseImage(t) {
                blocks.append(image); i += 1; continue
            }

            // Blockquote
            if t.hasPrefix(">") {
                var quoteLines: [String] = []
                while i < lines.count && lines[i].trimmingCharacters(in: .whitespaces).hasPrefix(">") {
                    let raw = lines[i].trimmingCharacters(in: .whitespaces)
                    let content = String(raw.dropFirst(1)).trimmingCharacters(in: .whitespaces)
                    quoteLines.append(content)
                    i += 1
                }
                blocks.append(.blockquote(parseInline(quoteLines.joined(separator: " "))))
                continue
            }

            // Checklist
            if let item = parseChecklistItem(t) {
                var items: [String] = [item]
                i += 1
                while i < lines.count, let next = parseChecklistItem(lines[i].trimmingCharacters(in: .whitespaces)) {
                    items.append(next)
                    i += 1
                }
                blocks.append(.checklist(items))
                continue
            }

            // Bullet list
            if let bullet = parseBullet(t) {
                var items: [[CalcInline]] = [parseInline(bullet)]
                i += 1
                while i < lines.count, let next = parseBullet(lines[i].trimmingCharacters(in: .whitespaces)) {
                    items.append(parseInline(next))
                    i += 1
                }
                blocks.append(.bulletList(items))
                continue
            }

            // Ordered list
            if let ordered = parseOrdered(t) {
                var items: [[CalcInline]] = [parseInline(ordered)]
                i += 1
                while i < lines.count, let next = parseOrdered(lines[i].trimmingCharacters(in: .whitespaces)) {
                    items.append(parseInline(next))
                    i += 1
                }
                blocks.append(.orderedList(items))
                continue
            }

            // Paragraph
            blocks.append(.paragraph(parseInline(t)))
            i += 1
        }

        return blocks
    }

    // MARK: - CalcInline parsing

    static func parseInline(_ text: String) -> [CalcInline] {
        var result: [CalcInline] = []
        var plain = ""
        let chars = Array(text)
        var i = 0

        func flush() {
            if !plain.isEmpty {
                result.append(.text(plain))
                plain = ""
            }
        }

        while i < chars.count {
            let c = chars[i]

            if c == "`" {
                if let end = indexOf(char: "`", in: chars, from: i + 1) {
                    flush()
                    let code = String(chars[(i + 1)..<end])
                    result.append(.code(code))
                    i = end + 1
                    continue
                }
            }

            if c == "*" {
                if i + 1 < chars.count && chars[i + 1] == "*" {
                    if let end = indexOf(double: "*", in: chars, from: i + 2) {
                        flush()
                        let inner = String(chars[(i + 2)..<end])
                        result.append(.bold(parseInline(inner)))
                        i = end + 2
                        continue
                    }
                } else {
                    if let end = indexOf(char: "*", in: chars, from: i + 1) {
                        flush()
                        let inner = String(chars[(i + 1)..<end])
                        result.append(.italic(parseInline(inner)))
                        i = end + 1
                        continue
                    }
                }
            }

            if c == "[" {
                if let link = parseLink(in: chars, from: i) {
                    flush()
                    result.append(.link(text: link.text, url: link.url))
                    i = link.end + 1
                    continue
                }
            }

            plain.append(c)
            i += 1
        }

        flush()
        return result
    }

    // MARK: - CalcInline helpers

    private static func indexOf(char: Character, in chars: [Character], from start: Int) -> Int? {
        guard start < chars.count else { return nil }
        for j in start..<chars.count where chars[j] == char {
            return j
        }
        return nil
    }

    private static func indexOf(double char: Character, in chars: [Character], from start: Int) -> Int? {
        guard start < chars.count else { return nil }
        var j = start
        while j < chars.count {
            if chars[j] == char && j + 1 < chars.count && chars[j + 1] == char {
                return j
            }
            j += 1
        }
        return nil
    }

    private static func parseLink(in chars: [Character], from start: Int) -> (text: String, url: String, end: Int)? {
        var j = start + 1
        var inner = ""
        while j < chars.count {
            if chars[j] == "]" {
                if j + 1 < chars.count && chars[j + 1] == "(" {
                    var k = j + 2
                    var url = ""
                    while k < chars.count && chars[k] != ")" {
                        url.append(chars[k])
                        k += 1
                    }
                    if k < chars.count {
                        return (inner, url, k)
                    }
                }
                break
            }
            inner.append(chars[j])
            j += 1
        }
        return nil
    }

    // MARK: - CalcBlock helpers

    private static func parseHeading(_ s: String) -> CalcBlock? {
        guard s.hasPrefix("#") else { return nil }
        var level = 0
        for c in s {
            if c == "#" { level += 1 } else { break }
        }
        guard level >= 1 && level <= 6 else { return nil }
        let content = String(s.dropFirst(level)).trimmingCharacters(in: .whitespaces)
        guard !content.isEmpty else { return nil }
        return .heading(level: level, inlines: parseInline(content))
    }

    private static func isHorizontalRule(_ s: String) -> Bool {
        let clean = s.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\t", with: "")
        return clean.count >= 3 && clean.allSatisfy { $0 == "-" || $0 == "*" || $0 == "_" }
    }

    private static func parseTable(_ lines: [String]) -> CalcBlock {
        func cells(_ line: String) -> [String] {
            var s = line
            if s.hasPrefix("|") { s.removeFirst() }
            if s.hasSuffix("|") { s.removeLast() }
            return s.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        }

        let all = lines.map(cells)
        var headers: [String] = []
        var rows: [[String]] = []

        for (index, row) in all.enumerated() {
            if index == 1 && isSeparatorRow(row) { continue }
            if headers.isEmpty {
                headers = row
            } else {
                rows.append(row)
            }
        }

        if headers.isEmpty {
            headers = all.first ?? []
        }

        return .table(headers: headers, rows: rows)
    }

    private static func isSeparatorRow(_ cells: [String]) -> Bool {
        cells.allSatisfy { cell in
            let s = cell.replacingOccurrences(of: "-", with: "")
                       .replacingOccurrences(of: ":", with: "")
                       .replacingOccurrences(of: " ", with: "")
            return s.isEmpty && cell.contains("-")
        }
    }

    private static func parseImage(_ s: String) -> CalcBlock? {
        guard s.hasPrefix("![") else { return nil }
        guard let altRange = s.range(of: "](") else { return nil }
        let altStart = s.index(s.startIndex, offsetBy: 2)
        let alt = String(s[altStart..<altRange.lowerBound])

        let pathStart = altRange.upperBound
        guard pathStart < s.endIndex, let endParen = s[pathStart...].firstIndex(of: ")") else { return nil }
        let path = String(s[pathStart..<endParen])
        let filename = (path as NSString).lastPathComponent

        return .image(alt: alt, filename: filename)
    }

    private static func parseChecklistItem(_ s: String) -> String? {
        guard s.hasPrefix("- [") else { return nil }
        let body = String(s.dropFirst(3))
        guard body.count >= 3 else { return nil }

        let mark = body[body.startIndex]
        guard mark == " " || mark == "x" || mark == "X" else { return nil }
        let second = body[body.index(after: body.startIndex)]
        guard second == "]" else { return nil }

        let rest = String(body.dropFirst(2)).trimmingCharacters(in: .whitespaces)
        guard !rest.isEmpty else { return nil }
        return rest
    }

    private static func parseBullet(_ s: String) -> String? {
        if s.hasPrefix("- [") { return nil }
        if isHorizontalRule(s) { return nil }
        if s.hasPrefix("- ") { return String(s.dropFirst(2)).trimmingCharacters(in: .whitespaces) }
        if s.hasPrefix("* ") { return String(s.dropFirst(2)).trimmingCharacters(in: .whitespaces) }
        if s.hasPrefix("+ ") { return String(s.dropFirst(2)).trimmingCharacters(in: .whitespaces) }
        return nil
    }

    private static func parseOrdered(_ s: String) -> String? {
        let prefix = s.prefix { $0.isNumber }
        guard !prefix.isEmpty else { return nil }
        let rest = String(s.dropFirst(prefix.count))
        guard rest.hasPrefix(". ") || rest.hasPrefix(".\t") else { return nil }
        return String(rest.dropFirst(2)).trimmingCharacters(in: .whitespaces)
    }

    private static func extractSummary(from s: String) -> String {
        guard let range = s.range(of: "<summary>") else { return "查看" }
        let start = range.upperBound
        guard let end = s[start...].range(of: "</summary>") else { return String(s[start...]) }
        return String(s[start..<end.lowerBound])
    }
}
