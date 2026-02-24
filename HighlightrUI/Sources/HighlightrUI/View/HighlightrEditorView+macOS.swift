#if canImport(AppKit)
import AppKit
import Observation

@MainActor
@Observable
public final class HighlightrEditorView: NSView {
    public let model: HighlightrModel

    @ObservationIgnored
    let configuration: EditorViewConfiguration
    @ObservationIgnored
    let engine: any SyntaxHighlightingEngine
    @ObservationIgnored
    let adapter: AppKitEditorAdapter
    @ObservationIgnored
    let session: EditorSession
    @ObservationIgnored
    let scrollView: NSScrollView
    @ObservationIgnored
    let platformTextView: NSTextView
    @ObservationIgnored
    let platformTextContainer: NSTextContainer
    @ObservationIgnored
    private var isModelObservationActive = false

    public init(
        model: HighlightrModel,
        configuration: EditorViewConfiguration = .init(),
        engineFactory: @escaping @MainActor () -> any SyntaxHighlightingEngine = { HighlightrEngine() }
    ) {
        self.model = model
        self.configuration = configuration

        let createdEngine = engineFactory()
        self.engine = createdEngine

        let textStorage = createdEngine.makeTextStorage(
            initialLanguage: model.language,
            initialThemeName: model.theme.resolvedThemeName(for: .light)
        )

        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(
            containerSize: NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        )
        self.platformTextContainer = textContainer
        textContainer.widthTracksTextView = configuration.lineWrappingEnabled
        layoutManager.addTextContainer(textContainer)

        let textView = NSTextView(frame: .zero, textContainer: textContainer)
        self.platformTextView = textView
        self.adapter = AppKitEditorAdapter(textView: textView)

        let scrollView = NSScrollView(frame: .zero)
        self.scrollView = scrollView

        self.session = EditorSession(
            model: model,
            adapter: self.adapter,
            engine: createdEngine,
            initialColorScheme: .light
        )

        super.init(frame: .zero)

        configureTextView(textView, textContainer: textContainer)
        configureScrollView(scrollView, textView: textView)
        setupHierarchy()
        startModelStateSync()
        session.applyAppearance(colorScheme: editorColorScheme(from: effectiveAppearance))
        session.syncViewFromModel(syncRuntimeState: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    isolated deinit {
        isModelObservationActive = false
    }

    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        session.syncViewFromModel()
    }

    public override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        session.applyAppearance(colorScheme: editorColorScheme(from: effectiveAppearance))
    }

    public func focus() {
        model.isEditorFocused = true
    }

    public func blur() {
        model.isEditorFocused = false
    }

    func setAutoIndentOnNewline(_ enabled: Bool) {
        session.setAutoIndentOnNewline(enabled)
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
        textView.isEditable = model.isEditable
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

    private func startModelStateSync() {
        isModelObservationActive = true
        observeModelState()
    }

    private func observeModelState() {
        guard isModelObservationActive else { return }

        withObservationTracking {
            _ = model.text
            _ = model.language
            _ = model.theme
            _ = model.selection
            _ = model.isEditable
            _ = model.isEditorFocused
            _ = model.isUndoable
            _ = model.isRedoable
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.isModelObservationActive else { return }
                self.session.syncViewFromModel()
                self.observeModelState()
            }
        }
    }
}
#endif
