import XCTest

final class MiniAppEditorFlowUITests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOpenSettingsAndToggleEditableUpdatesFooter() throws {
        let app = launchApp()

        openSettings(in: app)

        let editableToggleContainer = app.switches["settings.editableToggle"].firstMatch
        XCTAssertTrue(editableToggleContainer.waitForExistence(timeout: 3))
        let editableSwitch = editableToggleContainer.switches.firstMatch
        XCTAssertTrue(editableSwitch.waitForExistence(timeout: 3))
        let initialToggleValue = editableSwitch.value as? String
        editableSwitch.tap()
        XCTAssertTrue(waitForSwitchValueChange(of: editableSwitch, from: initialToggleValue))

        closeSettings(in: app)

        XCTAssertTrue(waitForStatusLabel(identifier: "status.editable", contains: "Read Only", in: app))
    }

    @MainActor
    func testSnippetChangeUpdatesLanguageIndicator() throws {
        let app = launchApp()

        openMenu(identifier: "toolbar.snippetMenu", in: app)
        chooseMenuItem("JSON Payload", in: app)

        XCTAssertTrue(waitForText("JSON", in: app))
    }

    @MainActor
    func testSettingsLanguageChangeUpdatesLanguageIndicator() throws {
        let app = launchApp()

        openSettings(in: app)
        openMenu(identifier: "settings.languagePicker", in: app)
        chooseMenuItem("TypeScript", in: app)
        closeSettings(in: app)

        XCTAssertTrue(waitForText("TypeScript", in: app))
    }

    @MainActor
    func testSettingsThemeChangeDismissesSheetWithoutRegression() throws {
        let app = launchApp()

        openSettings(in: app)
        openMenu(identifier: "settings.themePicker", in: app)
        chooseMenuItem("GitHub", in: app)
        closeSettings(in: app)

        XCTAssertTrue(app.descendants(matching: .any)["editor.host"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["toolbar.settingsButton"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["settings.doneButton"].exists)
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["editor.host"].waitForExistence(timeout: 5))
        return app
    }

    private func openSettings(in app: XCUIApplication) {
        let settingsButton = app.buttons["toolbar.settingsButton"].firstMatch
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 2))
        settingsButton.tap()
        XCTAssertTrue(app.buttons["settings.doneButton"].waitForExistence(timeout: 3))
    }

    private func closeSettings(in app: XCUIApplication) {
        let doneButton = app.buttons["settings.doneButton"].firstMatch
        XCTAssertTrue(doneButton.waitForExistence(timeout: 2))
        doneButton.tap()
        XCTAssertTrue(waitForDisappearance(doneButton, timeout: 3))
        XCTAssertTrue(app.buttons["toolbar.settingsButton"].waitForExistence(timeout: 3))
    }

    private func openMenu(identifier: String, in app: XCUIApplication) {
        let menu = app.descendants(matching: .any)[identifier].firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 3))
        menu.tap()
    }

    private func chooseMenuItem(_ title: String, in app: XCUIApplication) {
        let buttonItem = app.buttons[title].firstMatch
        if buttonItem.waitForExistence(timeout: 2) {
            buttonItem.tap()
            return
        }

        let staticTextItem = app.staticTexts[title].firstMatch
        XCTAssertTrue(staticTextItem.waitForExistence(timeout: 2))
        staticTextItem.tap()
    }

    private func waitForText(_ text: String, in app: XCUIApplication, timeout: TimeInterval = 2) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", text)
        return app.descendants(matching: .any).matching(predicate).firstMatch.waitForExistence(timeout: timeout)
    }

    private func waitForStatusLabel(
        identifier: String,
        contains value: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 5
    ) -> Bool {
        let element = app.staticTexts[identifier].firstMatch
        guard element.waitForExistence(timeout: timeout) else {
            return false
        }

        let predicate = NSPredicate(format: "label CONTAINS[c] %@", value)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    private func waitForDisappearance(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    private func waitForSwitchValueChange(
        of toggle: XCUIElement,
        from initialValue: String?,
        timeout: TimeInterval = 2
    ) -> Bool {
        guard let initialValue else { return true }
        let predicate = NSPredicate(format: "value != %@", initialValue)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: toggle)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
