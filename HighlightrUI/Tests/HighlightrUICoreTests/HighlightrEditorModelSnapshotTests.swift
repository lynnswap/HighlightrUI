import Testing
@testable import HighlightrUICore

@MainActor
struct HighlightrEditorModelSnapshotTests {
    @Test
    func snapshotReflectsAllFields() {
        let model = HighlightrEditorModel(text: "start", language: "swift")

        model.text = "updated"
        model.language = "javascript"
        model.theme = .named("atom-one-dark")
        model.selection = TextSelection(location: 2, length: 3)
        model.isEditable = false
        model.isFocused = true
        model.isUndoable = true
        model.isRedoable = true

        let snapshot = model.snapshot()

        #expect(snapshot.text == "updated")
        #expect(snapshot.language == "javascript")
        #expect(snapshot.theme == .named("atom-one-dark"))
        #expect(snapshot.selection == TextSelection(location: 2, length: 3))
        #expect(!snapshot.isEditable)
        #expect(snapshot.isFocused)
        #expect(snapshot.isUndoable)
        #expect(snapshot.isRedoable)
    }
}
