#if canImport(AppKit)
import AppKit
import Foundation
import Testing
@testable import HighlightrUI

@MainActor
@Suite(.serialized)
struct EditorCoordinatorAutoIndentmacOSTests {
    @Test
    func autoIndentEnabledInsertsLineIndentOnNewline() async {
        let model = HighlightrEditorView(text: "if true {\n    let x = 1", language: "swift")
        let controller = HighlightrEditorViewController(
            editorView: model,
            configuration: .init(autoIndentOnNewline: true),
        )

        controller.loadView()

        let textView = controller.editorView.platformTextView
        textView.setSelectedRange(NSRange(location: textView.string.utf16.count, length: 0))
        textView.insertText("\n", replacementRange: textView.selectedRange())

        await AsyncDrain.firstTurn()

        #expect(model.text == "if true {\n    let x = 1\n    ")
        #expect(textView.string == "if true {\n    let x = 1\n    ")
    }

    @Test
    func autoIndentDisabledKeepsPlainNewline() async {
        let model = HighlightrEditorView(text: "if true {\n    let x = 1", language: "swift")
        let controller = HighlightrEditorViewController(
            editorView: model,
            configuration: .init(autoIndentOnNewline: false),
        )

        controller.loadView()

        let textView = controller.editorView.platformTextView
        textView.setSelectedRange(NSRange(location: textView.string.utf16.count, length: 0))
        textView.insertText("\n", replacementRange: textView.selectedRange())

        await AsyncDrain.firstTurn()

        #expect(model.text == "if true {\n    let x = 1\n")
        #expect(textView.string == "if true {\n    let x = 1\n")
    }
}
#endif
