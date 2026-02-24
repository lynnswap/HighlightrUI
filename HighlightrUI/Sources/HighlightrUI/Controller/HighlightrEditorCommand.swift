import Foundation

public enum HighlightrEditorPairKind: String, Hashable, Sendable {
    case parentheses
    case singleQuote
    case doubleQuote
}

public enum HighlightrEditorCommand: Hashable, Sendable {
    case focus
    case blur
    case dismissKeyboard
    case undo
    case redo
    case insertIndent
    case insertCurlyBraces
    case insertPair(HighlightrEditorPairKind)
    case deleteCurrentLine
    case clearText
}
