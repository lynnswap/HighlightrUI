import Foundation

@MainActor
struct EditorCommandContext {
    var text: String
    var selection: TextSelection
    var isEditable: Bool
    var isEditorFocused: Bool
    var isUndoable: Bool
    var isRedoable: Bool
}

@MainActor
enum EditorCommandEffect {
    case requestFocus(Bool)
    case requestUndo
    case requestRedo
    case replaceText(range: NSRange, replacement: String, selectionAfter: TextSelection)
}

@MainActor
struct EditorCommandService {
    func canPerform(_ command: HighlightrEditorCommand, context: EditorCommandContext) -> Bool {
        switch command {
        case .focus:
            return !context.isEditorFocused
        case .blur, .dismissKeyboard:
            return context.isEditorFocused
        case .undo:
            return context.isEditable && context.isUndoable
        case .redo:
            return context.isEditable && context.isRedoable
        case .insertIndent, .insertCurlyBraces, .insertPair:
            return context.isEditable
        case .deleteCurrentLine, .clearText:
            return context.isEditable && !context.text.isEmpty
        }
    }

    func execute(
        _ command: HighlightrEditorCommand,
        context: EditorCommandContext
    ) -> [EditorCommandEffect] {
        guard canPerform(command, context: context) else {
            return []
        }

        switch command {
        case .focus:
            return [.requestFocus(true)]
        case .blur, .dismissKeyboard:
            return [.requestFocus(false)]
        case .undo:
            return [.requestUndo]
        case .redo:
            return [.requestRedo]
        case .insertIndent:
            return [insertIndentEffect(in: context)]
        case .insertCurlyBraces:
            return [insertCurlyBracesEffect(in: context)]
        case .insertPair(let kind):
            return [insertPairEffect(kind, in: context)]
        case .deleteCurrentLine:
            guard let effect = deleteCurrentLineEffect(in: context) else {
                return []
            }
            return [effect]
        case .clearText:
            return [clearTextEffect(in: context)]
        }
    }

    private func insertIndentEffect(in context: EditorCommandContext) -> EditorCommandEffect {
        let selection = clampedSelection(context.selection, in: context.text)
        return .replaceText(
            range: nsRange(for: selection),
            replacement: "    ",
            selectionAfter: TextSelection(location: selection.location + 4, length: 0)
        )
    }

    private func insertCurlyBracesEffect(in context: EditorCommandContext) -> EditorCommandEffect {
        let text = context.text
        let source = text as NSString
        let selection = clampedSelection(context.selection, in: text)
        let selectionRange = nsRange(for: selection)
        let indent = currentLineIndent(in: text, at: selection.location)

        if selection.length > 0 {
            let selected = source.substring(with: selectionRange)
            let replacement = "{\n\(indent)    \(selected)\n\(indent)}"
            return .replaceText(
                range: selectionRange,
                replacement: replacement,
                selectionAfter: TextSelection(
                    location: selection.location + 2 + utf16Count(indent) + 4,
                    length: selection.length
                )
            )
        }

        let replacement = "{\n\(indent)    \n\(indent)}"
        return .replaceText(
            range: selectionRange,
            replacement: replacement,
            selectionAfter: TextSelection(
                location: selection.location + 2 + utf16Count(indent) + 4,
                length: 0
            )
        )
    }

    private func insertPairEffect(
        _ kind: HighlightrEditorPairKind,
        in context: EditorCommandContext
    ) -> EditorCommandEffect {
        let text = context.text
        let source = text as NSString
        let selection = clampedSelection(context.selection, in: text)
        let selectionRange = nsRange(for: selection)
        let (open, close) = pairCharacters(for: kind)

        if selection.length > 0 {
            let selected = source.substring(with: selectionRange)
            let replacement = "\(open)\(selected)\(close)"
            return .replaceText(
                range: selectionRange,
                replacement: replacement,
                selectionAfter: TextSelection(
                    location: selection.location + utf16Count(open),
                    length: selection.length
                )
            )
        }

        return .replaceText(
            range: selectionRange,
            replacement: "\(open)\(close)",
            selectionAfter: TextSelection(
                location: selection.location + utf16Count(open),
                length: 0
            )
        )
    }

    private func deleteCurrentLineEffect(in context: EditorCommandContext) -> EditorCommandEffect? {
        let text = context.text
        guard !text.isEmpty else { return nil }

        let source = text as NSString
        let selection = clampedSelection(context.selection, in: text)
        let location = min(selection.location, source.length)
        let lineRange = source.lineRange(for: NSRange(location: location, length: 0))
        let deleteRange: NSRange

        if lineRange.location == source.length,
           lineRange.length == 0,
           let trailingBreakRange = trailingLineBreakRange(in: source)
        {
            deleteRange = trailingBreakRange
        } else {
            deleteRange = lineRange
        }

        return .replaceText(
            range: deleteRange,
            replacement: "",
            selectionAfter: TextSelection(location: deleteRange.location, length: 0)
        )
    }

    private func clearTextEffect(in context: EditorCommandContext) -> EditorCommandEffect {
        .replaceText(
            range: NSRange(location: 0, length: utf16Count(context.text)),
            replacement: "",
            selectionAfter: .zero
        )
    }

    private func pairCharacters(for kind: HighlightrEditorPairKind) -> (String, String) {
        switch kind {
        case .parentheses:
            return ("(", ")")
        case .singleQuote:
            return ("'", "'")
        case .doubleQuote:
            return ("\"", "\"")
        }
    }

    private func clampedSelection(_ selection: TextSelection, in text: String) -> TextSelection {
        let length = utf16Count(text)
        let location = min(max(0, selection.location), length)
        let remaining = max(0, length - location)
        let clampedLength = min(max(0, selection.length), remaining)
        return TextSelection(location: location, length: clampedLength)
    }

    private func nsRange(for selection: TextSelection) -> NSRange {
        NSRange(location: selection.location, length: selection.length)
    }

    private func utf16Count(_ text: String) -> Int {
        (text as NSString).length
    }

    private func currentLineIndent(in text: String, at location: Int) -> String {
        let source = text as NSString
        guard source.length > 0 else { return "" }

        let safeLocation = min(max(0, location), source.length)
        let lineRange = source.lineRange(for: NSRange(location: safeLocation, length: 0))
        let line = source.substring(with: lineRange)
        guard let indentRange = line.range(of: "^[ \\t]*", options: .regularExpression) else {
            return ""
        }
        return String(line[indentRange])
    }

    private func trailingLineBreakRange(in source: NSString) -> NSRange? {
        guard source.length > 0 else { return nil }

        if source.length >= 2 {
            let lastTwo = source.substring(with: NSRange(location: source.length - 2, length: 2))
            if lastTwo == "\r\n" {
                return NSRange(location: source.length - 2, length: 2)
            }
        }

        let last = source.substring(with: NSRange(location: source.length - 1, length: 1))
        if last == "\n" || last == "\r" || last == "\u{2028}" || last == "\u{2029}" {
            return NSRange(location: source.length - 1, length: 1)
        }
        return nil
    }
}
