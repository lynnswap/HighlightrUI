#if canImport(UIKit)
import Testing
@testable import HighlightrUI
import UIKit

@MainActor
struct HighlightrEditorViewConfigurationiOSTests {
    @Test
    func initialEngineWiringUsesModelLanguageAndTheme() {
        let engine = MockSyntaxHighlightingEngine()

        _ = makeEditorView(
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
        let wrappingView = makeEditorView(
            language: "swift",
            configuration: .init(lineWrappingEnabled: true, allowsUndo: true),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        #expect(wrappingView.platformTextView.textContainer.widthTracksTextView == true)

        let noWrapView = makeEditorView(
            language: "swift",
            configuration: .init(lineWrappingEnabled: false, allowsUndo: true),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        #expect(noWrapView.platformTextView.textContainer.widthTracksTextView == false)
        #expect(noWrapView.platformTextView.textContainer.lineBreakMode == .byClipping)
    }

    @Test
    func allowsUndoFalseDisablesUndoManager() {
        let view = makeEditorView(
            language: "swift",
            configuration: .init(lineWrappingEnabled: false, allowsUndo: false),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        #expect(view.platformTextView.undoManager == nil)
    }

    @Test
    func setInputAccessoryViewAssignsAccessory() {
        let view = makeEditorView(
            language: "swift",
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        let accessory = UIView(frame: .zero)
        view.setInputAccessoryView(accessory)

        #expect(view.platformTextView.inputAccessoryView === accessory)
    }

    @Test
    func focusAndBlurMirrorModelWhenWindowHosted() async {
        let view = makeEditorView(
            language: "swift",
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        let host = WindowHost(view: view)
        host.pump()

        view.focus()
        await AsyncDrain.firstTurn()
        host.pump()
        #expect(view.model.isEditorFocused == true)

        view.blur()
        await AsyncDrain.firstTurn()
        host.pump()
        #expect(view.model.isEditorFocused == false)

        _ = host
    }

    @Test
    func focusRequestBeforeWindowAttachAppliesAfterHosting() async {
        let view = makeEditorView(
            language: "swift",
            isEditorFocused: true,
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        await AsyncDrain.firstTurn()
        #expect(view.model.isEditorFocused == true)
        #expect(view.platformTextView.isFirstResponder == false)

        let host = WindowHost(view: view)
        host.pump()
        await AsyncDrain.firstTurn()
        host.pump()

        #expect(view.model.isEditorFocused == true)
        #expect(view.platformTextView.isFirstResponder == true)

        _ = host
    }

    @Test
    func viewReleasesAfterModelObservationSetup() async {
        weak var releasedView: HighlightrEditorView?

        do {
            var view: HighlightrEditorView? = makeEditorView(
                language: "swift",
                engineFactory: { MockSyntaxHighlightingEngine() }
            )
            releasedView = view
            view = nil
        }

        await AsyncDrain.firstTurn()
        #expect(releasedView == nil)
    }
}
#endif
