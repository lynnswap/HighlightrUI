#if canImport(AppKit)
import AppKit
import Observation

@MainActor
@Observable
public final class HighlightrEditorViewController: NSViewController {
    public let editorView: HighlightrEditorView

    @ObservationIgnored
    private let commandExecutor: EditorCommandExecutor
    @ObservationIgnored
    private let configuration: HighlightrEditorViewControllerConfiguration

    public convenience init(
        text: String = "",
        language: EditorLanguage,
        theme: EditorTheme = .automatic(light: "paraiso-light", dark: "paraiso-dark"),
        selection: TextSelection = .zero,
        isEditable: Bool = true,
        isEditorFocused: Bool = false,
        isUndoable: Bool = false,
        isRedoable: Bool = false,
        viewConfiguration: EditorViewConfiguration = .init(),
        controllerConfiguration: HighlightrEditorViewControllerConfiguration = .init(),
        engineFactory: @escaping @MainActor () -> any SyntaxHighlightingEngine = { HighlightrEngine() }
    ) {
        let editorView = HighlightrEditorView(
            text: text,
            language: language,
            theme: theme,
            selection: selection,
            isEditable: isEditable,
            isEditorFocused: isEditorFocused,
            isUndoable: isUndoable,
            isRedoable: isRedoable,
            configuration: viewConfiguration,
            engineFactory: engineFactory
        )
        self.init(editorView: editorView, configuration: controllerConfiguration)
    }

    public init(
        editorView: HighlightrEditorView,
        configuration: HighlightrEditorViewControllerConfiguration = .init()
    ) {
        self.editorView = editorView
        self.commandExecutor = EditorCommandExecutor(editorView: editorView)
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
        self.editorView.setAutoIndentOnNewline(configuration.autoIndentOnNewline)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = editorView
    }

    public func perform(_ command: HighlightrEditorCommand) {
        commandExecutor.perform(command)
    }

    public func canPerform(_ command: HighlightrEditorCommand) -> Bool {
        commandExecutor.canPerform(command)
    }
}
#endif
