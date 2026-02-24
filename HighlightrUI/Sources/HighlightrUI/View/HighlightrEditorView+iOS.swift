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
    let platformTextView: PlatformEditorTextView
    @ObservationIgnored
    private var styleTraitRegistration: UITraitChangeRegistration?
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

        self.coordinator = nil

        super.init(frame: .zero)

        self.coordinator = EditorCoordinator(
            owner: self,
            textView: textView,
            engine: createdEngine,
            initialColorScheme: .light
        )

        configureTextView(textView)
        setupHierarchy()
        registerTraitChanges()
        coordinator.applyAppearance(colorScheme: editorColorScheme(from: traitCollection.userInterfaceStyle))
        coordinator.syncViewFromOwner(syncRuntimeState: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        coordinator.syncViewFromOwner()
    }

    public func focus() {
        isEditorFocused = true
    }

    public func blur() {
        isEditorFocused = false
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
        textView.isEditable = isEditable
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

    func applyPlatformSelectionState(_ selection: TextSelection) {
        performCoordinatorMutation {
            self.selection = selection
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
