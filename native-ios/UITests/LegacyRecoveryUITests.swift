import XCTest

@MainActor
final class LegacyRecoveryUITests: XCTestCase {
  func testRecoveryIsAvailableAfterStartingPortfolioAndCannotImportOnSimulator() {
    let app = XCUIApplication()
    app.launchEnvironment["WEALTHONE_UI_TEST_STORE"] = UUID().uuidString
    app.launch()
    XCTAssertTrue(app.descendants(matching: .any)["Home"].firstMatch.waitForExistence(timeout: 15))
    if app.buttons["Start a new portfolio"].exists { app.buttons["Start a new portfolio"].tap() }
    app.descendants(matching: .any)["Settings"].firstMatch.tap()
    let recovery = app.buttons["Recover previous iCloud data"]
    for _ in 0..<5 where !recovery.isHittable { app.swipeUp() }
    recovery.tap()
    let status = app.staticTexts["Legacy recovery status"]
    XCTAssertTrue(status.waitForExistence(timeout: 5))
    XCTAssertTrue(status.label.contains("simulator cannot access"), status.label)
    XCTAssertFalse(app.buttons["Import recovered portfolio"].exists)
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "legacy-recovery-simulator-diagnostic"
    shot.lifetime = .keepAlways
    add(shot)
    app.navigationBars.buttons.element(boundBy: 0).tap()
    app.descendants(matching: .any)["Home"].firstMatch.tap()
    XCTAssertFalse(app.buttons["Start a new portfolio"].exists)
  }
}
