@MainActor
struct HighlightrModelObservationSnapshot: Equatable, Sendable {
    let text: String
    let language: EditorLanguage
    let theme: EditorTheme
    let selection: TextSelection
    let isEditable: Bool
    let isEditorFocused: Bool
    let isUndoable: Bool
    let isRedoable: Bool
}
