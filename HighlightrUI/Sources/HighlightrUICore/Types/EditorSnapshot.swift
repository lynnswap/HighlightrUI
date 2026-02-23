import Foundation

public struct EditorSnapshot: Hashable, Sendable, Equatable {
    public var text: String
    public var language: EditorLanguage
    public var theme: EditorTheme
    public var selection: TextSelection
    public var isEditable: Bool
    public var isFocused: Bool
    public var isUndoable: Bool
    public var isRedoable: Bool

    public init(
        text: String,
        language: EditorLanguage,
        theme: EditorTheme,
        selection: TextSelection,
        isEditable: Bool,
        isFocused: Bool,
        isUndoable: Bool,
        isRedoable: Bool
    ) {
        self.text = text
        self.language = language
        self.theme = theme
        self.selection = selection
        self.isEditable = isEditable
        self.isFocused = isFocused
        self.isUndoable = isUndoable
        self.isRedoable = isRedoable
    }
}
