#if canImport(AppKit)
import AppKit

@MainActor
public final class HighlightrEditorViewController: NSViewController {
    public let editorView: HighlightrEditorView

    public init(editorView: HighlightrEditorView) {
        self.editorView = editorView
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = editorView
    }
}
#endif
