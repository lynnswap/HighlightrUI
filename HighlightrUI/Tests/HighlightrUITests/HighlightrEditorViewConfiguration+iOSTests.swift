#if canImport(UIKit)
import Testing
@testable import HighlightrUI
import UIKit

@MainActor
struct HighlightrEditorViewConfigurationiOSTests {
    @Test
    func initialEngineWiringUsesModelLanguageAndTheme() {
        let engine = MockSyntaxHighlightingEngine()

        _ = HighlightrEditorView(
            text: "print(1)",
            language: "javascript",
            theme: .named("github"),
            configuration: .init(),
            engineFactory: { engine }
        )

        #expect(engine.makeTextStorageCalls.count == 1)
        #expect(engine.makeTextStorageCalls.first?.language == "javascript")
        #expect(engine.makeTextStorageCalls.first?.themeName == "github")
    }

    @Test
    func lineWrappingConfigurationChangesTextContainerBehavior() {
        let wrappingView = HighlightrEditorView(
            language: "swift",
            configuration: .init(lineWrappingEnabled: true, allowsUndo: true),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        #expect(wrappingView.platformTextView.textContainer.widthTracksTextView == true)

        let noWrapView = HighlightrEditorView(
            language: "swift",
            configuration: .init(lineWrappingEnabled: false, allowsUndo: true),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        #expect(noWrapView.platformTextView.textContainer.widthTracksTextView == false)
        #expect(noWrapView.platformTextView.textContainer.lineBreakMode == .byClipping)
    }

    @Test
    func allowsUndoFalseDisablesUndoManager() {
        let view = HighlightrEditorView(
            language: "swift",
            configuration: .init(lineWrappingEnabled: false, allowsUndo: false),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        #expect(view.platformTextView.undoManager == nil)
    }

    @Test
    func setInputAccessoryViewAssignsAccessory() {
        let view = HighlightrEditorView(
            language: "swift",
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        let accessory = UIView(frame: .zero)
        view.setInputAccessoryView(accessory)

        #expect(view.platformTextView.inputAccessoryView === accessory)
    }

    @Test
    func focusAndBlurMirrorModelWhenWindowHosted() async {
        let view = HighlightrEditorView(
            language: "swift",
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        let host = WindowHost(view: view)
        host.pump()

        view.focus()
        await AsyncDrain.firstTurn()
        host.pump()
        #expect(view.isEditorFocused == true)

        view.blur()
        await AsyncDrain.firstTurn()
        host.pump()
        #expect(view.isEditorFocused == false)

        _ = host
    }

    @Test
    func focusRequestBeforeWindowAttachAppliesAfterHosting() async {
        let view = HighlightrEditorView(
            language: "swift",
            isEditorFocused: true,
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        await AsyncDrain.firstTurn()
        #expect(view.isEditorFocused == true)
        #expect(view.platformTextView.isFirstResponder == false)

        let host = WindowHost(view: view)
        host.pump()
        await AsyncDrain.firstTurn()
        host.pump()

        #expect(view.isEditorFocused == true)
        #expect(view.platformTextView.isFirstResponder == true)

        _ = host
    }
}
#endif
