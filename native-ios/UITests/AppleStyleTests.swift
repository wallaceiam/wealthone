import XCTest

@MainActor
final class AppleStyleTests: XCTestCase {
  func testLightScreens() { captureJourney(appearance: "Light") }
  func testDarkScreens() { captureJourney(appearance: "Dark") }

  func testAllocationWithZeroAndNegativeAccounts() {
    let app = XCUIApplication()
    app.launchEnvironment["WEALTHONE_UI_TEST_STORE"] = UUID().uuidString
    app.launch()
    XCTAssertTrue(app.descendants(matching: .any)["Home"].firstMatch.waitForExistence(timeout: 15))
    if app.buttons["Start a new portfolio"].exists { app.buttons["Start a new portfolio"].tap() }
    let names = ["A Zero", "B Negative", "C Positive"]
    for name in names {
      let add = app.buttons["Add account"].firstMatch
      for _ in 0..<8 where !add.isHittable { app.swipeUp() }
      add.tap()
      app.textFields["Account name"].tap()
      app.textFields["Account name"].typeText(name)
      app.buttons["Save"].tap()
    }
    app.buttons["Add dated entry"].tap()
    for (name, value) in zip(names, ["0", "-100", "200"]) {
      let field = app.textFields[name + " Total"]
      field.tap()
      field.typeText(value)
    }
    app.buttons["Save"].tap()
    app.descendants(matching: .any)["Breakdown"].firstMatch.tap()
    XCTAssertTrue(app.staticTexts["B Negative"].exists)
    XCTAssertTrue(app.staticTexts["C Positive"].exists)
    shot(app, "allocation-zero-negative")
  }

  private func captureJourney(appearance: String) {
    let app = XCUIApplication()
    app.launchEnvironment["WEALTHONE_UI_TEST_STORE"] = UUID().uuidString
    // Set the simulator system appearance before each named test; launch defaults do not override UIKit.
    app.launch()
    XCTAssertTrue(app.descendants(matching: .any)["Home"].firstMatch.waitForExistence(timeout: 15))
    if app.buttons["Start a new portfolio"].exists { app.buttons["Start a new portfolio"].tap() }
    shot(app, appearance + "-empty")
    for name in ["Investments", "Savings"] {
      let add = app.buttons["Add account"].firstMatch
      for _ in 0..<8 where !add.isHittable { app.swipeUp() }
      add.tap()
      app.textFields["Account name"].tap()
      app.textFields["Account name"].typeText(name)
      app.buttons["Save"].tap()
    }
    let entry = app.buttons["Add dated entry"]
    for _ in 0..<8 where !entry.isHittable { app.swipeDown() }
    entry.tap()
    for (name, value) in [("Investments", "338500"), ("Savings", "346000")] {
      let field = app.textFields[name + " Total"]
      XCTAssertTrue(field.waitForExistence(timeout: 5))
      field.tap()
      field.typeText(value)
    }
    app.buttons["Save"].tap()
    app.swipeDown()
    app.swipeDown()
    XCTAssertTrue(app.buttons["Chart metric"].exists)
    XCTAssertFalse(app.descendants(matching: .any)["Chart selected value"].firstMatch.exists)
    shot(app, appearance + "-home")
    for tab in ["Breakdown", "Goals", "History", "Settings"] {
      app.descendants(matching: .any)[tab].firstMatch.tap()
      XCTAssertTrue(app.navigationBars[tab].waitForExistence(timeout: 5))
      shot(app, appearance + "-" + tab.lowercased())
    }
    app.buttons["Import and export JSON"].tap()
    shot(app, appearance + "-backups")
  }

  private func shot(_ app: XCUIApplication, _ name: String) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = "apple-" + name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
