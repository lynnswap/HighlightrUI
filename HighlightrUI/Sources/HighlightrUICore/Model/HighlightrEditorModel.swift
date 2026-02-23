import Foundation
import Observation
import ObservationsCompat

@MainActor
@Observable
public final class HighlightrEditorModel {
    public var text: String
    public var language: EditorLanguage
    public var theme: EditorTheme
    public var selection: TextSelection
    public var isEditable: Bool
    public var isFocused: Bool

    public init(
        text: String = "",
        language: EditorLanguage,
        theme: EditorTheme = .automatic(light: "paraiso-light", dark: "paraiso-dark"),
        isEditable: Bool = true
    ) {
        self.text = text
        self.language = language
        self.theme = theme
        self.selection = .zero
        self.isEditable = isEditable
        self.isFocused = false
    }

    public func snapshot() -> EditorSnapshot {
        EditorSnapshot(
            text: text,
            language: language,
            theme: theme,
            selection: selection,
            isEditable: isEditable,
            isFocused: isFocused
        )
    }

    public func snapshotStream(
        backend: ObservationsCompatBackend = .automatic
    ) -> ObservationsCompatStream<EditorSnapshot> {
        makeObservationsCompatStream(backend: backend) {
            self.snapshot()
        }
    }

    public func textStream(
        backend: ObservationsCompatBackend = .automatic
    ) -> ObservationsCompatStream<String> {
        makeObservationsCompatStream(backend: backend) {
            self.text
        }
    }

    public func themeStream(
        backend: ObservationsCompatBackend = .automatic
    ) -> ObservationsCompatStream<EditorTheme> {
        makeObservationsCompatStream(backend: backend) {
            self.theme
        }
    }
}
