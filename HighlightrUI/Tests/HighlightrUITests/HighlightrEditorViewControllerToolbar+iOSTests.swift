#if canImport(UIKit)
import Foundation
import Testing
@testable import HighlightrUI
import UIKit

@MainActor
struct HighlightrEditorViewControllerToolbariOSTests {
    @Test
    func controllerInstallsFixedKeyboardToolbar() {
        let controller = HighlightrEditorViewController(
            editorView: HighlightrEditorView(language: "swift"),
        )

        controller.loadViewIfNeeded()

        let toolbar = controller.editorView.platformTextView.inputAccessoryView as? UIToolbar
        #expect(toolbar != nil)

        let items = toolbar?.items ?? []
        #expect(items.count == 6)
        #expect(items[0].accessibilityIdentifier == "highlightr.keyboard.undo")
        #expect(items[1].accessibilityIdentifier == "highlightr.keyboard.redo")
        #expect(items[2].accessibilityIdentifier == "highlightr.keyboard.pairsMenu")
        #expect(items[4].accessibilityIdentifier == "highlightr.keyboard.editMenu")
        #expect(items[5].accessibilityIdentifier == "highlightr.keyboard.dismiss")

        let pairsItem = items.first(where: { $0.accessibilityIdentifier == "highlightr.keyboard.pairsMenu" })
        #expect(pairsItem?.menu != nil)
        #expect(pairsItem?.menu?.title == "")
        let pairTitles = pairsItem?.menu?.children.compactMap { ($0 as? UIAction)?.title } ?? []
        #expect(pairTitles == ["()", "{}", "\"\"", "''"])

        let editItem = items.first(where: { $0.accessibilityIdentifier == "highlightr.keyboard.editMenu" })
        #expect(editItem?.menu != nil)
        let editActionTitles = editItem?.menu?.children
            .compactMap { ($0 as? UIAction)?.title } ?? []
        let expectedEditActionTitles = [
            highlightrLocalized("editor.menu.deleteCurrentLine"),
            highlightrLocalized("editor.menu.clearText"),
        ]
        #expect(editActionTitles == expectedEditActionTitles)
    }

    @Test
    func undoRedoButtonsReflectUndoAvailability() async {
        let model = HighlightrEditorView(language: "swift")
        let controller = HighlightrEditorViewController(
            editorView: model,
        )

        controller.loadViewIfNeeded()
        controller.editorView.platformTextView.undoManager?.groupsByEvent = false

        let toolbar = controller.editorView.platformTextView.inputAccessoryView as? UIToolbar
        let items = toolbar?.items ?? []
        guard
            let undoItem = items.first(where: { $0.accessibilityIdentifier == "highlightr.keyboard.undo" }),
            let redoItem = items.first(where: { $0.accessibilityIdentifier == "highlightr.keyboard.redo" })
        else {
            Issue.record("Undo/Redo toolbar items were not found.")
            return
        }

        #expect(!undoItem.isEnabled)
        #expect(!redoItem.isEnabled)
        #expect(!model.isUndoable)
        #expect(!model.isRedoable)

        controller.perform(.insertIndent)
        await AsyncDrain.firstTurn()

        #expect(undoItem.isEnabled)
        #expect(!redoItem.isEnabled)
        #expect(model.isUndoable)
        #expect(!model.isRedoable)

        controller.perform(.undo)
        await AsyncDrain.firstTurn()

        #expect(!undoItem.isEnabled)
        #expect(redoItem.isEnabled)
        #expect(!model.isUndoable)
        #expect(model.isRedoable)
    }

    @Test
    func editMenuReflectsExternalModelChangesAfterViewSync() async {
        let model = HighlightrEditorView(text: "abc", language: "swift")
        let controller = HighlightrEditorViewController(
            editorView: model,
        )

        controller.loadViewIfNeeded()

        let toolbar = controller.editorView.platformTextView.inputAccessoryView as? UIToolbar
        let editItem = toolbar?.items?.first(where: { $0.accessibilityIdentifier == "highlightr.keyboard.editMenu" })
        #expect(editItem != nil)
        #expect(editItem?.isEnabled == true)

        model.text = ""
        await AsyncDrain.firstTurn()
        #expect(editItem?.isEnabled == false)

        model.text = "z"
        await AsyncDrain.firstTurn()
        #expect(editItem?.isEnabled == true)

        model.isEditable = false
        await AsyncDrain.firstTurn()
        #expect(editItem?.isEnabled == false)
    }

    @Test
    func redoButtonAlwaysVisibleInCompactAndTracksEnabledState() async {
        let controller = HighlightrEditorViewController(
            editorView: HighlightrEditorView(language: "swift"),
        )
        let container = UIViewController()
        container.addChild(controller)
        container.view.addSubview(controller.view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            controller.view.leadingAnchor.constraint(equalTo: container.view.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: container.view.trailingAnchor),
            controller.view.topAnchor.constraint(equalTo: container.view.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: container.view.bottomAnchor),
        ])
        controller.didMove(toParent: container)
        controller.traitOverrides.horizontalSizeClass = .compact

        let host = WindowHost(view: container.view)
        host.pump()

        #expect(controller.traitCollection.horizontalSizeClass == .compact)
        controller.editorView.platformTextView.undoManager?.groupsByEvent = false
        let toolbar = controller.editorView.platformTextView.inputAccessoryView as? UIToolbar
        #expect(toolbar != nil)
        #expect(hasRedoButton(in: toolbar))
        #expect(redoButton(in: toolbar)?.isEnabled == false)

        controller.perform(.insertIndent)
        await AsyncDrain.firstTurn()
        host.pump()
        #expect(hasRedoButton(in: toolbar))
        #expect(redoButton(in: toolbar)?.isEnabled == false)

        controller.perform(.undo)
        await AsyncDrain.firstTurn()
        host.pump()
        #expect(hasRedoButton(in: toolbar))
        #expect(redoButton(in: toolbar)?.isEnabled == true)

        controller.perform(.redo)
        await AsyncDrain.firstTurn()
        host.pump()
        #expect(hasRedoButton(in: toolbar))
        #expect(redoButton(in: toolbar)?.isEnabled == false)
    }

    @Test
    func controllerReleasesAfterToolbarObservationSetup() async {
        weak var releasedController: HighlightrEditorViewController?

        do {
            let model = HighlightrEditorView(language: "swift")
            var controller: HighlightrEditorViewController? = HighlightrEditorViewController(
                editorView: model,
            )
            controller?.loadViewIfNeeded()
            releasedController = controller
            controller = nil
        }

        await AsyncDrain.firstTurn()
        #expect(releasedController == nil)
    }

    private func hasRedoButton(in toolbar: UIToolbar?) -> Bool {
        toolbar?.items?.contains(where: { $0.accessibilityIdentifier == "highlightr.keyboard.redo" }) == true
    }

    private func redoButton(in toolbar: UIToolbar?) -> UIBarButtonItem? {
        toolbar?.items?.first(where: { $0.accessibilityIdentifier == "highlightr.keyboard.redo" })
    }
}
#endif
