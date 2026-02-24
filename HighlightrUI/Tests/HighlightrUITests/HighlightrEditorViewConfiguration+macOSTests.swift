#if canImport(AppKit)
import AppKit
import Testing
@testable import HighlightrUI

private final class BlurRejectingWindow: NSWindow {
    var rejectsBlurRequest = false

    override func makeFirstResponder(_ responder: NSResponder?) -> Bool {
        if rejectsBlurRequest, responder == nil {
            return false
        }
        return super.makeFirstResponder(responder)
    }
}

@MainActor
struct HighlightrEditorViewConfigurationmacOSTests {
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
    func lineWrappingConfigurationUpdatesScrollAndContainer() {
        let wrappingView = HighlightrEditorView(
            language: "swift",
            configuration: .init(lineWrappingEnabled: true, allowsUndo: true),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        #expect(wrappingView.platformTextView.isHorizontallyResizable == false)
        #expect(wrappingView.scrollView.hasHorizontalScroller == false)
        #expect(wrappingView.platformTextContainer.lineBreakMode == .byWordWrapping)

        let noWrapView = HighlightrEditorView(
            language: "swift",
            configuration: .init(lineWrappingEnabled: false, allowsUndo: true),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        #expect(noWrapView.platformTextView.isHorizontallyResizable == true)
        #expect(noWrapView.scrollView.hasHorizontalScroller == true)
        #expect(noWrapView.platformTextContainer.lineBreakMode == .byClipping)
    }

    @Test
    func allowsUndoFlagMirrorsTextViewConfiguration() {
        let disabledUndo = HighlightrEditorView(
            language: "swift",
            configuration: .init(lineWrappingEnabled: false, allowsUndo: false),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )
        #expect(disabledUndo.platformTextView.allowsUndo == false)

        let enabledUndo = HighlightrEditorView(
            language: "swift",
            configuration: .init(lineWrappingEnabled: false, allowsUndo: true),
            engineFactory: { MockSyntaxHighlightingEngine() }
        )
        #expect(enabledUndo.platformTextView.allowsUndo == true)
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
        #expect(host.window.firstResponder === view.platformTextView)

        view.blur()
        await AsyncDrain.firstTurn()
        host.pump()
        #expect(view.isEditorFocused == false)
        #expect(host.window.firstResponder !== view.platformTextView)

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

        let host = WindowHost(view: view)
        host.pump()
        await AsyncDrain.firstTurn()
        host.pump()

        #expect(view.isEditorFocused == true)
        #expect(host.window.firstResponder === view.platformTextView)

        _ = host
    }

    @Test
    func blurRequestFailureKeepsModelFocusSynchronizedWithResponderState() async {
        let view = HighlightrEditorView(
            language: "swift",
            engineFactory: { MockSyntaxHighlightingEngine() }
        )

        let frame = NSRect(x: 0, y: 0, width: 960, height: 640)
        let window = BlurRejectingWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        let host = WindowHost(view: view, window: window)
        host.pump()

        view.focus()
        await AsyncDrain.firstTurn()
        host.pump()
        #expect(window.firstResponder === view.platformTextView)
        #expect(view.isEditorFocused == true)

        window.rejectsBlurRequest = true
        view.blur()
        await AsyncDrain.firstTurn()
        host.pump()

        #expect(window.firstResponder === view.platformTextView)
        #expect(view.isEditorFocused == true)

        _ = host
    }
}
#endif
