#if canImport(AppKit)
import AppKit
import Foundation
import Testing
@testable import HighlightrUI

@MainActor
@Suite(.serialized)
struct HighlightrEditorViewControllerCommandmacOSTests {
    @Test
    func insertPairWrapsSelectionAndKeepsModelSynchronized() async {
        let model = HighlightrModel(text: "abc", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
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
        let model = HighlightrModel(text: "value", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
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
        let model = HighlightrModel(text: "abc", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
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
        let selectedRange = textView.selectedRange()
        #expect(selectedRange.length == 0)
        #expect(selectedRange.location == model.selection.location)
        #expect(selectedRange.location == 8 || selectedRange.location == 9)
    }

    @Test
    func undoAndRedoAreBlockedWhenModelIsReadOnly() async {
        let model = HighlightrModel(text: "abc", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
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
        let model = HighlightrModel(text: "a\nb\nc", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
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
        let model = HighlightrModel(text: "a\n", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
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
        let model = HighlightrModel(text: "", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
        )

        controller.loadView()
        let textView = controller.editorView.platformTextView
        #expect(textView.string == "")
        #expect(!controller.canPerform(.clearText))
        #expect(!controller.canPerform(.deleteCurrentLine))

        model.text = "line"
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
        let model = HighlightrModel(text: "old\nline", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
        )

        controller.loadView()
        let textView = controller.editorView.platformTextView
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        #expect(textView.string == "old\nline")

        model.text = "new"
        #expect(controller.canPerform(.deleteCurrentLine))

        controller.perform(.deleteCurrentLine)
        await AsyncDrain.firstTurn()

        #expect(model.text == "")
        #expect(textView.string == "")
    }

    @Test
    func insertIndentUsesLatestModelTextBeforeViewSync() async {
        let model = HighlightrModel(text: "old", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
        )

        controller.loadView()
        let textView = controller.editorView.platformTextView
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        #expect(textView.string == "old")

        model.text = "new"

        controller.perform(.insertIndent)
        await AsyncDrain.firstTurn()

        #expect(model.text == "    new")
        #expect(textView.string == "    new")
    }

    @Test
    func insertIndentUsesLatestModelSelectionBeforeViewSync() async {
        let model = HighlightrModel(text: "abc", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
        )

        controller.loadView()
        let textView = controller.editorView.platformTextView
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        #expect(textView.selectedRange() == NSRange(location: 0, length: 0))

        model.selection = TextSelection(location: 3, length: 0)

        controller.perform(.insertIndent)
        await AsyncDrain.firstTurn()

        #expect(model.text == "abc    ")
        #expect(textView.string == "abc    ")
        #expect(model.selection == TextSelection(location: 7, length: 0))
        #expect(textView.selectedRange() == NSRange(location: 7, length: 0))
    }

    @Test
    func undoUsesLatestModelTextBeforeViewSync() async {
        let model = HighlightrModel(text: "old", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
        )

        controller.loadView()
        let host = WindowHost(view: controller.view)
        host.pump()
        controller.perform(.focus)
        await AsyncDrain.firstTurn()
        host.pump()

        let textView = controller.editorView.platformTextView
        textView.undoManager?.groupsByEvent = false
        textView.setSelectedRange(NSRange(location: 0, length: 0))

        controller.perform(.insertIndent)
        await AsyncDrain.firstTurn()
        host.pump()
        #expect(model.text == "    old")
        #expect(controller.canPerform(.undo))

        model.text = "new"

        controller.perform(.undo)
        await AsyncDrain.firstTurn()
        host.pump()

        #expect(model.text == "new")
        #expect(textView.string == "new")

        _ = host
    }

    @Test
    func redoUsesLatestModelTextBeforeViewSync() async {
        let model = HighlightrModel(text: "old", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
        )

        controller.loadView()
        let host = WindowHost(view: controller.view)
        host.pump()
        controller.perform(.focus)
        await AsyncDrain.firstTurn()
        host.pump()

        let textView = controller.editorView.platformTextView
        textView.undoManager?.groupsByEvent = false
        textView.setSelectedRange(NSRange(location: 0, length: 0))

        controller.perform(.insertIndent)
        await AsyncDrain.firstTurn()
        host.pump()
        controller.perform(.undo)
        await AsyncDrain.firstTurn()
        host.pump()
        #expect(model.text == "old")
        #expect(controller.canPerform(.redo))

        model.text = "new"

        controller.perform(.redo)
        await AsyncDrain.firstTurn()
        host.pump()

        #expect(model.text == "new")
        #expect(textView.string == "new")

        _ = host
    }

    @Test
    func focusCommandBeforeWindowAttachPreservesPendingFocusRequest() async {
        let model = HighlightrModel(text: "abc", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
        )

        controller.loadView()
        #expect(model.isEditorFocused == false)
        #expect(NSApplication.shared.windows.contains { $0.firstResponder === controller.editorView.platformTextView } == false)

        controller.perform(.focus)
        await AsyncDrain.firstTurn()

        #expect(model.isEditorFocused == true)
        #expect(!controller.canPerform(.focus))
        #expect(controller.canPerform(.blur))

        let host = WindowHost(view: controller.view)
        host.pump()
        await AsyncDrain.firstTurn()
        host.pump()

        #expect(model.isEditorFocused == true)
        #expect(host.window.firstResponder === controller.editorView.platformTextView)

        _ = host
    }
}
#endif
