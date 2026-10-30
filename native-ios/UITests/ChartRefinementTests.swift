import XCTest

@MainActor
final class ChartRefinementTests: XCTestCase {
  func testCompactChartAndVisibleSmallGoalEstimates() {
    let app = XCUIApplication()
    app.launchEnvironment["WEALTHONE_UI_TEST_STORE"] = UUID().uuidString
    app.launch()
    XCTAssertTrue(app.descendants(matching: .any)["Home"].firstMatch.waitForExistence(timeout: 15))
    if app.buttons["Start a new portfolio"].exists { app.buttons["Start a new portfolio"].tap() }
    let add = app.buttons["Add account"].firstMatch
    for _ in 0..<8 where !add.isHittable { app.swipeUp() }
    add.tap()
    app.textFields["Account name"].tap()
    app.textFields["Account name"].typeText("Display savings")
    app.buttons["Save"].tap()
    for _ in 0..<8 where !app.buttons["Add dated entry"].isHittable { app.swipeDown() }
    app.buttons["Add dated entry"].tap()
    let field = app.textFields["Display savings Total"]
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    field.tap()
    field.typeText("102")
    app.buttons["Save"].tap()
    app.swipeDown()
    app.swipeDown()
    let metric = app.buttons["Chart metric"]
    XCTAssertTrue(metric.waitForExistence(timeout: 5))
    XCTAssertGreaterThan(metric.frame.midX, app.frame.midX)
    XCTAssertFalse(app.descendants(matching: .any)["Chart selected value"].firstMatch.exists)
    XCTAssertTrue(app.navigationBars["WealthOne"].exists)
    XCTAssertTrue(app.navigationBars["WealthOne"].exists)
    shot(app, "chart-refinement-home")
    metric.tap()
    app.buttons["Profit / loss"].tap()
    XCTAssertEqual(metric.value as? String, "Profit / loss")
    app.descendants(matching: .any)["Goals"].firstMatch.tap()
    XCTAssertTrue(
      app.staticTexts["Current savings is shown by the dashed line."].waitForExistence(timeout: 5))
    let poor = app.descendants(matching: .any)["Goal scenario Poor"].firstMatch
    let average = app.descendants(matching: .any)["Goal scenario Average"].firstMatch
    for _ in 0..<4 where !poor.isHittable { app.swipeUp() }
    XCTAssertTrue(poor.label.contains("£122"), poor.label)
    XCTAssertTrue(poor.label.contains("%"), poor.label)
    XCTAssertTrue(average.label.contains("£189"), average.label)
    XCTAssertTrue(app.navigationBars["Goals"].exists)
    shot(app, "chart-refinement-goals")
  }
  /// Seed this isolated simulator store with Tools/seed-performance-fixture.swift first.
  func testPopulatedPortfolioNavigationAndEdit() throws {
    guard let store = ProcessInfo.processInfo.environment["WEALTHONE_PERF_TEST_STORE"] else {
      throw XCTSkip("Requires the isolated synthetic 344-record performance fixture")
    }
    let app = XCUIApplication()
    app.launchEnvironment["WEALTHONE_UI_TEST_STORE"] = store
    let start = Date()
    app.launch()
    XCTAssertTrue(app.navigationBars["WealthOne"].waitForExistence(timeout: 15))
    XCTAssertTrue(app.staticTexts["£331,100"].firstMatch.exists)
    app.segmentedControls.firstMatch.buttons["All"].tap()
    let chart = app.descendants(matching: .any)["Value over time"].firstMatch
    if chart.exists {
      chart.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5)).press(forDuration: 0.1,
        thenDragTo: chart.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.5)))
    }
    for tab in ["Breakdown", "Goals", "History", "Settings", "Home"] {
      app.descendants(matching: .any)[tab].firstMatch.tap()
      XCTAssertTrue(app.navigationBars[tab == "Home" ? "WealthOne" : tab].waitForExistence(timeout: 5))
      app.swipeUp()
      app.swipeDown()
    }
    app.descendants(matching: .any)["History"].firstMatch.tap()
    let entry = app.descendants(matching: .any)["History entry 2026-07-29"].firstMatch
    XCTAssertTrue(entry.waitForExistence(timeout: 5))
    entry.tap()
    let field = app.textFields["Account 1 Total"]
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    field.tap()
    if let value = field.value as? String {
      field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count))
    }
    field.typeText("50000")
    app.buttons["Save"].tap()
    app.descendants(matching: .any)["Home"].firstMatch.tap()
    for _ in 0..<5 { app.swipeDown() }
    XCTAssertTrue(app.staticTexts["£336,800"].firstMatch.waitForExistence(timeout: 5))
    app.terminate()
    app.launch()
    XCTAssertTrue(app.staticTexts["£336,800"].firstMatch.waitForExistence(timeout: 10))
    print("Synthetic populated UI journey seconds: \(Date().timeIntervalSince(start))")
    shot(app, "populated-portfolio-after-edit")
  }
  func testCADEntryUsesSavedManualRateAndSurvivesRelaunch() {
    let app=XCUIApplication()
    app.launchEnvironment["WEALTHONE_UI_TEST_STORE"]=UUID().uuidString
    app.launch()
    XCTAssertTrue(app.navigationBars["WealthOne"].waitForExistence(timeout:15))
    if app.buttons["Start a new portfolio"].exists { app.buttons["Start a new portfolio"].tap() }
    let add=app.buttons["Add account"].firstMatch
    for _ in 0..<8 where !add.isHittable { app.swipeUp() }
    add.tap()
    app.textFields["Account name"].tap(); app.textFields["Account name"].typeText("Canadian savings")
    app.descendants(matching:.any)["Account currency"].firstMatch.tap()
    app.buttons["CAD"].tap()
    app.buttons["Save"].tap()
    app.buttons["Add dated entry"].tap()
    let total=app.textFields["Canadian savings Total"]
    XCTAssertTrue(total.waitForExistence(timeout:5))
    total.tap(); total.typeText("200")
    let rate=app.textFields["GBP per CAD"]
    for _ in 0..<5 where !rate.isHittable { app.swipeUp() }
    rate.tap()
    if let value=rate.value as? String, !value.isEmpty, value != "GBP per CAD" {
      rate.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:value.count))
    }
    rate.typeText("0.5")
    app.buttons["Save"].tap()
    for _ in 0..<5 { app.swipeDown() }
    XCTAssertTrue(app.staticTexts["£100"].firstMatch.waitForExistence(timeout:5))
    app.terminate();app.launch()
    XCTAssertTrue(app.staticTexts["£100"].firstMatch.waitForExistence(timeout:10))
    app.descendants(matching:.any)["Goals"].firstMatch.tap()
    let comparison=app.staticTexts["Actual vs projected wealth"].firstMatch
    for _ in 0..<8 where !comparison.isHittable { app.swipeUp() }
    XCTAssertTrue(comparison.exists)
    shot(app,"cad-goals-comparison")
  }
  func testHistoricalComparisonOnPopulatedPortfolio() throws {
    guard let store=ProcessInfo.processInfo.environment["WEALTHONE_PERF_TEST_STORE"] else { throw XCTSkip("Requires isolated synthetic fixture") }
    let app=XCUIApplication()
    app.launchEnvironment["WEALTHONE_UI_TEST_STORE"]=store
    app.launch()
    XCTAssertTrue(app.navigationBars["WealthOne"].waitForExistence(timeout:15))
    app.descendants(matching:.any)["Goals"].firstMatch.tap()
    let chart=app.descendants(matching:.any)["Actual versus projected wealth"].firstMatch
    for _ in 0..<10 where !chart.isHittable { app.swipeUp() }
    XCTAssertTrue(chart.exists)
    XCTAssertTrue(app.staticTexts["Average projection"].firstMatch.exists)
    shot(app,"populated-goals-history-comparison")
    let retirement = app.staticTexts["Average at retirement"].firstMatch
    for _ in 0..<8 where !retirement.isHittable { app.swipeUp() }
    XCTAssertTrue(retirement.exists)
    shot(app, "populated-retirement-endpoint")
  }
  func testCloseAndReopenAccountPreservesBalanceHistoryAndExtendsRetirementChart() {
    let app = XCUIApplication()
    app.launchEnvironment["WEALTHONE_UI_TEST_STORE"] = UUID().uuidString
    app.launch()
    XCTAssertTrue(app.navigationBars["WealthOne"].waitForExistence(timeout: 15))
    if app.buttons["Start a new portfolio"].exists { app.buttons["Start a new portfolio"].tap() }
    let add = app.buttons["Add account"].firstMatch
    for _ in 0..<8 where !add.isHittable { app.swipeUp() }
    add.tap()
    app.textFields["Account name"].tap(); app.textFields["Account name"].typeText("Lifecycle savings")
    app.textFields["Provider"].tap(); app.textFields["Provider"].typeText("Test bank")
    app.buttons["Save"].tap()
    app.buttons["Add dated entry"].tap()
    XCTAssertTrue(app.staticTexts["Test bank"].waitForExistence(timeout: 5))
    let total = app.textFields["Lifecycle savings Total"]
    XCTAssertTrue(total.waitForExistence(timeout: 5))
    total.tap(); total.typeText("1000")
    app.buttons["Save"].tap()
    app.descendants(matching: .any)["Settings"].firstMatch.tap()
    app.buttons["Lifecycle savings"].firstMatch.tap()
    XCTAssertFalse(app.buttons["Delete account"].exists)
    let close = app.buttons["Close account"]
    for _ in 0..<5 where !close.isHittable { app.swipeUp() }
    close.tap()
    XCTAssertTrue(app.staticTexts["Closing outflow"].waitForExistence(timeout: 5))
    app.buttons["Confirm close"].tap()
    XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.descendants(matching: .any)["Closed account Lifecycle savings"].firstMatch.exists)
    app.descendants(matching: .any)["Home"].firstMatch.tap()
    let noOpen = app.staticTexts["No open accounts"].firstMatch
    for _ in 0..<6 where !noOpen.isHittable { app.swipeUp() }
    XCTAssertTrue(noOpen.exists)
    XCTAssertFalse(app.staticTexts["Lifecycle savings"].exists)
    app.descendants(matching: .any)["Breakdown"].firstMatch.tap()
    XCTAssertTrue(app.navigationBars["Breakdown"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.staticTexts["Lifecycle savings"].exists)
    app.descendants(matching: .any)["Home"].firstMatch.tap()
    app.buttons["Add dated entry"].tap()
    XCTAssertFalse(app.textFields["Lifecycle savings Total"].exists)
    app.buttons["Cancel"].tap()
    app.descendants(matching: .any)["Goals"].firstMatch.tap()
    let endpoint = app.staticTexts["Average at retirement"].firstMatch
    for _ in 0..<12 where !endpoint.isHittable { app.swipeUp() }
    XCTAssertTrue(endpoint.exists)
    shot(app, "retirement-timeline")
    app.descendants(matching: .any)["Settings"].firstMatch.tap()
    app.descendants(matching: .any)["Closed account Lifecycle savings"].firstMatch.tap()
    let reopen = app.buttons["Reopen account"]
    for _ in 0..<5 where !reopen.isHittable { app.swipeUp() }
    reopen.tap()
    app.buttons["Confirm reopen"].tap()
    XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    app.terminate(); app.launch()
    app.buttons["Add dated entry"].tap()
    XCTAssertTrue(app.textFields["Lifecycle savings Total"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.textFields["Lifecycle savings Total"].value as? String, "0")
  }
  func testCSVImportIsAvailableAndUsesNativeFilePicker() {
    let app = XCUIApplication()
    app.launchEnvironment["WEALTHONE_UI_TEST_STORE"] = UUID().uuidString
    app.launch()
    XCTAssertTrue(app.navigationBars["WealthOne"].waitForExistence(timeout: 15))
    if app.buttons["Start a new portfolio"].exists { app.buttons["Start a new portfolio"].tap() }
    app.descendants(matching: .any)["Settings"].firstMatch.tap()
    let link = app.buttons["Import Wealth+ CSV"].firstMatch
    for _ in 0..<6 where !link.isHittable { app.swipeUp() }
    XCTAssertTrue(link.exists); link.tap()
    XCTAssertTrue(app.buttons["Choose Wealth+ CSV"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Accounts are matched by name. If any are missing, you can review and create them before importing balances."].exists)
    app.buttons["Choose Wealth+ CSV"].tap()
    XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 5))
    app.buttons["Cancel"].tap()
    XCTAssertTrue(app.buttons["Choose Wealth+ CSV"].waitForExistence(timeout: 5))
  }
  func testCSVCreationOfferAndImportUsingSourceDerivedProbe() throws {
    guard ProcessInfo.processInfo.environment["WEALTHONE_CSV_CREATION_PROBE"] == "YES" else {
      throw XCTSkip("Requires Tools/csv-creation-probe.py synthetic source-derived app")
    }
    let app = XCUIApplication()
    app.launchEnvironment["WEALTHONE_UI_TEST_STORE"] = UUID().uuidString
    app.launch()
    XCTAssertTrue(app.navigationBars["WealthOne"].waitForExistence(timeout: 15))
    if app.buttons["Start a new portfolio"].exists { app.buttons["Start a new portfolio"].tap() }
    app.descendants(matching: .any)["Settings"].firstMatch.tap()
    let link = app.buttons["Import Wealth+ CSV"].firstMatch
    for _ in 0..<6 where !link.isHittable { app.swipeUp() }
    link.tap()
    let offer = app.buttons["Review and create accounts"]
    XCTAssertTrue(offer.waitForExistence(timeout: 5)); offer.tap()
    for name in ["First import", "Second import"] {
      let field = app.textFields["Account name"]
      XCTAssertTrue(field.waitForExistence(timeout: 10))
      let expectedName = NSPredicate(format: "value == %@", name)
      expectation(for: expectedName, evaluatedWith: field)
      waitForExpectations(timeout: 10)
      app.buttons["Save"].tap()
    }
    let confirm = app.buttons["Import reviewed balances"]
    for _ in 0..<10 where !confirm.isHittable { app.swipeUp() }
    XCTAssertTrue(confirm.waitForExistence(timeout: 5)); confirm.tap()
    XCTAssertTrue(app.staticTexts["Imported balances for 1 dated entries."].waitForExistence(timeout: 5))
    app.descendants(matching: .any)["Home"].firstMatch.tap()
    for _ in 0..<5 { app.swipeDown() }
    XCTAssertTrue(app.staticTexts["£300"].firstMatch.waitForExistence(timeout: 5))
    shot(app, "csv-created-accounts-imported")
  }
  private func shot(_ app: XCUIApplication, _ name: String) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
