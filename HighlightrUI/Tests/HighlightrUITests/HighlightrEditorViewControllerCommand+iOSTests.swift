#if canImport(UIKit)
import Foundation
import Testing
@testable import HighlightrUI
import UIKit

@MainActor
@Suite(.serialized)
struct HighlightrEditorViewControllerCommandiOSTests {
    @Test
    func insertPairWrapsSelectionAndKeepsModelSynchronized() async {
        let model = HighlightrModel(text: "abc", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
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
        let model = HighlightrModel(text: "value", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
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
        let model = HighlightrModel(text: "abc", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
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
        let model = HighlightrModel(text: "", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
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
        let model = HighlightrModel(text: "abc", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
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
        let model = HighlightrModel(text: "a\nb\nc", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
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
        let model = HighlightrModel(text: "a\n", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
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
        let model = HighlightrModel(text: "", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
        )

        controller.loadViewIfNeeded()
        let textView = controller.editorView.platformTextView
        #expect(textView.text == "")
        #expect(!controller.canPerform(.clearText))
        #expect(!controller.canPerform(.deleteCurrentLine))

        model.text = "line"
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
        let model = HighlightrModel(text: "old\nline", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
        )

        controller.loadViewIfNeeded()
        let textView = controller.editorView.platformTextView
        textView.selectedRange = NSRange(location: 0, length: 0)
        #expect(textView.text == "old\nline")

        model.text = "new"
        #expect(controller.canPerform(.deleteCurrentLine))

        controller.perform(.deleteCurrentLine)
        await AsyncDrain.firstTurn()

        #expect(model.text == "")
        #expect(textView.text == "")
    }

    @Test
    func insertIndentUsesLatestModelTextBeforeViewSync() async {
        let model = HighlightrModel(text: "old", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
        )

        controller.loadViewIfNeeded()
        let textView = controller.editorView.platformTextView
        textView.selectedRange = NSRange(location: 0, length: 0)
        #expect(textView.text == "old")

        model.text = "new"

        controller.perform(.insertIndent)
        await AsyncDrain.firstTurn()

        #expect(model.text == "    new")
        #expect(textView.text == "    new")
    }

    @Test
    func insertIndentUsesLatestModelSelectionBeforeViewSync() async {
        let model = HighlightrModel(text: "abc", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
        )

        controller.loadViewIfNeeded()
        let textView = controller.editorView.platformTextView
        textView.selectedRange = NSRange(location: 0, length: 0)
        #expect(textView.selectedRange == NSRange(location: 0, length: 0))

        model.selection = TextSelection(location: 3, length: 0)

        controller.perform(.insertIndent)
        await AsyncDrain.firstTurn()

        #expect(model.text == "abc    ")
        #expect(textView.text == "abc    ")
        #expect(model.selection == TextSelection(location: 7, length: 0))
        #expect(textView.selectedRange == NSRange(location: 7, length: 0))
    }

    @Test
    func undoUsesLatestModelTextBeforeViewSync() async {
        let model = HighlightrModel(text: "old", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
        )

        controller.loadViewIfNeeded()
        let textView = controller.editorView.platformTextView
        textView.undoManager?.groupsByEvent = false
        textView.selectedRange = NSRange(location: 0, length: 0)

        controller.perform(.insertIndent)
        await AsyncDrain.firstTurn()
        #expect(model.text == "    old")
        #expect(controller.canPerform(.undo))

        model.text = "new"

        controller.perform(.undo)
        await AsyncDrain.firstTurn()

        #expect(model.text == "new")
        #expect(textView.text == "new")
    }

    @Test
    func redoUsesLatestModelTextBeforeViewSync() async {
        let model = HighlightrModel(text: "old", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
        )

        controller.loadViewIfNeeded()
        let textView = controller.editorView.platformTextView
        textView.undoManager?.groupsByEvent = false
        textView.selectedRange = NSRange(location: 0, length: 0)

        controller.perform(.insertIndent)
        await AsyncDrain.firstTurn()
        controller.perform(.undo)
        await AsyncDrain.firstTurn()
        #expect(model.text == "old")
        #expect(controller.canPerform(.redo))

        model.text = "new"

        controller.perform(.redo)
        await AsyncDrain.firstTurn()

        #expect(model.text == "new")
        #expect(textView.text == "new")
    }

    @Test
    func focusCommandBeforeWindowAttachPreservesPendingFocusRequest() async {
        let model = HighlightrModel(text: "abc", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
        )

        controller.loadViewIfNeeded()
        #expect(model.isEditorFocused == false)
        #expect(controller.editorView.platformTextView.isFirstResponder == false)

        controller.perform(.focus)
        await AsyncDrain.firstTurn()

        #expect(model.isEditorFocused == true)
        #expect(controller.editorView.platformTextView.isFirstResponder == false)
        #expect(!controller.canPerform(.focus))
        #expect(controller.canPerform(.blur))

        let host = WindowHost(view: controller.view)
        host.pump()
        await AsyncDrain.firstTurn()
        host.pump()

        #expect(model.isEditorFocused == true)
        #expect(controller.editorView.platformTextView.isFirstResponder == true)

        _ = host
    }

    @Test
    func focusAndDismissKeyboardCommandsSyncResponderImmediatelyWhenHosted() {
        let model = HighlightrModel(text: "abc", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
        )

        controller.loadViewIfNeeded()
        let host = WindowHost(view: controller.view)
        host.pump()

        #expect(controller.editorView.platformTextView.isFirstResponder == false)
        #expect(model.isEditorFocused == false)

        controller.perform(.focus)
        #expect(controller.editorView.platformTextView.isFirstResponder == true)
        #expect(model.isEditorFocused == true)

        controller.perform(.dismissKeyboard)
        #expect(controller.editorView.platformTextView.isFirstResponder == false)
        #expect(model.isEditorFocused == false)

        _ = host
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
