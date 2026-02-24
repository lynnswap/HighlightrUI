#if canImport(UIKit)
import Observation
import UIKit

@MainActor
final class PlatformEditorTextView: UITextView {
    var allowsUndoFeature = true

    override var undoManager: UndoManager? {
        guard allowsUndoFeature else { return nil }
        return super.undoManager
    }
}

@MainActor
@Observable
public final class HighlightrEditorView: UIView {
    public let model: HighlightrModel

    @ObservationIgnored
    let configuration: EditorViewConfiguration
    @ObservationIgnored
    let engine: any SyntaxHighlightingEngine
    @ObservationIgnored
    let adapter: UIKitEditorAdapter
    @ObservationIgnored
    let session: EditorSession
    @ObservationIgnored
    let platformTextView: PlatformEditorTextView
    @ObservationIgnored
    private var styleTraitRegistration: UITraitChangeRegistration?
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
        self.adapter = UIKitEditorAdapter(textView: textView)
        self.session = EditorSession(
            model: model,
            adapter: self.adapter,
            engine: createdEngine,
            initialColorScheme: .light
        )

        super.init(frame: .zero)

        configureTextView(textView)
        setupHierarchy()
        registerTraitChanges()
        startModelStateSync()
        session.applyAppearance(colorScheme: editorColorScheme(from: traitCollection.userInterfaceStyle))
        session.syncViewFromModel(syncRuntimeState: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    isolated deinit {
        isModelObservationActive = false
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        session.syncViewFromModel()
    }

    public func focus() {
        model.isEditorFocused = true
    }

    public func blur() {
        model.isEditorFocused = false
    }

    func setInputAccessoryView(_ view: UIView?) {
        platformTextView.inputAccessoryView = view
        if platformTextView.isFirstResponder {
            platformTextView.reloadInputViews()
        }
    }

    func setAutoIndentOnNewline(_ enabled: Bool) {
        session.setAutoIndentOnNewline(enabled)
    }

    private func setupHierarchy() {
        addSubview(platformTextView)
        platformTextView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            platformTextView.leadingAnchor.constraint(equalTo: leadingAnchor),
            platformTextView.trailingAnchor.constraint(equalTo: trailingAnchor),
            platformTextView.topAnchor.constraint(equalTo: topAnchor),
            platformTextView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

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
