import Observation

@MainActor
@Observable
public final class HighlightrModel {
    public var text: String
    public var language: EditorLanguage
    public var theme: EditorTheme
    public var selection: TextSelection
    public var isEditable: Bool
    public var isEditorFocused: Bool
    public var isUndoable: Bool
    public var isRedoable: Bool

    public var hasText: Bool {
        !text.isEmpty
    }

    public init(
        text: String = "",
        language: EditorLanguage,
        theme: EditorTheme = .automatic(light: "paraiso-light", dark: "paraiso-dark"),
        selection: TextSelection = .zero,
        isEditable: Bool = true,
        isEditorFocused: Bool = false,
        isUndoable: Bool = false,
        isRedoable: Bool = false
    ) {
        self.text = text
        self.language = language
        self.theme = theme
        self.selection = selection
        self.isEditable = isEditable
        self.isEditorFocused = isEditorFocused
        self.isUndoable = isUndoable
        self.isRedoable = isRedoable
    }
}
