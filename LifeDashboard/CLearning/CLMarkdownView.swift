import SwiftUI
import UIKit

// MARK: - CLInline rendering

struct CLInlineText: View {
    let inlines: [CLInline]

    var body: some View {
        Self.text(for: inlines)
    }

    static func text(for inlines: [CLInline]) -> Text {
        var result = Text("")
        for inline in inlines {
            result = result + text(for: inline)
        }
        return result
    }

    static func text(for inline: CLInline) -> Text {
        switch inline {
        case .text(let s):
            return Text(s)
        case .bold(let inner):
            return text(for: inner).bold()
        case .italic(let inner):
            return text(for: inner).italic()
        case .code(let s):
            return Text(s)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundColor(Color(red: 0.78, green: 0.28, blue: 0.52))
        case .link(let s, _):
            return Text(s).foregroundColor(.blue)
        }
    }
}

// MARK: - CLBlock rendering

struct CLBlockView: View {
    let block: CLBlock
    var dayID: Int? = nil
    var track: CLTrack = .xcode

    var body: some View {
        switch block {
        case .heading(let level, let inlines):
            CLInlineText(inlines: inlines)
                .font(headingFont(level))
                .fontWeight(.bold)
                .padding(.top, level <= 2 ? 10 : 6)

        case .paragraph(let inlines):
            CLInlineText(inlines: inlines)
                .fixedSize(horizontal: false, vertical: true)

        case .codeBlock(let language, let code):
            CLCodeBlockView(language: language, code: code)

        case .bulletList(let items):
            VStack(alignment: .leading, spacing: 7) {
                ForEach(items.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 9) {
                        Text("•")
                            .foregroundColor(.secondary)
                        CLInlineText(inlines: items[index])
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

        case .orderedList(let items):
            VStack(alignment: .leading, spacing: 7) {
                ForEach(items.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 9) {
                        Text("\(index + 1).")
                            .foregroundColor(.secondary)
                            .frame(minWidth: 24, alignment: .trailing)
                        CLInlineText(inlines: items[index])
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

        case .checklist(let items):
            VStack(alignment: .leading, spacing: 2) {
                ForEach(items.indices, id: \.self) { index in
                    CLChecklistRow(dayID: dayID, track: track, item: items[index])
                }
            }

        case .blockquote(let inlines):
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor.opacity(0.55))
                    .frame(width: 3)
                CLInlineText(inlines: inlines)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)

        case .table(let headers, let rows):
            CLMarkdownTable(headers: headers, rows: rows)

        case .details(let summary, let innerBlocks):
            DisclosureGroup {
                CLMarkdownView(blocks: innerBlocks, dayID: dayID, track: track)
                    .padding(.top, 10)
                    .padding(.leading, 8)
            } label: {
                Label(summary, systemImage: "eye.fill")
                    .font(.subheadline.weight(.semibold))
            }
            .tint(.accentColor)

        case .image(let alt, let filename):
            VStack(alignment: .leading, spacing: 6) {
                CLGIFImageView(filename: filename, subdirectory: track.subdirectory)
                    .frame(maxWidth: .infinity)
                if !alt.isEmpty {
                    Text(alt)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)

        case .horizontalRule:
            Divider()
        }
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: return .title2
        case 2: return .title3
        case 3: return .headline
        default: return .subheadline
        }
    }
}

struct CLMarkdownView: View {
    let blocks: [CLBlock]
    var dayID: Int? = nil
    var track: CLTrack = .xcode

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 13) {
            ForEach(blocks.indices, id: \.self) { index in
                CLBlockView(block: blocks[index], dayID: dayID, track: track)
            }
        }
    }
}

// MARK: - Checklist row

struct CLChecklistRow: View {
    let dayID: Int?
    let track: CLTrack
    let item: String
    @EnvironmentObject private var store: CLAppStore

    var body: some View {
        Button {
            guard let dayID else { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                store.toggle(track: track, day: dayID, item: item)
            }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(isOn ? .green : .secondary)
                CLInlineText(inlines: CLMarkdownParser.parseInline(item))
                    .multilineTextAlignment(.leading)
                    .foregroundColor(isOn ? .secondary : .primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 3)
    }

    private var isOn: Bool {
        guard let dayID else { return false }
        return store.isChecked(track: track, day: dayID, item: item)
    }
}

// MARK: - Code block

struct CLCodeBlockView: View {
    let language: String?
    let code: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label(languageDisplayName, systemImage: "chevron.left.forwardslash.chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.75))
                Spacer()
                Button {
                    UIPasteboard.general.string = code
                } label: {
                    Label("复制", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.22))

            ScrollView(.horizontal, showsIndicators: true) {
                codeText
                    .font(.system(size: 13, design: .monospaced))
                    .padding(12)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .background(Color(red: 0.12, green: 0.12, blue: 0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var languageDisplayName: String {
        if let language, !language.isEmpty { return language }
        return "代码"
    }

    private var codeText: Text {
        if language?.lowercased() == "cpp" || language?.lowercased() == "c++" {
            return highlightedCode
        }
        return Text(code).foregroundColor(.white.opacity(0.95))
    }

    private var highlightedCode: Text {
        var result = Text("")
        for token in CLHighlighter.tokenize(code) {
            let part = Text(token.text)
            switch token.kind {
            case .comment:
                result = result + part.foregroundColor(Color(red: 0.45, green: 0.68, blue: 0.45))
            case .string:
                result = result + part.foregroundColor(Color(red: 0.95, green: 0.65, blue: 0.40))
            case .keyword:
                result = result + part.foregroundColor(Color(red: 0.96, green: 0.52, blue: 0.75))
            case .number:
                result = result + part.foregroundColor(Color(red: 0.75, green: 0.85, blue: 1.0))
            case .preprocessor:
                result = result + part.foregroundColor(Color(red: 0.55, green: 0.76, blue: 0.95))
            case .plain:
                result = result + part.foregroundColor(.white.opacity(0.95))
            }
        }
        return result
    }
}

// MARK: - Table

struct CLMarkdownTable: View {
    let headers: [String]
    let rows: [[String]]

    private var columnCount: Int {
        max(headers.count, rows.map { $0.count }.max() ?? 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !headers.isEmpty {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(0..<columnCount, id: \.self) { index in
                        cell(headers.count > index ? headers[index] : "", isHeader: true)
                    }
                }
                .background(Color(uiColor: .tertiarySystemFill))
            }

            ForEach(rows.indices, id: \.self) { rowIndex in
                Divider()
                HStack(alignment: .top, spacing: 0) {
                    ForEach(0..<columnCount, id: \.self) { columnIndex in
                        let cellText = rows[rowIndex].count > columnIndex ? rows[rowIndex][columnIndex] : ""
                        cell(cellText, isHeader: false)
                    }
                }
            }
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private func cell(_ text: String, isHeader: Bool) -> some View {
        CLInlineText(inlines: CLMarkdownParser.parseInline(text))
            .font(isHeader ? .subheadline.weight(.semibold) : .subheadline)
            .foregroundColor(isHeader ? .primary : .primary)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
    }
}
