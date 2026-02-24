#if canImport(UIKit)
import Foundation
import UIKit

@MainActor
final class EditorCommandExecutor {
    private unowned let editorView: HighlightrEditorView

    init(editorView: HighlightrEditorView) {
        self.editorView = editorView
    }

    private var textView: PlatformEditorTextView {
        editorView.platformTextView
    }

    func canPerform(_ command: HighlightrEditorCommand) -> Bool {
        switch command {
        case .focus:
            return !editorView.isEditorFocused
        case .blur:
            return editorView.isEditorFocused
        case .dismissKeyboard:
            return editorView.isEditorFocused
        case .undo:
            return editorView.isEditable && editorView.isUndoable
        case .redo:
            return editorView.isEditable && editorView.isRedoable
        case .insertIndent:
            return editorView.isEditable
        case .insertCurlyBraces:
            return editorView.isEditable
        case .insertPair:
            return editorView.isEditable
        case .deleteCurrentLine:
            return editorView.isEditable && hasCurrentDocumentText
        case .clearText:
            return editorView.isEditable && hasCurrentDocumentText
        }
    }

    func perform(_ command: HighlightrEditorCommand) {
        switch command {
        case .focus:
            editorView.focus()
        case .blur, .dismissKeyboard:
            editorView.blur()
        case .undo:
            guard canPerform(.undo) else { return }
            textView.undoManager?.undo()
            editorView.coordinator.syncStateFromView()
        case .redo:
            guard canPerform(.redo) else { return }
            textView.undoManager?.redo()
            editorView.coordinator.syncStateFromView()
        case .insertIndent:
            insertIndent()
        case .insertCurlyBraces:
            insertCurlyBraces()
        case .insertPair(let kind):
            insertPair(kind)
        case .deleteCurrentLine:
            deleteCurrentLine()
        case .clearText:
            clearText()
        }
    }

    private func insertIndent() {
        guard canPerform(.insertIndent) else { return }
        let selection = clampedSelection(textView.selectedRange)
        replaceText(
            in: selection,
            with: "    ",
            selectedRangeAfter: NSRange(location: selection.location + 4, length: 0)
        )
    }

    private func insertCurlyBraces() {
        guard canPerform(.insertCurlyBraces) else { return }
        let selection = clampedSelection(textView.selectedRange)
        let text = textView.text ?? ""
        let source = text as NSString
        let indent = currentLineIndent(in: text, at: selection.location)

        if selection.length > 0 {
            let selected = source.substring(with: selection)
            let replacement = "{\n\(indent)    \(selected)\n\(indent)}"
            let wrappedSelection = NSRange(
                location: selection.location + 2 + utf16Count(indent) + 4,
                length: selection.length
            )
            replaceText(in: selection, with: replacement, selectedRangeAfter: wrappedSelection)
            return
        }

        let replacement = "{\n\(indent)    \n\(indent)}"
        let cursorLocation = selection.location + 2 + utf16Count(indent) + 4

        replaceText(
            in: selection,
            with: replacement,
            selectedRangeAfter: NSRange(location: cursorLocation, length: 0)
        )
    }

    private func insertPair(_ kind: HighlightrEditorPairKind) {
        guard canPerform(.insertPair(kind)) else { return }
        let (open, close) = pairCharacters(for: kind)
        let selection = clampedSelection(textView.selectedRange)
        let text = textView.text ?? ""
        let source = text as NSString

        if selection.length > 0 {
            let selected = source.substring(with: selection)
            let replacement = "\(open)\(selected)\(close)"
            let wrappedSelection = NSRange(
                location: selection.location + utf16Count(open),
                length: selection.length
            )
            replaceText(in: selection, with: replacement, selectedRangeAfter: wrappedSelection)
            return
        }

        let replacement = "\(open)\(close)"
        let cursor = NSRange(location: selection.location + utf16Count(open), length: 0)
        replaceText(in: selection, with: replacement, selectedRangeAfter: cursor)
    }

    private func deleteCurrentLine() {
        guard canPerform(.deleteCurrentLine) else { return }
        let text = textViewText
        guard !text.isEmpty else { return }

        let source = text as NSString
        let selection = clampedSelection(textView.selectedRange, in: text)
        let location = min(selection.location, source.length)
        let lineRange = source.lineRange(for: NSRange(location: location, length: 0))
        let deleteRange: NSRange
        if lineRange.location == source.length,
           lineRange.length == 0,
           let trailingBreakRange = trailingLineBreakRange(in: source) {
            deleteRange = trailingBreakRange
        } else {
            deleteRange = lineRange
        }

        replaceText(
            in: deleteRange,
            with: "",
            selectedRangeAfter: NSRange(location: deleteRange.location, length: 0)
        )
    }

    private func clearText() {
        guard canPerform(.clearText) else { return }
        let text = textViewText
        let allRange = NSRange(location: 0, length: utf16Count(text))
        replaceText(in: allRange, with: "", selectedRangeAfter: NSRange(location: 0, length: 0))
    }

    private func replaceText(in range: NSRange, with replacement: String, selectedRangeAfter: NSRange) {
        let text = textView.text ?? ""
        let safeRange = clampedSelection(range, in: text)
        let updatedText = (text as NSString).replacingCharacters(in: safeRange, with: replacement)
        let targetSelection = clampedSelection(selectedRangeAfter, in: updatedText)
        guard
            let start = textView.position(from: textView.beginningOfDocument, offset: safeRange.location),
            let end = textView.position(from: start, offset: safeRange.length),
            let textRange = textView.textRange(from: start, to: end)
        else {
            return
        }

        performUndoStep {
            textView.replace(textRange, withText: replacement)
            setSelectedRange(targetSelection)
        }
        editorView.coordinator.syncStateFromView()
    }

    private func setSelectedRange(_ range: NSRange) {
        guard
            let start = textView.position(from: textView.beginningOfDocument, offset: range.location),
            let end = textView.position(from: start, offset: range.length),
            let selectedRange = textView.textRange(from: start, to: end)
        else {
            return
        }
        textView.selectedTextRange = selectedRange
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

    private func clampedSelection(_ range: NSRange, in text: String? = nil) -> NSRange {
        let sourceText = text ?? (textView.text ?? "")
        let length = utf16Count(sourceText)
        let location = min(max(0, range.location), length)
        let remaining = max(0, length - location)
        let clampedLength = min(max(0, range.length), remaining)
        return NSRange(location: location, length: clampedLength)
    }

    private func utf16Count(_ text: String) -> Int {
        (text as NSString).length
    }

    private var textViewText: String {
        textView.text ?? ""
    }

    private var hasCurrentDocumentText: Bool {
        !textViewText.isEmpty || editorView.hasText
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

    private func performUndoStep(_ operation: () -> Void) {
        guard let undoManager = textView.undoManager else {
            operation()
            return
        }

        undoManager.beginUndoGrouping()
        operation()
        undoManager.endUndoGrouping()
    }
}
#endif
