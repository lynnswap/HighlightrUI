#if canImport(UIKit)
import HighlightrUICore
import Testing
@testable import HighlightrUI
import UIKit

@MainActor
struct HighlightrEditorViewConfigurationiOSTests {
    @Test
    func initialEngineWiringUsesModelLanguageAndTheme() {
        let model = HighlightrEditorModel(
            text: "print(1)",
            language: "javascript",
            theme: .named("github")
        )
        let engine = MockSyntaxHighlightingEngine()

        _ = HighlightrEditorView(
            model: model,
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
            model: HighlightrEditorModel(language: "swift"),
            configuration: .init(lineWrappingEnabled: true, allowsUndo: true),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        #expect(wrappingView.platformTextView.textContainer.widthTracksTextView == true)

        let noWrapView = HighlightrEditorView(
            model: HighlightrEditorModel(language: "swift"),
            configuration: .init(lineWrappingEnabled: false, allowsUndo: true),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        #expect(noWrapView.platformTextView.textContainer.widthTracksTextView == false)
        #expect(noWrapView.platformTextView.textContainer.lineBreakMode == .byClipping)
    }

    @Test
    func allowsUndoFalseDisablesUndoManager() {
        let view = HighlightrEditorView(
            model: HighlightrEditorModel(language: "swift"),
            configuration: .init(lineWrappingEnabled: false, allowsUndo: false),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        #expect(view.platformTextView.undoManager == nil)
    }

    @Test
    func setInputAccessoryViewAssignsAccessory() {
        let view = HighlightrEditorView(
            model: HighlightrEditorModel(language: "swift"),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        let accessory = UIView(frame: .zero)
        view.setInputAccessoryView(accessory)

        #expect(view.platformTextView.inputAccessoryView === accessory)
    }

    @Test
    func focusAndBlurMirrorModelWhenWindowHosted() async {
        let view = HighlightrEditorView(
            model: HighlightrEditorModel(language: "swift"),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        let host = WindowHost(view: view)
        host.pump()

        view.focus()
        await AsyncDrain.firstTurn()
        host.pump()
        #expect(view.model.isFocused == true)

        view.blur()
        await AsyncDrain.firstTurn()
        host.pump()
        #expect(view.model.isFocused == false)

        _ = host
    }
}
#endif
