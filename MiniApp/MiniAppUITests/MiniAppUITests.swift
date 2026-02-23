//
//  MiniAppUITests.swift
//  MiniAppUITests
//
//  Created by Kazuki Nakashima on 2026/02/23.
//

import XCTest

final class MiniAppUITests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchAndEditorVisible() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["editor.host"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["toolbar.settingsButton"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["toolbar.snippetMenu"].waitForExistence(timeout: 2))
    }
}
