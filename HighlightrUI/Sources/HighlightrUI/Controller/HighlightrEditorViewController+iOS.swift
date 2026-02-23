#if canImport(UIKit)
import HighlightrUICore
import UIKit

@MainActor
public final class HighlightrEditorViewController: UIViewController {
    public let editorView: HighlightrEditorView
    public var model: HighlightrEditorModel { editorView.model }

    private let commandExecutor: EditorCommandExecutor
    private let configuration: HighlightrEditorViewControllerConfiguration
    private var toolbarUndoItem: UIBarButtonItem?
    private var toolbarRedoItem: UIBarButtonItem?
    private var toolbarPairsMenuItem: UIBarButtonItem?
    private var toolbarEditMenuItem: UIBarButtonItem?
    private var toolbarFlexibleSpaceItem: UIBarButtonItem?
    private var toolbarDismissItem: UIBarButtonItem?
    private weak var keyboardToolbar: UIToolbar?
    private var toolbarStateSyncTask: Task<Void, Never>?

    public convenience init(
        model: HighlightrEditorModel,
        viewConfiguration: EditorViewConfiguration = .init(),
        controllerConfiguration: HighlightrEditorViewControllerConfiguration = .init(),
        engineFactory: @escaping @MainActor () -> any SyntaxHighlightingEngine = { HighlightrEngine() }
    ) {
        let editorView = HighlightrEditorView(
            model: model,
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

    isolated deinit {
        toolbarStateSyncTask?.cancel()
        toolbarStateSyncTask = nil
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        editorView.setInputAccessoryView(makeKeyboardToolbar())
        startToolbarStateSync()
        registerSizeClassChanges()
        applyToolbarCommandAvailability(currentCommandObservation)
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

    private func makeKeyboardToolbar() -> UIToolbar {
        let toolbar = UIToolbar(frame: .zero)
        let undoItem = makeCommandButton(
            id: "highlightr.keyboard.undo",
            systemName: "arrow.uturn.backward",
            accessibilityLabel: "Undo",
            command: .undo
        )
        let redoItem = makeCommandButton(
            id: "highlightr.keyboard.redo",
            systemName: "arrow.uturn.forward",
            accessibilityLabel: "Redo",
            command: .redo
        )
        let pairsMenuItem = makePairsMenuButton()
        let editMenuItem = makeEditMenuButton()
        let flexibleSpaceItem = UIBarButtonItem(systemItem: .flexibleSpace)
        let dismissItem = makeCommandButton(
            id: "highlightr.keyboard.dismiss",
            systemName: "chevron.down",
            accessibilityLabel: "Dismiss Keyboard",
            command: .dismissKeyboard
        )
        toolbarUndoItem = undoItem
        toolbarRedoItem = redoItem
        toolbarPairsMenuItem = pairsMenuItem
        toolbarEditMenuItem = editMenuItem
        toolbarFlexibleSpaceItem = flexibleSpaceItem
        toolbarDismissItem = dismissItem
        keyboardToolbar = toolbar

        toolbar.items = currentToolbarItems()
        toolbar.sizeToFit()
        return toolbar
    }

    private func makeCommandButton(
        id: String,
        systemName: String,
        accessibilityLabel: String,
        command: HighlightrEditorCommand
    ) -> UIBarButtonItem {
        let item = UIBarButtonItem(
            title: nil,
            image: UIImage(systemName: systemName),
            primaryAction: UIAction { [weak self] _ in
                self?.perform(command)
            },
            menu: nil
        )
        item.accessibilityIdentifier = id
        item.accessibilityLabel = accessibilityLabel
        item.isEnabled = canPerform(command)
        return item
    }

    private func makePairsMenuButton() -> UIBarButtonItem {
        let pairsMenu = UIMenu(
            title: "",
            children: [
                makeMenuAction(title: "()", command: .insertPair(.parentheses)),
                makeMenuAction(title: "{}", command: .insertCurlyBraces),
                makeMenuAction(title: "\"\"", command: .insertPair(.doubleQuote)),
                makeMenuAction(title: "''", command: .insertPair(.singleQuote)),
            ]
        )

        let image = UIImage(systemName: "parentheses") ?? UIImage(systemName: "textformat.abc")
        let item = UIBarButtonItem(
            title: nil,
            image: image,
            primaryAction: nil,
            menu: pairsMenu
        )
        item.accessibilityIdentifier = "highlightr.keyboard.pairsMenu"
        item.accessibilityLabel = "Pairs"
        return item
    }

    private func makeEditMenuButton() -> UIBarButtonItem {
        let editMenu = UIMenu(
            title: "",
            children: [
                makeMenuAction(
                    title: "Delete Current Line",
                    imageSystemName: "delete.left",
                    command: .deleteCurrentLine
                ),
                makeMenuAction(
                    title: "Clear Text",
                    imageSystemName: "eraser",
                    attributes: .destructive,
                    command: .clearText
                ),
            ]
        )

        let item = UIBarButtonItem(
            title: nil,
            image: UIImage(systemName: "eraser"),
            primaryAction: nil,
            menu: editMenu
        )
        item.accessibilityIdentifier = "highlightr.keyboard.editMenu"
        item.accessibilityLabel = "Edit"
        return item
    }

    private func makeMenuAction(
        title: String,
        imageSystemName: String? = nil,
        attributes: UIMenuElement.Attributes = [],
        command: HighlightrEditorCommand
    ) -> UIAction {
        UIAction(
            title: title,
            image: imageSystemName.flatMap(UIImage.init(systemName:)),
            attributes: attributes,
            handler: { [weak self] _ in
                self?.perform(command)
            }
        )
    }

    private var currentCommandObservation: EditorCommandObservation {
        EditorCommandObservation(model: model)
    }

    private func startToolbarStateSync() {
        toolbarStateSyncTask?.cancel()
        let stream = observeCommandInputs(model: model)
        toolbarStateSyncTask = Task { [weak self] in
            for await observation in stream {
                if Task.isCancelled {
                    break
                }
                guard let self else {
                    break
                }
                self.applyToolbarCommandAvailability(observation)
            }
        }
    }

    private func applyToolbarCommandAvailability(_ observation: EditorCommandObservation) {
        toolbarUndoItem?.isEnabled = observation.isEditable && observation.isUndoable
        toolbarRedoItem?.isEnabled = observation.isEditable && observation.isRedoable
        toolbarPairsMenuItem?.isEnabled = observation.isEditable
        toolbarEditMenuItem?.isEnabled = observation.isEditable && observation.hasText
        toolbarDismissItem?.isEnabled = observation.isFocused
        refreshToolbarLayoutIfNeeded()
    }

    private func registerSizeClassChanges() {
        _ = registerForTraitChanges([UITraitHorizontalSizeClass.self]) { (controller: Self, _) in
            controller.applyToolbarCommandAvailability(controller.currentCommandObservation)
        }
    }

    private func currentToolbarItems() -> [UIBarButtonItem] {
        guard
            let undoItem = toolbarUndoItem,
            let pairsMenuItem = toolbarPairsMenuItem,
            let editMenuItem = toolbarEditMenuItem,
            let flexibleSpaceItem = toolbarFlexibleSpaceItem,
            let dismissItem = toolbarDismissItem
        else {
            return []
        }

        var items: [UIBarButtonItem] = [undoItem]
        if let redoItem = toolbarRedoItem {
            items.append(redoItem)
        }
        items.append(contentsOf: [pairsMenuItem, flexibleSpaceItem, editMenuItem, dismissItem])
        return items
    }

    private func refreshToolbarLayoutIfNeeded() {
        guard let toolbar = keyboardToolbar else { return }

        let newItems = currentToolbarItems()
        let currentItems = toolbar.items ?? []
        let needsUpdate = currentItems.count != newItems.count || zip(currentItems, newItems).contains { lhs, rhs in
            lhs !== rhs
        }
        guard needsUpdate else { return }

        toolbar.setItems(newItems, animated: false)
        toolbar.sizeToFit()
        if editorView.platformTextView.isFirstResponder {
            editorView.platformTextView.reloadInputViews()
        }
    }
}
#endif
