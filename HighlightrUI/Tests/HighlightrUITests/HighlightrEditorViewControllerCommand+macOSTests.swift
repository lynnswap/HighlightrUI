#if canImport(AppKit)
import AppKit
import Foundation
import HighlightrUICore
import Testing
@testable import HighlightrUI

@MainActor
@Suite(.serialized)
struct HighlightrEditorViewControllerCommandmacOSTests {
    @Test
    func insertPairWrapsSelectionAndKeepsModelSynchronized() async {
        let model = HighlightrEditorModel(text: "abc", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        controller.loadView()
        let textView = controller.editorView.platformTextView
        textView.setSelectedRange(NSRange(location: 0, length: 3))
        controller.perform(.insertPair(.doubleQuote))

        await AsyncDrain.firstTurn()

        #expect(textView.string == "\"abc\"")
        #expect(model.text == "\"abc\"")
        #expect(model.selection == TextSelection(location: 1, length: 3))
    }

    @Test
    func insertCurlyBracesWrapsSelectionAndKeepsSelectedText() async {
        let model = HighlightrEditorModel(text: "value", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        controller.loadView()
        let textView = controller.editorView.platformTextView
        textView.setSelectedRange(NSRange(location: 0, length: 5))
        controller.perform(.insertCurlyBraces)

        await AsyncDrain.firstTurn()

        #expect(textView.string == "{\n    value\n}")
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

        controller.loadView()
        let textView = controller.editorView.platformTextView
        textView.setSelectedRange(NSRange(location: 3, length: 0))

        controller.perform(.insertPair(.parentheses))
        await AsyncDrain.firstTurn()

        #expect(textView.string == "abc()")
        #expect(textView.selectedRange() == NSRange(location: 4, length: 0))
        #expect(model.selection == TextSelection(location: 4, length: 0))

        controller.perform(.insertIndent)
        await AsyncDrain.firstTurn()

        #expect(textView.string == "abc(    )")
        #expect(textView.selectedRange() == NSRange(location: 8, length: 0))
        #expect(model.selection == TextSelection(location: 8, length: 0))
    }

    @Test
    func undoAndRedoAreBlockedWhenModelIsReadOnly() async {
        let model = HighlightrEditorModel(text: "abc", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        controller.loadView()
        let host = WindowHost(view: controller.view)
        host.pump()

        controller.perform(.focus)
        await AsyncDrain.firstTurn()
        host.pump()

        let textView = controller.editorView.platformTextView
        textView.undoManager?.groupsByEvent = false
        textView.setSelectedRange(NSRange(location: 3, length: 0))

        controller.perform(.insertIndent)
        await AsyncDrain.firstTurn()
        host.pump()
        #expect(model.text == "abc    ")
        #expect(controller.canPerform(.undo))

        model.isEditable = false
        await AsyncDrain.firstTurn()
        host.pump()
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

        controller.loadView()
        let textView = controller.editorView.platformTextView
        textView.setSelectedRange(NSRange(location: 2, length: 0))
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

        controller.loadView()
        let textView = controller.editorView.platformTextView
        textView.setSelectedRange(NSRange(location: 2, length: 0))

        #expect(controller.canPerform(.deleteCurrentLine))
        controller.perform(.deleteCurrentLine)
        await AsyncDrain.firstTurn()

        #expect(model.text == "a")
        #expect(textView.string == "a")
    }

    @Test
    func clearAndDeleteCommandsRemainAvailableBeforeViewSync() async {
        let model = HighlightrEditorModel(text: "", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        controller.loadView()
        let textView = controller.editorView.platformTextView
        #expect(textView.string == "")
        #expect(!controller.canPerform(.clearText))
        #expect(!controller.canPerform(.deleteCurrentLine))

        model.text = "line"
        #expect(textView.string == "")
        #expect(controller.canPerform(.clearText))
        #expect(controller.canPerform(.deleteCurrentLine))

        controller.perform(.deleteCurrentLine)
        await AsyncDrain.firstTurn()
        #expect(model.text == "")
        #expect(textView.string == "")

        model.text = "line"
        #expect(controller.canPerform(.clearText))
        controller.perform(.clearText)
        await AsyncDrain.firstTurn()
        #expect(model.text == "")
        #expect(textView.string == "")
        #expect(!controller.canPerform(.clearText))
    }

    @Test
    func deleteCurrentLineUsesLatestModelTextBeforeViewSync() async {
        let model = HighlightrEditorModel(text: "old\nline", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        controller.loadView()
        let textView = controller.editorView.platformTextView
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        #expect(textView.string == "old\nline")

        model.text = "new"
        #expect(textView.string == "old\nline")
        #expect(controller.canPerform(.deleteCurrentLine))

        controller.perform(.deleteCurrentLine)
        await AsyncDrain.firstTurn()

        #expect(model.text == "")
        #expect(textView.string == "")
    }
}
#endif
