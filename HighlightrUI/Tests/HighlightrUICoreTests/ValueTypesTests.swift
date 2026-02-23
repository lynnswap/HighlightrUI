import Testing
@testable import HighlightrUICore

struct ValueTypesTests {
    @Test
    func editorLanguageRawRepresentableRoundTrip() {
        let languageFromLiteral: EditorLanguage = "swift"
        let languageFromRaw = EditorLanguage(rawValue: "swift")

        #expect(languageFromLiteral == languageFromRaw)
        #expect(languageFromLiteral.rawValue == "swift")
    }

    @Test
    func editorLanguageIsHashable() {
        let languages: Set<EditorLanguage> = ["swift", "swift", "json"]
        #expect(languages.count == 2)
    }

    @Test
    func textSelectionZero() {
        #expect(TextSelection.zero == TextSelection(location: 0, length: 0))
    }

    @Test
    func editorSnapshotEqualityAndHashable() {
        let lhs = EditorSnapshot(
            text: "a",
            language: "swift",
            theme: .named("github"),
            selection: TextSelection(location: 1, length: 1),
            isEditable: true,
            isFocused: false,
            isUndoable: false,
            isRedoable: false
        )

        let rhs = EditorSnapshot(
            text: "a",
            language: "swift",
            theme: .named("github"),
            selection: TextSelection(location: 1, length: 1),
            isEditable: true,
            isFocused: false,
            isUndoable: false,
            isRedoable: false
        )

        #expect(lhs == rhs)
        #expect(Set([lhs, rhs]).count == 1)
    }
}
