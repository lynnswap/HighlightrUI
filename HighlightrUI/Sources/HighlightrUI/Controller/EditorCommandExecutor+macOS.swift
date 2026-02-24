#if canImport(AppKit)
import AppKit
import Foundation

@MainActor
final class EditorCommandExecutor {
    private unowned let editorView: HighlightrEditorView
    private let commandService: EditorCommandService

    init(
        editorView: HighlightrEditorView,
        commandService: EditorCommandService = .init()
    ) {
        self.editorView = editorView
        self.commandService = commandService
    }

    func canPerform(_ command: HighlightrEditorCommand) -> Bool {
        commandService.canPerform(command, context: context)
    }

    func perform(_ command: HighlightrEditorCommand) {
        let effects = commandService.execute(command, context: context)
        editorView.session.applyCommandEffects(effects)
    }

    private var context: EditorCommandContext {
        EditorCommandContext(
            text: editorView.model.text,
            selection: editorView.model.selection,
            isEditable: editorView.model.isEditable,
            isEditorFocused: editorView.model.isEditorFocused,
            isUndoable: editorView.model.isUndoable,
            isRedoable: editorView.model.isRedoable
        )
    }
}
#endif
