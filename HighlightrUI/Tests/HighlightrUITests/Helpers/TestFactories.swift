import Foundation
@testable import HighlightrUI

@MainActor
func makeModel(
    text: String = "",
    language: EditorLanguage,
    theme: EditorTheme = .automatic(light: "paraiso-light", dark: "paraiso-dark"),
    isEditable: Bool = true,
    isEditorFocused: Bool = false,
    isUndoable: Bool = false,
    isRedoable: Bool = false
) -> HighlightrModel {
    HighlightrModel(
        text: text,
        language: language,
        theme: theme,
        isEditable: isEditable,
        isEditorFocused: isEditorFocused,
        isUndoable: isUndoable,
        isRedoable: isRedoable
    )
}

@MainActor
func makeEditorView(
    text: String = "",
    language: EditorLanguage,
    theme: EditorTheme = .automatic(light: "paraiso-light", dark: "paraiso-dark"),
    isEditable: Bool = true,
    isEditorFocused: Bool = false,
    isUndoable: Bool = false,
    isRedoable: Bool = false,
    configuration: EditorViewConfiguration = .init(),
    engineFactory: @escaping @MainActor () -> any SyntaxHighlightingEngine = { HighlightrEngine() }
) -> HighlightrEditorView {
    let model = makeModel(
        text: text,
        language: language,
        theme: theme,
        isEditable: isEditable,
        isEditorFocused: isEditorFocused,
        isUndoable: isUndoable,
        isRedoable: isRedoable
    )
    return HighlightrEditorView(
        model: model,
        configuration: configuration,
        engineFactory: engineFactory
    )
}

#if canImport(UIKit)
import UIKit

@MainActor
func makeEditorSession(
    model: HighlightrModel,
    textView: PlatformEditorTextView,
    engine: any SyntaxHighlightingEngine,
    initialColorScheme: EditorColorScheme = .light
) -> EditorSession {
    let adapter = UIKitEditorAdapter(textView: textView)
    return EditorSession(
        model: model,
        adapter: adapter,
        engine: engine,
        initialColorScheme: initialColorScheme
    )
}

#elseif canImport(AppKit)
import AppKit

@MainActor
func makeEditorSession(
    model: HighlightrModel,
    textView: NSTextView,
    engine: any SyntaxHighlightingEngine,
    initialColorScheme: EditorColorScheme = .light
) -> EditorSession {
    let adapter = AppKitEditorAdapter(textView: textView)
    return EditorSession(
        model: model,
        adapter: adapter,
        engine: engine,
        initialColorScheme: initialColorScheme
    )
}
#endif
