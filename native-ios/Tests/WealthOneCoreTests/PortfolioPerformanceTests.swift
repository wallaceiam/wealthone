import Foundation
import XCTest
@testable import WealthOneCore

final class PortfolioPerformanceTests: XCTestCase {
  private func fixture(completeBalances: Bool = false) -> Snapshot {
    let accounts = [Account(id: "a", name: "Savings"), Account(id: "l", name: "Loan", isAsset: false, accountType: 9)]
    let base = Date(timeIntervalSince1970: 1577750400)
    let formatter = ISO8601DateFormatter()
    let records: [DayRecord] = (0..<400).map { i in
      let balanceIndex = completeBalances && i > 0 && i % 17 == 0 ? i - 1 : i
      let totals: [String: Decimal] = i % 17 == 0 && (!completeBalances || i == 0) ? [:]
        : ["a": Decimal(1000 + balanceIndex * 13), "l": Decimal(500 - balanceIndex * 2)]
      let inflows: [String: Decimal] = i % 3 == 0 ? ["a": Decimal(i % 11)] : [:]
      let outflows: [String: Decimal] = i % 5 == 0 ? ["l": 3] : [:]
      return DayRecord(date: formatter.string(from: base.addingTimeInterval(Double(i) * 7 * 86400)),
        totals: totals, inflows: inflows, outflows: outflows)
    }
    return Snapshot(accounts: accounts, records: records.reversed())
  }
  private func assertPoints(_ actual: [NetWorthPoint], _ expected: [NetWorthPoint], legacyCompatibleOnly: Bool = false, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(actual.count, expected.count, file: file, line: line)
    for (actual, expected) in zip(actual, expected) {
      XCTAssertEqual(actual.day, expected.day, file: file, line: line)
      XCTAssertEqual(actual.date, expected.date, file: file, line: line)
      let corrected: Set<String> = ["yearlyTwrrPercent", "yearlyGrowth", "yearlyGrowthPercent", "taxYearNetflows", "totalPL", "totalPLPercent", "yearlyPL", "yearlyPLPercent"]
      let reference = Dictionary(uniqueKeysWithValues: Mirror(reflecting: expected).children.compactMap { child in
        child.label.map { ($0, child.value) }
      })
      for child in Mirror(reflecting: actual).children {
        guard let name = child.label, !(legacyCompatibleOnly && corrected.contains(name)),
          let x = child.value as? Double, let y = reference[name] as? Double else { continue }
        XCTAssertTrue(x == y || (x.isNaN && y.isNaN), "Metric changed: " + name, file: file, line: line)
      }
    }
  }
  func testUnaffectedMetricsRetainLegacyResultsForCompleteBalances() {
    let source = fixture(completeBalances: true)
    assertPoints(PortfolioCalculator.netWorth(accounts: source.accounts, records: source.records),
      ReferencePortfolioCalculator.netWorth(accounts: source.accounts, records: source.records), legacyCompatibleOnly: true)
  }
  func testMixedHistoricalDatesRetainParsingOrderingAndLocalDayLookup() {
    let keys = ["2020-01-01", "2020-01-01T12:00:00Z", "2020-01-01T12:00:00.123Z", "1578009600000", "2020-04-01", "2021-01-01"]
    for key in keys + ["invalid", "0", "-1234567890000"] {
      XCTAssertEqual(PortfolioCalculator.date(key), ReferencePortfolioCalculator.date(key))
    }
    let records = keys.enumerated().map { DayRecord(date: $0.element, totals: ["a": Decimal(100 + $0.offset)]) }.reversed()
    let accounts = [Account(id: "a", name: "A")]
    assertPoints(PortfolioCalculator.netWorth(accounts: accounts, records: Array(records)),
      ReferencePortfolioCalculator.netWorth(accounts: accounts, records: Array(records)), legacyCompatibleOnly: true)
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: -8 * 3600)!
    let expected = ReferencePortfolioCalculator.record(on: "2020-01-01", records: Array(records), calendar: calendar)
    XCTAssertEqual(PortfolioCalculator.record(on: "2020-01-01", records: Array(records), calendar: calendar), expected)
  }
  func testReadModelCacheReusesUnchangedDataAndInvalidatesEditsAndCalendar() throws {
    var cache = PortfolioReadModelCache()
    var source = fixture()
    XCTAssertTrue(cache.update(source))
    let firstRevision = cache.revision
    XCTAssertFalse(cache.update(source))
    XCTAssertEqual(cache.revision, firstRevision)
    assertPoints(cache.model.points, PortfolioCalculator.netWorth(accounts: source.accounts, records: source.records))
    assertPoints(cache.model.accountHistories["l"] ?? [], PortfolioCalculator.accountHistory(accountID: "l", records: source.records))
    XCTAssertEqual(cache.model.historySections.flatMap(\.points).map(\.day), cache.model.points.reversed().map(\.day))
    source.records[0].totals["a"] = 9999
    XCTAssertTrue(cache.update(source))
    XCTAssertNotEqual(cache.revision, firstRevision)
    XCTAssertEqual(cache.model.latestRecord?.totals["a"], 9999)
    var calendar = Calendar.current
    calendar.timeZone = TimeZone(secondsFromGMT: 7 * 3600)!
    XCTAssertTrue(cache.update(source, calendar: calendar))
    XCTAssertFalse(cache.update(source, calendar: calendar))
    XCTAssertTrue(cache.update(Snapshot()))
    XCTAssertTrue(cache.model.points.isEmpty)
    XCTAssertTrue(cache.model.accountHistories.isEmpty)
  }
  func testUnchangedMergeDoesNotWriteAndStillRejectsCollisions() throws {
    var writes = 0
    let store = try EventStore(commit: { _ in writes += 1 })
    try store.replace(Snapshot(accounts: [Account(id: "a", name: "A")]))
    let before = store.envelope
    let count = writes
    XCTAssertFalse(try store.merge([]))
    XCTAssertFalse(try store.merge(store.events + store.events))
    XCTAssertEqual(writes, count)
    XCTAssertEqual(store.envelope, before)
    let old = try XCTUnwrap(store.events.first)
    let collision = Event(id: old.id, actor: old.actor, counter: old.counter, parents: old.parents,
      epoch: old.epoch, operation: .replace(Snapshot()), recordedAt: old.recordedAt)
    XCTAssertThrowsError(try store.merge([collision]))
    XCTAssertEqual(writes, count)
  }
  func testDuplicateRemoteEventStillAdvancesObservedClock() throws {
    let remote = Event(id: "r", actor: "remote", counter: 20, parents: [], epoch: "root", operation: .replace(Snapshot()), recordedAt: Date())
    let store = try EventStore(envelope: Envelope(actor: "local", clock: 0, events: [remote]))
    _ = try store.merge([remote])
    XCTAssertEqual(store.envelope.clock, 20)
  }
}
