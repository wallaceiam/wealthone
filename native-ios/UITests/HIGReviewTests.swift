import XCTest

@MainActor
final class HIGReviewTests: XCTestCase {
  func testScreenInventory() {
    let app = XCUIApplication()
    app.launchEnvironment["WEALTHONE_UI_TEST_STORE"] = UUID().uuidString
    app.launch()
    XCTAssertTrue(app.descendants(matching: .any)["Home"].firstMatch.waitForExistence(timeout: 15))
    shot(app, "01-migration-home")
    if app.buttons["Start a new portfolio"].exists { app.buttons["Start a new portfolio"].tap() }
    shot(app, "02-empty-home")
    for _ in 0..<3 where !app.buttons["Add account"].firstMatch.isHittable { app.swipeUp() }
    app.buttons["Add account"].firstMatch.tap()
    shot(app, "03-account-editor-empty")
    app.textFields["Account name"].tap()
    app.textFields["Account name"].typeText("Everyday savings")
    app.textFields["Provider"].tap()
    app.textFields["Provider"].typeText("Example Building Society")
    shot(app, "04-account-editor-filled")
    app.buttons["Save"].tap()
    for _ in 0..<3 where !app.buttons["Add dated entry"].isHittable { app.swipeDown() }
    app.buttons["Add dated entry"].tap()
    shot(app, "05-entry-editor-empty")
    let total = app.textFields["Everyday savings Total"]
    total.tap()
    total.typeText("125000")
    shot(app, "06-entry-editor-filled")
    app.buttons["Save"].tap()
    shot(app, "07-populated-home")
    app.staticTexts["Everyday savings"].firstMatch.tap()
    shot(app, "08-account-detail")
    app.swipeUp()
    shot(app, "09-account-metrics")
    app.descendants(matching: .any)["Breakdown"].firstMatch.tap()
    shot(app, "10-breakdown")
    app.descendants(matching: .any)["Goals"].firstMatch.tap()
    shot(app, "11-goals")
    app.buttons["Edit"].tap()
    shot(app, "12-goal-editor")
    app.swipeUp()
    shot(app, "13-goal-editor-lower")
    app.buttons["Cancel"].tap()
    app.descendants(matching: .any)["History"].firstMatch.tap()
    shot(app, "14-history")
    app.descendants(matching: .any)["Settings"].firstMatch.tap()
    shot(app, "15-settings")
    app.buttons["Import and export JSON"].tap()
    shot(app, "16-backups")
    app.navigationBars.buttons.element(boundBy: 0).tap()
    let log = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Permanent edit log"))
      .firstMatch
    log.tap()
    shot(app, "17-audit")
    app.cells.element(boundBy: 1).tap()
    shot(app, "18-event-details")
    app.navigationBars.buttons.element(boundBy: 0).tap()
    app.navigationBars.buttons.element(boundBy: 0).tap()
    app.buttons["Conflicts (0)"].tap()
    shot(app, "19-empty-conflicts")
    app.navigationBars.buttons.element(boundBy: 0).tap()
    app.buttons["About WealthOne"].tap()
    shot(app, "20-about")
  }
  private func shot(_ app: XCUIApplication, _ name: String) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
