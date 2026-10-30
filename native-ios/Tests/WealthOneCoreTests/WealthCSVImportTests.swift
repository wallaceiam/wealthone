import Foundation
import XCTest
@testable import WealthOneCore

final class WealthCSVImportTests: XCTestCase {
  let source = "Date,Total,Assets,Liabilities,Savings,Note,\r\n2 Jan 2025,200,200,0,200,,\r\n1 Jan 2025,100,100,0,100,,\r\n"
  func parse(_ text: String? = nil) throws -> WealthCSVDocument { try WealthCSVDocument.parse(Data((text ?? source).utf8)) }
  func testParserSortsDatesAndSupportsBOMQuotedNamesAndExactDecimals() throws {
    let doc = try parse("\u{feff}Date,Total,Assets,Liabilities,\"Savings, CAD\",Note,\n1 Jan 2025,0.03,0.03,0,0.03,,\n")
    XCTAssertEqual(doc.accountNames, ["Savings, CAD"])
    XCTAssertEqual(doc.rows[0].balances["Savings, CAD"], Decimal(string: "0.03"))
    XCTAssertEqual(try parse().rows.map(\.day), ["2025-01-01", "2025-01-02"])
  }
  func testMissingAndAmbiguousAccountsAreRejectedWithoutCreatingAny() throws {
    let doc = try parse()
    XCTAssertThrowsError(try WealthCSVImportPlan(document: doc, snapshot: Snapshot())) { XCTAssertTrue($0.localizedDescription.contains("Savings")) }
    XCTAssertThrowsError(try WealthCSVImportPlan(document: doc, snapshot: Snapshot(accounts: [Account(id: "a", name: "Savings"), Account(id: "b", name: " savings ")])))
    let plan = try WealthCSVImportPlan(document: doc, snapshot: Snapshot(accounts: [Account(id: "a", name: " SAVINGS ")]))
    XCTAssertEqual(plan.accountCount, 1)
    XCTAssertEqual(plan.newDateCount, 2)
  }
  func testMergeKeepsOtherAccountsFlowsGoalAndExistingDifferencesByDefault() throws {
    let before = Snapshot(accounts: [Account(id: "a", name: "Savings"), Account(id: "b", name: "Other")], records: [
      DayRecord(date: "2025-01-01T12:00:00Z", totals: ["a": 99, "b": 500], inflows: ["a": 4])], goal: ["contributions": .decimal(300)])
    let doc = try parse()
    let plan = try WealthCSVImportPlan(document: doc, snapshot: before)
    XCTAssertEqual(plan.differentBalanceCount, 1)
    XCTAssertEqual(plan.newDateCount, 1)
    let s = try EventStore(); try s.replace(before); try s.importCSV(plan)
    XCTAssertEqual(s.projection.snapshot.records.first?.totals, ["a": 99, "b": 500])
    XCTAssertEqual(s.projection.snapshot.records.first?.inflows, ["a": 4])
    XCTAssertEqual(s.projection.snapshot.goal, before.goal)
    let updated = try WealthCSVImportPlan(document: doc, snapshot: s.projection.snapshot, overwriteExisting: true)
    try s.importCSV(updated)
    XCTAssertEqual(s.projection.snapshot.records.first?.totals["a"], 100)
    XCTAssertEqual(s.projection.snapshot.records.first?.totals["b"], 500)
    let count = s.events.count
    try s.importCSV(WealthCSVImportPlan(document: doc, snapshot: s.projection.snapshot))
    XCTAssertEqual(s.events.count, count)
  }
  func testImportIsAtomicAndStalePreviewFails() throws {
    let baseline = Snapshot(accounts: [Account(id: "a", name: "Savings")])
    var commits = 0, fail = false
    let s = try EventStore(commit: { _ in commits += 1; if fail { throw CoreError.invalid("disk full") } })
    try s.replace(baseline)
    let plan = try WealthCSVImportPlan(document: parse(), snapshot: baseline)
    let original = s.envelope; fail = true
    XCTAssertThrowsError(try s.importCSV(plan))
    XCTAssertEqual(s.envelope, original)
    fail = false; try s.importCSV(plan)
    XCTAssertEqual(commits, 3, "One baseline, one failed transaction and one complete import")
    XCTAssertThrowsError(try s.importCSV(plan))
  }
  func testCurrencyUnitsAreExplicitAndSavedRatesStayFrozen() throws {
    let account = Account(id: "a", name: "Savings", currency: "CAD")
    let snapshot = Snapshot(accounts: [account], records: [DayRecord(date: "2025-01-01", exchangeRates: ["CAD": Decimal(string: "0.4")!], exchangeRateDates: ["CAD": "2024-12-31"], exchangeRateSources: ["CAD": "Saved"])])
    XCTAssertThrowsError(try WealthCSVImportPlan(document: parse(), snapshot: snapshot))
    let quote = ExchangeRateQuote(ratesToGBP: ["CAD": Decimal(string: "0.5")!], date: "2025-03-01", source: "Manual")
    let own = try WealthCSVImportPlan(document: parse(), snapshot: snapshot, quote: quote)
    let s = try EventStore(); try s.replace(snapshot); try s.importCSV(own)
    XCTAssertEqual(s.projection.snapshot.records[0].totals["a"], 100)
    XCTAssertEqual(s.projection.snapshot.records[0].exchangeRates["CAD"], Decimal(string: "0.4"))
    XCTAssertEqual(s.projection.snapshot.records[1].exchangeRateSources["CAD"], "Manual")
    let main = try WealthCSVImportPlan(document: parse(), snapshot: snapshot, units: .reportingCurrency, quote: quote)
    let other = try EventStore(); try other.replace(snapshot); try other.importCSV(main)
    XCTAssertEqual(other.projection.snapshot.records[0].totals["a"], 250)
    XCTAssertEqual(other.projection.snapshot.records[1].totals["a"], 400)
  }
  func testClosedPeriodsAndAmbiguousStoredDaysAreRejected() throws {
    let account = Account(id: "a", name: "Savings", closureDates: ["2025-01-02": true])
    XCTAssertThrowsError(try WealthCSVImportPlan(document: parse(), snapshot: Snapshot(accounts: [account])))
    let ambiguous = Snapshot(accounts: [Account(id: "a", name: "Savings")], records: [DayRecord(date: "2025-01-01"), DayRecord(date: "2025-01-01T12:00:00Z")])
    XCTAssertThrowsError(try WealthCSVImportPlan(document: parse(), snapshot: ambiguous))
  }
  func testMalformedCSVNumbersDatesNotesDuplicateHeadersOrDaysAreRejected() throws {
    for input in [
      "Date,Total,Assets,Liabilities,Savings,Note,\n31 Feb 2025,0,0,0,1,,",
      "Date,Total,Assets,Liabilities,Savings,Note,\n1 Jan 2025,0,0,0,12oops,,",
      "Date,Total,Assets,Liabilities,Savings,Note,\n1 Jan 2025,0,0,0,1,note,",
      "Date,Total,Assets,Liabilities,Savings,Savings,Note,\n1 Jan 2025,0,0,0,1,2,,",
      source + "1 Jan 2025,0,0,0,1,,\n",
      "Date,Total,Assets,Liabilities,\"Savings,Note,\n",
      "Date,Total,Assets,Liabilities,Savings,Note,\n1 Jan 2025,0,0,0,\"1\"oops,,",
    ] { XCTAssertThrowsError(try parse(input)) }
    let blank = try parse("Date,Total,Assets,Liabilities,Savings,Note,\n1 Jan 2025,0,0,0,,,\n2 Jan 2025,0,0,0,0,,")
    XCTAssertNil(blank.rows[0].balances["Savings"])
    XCTAssertEqual(blank.rows[1].balances["Savings"], 0)
  }
}

extension WealthCSVImportTests {
  func testMissingAccountsCanBeCreatedExplicitlyBeforeImportButNeverByImportItself() throws {
    let document = try parse()
    let s = try EventStore()
    try s.replace(Snapshot(accounts: [Account(id: "other", name: "Other")]))
    XCTAssertEqual(document.missingAccountNames(in: s.projection.snapshot), ["Savings"])
    XCTAssertThrowsError(try WealthCSVImportPlan(document: document, snapshot: s.projection.snapshot))
    XCTAssertEqual(s.projection.snapshot.accounts.map(\.id), ["other"])
    // This is the explicit account-creation command after the user reviews the editor.
    try s.append(.create(.account("approved"), generation: "approved", fields: ["name": .string("Savings"), "currency": .string("GBP")]))
    XCTAssertEqual(document.missingAccountNames(in: s.projection.snapshot), [])
    try s.importCSV(WealthCSVImportPlan(document: document, snapshot: s.projection.snapshot))
    XCTAssertEqual(s.projection.snapshot.accounts.count, 2)
    XCTAssertEqual(s.projection.snapshot.records.last?.totals["approved"], 200)
  }
}
