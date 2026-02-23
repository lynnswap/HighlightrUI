#if canImport(UIKit)
import UIKit
import HighlightrUICore

@MainActor
final class PlatformEditorTextView: UITextView {
    var allowsUndoFeature = true

    override var undoManager: UndoManager? {
        guard allowsUndoFeature else { return nil }
        return super.undoManager
    }
}

@MainActor
public final class HighlightrEditorView: UIView {
    public let model: HighlightrEditorModel

    let configuration: EditorViewConfiguration
    let engine: any SyntaxHighlightingEngine
    let coordinator: EditorCoordinator
    let platformTextView: PlatformEditorTextView
    private var styleTraitRegistration: UITraitChangeRegistration?

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

        self.coordinator = EditorCoordinator(
            model: model,
            textView: textView,
            engine: createdEngine,
            initialColorScheme: .light
        )

        super.init(frame: .zero)

        configureTextView(textView)
        setupHierarchy()
        registerTraitChanges()
        coordinator.applyAppearance(colorScheme: editorColorScheme(from: traitCollection.userInterfaceStyle))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        coordinator.syncViewFromModel()
    }

    public func focus() {
        _ = platformTextView.becomeFirstResponder()
        coordinator.syncStateFromView(focusOverride: true)
    }

    public func blur() {
        _ = platformTextView.resignFirstResponder()
        coordinator.syncStateFromView(focusOverride: platformTextView.isFirstResponder)
    }

    func setInputAccessoryView(_ view: UIView?) {
        platformTextView.inputAccessoryView = view
        if platformTextView.isFirstResponder {
            platformTextView.reloadInputViews()
        }
    }

    func setAutoIndentOnNewline(_ enabled: Bool) {
        coordinator.setAutoIndentOnNewline(enabled)
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
            view.coordinator.applyAppearance(
                colorScheme: editorColorScheme(from: view.traitCollection.userInterfaceStyle)
            )
        }
    }
}
#endif
