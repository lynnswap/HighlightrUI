#if canImport(AppKit)
import AppKit
import HighlightrUICore
import Testing
@testable import HighlightrUI

@MainActor
struct HighlightrEditorViewConfigurationmacOSTests {
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
    func lineWrappingConfigurationUpdatesScrollAndContainer() {
        let wrappingView = HighlightrEditorView(
            model: HighlightrEditorModel(language: "swift"),
            configuration: .init(lineWrappingEnabled: true, allowsUndo: true),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        #expect(wrappingView.platformTextView.isHorizontallyResizable == false)
        #expect(wrappingView.scrollView.hasHorizontalScroller == false)
        #expect(wrappingView.platformTextView.textContainer?.lineBreakMode == .byWordWrapping)

        let noWrapView = HighlightrEditorView(
            model: HighlightrEditorModel(language: "swift"),
            configuration: .init(lineWrappingEnabled: false, allowsUndo: true),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        #expect(noWrapView.platformTextView.isHorizontallyResizable == true)
        #expect(noWrapView.scrollView.hasHorizontalScroller == true)
        #expect(noWrapView.platformTextView.textContainer?.lineBreakMode == .byClipping)
    }

    @Test
    func allowsUndoFlagMirrorsTextViewConfiguration() {
        let disabledUndo = HighlightrEditorView(
            model: HighlightrEditorModel(language: "swift"),
            configuration: .init(lineWrappingEnabled: false, allowsUndo: false),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )
        #expect(disabledUndo.platformTextView.allowsUndo == false)

        let enabledUndo = HighlightrEditorView(
            model: HighlightrEditorModel(language: "swift"),
            configuration: .init(lineWrappingEnabled: false, allowsUndo: true),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )
        #expect(enabledUndo.platformTextView.allowsUndo == true)
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
        #expect(host.window.firstResponder === view.platformTextView)

        view.blur()
        await AsyncDrain.firstTurn()
        host.pump()
        #expect(view.model.isFocused == false)

        _ = host
    }
}
#endif
