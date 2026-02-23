#if canImport(AppKit)
import AppKit
import Foundation
import HighlightrUICore
import Testing
@testable import HighlightrUI

@MainActor
final class UndoOperationDriver {
    let model: HighlightrEditorModel
    let view: HighlightrEditorView
    let host: WindowHost

    var textView: NSTextView { view.platformTextView }

    init(initialText: String, allowsUndo: Bool = true) {
        self.model = HighlightrEditorModel(text: initialText, language: "swift")
        self.view = HighlightrEditorView(
            model: model,
            configuration: .init(lineWrappingEnabled: false, allowsUndo: allowsUndo),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )
        self.host = WindowHost(view: view)
        host.pump()
    }

    var currentText: String { textView.string }

    func prepareForEditing() async {
        view.focus()
        await settle()
        textView.undoManager?.groupsByEvent = false
    }

    func settle() async {
        host.pump()
        await AsyncDrain.firstTurn()
        host.pump()
    }

    func setSelection(_ range: NSRange) async {
        textView.setSelectedRange(range)
        await settle()
    }

    func insert(_ text: String) async {
        await performUndoStep {
            let range = textView.selectedRange()
            textView.insertText(text, replacementRange: range)
        }
    }

    func deleteBackward() async {
        await performUndoStep {
            textView.deleteBackward(nil)
        }
    }

    func replace(range: NSRange, with text: String) async {
        await performUndoStep {
            textView.setSelectedRange(range)
            textView.insertText(text, replacementRange: range)
        }
    }

    func undo() async {
        textView.undoManager?.undo()
        await settle()
    }

    func redo() async {
        textView.undoManager?.redo()
        await settle()
    }

    func canRedo() -> Bool {
        textView.undoManager?.canRedo ?? false
    }

    func expectText(_ expected: String, _ context: String) {
        let state = debugState(prefix: context)
        #expect(currentText == expected, "\(state)")
        #expect(model.text == expected, "\(state)")
    }

    func expectSelection(_ expected: NSRange, _ context: String) {
        let state = debugState(prefix: context)
        #expect(textView.selectedRange() == expected, "\(state)")
        #expect(
            model.selection == TextSelection(location: expected.location, length: expected.length),
            "\(state)"
        )
    }

    func expectSynchronized(_ context: String) {
        let selection = textView.selectedRange()
        let state = debugState(prefix: context)
        #expect(model.text == currentText, "\(state)")
        #expect(
            model.selection == TextSelection(location: selection.location, length: selection.length),
            "\(state)"
        )
        #expect(
            model.isUndoable == (textView.undoManager?.canUndo ?? false),
            "\(state)"
        )
        #expect(
            model.isRedoable == (textView.undoManager?.canRedo ?? false),
            "\(state)"
        )
    }

    private func debugState(prefix: String) -> String {
        let selection = textView.selectedRange()
        return "\(prefix) | textView=\"\(currentText)\" model=\"\(model.text)\" selection=\(selection.location),\(selection.length) modelSelection=\(model.selection.location),\(model.selection.length) undo(view:\(textView.undoManager?.canUndo ?? false), model:\(model.isUndoable)) redo(view:\(textView.undoManager?.canRedo ?? false), model:\(model.isRedoable))"
    }

    private func performUndoStep(_ operation: () -> Void) async {
        guard let undoManager = textView.undoManager else {
            operation()
            await settle()
            return
        }

        undoManager.beginUndoGrouping()
        operation()
        undoManager.endUndoGrouping()
        await settle()
    }
}
#endif
