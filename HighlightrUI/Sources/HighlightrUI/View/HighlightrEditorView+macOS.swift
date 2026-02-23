#if canImport(AppKit)
import AppKit
import HighlightrUICore

@MainActor
public final class HighlightrEditorView: NSView {
    public let model: HighlightrEditorModel

    let configuration: EditorViewConfiguration
    let engine: any SyntaxHighlightingEngine
    let coordinator: EditorCoordinator
    let scrollView: NSScrollView
    let platformTextView: NSTextView

    public init(
        model: HighlightrEditorModel,
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
        textContainer.widthTracksTextView = configuration.lineWrappingEnabled
        layoutManager.addTextContainer(textContainer)

        let textView = NSTextView(frame: .zero, textContainer: textContainer)
        self.platformTextView = textView

        let scrollView = NSScrollView(frame: .zero)
        self.scrollView = scrollView

        self.coordinator = EditorCoordinator(
            model: model,
            textView: textView,
            engine: createdEngine,
            initialColorScheme: .light
        )

        super.init(frame: .zero)

        configureTextView(textView, textContainer: textContainer)
        configureScrollView(scrollView, textView: textView)
        setupHierarchy()
        coordinator.applyAppearance(colorScheme: editorColorScheme(from: effectiveAppearance))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        coordinator.applyAppearance(colorScheme: editorColorScheme(from: effectiveAppearance))
    }

    public func focus() {
        _ = window?.makeFirstResponder(platformTextView)
        coordinator.syncStateFromView(focusOverride: window?.firstResponder === platformTextView)
    }

    public func blur() {
        _ = window?.makeFirstResponder(nil)
        coordinator.syncStateFromView(focusOverride: window?.firstResponder === platformTextView)
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
}
#endif
