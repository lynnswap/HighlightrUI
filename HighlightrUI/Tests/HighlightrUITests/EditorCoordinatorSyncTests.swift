import Foundation
import Testing
@testable import HighlightrUI

#if canImport(UIKit)
import UIKit

@MainActor
@Suite(.serialized)
struct EditorCoordinatorSyncTests {
    @Test
    func modelToViewTextAndSelectionSync() async {
        let model = HighlightrEditorView(text: "hello", language: "swift")
        let textView = PlatformEditorTextView(frame: .zero, textContainer: nil)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            owner: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )

        await AsyncDrain.firstTurn()
        model.text = "updated"
        model.selection = TextSelection(location: 1, length: 3)
        coordinator.syncViewFromOwner()

        #expect(textView.text == "updated")
        #expect(textView.selectedRange == NSRange(location: 1, length: 3))
        withExtendedLifetime(coordinator) {}
    }

    @Test
    func viewToModelTextAndSelectionSync() async {
        let model = HighlightrEditorView(text: "", language: "swift")
        let textView = PlatformEditorTextView(frame: .zero, textContainer: nil)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            owner: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )

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
        let model = HighlightrEditorView(text: "abc", language: "swift")
        let textView = PlatformEditorTextView(frame: .zero, textContainer: nil)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            owner: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )

        model.selection = TextSelection(location: -10, length: 40)
        coordinator.syncViewFromOwner()

        #expect(textView.selectedRange == NSRange(location: 0, length: 3))
        #expect(model.selection == TextSelection(location: 0, length: 3))
        withExtendedLifetime(coordinator) {}
    }

    @Test
    func selectionClampCorrectsOverflowValues() async {
        let model = HighlightrEditorView(text: "abc", language: "swift")
        let textView = PlatformEditorTextView(frame: .zero, textContainer: nil)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            owner: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )

        model.selection = TextSelection(location: 100, length: 20)
        coordinator.syncViewFromOwner()

        #expect(textView.selectedRange == NSRange(location: 3, length: 0))
        #expect(model.selection == TextSelection(location: 3, length: 0))
        withExtendedLifetime(coordinator) {}
    }

    @Test
    func modelEditableReflectsIntoTextView() async {
        let model = HighlightrEditorView(text: "abc", language: "swift")
        let textView = PlatformEditorTextView(frame: .zero, textContainer: nil)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            owner: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )

        model.isEditable = false
        coordinator.syncViewFromOwner()

        #expect(textView.isEditable == false)
        withExtendedLifetime(coordinator) {}
    }

    @Test
    func languageApplyDeduplicatesRepeatedValues() async {
        let model = HighlightrEditorView(text: "abc", language: "swift")
        let textView = PlatformEditorTextView(frame: .zero, textContainer: nil)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            owner: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )

        await AsyncDrain.firstTurn()
        #expect(engine.setLanguageCalls == ["swift"])

        model.language = "swift"
        coordinator.syncViewFromOwner()
        #expect(engine.setLanguageCalls == ["swift"])

        model.language = "json"
        coordinator.syncViewFromOwner()
        #expect(engine.setLanguageCalls == ["swift", "json"])
        withExtendedLifetime(coordinator) {}
    }

    @Test
    func coordinatorReleasesWhileHighlightRenderIsSuspended() async {
        let model = HighlightrEditorView(text: "hello", language: "swift")
        let textView = PlatformEditorTextView(frame: .zero, textContainer: nil)
        let engine = SuspendingSyntaxHighlightingEngine()
        weak var weakCoordinator: EditorCoordinator?

        var coordinator: EditorCoordinator? = EditorCoordinator(
            owner: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )
        weakCoordinator = coordinator

        await engine.waitForRenderStart()
        coordinator = nil
        await AsyncDrain.firstTurn()

        #expect(weakCoordinator == nil)
        await engine.resumeRender()
    }

    @Test
    func initDoesNotOverrideCallerProvidedRuntimeFlags() {
        let model = HighlightrEditorView(text: "abc", language: "swift")
        model.isUndoable = true
        model.isRedoable = true

        let textView = PlatformEditorTextView(frame: .zero, textContainer: nil)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            owner: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )

        #expect(model.isUndoable)
        #expect(model.isRedoable)
        withExtendedLifetime(coordinator) {}
    }

}

#elseif canImport(AppKit)
import AppKit

@MainActor
@Suite(.serialized)
struct EditorCoordinatorSyncTests {
    @Test
    func modelToViewTextAndSelectionSync() async {
        let model = HighlightrEditorView(text: "hello", language: "swift")
        let textView = NSTextView(frame: .zero)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            owner: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )

        await AsyncDrain.firstTurn()
        model.text = "updated"
        model.selection = TextSelection(location: 1, length: 3)
        coordinator.syncViewFromOwner()

        #expect(textView.string == "updated")
        #expect(textView.selectedRange() == NSRange(location: 1, length: 3))
        withExtendedLifetime(coordinator) {}
    }

    @Test
    func viewToModelTextAndSelectionSync() async {
        let model = HighlightrEditorView(text: "", language: "swift")
        let textView = NSTextView(frame: .zero)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            owner: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )

        textView.string = "abc"
        textView.setSelectedRange(NSRange(location: 2, length: 1))
        coordinator.textDidChange(Notification(name: NSText.didChangeNotification, object: textView))
        coordinator.textViewDidChangeSelection(Notification(name: NSTextView.didChangeSelectionNotification, object: textView))
        await AsyncDrain.firstTurn()

        #expect(model.text == "abc")
        #expect(model.selection == TextSelection(location: 2, length: 1))
        withExtendedLifetime(coordinator) {}
    }

    @Test
    func selectionClampCorrectsNegativeValues() async {
        let model = HighlightrEditorView(text: "abc", language: "swift")
        let textView = NSTextView(frame: .zero)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            owner: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )

        model.selection = TextSelection(location: -10, length: 40)
        coordinator.syncViewFromOwner()

        #expect(textView.selectedRange() == NSRange(location: 0, length: 3))
        #expect(model.selection == TextSelection(location: 0, length: 3))
        withExtendedLifetime(coordinator) {}
    }

    @Test
    func selectionClampCorrectsOverflowValues() async {
        let model = HighlightrEditorView(text: "abc", language: "swift")
        let textView = NSTextView(frame: .zero)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            owner: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )

        model.selection = TextSelection(location: 100, length: 20)
        coordinator.syncViewFromOwner()

        #expect(textView.selectedRange() == NSRange(location: 3, length: 0))
        #expect(model.selection == TextSelection(location: 3, length: 0))
        withExtendedLifetime(coordinator) {}
    }

    @Test
    func modelEditableReflectsIntoTextView() async {
        let model = HighlightrEditorView(text: "abc", language: "swift")
        let textView = NSTextView(frame: .zero)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            owner: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )

        model.isEditable = false
        coordinator.syncViewFromOwner()

        #expect(textView.isEditable == false)
        withExtendedLifetime(coordinator) {}
    }

    @Test
    func languageApplyDeduplicatesRepeatedValues() async {
        let model = HighlightrEditorView(text: "abc", language: "swift")
        let textView = NSTextView(frame: .zero)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            owner: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )

        await AsyncDrain.firstTurn()
        #expect(engine.setLanguageCalls == ["swift"])

        model.language = "swift"
        coordinator.syncViewFromOwner()
        #expect(engine.setLanguageCalls == ["swift"])

        model.language = "json"
        coordinator.syncViewFromOwner()
        #expect(engine.setLanguageCalls == ["swift", "json"])
        withExtendedLifetime(coordinator) {}
    }

    @Test
    func coordinatorReleasesWhileHighlightRenderIsSuspended() async {
        let model = HighlightrEditorView(text: "hello", language: "swift")
        let textView = NSTextView(frame: .zero)
        let engine = SuspendingSyntaxHighlightingEngine()
        weak var weakCoordinator: EditorCoordinator?

        var coordinator: EditorCoordinator? = EditorCoordinator(
            owner: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )
        weakCoordinator = coordinator

        await engine.waitForRenderStart()
        coordinator = nil
        await AsyncDrain.firstTurn()

        #expect(weakCoordinator == nil)
        await engine.resumeRender()
    }

    @Test
    func initDoesNotOverrideCallerProvidedRuntimeFlags() {
        let model = HighlightrEditorView(text: "abc", language: "swift")
        model.isUndoable = true
        model.isRedoable = true

        let textView = NSTextView(frame: .zero)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            owner: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )

        #expect(model.isUndoable)
        #expect(model.isRedoable)
        withExtendedLifetime(coordinator) {}
    }

    @Test
    func undoAvailabilityMirrorsUndoManagerState() async {
        let model = HighlightrEditorView(text: "", language: "swift")
        let textView = NSTextView(frame: .zero)
        textView.allowsUndo = true
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            owner: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )

        await AsyncDrain.firstTurn()
        #expect(model.isUndoable == (textView.undoManager?.canUndo ?? false))
        #expect(model.isRedoable == (textView.undoManager?.canRedo ?? false))

        textView.undoManager?.groupsByEvent = false
        textView.insertText("a", replacementRange: textView.selectedRange())
        coordinator.textDidChange(Notification(name: NSText.didChangeNotification, object: textView))
        await AsyncDrain.firstTurn()

        #expect(model.isUndoable == (textView.undoManager?.canUndo ?? false))
        #expect(model.isRedoable == (textView.undoManager?.canRedo ?? false))

        textView.undoManager?.undo()
        coordinator.textDidChange(Notification(name: NSText.didChangeNotification, object: textView))
        await AsyncDrain.firstTurn()

        #expect(model.isUndoable == (textView.undoManager?.canUndo ?? false))
        #expect(model.isRedoable == (textView.undoManager?.canRedo ?? false))
        withExtendedLifetime(coordinator) {}
    }
}
#endif
