import XCTest

@MainActor
final class PremiumUITests: XCTestCase {
  private func launch(largeText: Bool = false) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchEnvironment["WEALTHONE_UI_TEST_STORE"] = UUID().uuidString
    if largeText {
      app.launchArguments = [
        "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
      ]
    }
    app.launch()
    XCTAssertTrue(app.descendants(matching: .any)["Home"].firstMatch.waitForExistence(timeout: 15))
    return app
  }
  func testDirtyAccountCanKeepEditingThenDiscard() {
    let app = launch()
    let add = app.buttons["Add account"].firstMatch
    for _ in 0..<8 where !add.isHittable { app.swipeUp() }
    add.tap()
    let name = app.textFields["Account name"]
    XCTAssertTrue(name.waitForExistence(timeout: 5))
    name.tap()
    name.typeText("Unsaved savings")
    app.buttons["Cancel"].tap()
    XCTAssertTrue(app.buttons["Keep Editing"].waitForExistence(timeout: 5))
    app.buttons["Keep Editing"].tap()
    XCTAssertEqual(name.value as? String, "Unsaved savings")
    app.buttons["Cancel"].tap()
    app.buttons["Discard Changes"].tap()
    XCTAssertTrue(app.navigationBars["WealthOne"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.staticTexts["Unsaved savings"].exists)
  }
  func testDirtySheetSwipePreservesDraft() {
    let app = launch()
    let add = app.buttons["Add account"].firstMatch
    for _ in 0..<8 where !add.isHittable { app.swipeUp() }
    add.tap()
    let name = app.textFields["Account name"]
    XCTAssertTrue(name.waitForExistence(timeout: 5))
    name.tap()
    name.typeText("Gesture draft")
    let bar = app.navigationBars["Add account"]
    let start = bar.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15))
    let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.94))
    start.press(forDuration: 0.1, thenDragTo: end)
    // Dirty sheets block interactive dismissal; Cancel offers the explicit decision.
    XCTAssertTrue(name.waitForExistence(timeout: 5))
    XCTAssertEqual(name.value as? String, "Gesture draft")
    app.buttons["Cancel"].tap()
    XCTAssertTrue(app.buttons["Keep Editing"].waitForExistence(timeout: 5))
    app.buttons["Keep Editing"].tap()
    XCTAssertEqual(name.value as? String, "Gesture draft")
    app.buttons["Cancel"].tap()
    app.buttons["Discard Changes"].tap()
  }
  func testExactGoalInputSavesAndReopens() {
    let app = launch()
    app.descendants(matching: .any)["Goals"].firstMatch.tap()
    app.buttons["Edit"].tap()
    let earnings = app.textFields["Annual earnings GBP per year"]
    XCTAssertTrue(earnings.waitForExistence(timeout: 5))
    for _ in 0..<4 where !earnings.isHittable { app.swipeUp() }
    earnings.tap()
    earnings.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 10) + "60000")
    app.buttons["Save"].tap()
    XCTAssertTrue(app.navigationBars["Goals"].waitForExistence(timeout: 5))
    app.buttons["Edit"].tap()
    XCTAssertTrue(earnings.waitForExistence(timeout: 5))
    XCTAssertEqual(earnings.value as? String, "60000")
    app.buttons["Cancel"].tap()
  }
  func testAccessibilityTextHomeAndFormsRemainReachable() {
    let app = launch(largeText: true)
    let home = XCTAttachment(screenshot: app.screenshot())
    home.name = "premium-home-accessibility-text"
    home.lifetime = .keepAlways
    add(home)
    let create = app.buttons["Add account"].firstMatch
    for _ in 0..<10 where !create.isHittable { app.swipeUp() }
    XCTAssertTrue(create.isHittable)
    create.tap()
    XCTAssertTrue(app.textFields["Account name"].waitForExistence(timeout: 5))
    let form = XCTAttachment(screenshot: app.screenshot())
    form.name = "premium-form-accessibility-text"
    form.lifetime = .keepAlways
    add(form)
    XCTAssertTrue(app.buttons["Cancel"].isHittable)
    app.buttons["Cancel"].tap()
  }
}
