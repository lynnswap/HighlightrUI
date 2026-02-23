#if canImport(UIKit)
import Foundation
import HighlightrUICore
import Testing
@testable import HighlightrUI
import UIKit

@MainActor
@Suite(.serialized)
struct HighlightrEditorViewControllerCommandiOSTests {
    @Test
    func insertPairWrapsSelectionAndKeepsModelSynchronized() async {
        let model = HighlightrEditorModel(text: "abc", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        controller.loadViewIfNeeded()
        let textView = controller.editorView.platformTextView
        textView.selectedRange = NSRange(location: 0, length: 3)
        controller.perform(.insertPair(.doubleQuote))

        await AsyncDrain.firstTurn()

        #expect(normalizeQuotes(textView.text) == "\"abc\"")
        #expect(normalizeQuotes(model.text) == "\"abc\"")
        #expect(model.selection == TextSelection(location: 1, length: 3))
    }

    @Test
    func insertCurlyBracesWrapsSelectionAndKeepsSelectedText() async {
        let model = HighlightrEditorModel(text: "value", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        controller.loadViewIfNeeded()
        let textView = controller.editorView.platformTextView
        textView.selectedRange = NSRange(location: 0, length: 5)
        controller.perform(.insertCurlyBraces)

        await AsyncDrain.firstTurn()

        #expect(textView.text == "{\n    value\n}")
        #expect(model.text == "{\n    value\n}")
        #expect(model.selection == TextSelection(location: 6, length: 5))
    }

    @Test
    func insertCommandsAtEndKeepCursorAtExpectedPosition() async {
        let model = HighlightrEditorModel(text: "abc", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        controller.loadViewIfNeeded()
        let textView = controller.editorView.platformTextView
        textView.selectedRange = NSRange(location: 3, length: 0)

        controller.perform(.insertPair(.parentheses))
        await AsyncDrain.firstTurn()

        #expect(textView.text == "abc()")
        #expect(textView.selectedRange == NSRange(location: 4, length: 0))
        #expect(model.selection == TextSelection(location: 4, length: 0))

        controller.perform(.insertIndent)
        await AsyncDrain.firstTurn()

        #expect(textView.text == "abc(    )")
        #expect(textView.selectedRange == NSRange(location: 8, length: 0))
        #expect(model.selection == TextSelection(location: 8, length: 0))
    }

    @Test
    func undoAndRedoCommandsOperateThroughController() async {
        let model = HighlightrEditorModel(text: "", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        controller.loadViewIfNeeded()
        controller.editorView.platformTextView.undoManager?.groupsByEvent = false

        controller.perform(.insertIndent)
        await AsyncDrain.firstTurn()
        #expect(model.text == "    ")

        controller.perform(.undo)
        await AsyncDrain.firstTurn()
        #expect(model.text == "")

        controller.perform(.redo)
        await AsyncDrain.firstTurn()
        #expect(model.text == "    ")
    }

    @Test
    func undoAndRedoAreBlockedWhenModelIsReadOnly() async {
        let model = HighlightrEditorModel(text: "abc", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        controller.loadViewIfNeeded()
        let textView = controller.editorView.platformTextView
        textView.undoManager?.groupsByEvent = false
        textView.selectedRange = NSRange(location: 3, length: 0)

        controller.perform(.insertIndent)
        await AsyncDrain.firstTurn()
        #expect(model.text == "abc    ")
        #expect(controller.canPerform(.undo))

        model.isEditable = false
        #expect(!controller.canPerform(.undo))
        #expect(!controller.canPerform(.redo))

        controller.perform(.undo)
        await AsyncDrain.firstTurn()
        #expect(model.text == "abc    ")
    }

    @Test
    func deleteCurrentLineAndClearTextCommandsWork() async {
        let model = HighlightrEditorModel(text: "a\nb\nc", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        controller.loadViewIfNeeded()
        let textView = controller.editorView.platformTextView
        textView.selectedRange = NSRange(location: 2, length: 0)
        controller.perform(.deleteCurrentLine)
        await AsyncDrain.firstTurn()
        #expect(model.text == "a\nc")

        controller.perform(.clearText)
        await AsyncDrain.firstTurn()
        #expect(model.text == "")
        #expect(!controller.canPerform(.clearText))
    }

    @Test
    func deleteCurrentLineAtEOFRemovesTrailingBlankLine() async {
        let model = HighlightrEditorModel(text: "a\n", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        controller.loadViewIfNeeded()
        let textView = controller.editorView.platformTextView
        textView.selectedRange = NSRange(location: 2, length: 0)

        #expect(controller.canPerform(.deleteCurrentLine))
        controller.perform(.deleteCurrentLine)
        await AsyncDrain.firstTurn()

        #expect(model.text == "a")
        #expect(textView.text == "a")
    }

    @Test
    func clearAndDeleteCommandsRemainAvailableBeforeViewSync() async {
        let model = HighlightrEditorModel(text: "", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        controller.loadViewIfNeeded()
        let textView = controller.editorView.platformTextView
        #expect(textView.text == "")
        #expect(!controller.canPerform(.clearText))
        #expect(!controller.canPerform(.deleteCurrentLine))

        model.text = "line"
        #expect(textView.text == "")
        #expect(controller.canPerform(.clearText))
        #expect(controller.canPerform(.deleteCurrentLine))

        controller.perform(.deleteCurrentLine)
        await AsyncDrain.firstTurn()
        #expect(model.text == "")
        #expect(textView.text == "")

        model.text = "line"
        #expect(controller.canPerform(.clearText))
        controller.perform(.clearText)
        await AsyncDrain.firstTurn()
        #expect(model.text == "")
        #expect(textView.text == "")
        #expect(!controller.canPerform(.clearText))
    }

    @Test
    func deleteCurrentLineUsesLatestModelTextBeforeViewSync() async {
        let model = HighlightrEditorModel(text: "old\nline", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        controller.loadViewIfNeeded()
        let textView = controller.editorView.platformTextView
        textView.selectedRange = NSRange(location: 0, length: 0)
        #expect(textView.text == "old\nline")

        model.text = "new"
        #expect(textView.text == "old\nline")
        #expect(controller.canPerform(.deleteCurrentLine))

        controller.perform(.deleteCurrentLine)
        await AsyncDrain.firstTurn()

        #expect(model.text == "")
        #expect(textView.text == "")
    }

    private func normalizeQuotes(_ text: String?) -> String? {
        guard let text else { return nil }
        return normalizeQuotes(text)
    }

    private func normalizeQuotes(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\u{201C}", with: "\"")
            .replacingOccurrences(of: "\u{201D}", with: "\"")
    }
}
#endif
