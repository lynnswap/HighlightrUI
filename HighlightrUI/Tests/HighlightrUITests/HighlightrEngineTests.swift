import Foundation
import Testing
@testable import HighlightrUI

@MainActor
struct HighlightrEngineTests {
    @Test
    func availableThemeNamesAreSortedAndNotEmpty() {
        let engine = HighlightrEngine()
        let names = engine.availableThemeNames

        #expect(!names.isEmpty)
        #expect(names == names.sorted())
    }

    @Test
    func languageAndThemeCanBeAppliedAfterStorageCreation() {
        let engine = HighlightrEngine()
        let storage = engine.makeTextStorage(initialLanguage: "swift", initialThemeName: "github")

        storage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "print(1)")
        engine.setLanguage("json")
        engine.setThemeName("paraiso-dark")

        #expect(storage.string == "print(1)")
    }

    @Test
    func unknownLanguageFallsBackWithoutCrashing() async {
        let engine = HighlightrEngine()
        let source = "print(1)"
        let sourceLength = (source as NSString).length

        _ = engine.makeTextStorage(initialLanguage: "unknown-language", initialThemeName: "github")
        engine.setLanguage("still-unknown-language")

        let payload = await engine.renderHighlightPayload(
            source: source,
            in: NSRange(location: 0, length: sourceLength)
        )

        #expect((payload?.utf16Length ?? sourceLength) == sourceLength)
        if let payload {
            #expect(payload.usedAutoDetection)
        }
    }

    @Test
    func invalidThemeNameIsIgnoredWithoutCrashing() async {
        let engine = HighlightrEngine()
        let source = "let value = 42"
        let sourceLength = (source as NSString).length

        _ = engine.makeTextStorage(initialLanguage: "swift", initialThemeName: "github")

        let baseline = await engine.renderHighlightPayload(
            source: source,
            in: NSRange(location: 0, length: sourceLength)
        )

        engine.setThemeName("__invalid_theme__")

        let payloadAfterInvalidTheme = await engine.renderHighlightPayload(
            source: source,
            in: NSRange(location: 0, length: sourceLength)
        )

        #expect((payloadAfterInvalidTheme?.utf16Length ?? sourceLength) == sourceLength)

        if let baseline, let payloadAfterInvalidTheme {
            #expect(payloadAfterInvalidTheme.utf16Length == baseline.utf16Length)
        }
    }
}
