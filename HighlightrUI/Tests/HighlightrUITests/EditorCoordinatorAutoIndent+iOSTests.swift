#if canImport(UIKit)
import Foundation
import HighlightrUICore
import Testing
@testable import HighlightrUI
import UIKit

@MainActor
@Suite(.serialized)
struct EditorCoordinatorAutoIndentiOSTests {
    @Test
    func autoIndentEnabledInsertsLineIndentOnNewline() async {
        let model = HighlightrEditorModel(text: "if true {\n    let x = 1", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
            controllerConfiguration: .init(autoIndentOnNewline: true),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        controller.loadViewIfNeeded()
        let textView = controller.editorView.platformTextView
        textView.selectedRange = NSRange(location: (textView.text ?? "").utf16.count, length: 0)
        let handled = controller.editorView.coordinator.textView(
            textView,
            shouldChangeTextIn: textView.selectedRange,
            replacementText: "\n"
        )

        await AsyncDrain.firstTurn()
        #expect(handled == false)

        #expect(model.text == "if true {\n    let x = 1\n    ")
        #expect(textView.text == "if true {\n    let x = 1\n    ")
    }

    @Test
    func autoIndentDisabledKeepsPlainNewline() async {
        let model = HighlightrEditorModel(text: "if true {\n    let x = 1", language: "swift")
        let controller = HighlightrEditorViewController(
            model: model,
            controllerConfiguration: .init(autoIndentOnNewline: false),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        controller.loadViewIfNeeded()
        let textView = controller.editorView.platformTextView
        textView.selectedRange = NSRange(location: (textView.text ?? "").utf16.count, length: 0)
        let handled = controller.editorView.coordinator.textView(
            textView,
            shouldChangeTextIn: textView.selectedRange,
            replacementText: "\n"
        )
        #expect(handled == true)
        textView.insertText("\n")

        await AsyncDrain.firstTurn()

        #expect(model.text == "if true {\n    let x = 1\n")
        #expect(textView.text == "if true {\n    let x = 1\n")
    }
}
#endif
