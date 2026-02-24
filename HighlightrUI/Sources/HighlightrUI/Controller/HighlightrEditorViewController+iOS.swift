#if canImport(UIKit)
import Observation
import ObservationsCompat
import UIKit

@MainActor
@Observable
public final class HighlightrEditorViewController: UIViewController {
    public let model: HighlightrModel
    public let editorView: HighlightrEditorView

    @ObservationIgnored
    private let commandExecutor: EditorCommandExecutor
    @ObservationIgnored
    private let configuration: HighlightrEditorViewControllerConfiguration
    @ObservationIgnored
    private var toolbarUndoItem: UIBarButtonItem?
    @ObservationIgnored
    private var toolbarRedoItem: UIBarButtonItem?
    @ObservationIgnored
    private var toolbarPairsMenuItem: UIBarButtonItem?
    @ObservationIgnored
    private var toolbarEditMenuItem: UIBarButtonItem?
    @ObservationIgnored
    private var toolbarFlexibleSpaceItem: UIBarButtonItem?
    @ObservationIgnored
    private var toolbarDismissItem: UIBarButtonItem?
    @ObservationIgnored
    private weak var keyboardToolbar: UIToolbar?
    @ObservationIgnored
    private var sizeClassTraitRegistration: UITraitChangeRegistration?
    @ObservationIgnored
    private var toolbarObservationTask: Task<Void, Never>?

    private struct ToolbarObservationSnapshot: Equatable, Sendable {
        let text: String
        let isEditable: Bool
        let isEditorFocused: Bool
        let isUndoable: Bool
        let isRedoable: Bool
    }

    public convenience init(
        model: HighlightrModel,
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
        self.model = editorView.model
        self.editorView = editorView
        self.commandExecutor = EditorCommandExecutor(editorView: editorView)
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
        self.editorView.setAutoIndentOnNewline(configuration.autoIndentOnNewline)
    }

    isolated deinit {
        toolbarObservationTask?.cancel()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        editorView.setInputAccessoryView(makeKeyboardToolbar())
        startToolbarStateSync()
        registerSizeClassChanges()
        applyToolbarCommandAvailability()
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
                    title: highlightrLocalized("editor.menu.deleteCurrentLine"),
                    imageSystemName: "delete.left",
                    command: .deleteCurrentLine
                ),
                makeMenuAction(
                    title: highlightrLocalized("editor.menu.clearText"),
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

    private func startToolbarStateSync() {
        toolbarObservationTask?.cancel()
        let observedModel = model
        let stream = ObservationsCompat(backend: .automatic) {
            ToolbarObservationSnapshot(
                text: observedModel.text,
                isEditable: observedModel.isEditable,
                isEditorFocused: observedModel.isEditorFocused,
                isUndoable: observedModel.isUndoable,
                isRedoable: observedModel.isRedoable
            )
        }
        toolbarObservationTask = Task { @MainActor [weak self] in
            for await _ in stream {
                if Task.isCancelled {
                    break
                }
                guard let self else {
                    break
                }
                self.applyToolbarCommandAvailability()
            }
        }
    }

    private func applyToolbarCommandAvailability() {
        toolbarUndoItem?.isEnabled = model.isEditable && model.isUndoable
        toolbarRedoItem?.isEnabled = model.isEditable && model.isRedoable
        toolbarPairsMenuItem?.isEnabled = model.isEditable
        toolbarEditMenuItem?.isEnabled = model.isEditable && model.hasText
        toolbarDismissItem?.isEnabled = model.isEditorFocused
        refreshToolbarLayoutIfNeeded()
    }

    private func registerSizeClassChanges() {
        sizeClassTraitRegistration = registerForTraitChanges([UITraitHorizontalSizeClass.self]) { (controller: Self, _) in
            controller.applyToolbarCommandAvailability()
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
