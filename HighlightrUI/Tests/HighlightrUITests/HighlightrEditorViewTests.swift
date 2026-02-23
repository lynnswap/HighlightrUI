import XCTest
@testable import HighlightrUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
final class HighlightrEditorViewTests: XCTestCase {
    @MainActor
    private final class MockEngine: SyntaxHighlightingEngine {
        var availableThemeNames: [String] = ["paraiso-light", "paraiso-dark"]
        private let storage = NSTextStorage(string: "")

        var makeStorageInputs: [(EditorLanguage, String)] = []
        var setLanguageCalls: [EditorLanguage] = []
        var setThemeCalls: [String] = []

        func makeTextStorage(initialLanguage: EditorLanguage, initialThemeName: String) -> NSTextStorage {
            makeStorageInputs.append((initialLanguage, initialThemeName))
            return storage
        }

        func setLanguage(_ language: EditorLanguage) {
            setLanguageCalls.append(language)
        }

        func setThemeName(_ themeName: String) {
            setThemeCalls.append(themeName)
        }
    }

    @MainActor
    private func drainMainActor() async {
        await Task.yield()
        try? await Task.sleep(nanoseconds: 80_000_000)
    }

    func testModelToViewSynchronization() async {
        let model = HighlightrEditorModel(text: "", language: "swift")
        let engine = MockEngine()
        let view = HighlightrEditorView(model: model, engineFactory: { engine })

        model.text = "let x = 1"
        model.selection = TextSelection(location: 3, length: 2)

        await drainMainActor()

        #if canImport(UIKit)
        XCTAssertEqual(view.platformTextView.text, "let x = 1")
        XCTAssertEqual(view.platformTextView.selectedRange, NSRange(location: 3, length: 2))
        #elseif canImport(AppKit)
        XCTAssertEqual(view.platformTextView.string, "let x = 1")
        XCTAssertEqual(view.platformTextView.selectedRange(), NSRange(location: 3, length: 2))
        #endif
    }

    func testViewInputUpdatesModel() async {
        let model = HighlightrEditorModel(text: "", language: "swift")
        let engine = MockEngine()
        let view = HighlightrEditorView(model: model, engineFactory: { engine })

        #if canImport(UIKit)
        view.platformTextView.text = "updated from view"
        view.platformTextView.selectedRange = NSRange(location: 2, length: 1)
        view.coordinator.textViewDidChange(view.platformTextView)
        view.coordinator.textViewDidChangeSelection(view.platformTextView)
        #elseif canImport(AppKit)
        view.platformTextView.string = "updated from view"
        view.platformTextView.setSelectedRange(NSRange(location: 2, length: 1))
        view.coordinator.textDidChange(Notification(name: NSText.didChangeNotification, object: view.platformTextView))
        view.coordinator.textViewDidChangeSelection(Notification(name: NSTextView.didChangeSelectionNotification, object: view.platformTextView))
        #endif

        await drainMainActor()

        XCTAssertEqual(model.text, "updated from view")
        XCTAssertEqual(model.selection, TextSelection(location: 2, length: 1))
    }

    func testRuntimeLanguageSwitchCallsEngine() async {
        let model = HighlightrEditorModel(text: "", language: "swift")
        let engine = MockEngine()
        let view = HighlightrEditorView(model: model, engineFactory: { engine })
        _ = view

        model.language = "javascript"
        await drainMainActor()

        XCTAssertEqual(engine.setLanguageCalls.last?.rawValue, "javascript")
    }

    func testFocusAndBlurMirrorIntoModel() {
        let model = HighlightrEditorModel(text: "", language: "swift")
        let view = HighlightrEditorView(model: model)

        view.focus()
        #if canImport(UIKit)
        XCTAssertEqual(model.isFocused, view.platformTextView.isFirstResponder)
        #elseif canImport(AppKit)
        XCTAssertEqual(model.isFocused, view.window?.firstResponder === view.platformTextView)
        #endif

        view.blur()
        #if canImport(UIKit)
        XCTAssertEqual(model.isFocused, view.platformTextView.isFirstResponder)
        #elseif canImport(AppKit)
        XCTAssertEqual(model.isFocused, view.window?.firstResponder === view.platformTextView)
        #endif
    }
}
