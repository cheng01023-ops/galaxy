import SwiftUI

struct CLCodeToken {
    enum Kind {
        case plain, keyword, comment, string, number, preprocessor
    }
    let text: String
    let kind: Kind
}

enum CLHighlighter {
    private static let keywords: Set<String> = [
        "auto", "break", "case", "catch", "char", "class", "const", "continue",
        "default", "delete", "do", "double", "else", "enum", "explicit", "extern",
        "false", "float", "for", "friend", "if", "inline", "int", "long", "namespace",
        "new", "operator", "override", "private", "protected", "public", "return",
        "short", "signed", "sizeof", "static", "struct", "switch", "template", "this",
        "throw", "true", "try", "typedef", "typename", "union", "unsigned", "using",
        "virtual", "void", "volatile", "while", "nullptr",
        "include", "std", "cout", "cin", "endl", "vector", "map", "string",
        "ofstream", "ifstream", "fstream"
    ]

    static func tokenize(_ code: String) -> [CLCodeToken] {
        let chars = Array(code)
        var tokens: [CLCodeToken] = []
        var plain = ""
        var i = 0

        func flush() {
            if !plain.isEmpty {
                tokens.append(CLCodeToken(text: plain, kind: .plain))
                plain = ""
            }
        }

        while i < chars.count {
            let c = chars[i]

            // Line comment
            if c == "/" && i + 1 < chars.count && chars[i + 1] == "/" {
                flush()
                var j = i
                var comment = ""
                while j < chars.count && chars[j] != "\n" {
                    comment.append(chars[j])
                    j += 1
                }
                tokens.append(CLCodeToken(text: comment, kind: .comment))
                i = j
                continue
            }

            // String literal
            if c == "\"" {
                flush()
                var j = i + 1
                var s = "\""
                while j < chars.count && chars[j] != "\"" {
                    s.append(chars[j])
                    if chars[j] == "\\" && j + 1 < chars.count {
                        s.append(chars[j + 1])
                        j += 2
                        continue
                    }
                    j += 1
                }
                if j < chars.count { s.append(chars[j]) }
                tokens.append(CLCodeToken(text: s, kind: .string))
                i = j + 1
                continue
            }

            // Char literal
            if c == "'" {
                flush()
                var j = i + 1
                var s = "'"
                while j < chars.count && chars[j] != "'" {
                    s.append(chars[j])
                    if chars[j] == "\\" && j + 1 < chars.count {
                        s.append(chars[j + 1])
                        j += 2
                        continue
                    }
                    j += 1
                }
                if j < chars.count { s.append(chars[j]) }
                tokens.append(CLCodeToken(text: s, kind: .string))
                i = j + 1
                continue
            }

            // Preprocessor directive (only at start of a line)
            if c == "#" && (i == 0 || chars[i - 1] == "\n") {
                flush()
                var j = i
                var s = ""
                while j < chars.count && chars[j] != "\n" {
                    s.append(chars[j])
                    j += 1
                }
                tokens.append(CLCodeToken(text: s, kind: .preprocessor))
                i = j
                continue
            }

            // Number
            if c.isNumber || (c == "." && i + 1 < chars.count && chars[i + 1].isNumber) {
                flush()
                var j = i
                var s = ""
                while j < chars.count && (chars[j].isNumber || chars[j] == ".") {
                    s.append(chars[j])
                    j += 1
                }
                tokens.append(CLCodeToken(text: s, kind: .number))
                i = j
                continue
            }

            // Identifier / keyword
            if c.isLetter || c == "_" {
                flush()
                var j = i
                var s = ""
                while j < chars.count && (chars[j].isLetter || chars[j].isNumber || chars[j] == "_") {
                    s.append(chars[j])
                    j += 1
                }
                tokens.append(CLCodeToken(text: s, kind: keywords.contains(s) ? .keyword : .plain))
                i = j
                continue
            }

            plain.append(c)
            i += 1
        }

        flush()
        return tokens
    }
}
