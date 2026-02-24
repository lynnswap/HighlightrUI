import Testing
@testable import HighlightrUI

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
    func editorThemeEqualityAndHashable() {
        let lhs = EditorTheme.automatic(light: "paraiso-light", dark: "paraiso-dark")
        let rhs = EditorTheme.automatic(light: "paraiso-light", dark: "paraiso-dark")

        #expect(lhs == rhs)
        #expect(Set([lhs, rhs]).count == 1)
    }
}
