import Foundation
import Observation

@MainActor
@Observable
public final class HighlightrEditorModel {
    public var text: String
    public var language: EditorLanguage
    public var theme: EditorTheme
    public var selection: TextSelection
    public var isEditable: Bool
    public var isFocused: Bool
    public var isUndoable: Bool
    public var isRedoable: Bool
    public var hasText: Bool

    public init(
        text: String = "",
        language: EditorLanguage,
        theme: EditorTheme = .automatic(light: "paraiso-light", dark: "paraiso-dark"),
        isEditable: Bool = true,
        isFocused: Bool = false,
        isUndoable: Bool = false,
        isRedoable: Bool = false,
        hasText: Bool? = nil
    ) {
        self.text = text
        self.language = language
        self.theme = theme
        self.selection = .zero
        self.isEditable = isEditable
        self.isFocused = isFocused
        self.isUndoable = isUndoable
        self.isRedoable = isRedoable
        self.hasText = hasText ?? !text.isEmpty
    }
}
