import Foundation
import HighlightrUICore
import Testing
@testable import HighlightrUI

#if canImport(UIKit)
import UIKit

@MainActor
@Suite(.serialized)
struct EditorCoordinatorSyncTests {
    @Test
    func modelToViewTextAndSelectionSync() async {
        let model = HighlightrEditorModel(text: "hello", language: "swift")
        let textView = PlatformEditorTextView(frame: .zero, textContainer: nil)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            model: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )
        defer { coordinator.invalidate() }

        await AsyncDrain.firstTurn()
        model.text = "updated"
        model.selection = TextSelection(location: 1, length: 3)
        await AsyncDrain.firstTurn()
        await AsyncDrain.shortDelay()

        #expect(textView.text == "updated")
        #expect(textView.selectedRange == NSRange(location: 1, length: 3))
    }

    @Test
    func viewToModelTextAndSelectionSync() async {
        let model = HighlightrEditorModel(text: "", language: "swift")
        let textView = PlatformEditorTextView(frame: .zero, textContainer: nil)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            model: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )
        defer { coordinator.invalidate() }

        textView.text = "abc"
        textView.selectedRange = NSRange(location: 2, length: 1)
        coordinator.textViewDidChange(textView)
        coordinator.textViewDidChangeSelection(textView)
        await AsyncDrain.firstTurn()

        #expect(model.text == "abc")
        #expect(model.selection == TextSelection(location: 2, length: 1))
    }

    @Test
    func selectionClampCorrectsNegativeValues() async {
        let model = HighlightrEditorModel(text: "abc", language: "swift")
        let textView = PlatformEditorTextView(frame: .zero, textContainer: nil)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            model: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )
        defer { coordinator.invalidate() }

        model.selection = TextSelection(location: -10, length: 40)
        await AsyncDrain.firstTurn()

        #expect(textView.selectedRange == NSRange(location: 0, length: 3))
    }

    @Test
    func selectionClampCorrectsOverflowValues() async {
        let model = HighlightrEditorModel(text: "abc", language: "swift")
        let textView = PlatformEditorTextView(frame: .zero, textContainer: nil)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            model: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )
        defer { coordinator.invalidate() }

        model.selection = TextSelection(location: 100, length: 20)
        await AsyncDrain.firstTurn()

        #expect(textView.selectedRange == NSRange(location: 3, length: 0))
    }

    @Test
    func modelEditableReflectsIntoTextView() async {
        let model = HighlightrEditorModel(text: "abc", language: "swift")
        let textView = PlatformEditorTextView(frame: .zero, textContainer: nil)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            model: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )
        defer { coordinator.invalidate() }

        model.isEditable = false
        await AsyncDrain.firstTurn()
        await AsyncDrain.shortDelay()

        #expect(textView.isEditable == false)
    }

    @Test
    func languageApplyDeduplicatesRepeatedValues() async {
        let model = HighlightrEditorModel(text: "abc", language: "swift")
        let textView = PlatformEditorTextView(frame: .zero, textContainer: nil)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            model: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )
        defer { coordinator.invalidate() }

        await AsyncDrain.firstTurn()
        #expect(engine.setLanguageCalls == ["swift"])

        model.language = "swift"
        await AsyncDrain.firstTurn()
        #expect(engine.setLanguageCalls == ["swift"])

        model.language = "json"
        await AsyncDrain.firstTurn()
        #expect(engine.setLanguageCalls == ["swift", "json"])
    }
}

#elseif canImport(AppKit)
import AppKit

@MainActor
@Suite(.serialized)
struct EditorCoordinatorSyncTests {
    @Test
    func modelToViewTextAndSelectionSync() async {
        let model = HighlightrEditorModel(text: "hello", language: "swift")
        let textView = NSTextView(frame: .zero)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            model: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )
        defer { coordinator.invalidate() }

        await AsyncDrain.firstTurn()
        model.text = "updated"
        model.selection = TextSelection(location: 1, length: 3)
        await AsyncDrain.firstTurn()
        await AsyncDrain.shortDelay()

        #expect(textView.string == "updated")
        #expect(textView.selectedRange() == NSRange(location: 1, length: 3))
    }

    @Test
    func viewToModelTextAndSelectionSync() async {
        let model = HighlightrEditorModel(text: "", language: "swift")
        let textView = NSTextView(frame: .zero)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            model: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )
        defer { coordinator.invalidate() }

        textView.string = "abc"
        textView.setSelectedRange(NSRange(location: 2, length: 1))
        coordinator.textDidChange(Notification(name: NSText.didChangeNotification, object: textView))
        coordinator.textViewDidChangeSelection(Notification(name: NSTextView.didChangeSelectionNotification, object: textView))
        await AsyncDrain.firstTurn()

        #expect(model.text == "abc")
        #expect(model.selection == TextSelection(location: 2, length: 1))
    }

    @Test
    func selectionClampCorrectsNegativeValues() async {
        let model = HighlightrEditorModel(text: "abc", language: "swift")
        let textView = NSTextView(frame: .zero)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            model: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )
        defer { coordinator.invalidate() }

        model.selection = TextSelection(location: -10, length: 40)
        await AsyncDrain.firstTurn()

        #expect(textView.selectedRange() == NSRange(location: 0, length: 3))
    }

    @Test
    func selectionClampCorrectsOverflowValues() async {
        let model = HighlightrEditorModel(text: "abc", language: "swift")
        let textView = NSTextView(frame: .zero)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            model: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )
        defer { coordinator.invalidate() }

        model.selection = TextSelection(location: 100, length: 20)
        await AsyncDrain.firstTurn()

        #expect(textView.selectedRange() == NSRange(location: 3, length: 0))
    }

    @Test
    func modelEditableReflectsIntoTextView() async {
        let model = HighlightrEditorModel(text: "abc", language: "swift")
        let textView = NSTextView(frame: .zero)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            model: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )
        defer { coordinator.invalidate() }

        model.isEditable = false
        await AsyncDrain.firstTurn()
        await AsyncDrain.shortDelay()

        #expect(textView.isEditable == false)
    }

    @Test
    func languageApplyDeduplicatesRepeatedValues() async {
        let model = HighlightrEditorModel(text: "abc", language: "swift")
        let textView = NSTextView(frame: .zero)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            model: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )
        defer { coordinator.invalidate() }

        await AsyncDrain.firstTurn()
        #expect(engine.setLanguageCalls == ["swift"])

        model.language = "swift"
        await AsyncDrain.firstTurn()
        #expect(engine.setLanguageCalls == ["swift"])

        model.language = "json"
        await AsyncDrain.firstTurn()
        #expect(engine.setLanguageCalls == ["swift", "json"])
    }
}
#endif
