import XCTest
import ObservationsCompat
@testable import HighlightrUICore

final class HighlightrEditorModelTests: XCTestCase {
    @MainActor
    func testSnapshotStreamSuppressesConsecutiveDuplicates() async {
        let model = HighlightrEditorModel(
            text: "",
            language: "swift"
        )

        var received: [EditorSnapshot] = []
        let firstValueReady = expectation(description: "Receive first snapshot")
        let valuesReady = expectation(description: "Receive first/text/language snapshots")
        valuesReady.expectedFulfillmentCount = 3

        let consumeTask = Task {
            for await snapshot in model.snapshotStream(backend: .legacy) {
                received.append(snapshot)
                if received.count == 1 {
                    firstValueReady.fulfill()
                }
                valuesReady.fulfill()
                if received.count == 3 {
                    break
                }
            }
        }

        await fulfillment(of: [firstValueReady], timeout: 1.0)

        model.text = "print(1)"
        await Task.yield()
        model.text = "print(1)"
        await Task.yield()
        model.language = "javascript"

        await fulfillment(of: [valuesReady], timeout: 1.0)
        consumeTask.cancel()
        _ = await consumeTask.result

        XCTAssertGreaterThanOrEqual(received.count, 3)
        XCTAssertEqual(received[1].text, "print(1)")
        XCTAssertEqual(received[2].language.rawValue, "javascript")
    }

    @MainActor
    func testSnapshotReflectsTextThemeLanguageAndSelection() {
        let model = HighlightrEditorModel(
            text: "start",
            language: "swift"
        )

        model.text = "updated"
        model.language = "javascript"
        model.theme = .named("atom-one-dark")
        model.selection = TextSelection(location: 2, length: 3)
        model.isEditable = false
        model.isFocused = true

        let snapshot = model.snapshot()

        XCTAssertEqual(snapshot.text, "updated")
        XCTAssertEqual(snapshot.language.rawValue, "javascript")
        XCTAssertEqual(snapshot.theme, .named("atom-one-dark"))
        XCTAssertEqual(snapshot.selection, TextSelection(location: 2, length: 3))
        XCTAssertEqual(snapshot.isEditable, false)
        XCTAssertEqual(snapshot.isFocused, true)
    }

    func testAutomaticThemeResolution() {
        let theme = EditorTheme.automatic(light: "paraiso-light", dark: "paraiso-dark")

        XCTAssertEqual(theme.resolvedThemeName(for: .light), "paraiso-light")
        XCTAssertEqual(theme.resolvedThemeName(for: .dark), "paraiso-dark")
    }
}
