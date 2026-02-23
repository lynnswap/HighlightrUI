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
}
