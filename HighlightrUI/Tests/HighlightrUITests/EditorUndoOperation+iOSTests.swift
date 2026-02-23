#if canImport(UIKit)
import Foundation
import Testing
@testable import HighlightrUI
import UIKit

@MainActor
@Suite(.serialized)
struct EditorUndoOperationiOSTests {
    @Test
    func insertTextCreatesUndoStepAndSyncsModel() async {
        let driver = UndoOperationDriver(initialText: "")
        await driver.prepareForEditing()

        await driver.insert("abc")
        driver.expectText("abc", "after insert")
        driver.expectSynchronized("after insert")

        await driver.undo()
        driver.expectText("", "after undo")
        driver.expectSynchronized("after undo")

        await driver.redo()
        driver.expectText("abc", "after redo")
        driver.expectSynchronized("after redo")
    }

    @Test
    func deleteBackwardCreatesUndoStepAndRestoresWithUndo() async {
        let driver = UndoOperationDriver(initialText: "abc")
        await driver.prepareForEditing()
        await driver.setSelection(NSRange(location: 3, length: 0))

        await driver.deleteBackward()
        driver.expectText("ab", "after deleteBackward")
        driver.expectSynchronized("after deleteBackward")

        await driver.undo()
        driver.expectText("abc", "after undo deleteBackward")
        driver.expectSynchronized("after undo deleteBackward")
    }

    @Test
    func replaceSelectionCreatesUndoRedoSteps() async {
        let driver = UndoOperationDriver(initialText: "abcde")
        await driver.prepareForEditing()

        await driver.replace(range: NSRange(location: 1, length: 3), with: "X")
        driver.expectText("aXe", "after replace")
        driver.expectSynchronized("after replace")

        await driver.undo()
        driver.expectText("abcde", "after undo replace")
        driver.expectSynchronized("after undo replace")

        await driver.redo()
        driver.expectText("aXe", "after redo replace")
        driver.expectSynchronized("after redo replace")
    }

    @Test
    func multiStepUndoRedoMaintainsConsistentHistory() async {
        let driver = UndoOperationDriver(initialText: "")
        await driver.prepareForEditing()

        await driver.insert("a")
        await driver.insert("b")
        await driver.insert("c")
        driver.expectText("abc", "after three inserts")
        driver.expectSynchronized("after three inserts")

        await driver.undo()
        driver.expectText("ab", "after undo #1")
        await driver.undo()
        driver.expectText("a", "after undo #2")
        await driver.undo()
        driver.expectText("", "after undo #3")
        driver.expectSynchronized("after undo sequence")

        await driver.redo()
        driver.expectText("a", "after redo #1")
        await driver.redo()
        driver.expectText("ab", "after redo #2")
        await driver.redo()
        driver.expectText("abc", "after redo #3")
        driver.expectSynchronized("after redo sequence")
    }

    @Test
    func newEditAfterUndoInvalidatesRedoStack() async {
        let driver = UndoOperationDriver(initialText: "")
        await driver.prepareForEditing()

        await driver.insert("a")
        await driver.insert("b")
        driver.expectText("ab", "after initial edits")

        await driver.undo()
        driver.expectText("a", "after undo before branch")
        #expect(driver.canRedo(), "redo should be available before branching edit")

        await driver.insert("z")
        driver.expectText("az", "after branch edit")
        #expect(!driver.canRedo(), "redo should be invalidated after branching edit")

        let beforeRedo = driver.currentText
        await driver.redo()
        driver.expectText(beforeRedo, "after redo attempt post-branch")
        driver.expectSynchronized("after redo attempt post-branch")
    }
}
#endif
