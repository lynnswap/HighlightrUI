import Observation
import ObservationsCompat

#if canImport(UIKit)
import UIKit

@MainActor
final class PlatformEditorTextView: UITextView {
    var allowsUndoFeature = true

    override var undoManager: UndoManager? {
        guard allowsUndoFeature else { return nil }
        return super.undoManager
    }
}

typealias PlatformNativeTextView = PlatformEditorTextView
typealias PlatformNativeEditorAdapter = UIKitEditorAdapter
public typealias _HighlightrEditorViewBase = UIView
#elseif canImport(AppKit)
import AppKit

typealias PlatformNativeTextView = NSTextView
typealias PlatformNativeEditorAdapter = AppKitEditorAdapter
public typealias _HighlightrEditorViewBase = NSView
#endif

@MainActor
@Observable
public final class HighlightrEditorView: _HighlightrEditorViewBase {
    public let model: HighlightrModel

    @ObservationIgnored
    let configuration: EditorViewConfiguration
    @ObservationIgnored
    let engine: any SyntaxHighlightingEngine
    @ObservationIgnored
    let adapter: PlatformNativeEditorAdapter
    @ObservationIgnored
    let session: EditorSession
    @ObservationIgnored
    let platformTextView: PlatformNativeTextView

#if canImport(AppKit)
    @ObservationIgnored
    let scrollView: NSScrollView
    @ObservationIgnored
    let platformTextContainer: NSTextContainer
#endif

#if canImport(UIKit)
    @ObservationIgnored
    private var styleTraitRegistration: UITraitChangeRegistration?
#endif

    @ObservationIgnored
    private var modelObservationTask: Task<Void, Never>?

    public init(
        model: HighlightrModel,
        configuration: EditorViewConfiguration = .init(),
        engineFactory: @escaping @MainActor () -> any SyntaxHighlightingEngine = { HighlightrEngine() }
    ) {
        self.model = model
        self.configuration = configuration

        let createdEngine = engineFactory()
        self.engine = createdEngine

#if canImport(UIKit)
        let textStorage = createdEngine.makeTextStorage(
            initialLanguage: model.language,
            initialThemeName: model.theme.resolvedThemeName(for: .light)
        )

        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(size: .zero)
        textContainer.widthTracksTextView = configuration.lineWrappingEnabled
        if !configuration.lineWrappingEnabled {
            textContainer.size = CGSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            )
        }
        layoutManager.addTextContainer(textContainer)

        let textView = PlatformEditorTextView(frame: .zero, textContainer: textContainer)
        self.platformTextView = textView

        let platformAdapter = UIKitEditorAdapter(textView: textView)
        self.adapter = platformAdapter

        self.session = EditorSession(
            model: model,
            adapter: platformAdapter,
            engine: createdEngine,
            initialColorScheme: .light
        )
#elseif canImport(AppKit)
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

        let platformAdapter = AppKitEditorAdapter(textView: textView)
        self.adapter = platformAdapter

        let scrollView = NSScrollView(frame: .zero)
        self.scrollView = scrollView

        self.session = EditorSession(
            model: model,
            adapter: platformAdapter,
            engine: createdEngine,
            initialColorScheme: .light
        )
#endif

        super.init(frame: .zero)

#if canImport(UIKit)
        configureTextView(platformTextView)
        registerTraitChanges()
        session.applyAppearance(colorScheme: editorColorScheme(from: traitCollection.userInterfaceStyle))
#elseif canImport(AppKit)
        configureTextView(platformTextView, textContainer: platformTextContainer)
        configureScrollView(scrollView, textView: platformTextView)
        session.applyAppearance(colorScheme: editorColorScheme(from: effectiveAppearance))
#endif

        setupHierarchy()
        startModelStateSync()
        session.syncViewFromModel(syncRuntimeState: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    isolated deinit {
        modelObservationTask?.cancel()
    }

#if canImport(UIKit)
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        session.syncViewFromModel()
    }
#elseif canImport(AppKit)
    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        session.syncViewFromModel()
    }

    public override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        session.applyAppearance(colorScheme: editorColorScheme(from: effectiveAppearance))
    }
#endif

    public func focus() {
        model.isEditorFocused = true
        session.syncViewFromModel()
    }

    public func blur() {
        model.isEditorFocused = false
        session.syncViewFromModel()
    }

#if canImport(UIKit)
    func setInputAccessoryView(_ view: UIView?) {
        platformTextView.inputAccessoryView = view
        if platformTextView.isFirstResponder {
            platformTextView.reloadInputViews()
        }
    }
#endif

    func setAutoIndentOnNewline(_ enabled: Bool) {
        session.setAutoIndentOnNewline(enabled)
    }

    private func setupHierarchy() {
#if canImport(UIKit)
        addSubview(platformTextView)
        platformTextView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            platformTextView.leadingAnchor.constraint(equalTo: leadingAnchor),
            platformTextView.trailingAnchor.constraint(equalTo: trailingAnchor),
            platformTextView.topAnchor.constraint(equalTo: topAnchor),
            platformTextView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
#elseif canImport(AppKit)
        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
#endif
    }

#if canImport(UIKit)
    private func configureTextView(_ textView: UITextView) {
        textView.backgroundColor = .clear
        textView.alwaysBounceVertical = true
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        textView.smartInsertDeleteType = .no
        textView.spellCheckingType = .no
        textView.keyboardDismissMode = .interactive
        textView.isEditable = model.isEditable
        textView.isScrollEnabled = true

        if configuration.lineWrappingEnabled {
            textView.textContainer.widthTracksTextView = true
            textView.textContainer.lineBreakMode = .byWordWrapping
        } else {
            textView.textContainer.widthTracksTextView = false
            textView.textContainer.size = CGSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            )
            textView.textContainer.lineBreakMode = .byClipping
        }

        if let textView = textView as? PlatformEditorTextView {
            textView.allowsUndoFeature = configuration.allowsUndo
        }
    }

    private func registerTraitChanges() {
        styleTraitRegistration = registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: Self, _) in
            view.session.applyAppearance(
                colorScheme: editorColorScheme(from: view.traitCollection.userInterfaceStyle)
            )
        }
    }
#elseif canImport(AppKit)
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
#endif

    private func startModelStateSync() {
        modelObservationTask?.cancel()
        let observedModel = model
        let stream = ObservationsCompat(backend: .automatic) {
            HighlightrModelObservationSnapshot(
                text: observedModel.text,
                language: observedModel.language,
                theme: observedModel.theme,
                selection: observedModel.selection,
                isEditable: observedModel.isEditable,
                isEditorFocused: observedModel.isEditorFocused,
                isUndoable: observedModel.isUndoable,
                isRedoable: observedModel.isRedoable
            )
        }
        modelObservationTask = Task { @MainActor [weak self] in
            for await _ in stream {
                if Task.isCancelled {
                    break
                }
                guard let self else {
                    break
                }
                self.session.syncViewFromModel()
            }
        }
    }
}
