import XCTest

@MainActor
final class WealthOneUITests: XCTestCase {
  func testOfflineLaunchSaveAndReopen() {
    let app = XCUIApplication()
    app.launchEnvironment["WEALTHONE_UI_TEST_STORE"] = UUID().uuidString
    app.launch()
    XCTAssertTrue(app.descendants(matching: .any)["Home"].firstMatch.waitForExistence(timeout: 20))
    if app.buttons["Start a new portfolio"].exists { app.buttons["Start a new portfolio"].tap() }
    let name = "Smoke " + UUID().uuidString.prefix(8)
    for _ in 0..<4 where !app.buttons["Add account"].firstMatch.isHittable { app.swipeUp() }
    app.buttons["Add account"].firstMatch.tap()
    let field = app.textFields["Account name"]
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    field.tap()
    field.typeText(name)
    app.buttons["Save"].tap()
    for _ in 0..<4 where !app.buttons["Add dated entry"].isHittable { app.swipeDown() }
    app.buttons["Add dated entry"].tap()
    let total = app.textFields[name + " Total"]
    XCTAssertTrue(total.waitForExistence(timeout: 5))
    total.tap()
    total.typeText("123")
    app.buttons["Save"].tap()
    app.terminate()
    app.launch()
    XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 10))
    app.descendants(matching: .any)["History"].firstMatch.tap()
    XCTAssertTrue(app.staticTexts["£123"].waitForExistence(timeout: 5))
    app.descendants(matching: .any)["Settings"].firstMatch.tap()
    let log = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Permanent edit log"))
      .firstMatch
    XCTAssertTrue(log.waitForExistence(timeout: 5))
    log.tap()
    XCTAssertTrue(app.navigationBars["Edit log"].waitForExistence(timeout: 5))
  }
}
