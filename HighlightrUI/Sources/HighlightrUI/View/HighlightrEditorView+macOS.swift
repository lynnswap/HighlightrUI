#if canImport(AppKit)
import AppKit
import Observation

@MainActor
@Observable
public final class HighlightrEditorView: NSView {
    public var text: String {
        didSet { synchronizeFromOwnerState() }
    }
    public var language: EditorLanguage {
        didSet { synchronizeFromOwnerState() }
    }
    public var theme: EditorTheme {
        didSet { synchronizeFromOwnerState() }
    }
    public var selection: TextSelection {
        didSet { synchronizeFromOwnerState() }
    }
    public var isEditable: Bool {
        didSet { synchronizeFromOwnerState() }
    }
    public var isEditorFocused: Bool {
        didSet { synchronizeFromOwnerState() }
    }
    public var isUndoable: Bool
    public var isRedoable: Bool
    public var hasText: Bool { !text.isEmpty }

    @ObservationIgnored
    let configuration: EditorViewConfiguration
    @ObservationIgnored
    let engine: any SyntaxHighlightingEngine
    @ObservationIgnored
    var coordinator: EditorCoordinator!
    @ObservationIgnored
    let scrollView: NSScrollView
    @ObservationIgnored
    let platformTextView: NSTextView
    @ObservationIgnored
    private var isApplyingCoordinatorState = false

    public init(
        text: String = "",
        language: EditorLanguage,
        theme: EditorTheme = .automatic(light: "paraiso-light", dark: "paraiso-dark"),
        selection: TextSelection = .zero,
        isEditable: Bool = true,
        isEditorFocused: Bool = false,
        isUndoable: Bool = false,
        isRedoable: Bool = false,
        configuration: EditorViewConfiguration = .init(),
        engineFactory: @escaping @MainActor () -> any SyntaxHighlightingEngine = { HighlightrEngine() }
    ) {
        self.text = text
        self.language = language
        self.theme = theme
        self.selection = selection
        self.isEditable = isEditable
        self.isEditorFocused = isEditorFocused
        self.isUndoable = isUndoable
        self.isRedoable = isRedoable
        self.configuration = configuration

        let createdEngine = engineFactory()
        self.engine = createdEngine

        let textStorage = createdEngine.makeTextStorage(
            initialLanguage: language,
            initialThemeName: theme.resolvedThemeName(for: .light)
        )

        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(
            containerSize: NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        )
        textContainer.widthTracksTextView = configuration.lineWrappingEnabled
        layoutManager.addTextContainer(textContainer)

        let textView = NSTextView(frame: .zero, textContainer: textContainer)
        self.platformTextView = textView

        let scrollView = NSScrollView(frame: .zero)
        self.scrollView = scrollView

        self.coordinator = nil

        super.init(frame: .zero)

        self.coordinator = EditorCoordinator(
            owner: self,
            textView: textView,
            engine: createdEngine,
            initialColorScheme: .light
        )

        configureTextView(textView, textContainer: textContainer)
        configureScrollView(scrollView, textView: textView)
        setupHierarchy()
        coordinator.applyAppearance(colorScheme: editorColorScheme(from: effectiveAppearance))
        coordinator.syncViewFromOwner(syncRuntimeState: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        coordinator.syncViewFromOwner()
    }

    public override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        coordinator.applyAppearance(colorScheme: editorColorScheme(from: effectiveAppearance))
    }

    public func focus() {
        isEditorFocused = true
    }

    public func blur() {
        isEditorFocused = false
    }

    func setAutoIndentOnNewline(_ enabled: Bool) {
        coordinator.setAutoIndentOnNewline(enabled)
    }

    private func setupHierarchy() {
        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func configureScrollView(_ scrollView: NSScrollView, textView: NSTextView) {
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = !configuration.lineWrappingEnabled
        scrollView.autohidesScrollers = true
        scrollView.documentView = textView
    }

    private func configureTextView(_ textView: NSTextView, textContainer: NSTextContainer) {
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.allowsUndo = configuration.allowsUndo
        textView.isEditable = isEditable
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false

        if configuration.lineWrappingEnabled {
            textView.isHorizontallyResizable = false
            textContainer.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
            textContainer.lineBreakMode = .byWordWrapping
        } else {
            textView.isHorizontallyResizable = true
            textContainer.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            textContainer.lineBreakMode = .byClipping
        }

        textView.isVerticallyResizable = true
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    }

    private func synchronizeFromOwnerState() {
        guard !isApplyingCoordinatorState else { return }
        coordinator.syncViewFromOwner()
    }

    func applyPlatformDocumentState(
        text: String,
        selection: TextSelection,
        isEditable: Bool
    ) {
        performCoordinatorMutation {
            self.text = text
            self.selection = selection
            self.isEditable = isEditable
        }
    }

    func applyPlatformRuntimeState(
        isEditorFocused: Bool,
        isUndoable: Bool,
        isRedoable: Bool
    ) {
        performCoordinatorMutation {
            self.isEditorFocused = isEditorFocused
            self.isUndoable = isUndoable
            self.isRedoable = isRedoable
        }
    }

    private func performCoordinatorMutation(_ updates: () -> Void) {
        guard !isApplyingCoordinatorState else {
            updates()
            return
        }
        isApplyingCoordinatorState = true
        updates()
        isApplyingCoordinatorState = false
    }
}
#endif
