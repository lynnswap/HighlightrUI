import HighlightrUICore
import ObservationsCompat

struct EditorDocumentObservation: Equatable {
    let text: String
    let language: EditorLanguage
    let theme: EditorTheme
    let selection: TextSelection
    let isEditable: Bool
    let isFocused: Bool

    @MainActor
    init(model: HighlightrEditorModel) {
        text = model.text
        language = model.language
        theme = model.theme
        selection = model.selection
        isEditable = model.isEditable
        isFocused = model.isFocused
    }
}

struct EditorCommandObservation: Equatable {
    let isEditable: Bool
    let isFocused: Bool
    let isUndoable: Bool
    let isRedoable: Bool
    let hasText: Bool

    @MainActor
    init(model: HighlightrEditorModel) {
        isEditable = model.isEditable
        isFocused = model.isFocused
        isUndoable = model.isUndoable
        isRedoable = model.isRedoable
        hasText = !model.text.isEmpty
    }
}

@MainActor
func observeDocumentState(
    model: HighlightrEditorModel,
    backend: ObservationsCompatBackend = .automatic
) -> ObservationsCompatStream<EditorDocumentObservation> {
    makeObservationsCompatStream(backend: backend) {
        EditorDocumentObservation(model: model)
    }
}

@MainActor
func observeCommandInputs(
    model: HighlightrEditorModel,
    backend: ObservationsCompatBackend = .automatic
) -> ObservationsCompatStream<EditorCommandObservation> {
    makeObservationsCompatStream(backend: backend) {
        EditorCommandObservation(model: model)
    }
}
