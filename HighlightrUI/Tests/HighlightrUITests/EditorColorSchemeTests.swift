import Testing
@testable import HighlightrUI

#if canImport(UIKit)
import UIKit

struct EditorColorSchemeTests {
    @Test
    @MainActor
    func mapsInterfaceStyleIntoEditorColorScheme() {
        #expect(editorColorScheme(from: .light) == .light)
        #expect(editorColorScheme(from: .dark) == .dark)
        #expect(editorColorScheme(from: .unspecified) == .light)
    }
}

#elseif canImport(AppKit)
import AppKit

struct EditorColorSchemeTests {
    @Test
    @MainActor
    func mapsAppearanceIntoEditorColorScheme() throws {
        let dark = try #require(NSAppearance(named: .darkAqua))
        let light = try #require(NSAppearance(named: .aqua))

        #expect(editorColorScheme(from: dark) == .dark)
        #expect(editorColorScheme(from: light) == .light)
    }
}
#endif
