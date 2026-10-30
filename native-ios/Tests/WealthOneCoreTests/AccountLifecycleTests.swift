import Foundation
import XCTest
@testable import WealthOneCore

final class AccountLifecycleTests: XCTestCase {
  func store(commit: @escaping (Envelope) throws -> Void = { _ in }) throws -> EventStore {
    let store = try EventStore(commit: commit)
    try store.replace(Snapshot(accounts: [Account(id: "a", name: "Savings")], records: [
      DayRecord(date: "2025-01-01", totals: ["a": 1000]),
      DayRecord(date: "2025-02-01", totals: ["a": 1200], inflows: ["a": 200], outflows: ["a": 10])]))
    return store
  }
  func testClosePreservesHistoryAndAddsOutflowAtomically() throws {
    var commits = 0
    let s = try store { _ in commits += 1 }
    let context = s.editContext(for: .account("a"))
    try s.setAccountClosed("a", closed: true, day: "2025-02-01", today: "2025-03-01", context: context)
    XCTAssertEqual(commits, 2)
    let snapshot = s.projection.snapshot
    XCTAssertEqual(snapshot.records.first?.totals["a"], 1000)
    XCTAssertEqual(snapshot.records.last?.totals["a"], 0)
    XCTAssertEqual(snapshot.records.last?.outflows["a"], 1210)
    XCTAssertEqual(snapshot.records.last?.inflows["a"], 200)
    XCTAssertTrue(snapshot.accounts[0].isClosed(on: "2025-02-01"))
    XCTAssertFalse(snapshot.accounts[0].isClosed(on: "2025-01-31"))
    let replay = try EventStore(envelope: JSONDecoder().decode(Envelope.self, from: JSONEncoder().encode(s.envelope)))
    XCTAssertEqual(replay.projection.snapshot, snapshot)
    let archived = try Archive.snapshot(from: JSONEncoder().encode(snapshot))
    XCTAssertEqual(archived, snapshot)
  }
  func testReopenKeepsZeroBalanceAndAllowsNewEntry() throws {
    let s = try store()
    try s.setAccountClosed("a", closed: true, day: "2025-02-02", today: "2025-03-01", context: s.editContext(for: .account("a")))
    XCTAssertThrowsError(try s.applyQuickEntry(id: "closed", accountID: "a", day: "2025-02-03", total: 99, today: "2025-02-03"))
    try s.setAccountClosed("a", closed: false, day: "2025-02-04", today: "2025-03-01", context: s.editContext(for: .account("a")))
    XCTAssertTrue(s.projection.snapshot.accounts[0].isClosed(on: "2025-02-03"))
    XCTAssertFalse(s.projection.snapshot.accounts[0].isClosed(on: "2025-02-04"))
    XCTAssertEqual(PortfolioReadModel(snapshot: s.projection.snapshot).latestRecord?.totals["a"], 0)
    try s.applyQuickEntry(id: "open", accountID: "a", day: "2025-02-04", total: 50, today: "2025-02-04")
    XCTAssertEqual(PortfolioReadModel(snapshot: s.projection.snapshot).latestRecord?.totals["a"], 50)
  }
  func testClosureRejectsStaleFormsBackdatesFutureDatesAndHistoryDeletion() throws {
    let s = try store()
    let oldDay = s.editContext(for: .day("2025-02-02"))
    let oldAccount = s.editContext(for: .account("a"))
    XCTAssertThrowsError(try s.setAccountClosed("a", closed: true, day: "2025-01-02", today: "2025-03-01", context: oldAccount))
    XCTAssertThrowsError(try s.setAccountClosed("a", closed: true, day: "2026-01-01", today: "2025-03-01", context: oldAccount))
    try s.setAccountClosed("a", closed: true, day: "2025-02-02", today: "2025-03-01", context: oldAccount)
    XCTAssertThrowsError(try s.submit(["totals:a": .decimal(100)], context: oldDay))
    XCTAssertThrowsError(try s.setAccountClosed("a", closed: false, day: "2025-02-03", today: "2025-03-01", context: oldAccount))
    XCTAssertThrowsError(try s.append(.remove(.account("a"), generation: s.projection.generation(for: .account("a"))!)))
    XCTAssertThrowsError(try s.append(.remove(.day("2025-02-02"), generation: s.projection.generation(for: .day("2025-02-02"))!)))
  }
  func testFailedClosureDoesNotPublishPartialStatusOrAmounts() throws {
    var fail = false
    let s = try store { _ in if fail { throw CoreError.invalid("disk full") } }
    let before = s.envelope
    fail = true
    XCTAssertThrowsError(try s.setAccountClosed("a", closed: true, day: "2025-02-02", today: "2025-03-01", context: s.editContext(for: .account("a"))))
    XCTAssertEqual(s.envelope, before)
    XCTAssertFalse(s.projection.snapshot.accounts[0].isClosed(on: "2025-02-02"))
  }
}

extension AccountLifecycleTests {
  func testConcurrentOfflineEntryCannotResurrectClosedBalanceAndReplayOrderConverges() throws {
    let s = try store()
    let offline = try EventStore(envelope: Envelope(actor: "offline", clock: s.envelope.clock, events: s.events))
    try s.setAccountClosed("a", closed: true, day: "2025-02-02", today: "2025-03-01", context: s.editContext(for: .account("a")))
    try offline.applyQuickEntry(id: "offline-entry", accountID: "a", day: "2025-02-03", total: 900, today: "2025-02-03")
    try s.merge(offline.events)
    XCTAssertEqual(s.projection.snapshot.records.last?.totals["a"], 900, "Original offline observation remains in history")
    XCTAssertEqual(PortfolioReadModel(snapshot: s.projection.snapshot).points.last?.total, 0, "Closed status controls derived balances")
    let reverse = try Projection(events: s.events.reversed())
    XCTAssertEqual(reverse.snapshot, s.projection.snapshot)
  }
  func testClosingForeignBalanceUsesSavedRateAndZeroAndNegativeBalancesRemainSigned() throws {
    let s = try EventStore()
    try s.replace(Snapshot(accounts: [Account(id: "a", name: "CAD", currency: "CAD")], records: [
      DayRecord(date: "2025-01-01", totals: ["a": 200], exchangeRates: ["CAD": Decimal(string: "0.5")!], exchangeRateDates: ["CAD": "2025-01-01"], exchangeRateSources: ["CAD": "Manual"])]))
    try s.setAccountClosed("a", closed: true, day: "2025-01-02", today: "2025-03-01", context: s.editContext(for: .account("a")))
    let last = PortfolioReadModel(snapshot: s.projection.snapshot).points.last!
    XCTAssertEqual(last.total, 0)
    XCTAssertEqual(last.outflows, 100)
    XCTAssertEqual(last.totalPL, 0)
    XCTAssertEqual(s.projection.snapshot.records.last?.exchangeRateSources["CAD"], "Manual")
    for balance in [0, -50] {
      let store = try EventStore()
      try store.replace(Snapshot(accounts: [Account(id: "a", name: "Signed")], records: [DayRecord(date: "2025-01-01", totals: ["a": Decimal(balance)])]))
      try store.setAccountClosed("a", closed: true, day: "2025-01-02", today: "2025-03-01", context: store.editContext(for: .account("a")))
      XCTAssertEqual(store.projection.snapshot.records.last?.outflows["a"] ?? 0, Decimal(balance))
    }
  }
  func testOldArchiveDefaultsToOpenAndEmptyAccountCanBeDeleted() throws {
    let old = Data(#"{"accounts":[{"id":"a","name":"Savings","provider":"","isAsset":true,"accountType":0}],"records":[],"goal":{}}"#.utf8)
    let snapshot = try Archive.snapshot(from: old)
    XCTAssertEqual(snapshot.accounts[0].closureDates, [:])
    let s = try EventStore()
    let event = try s.replace(snapshot)
    try s.append(.remove(.account("a"), generation: event.id))
    XCTAssertTrue(s.projection.snapshot.accounts.isEmpty)
  }
}

extension AccountLifecycleTests {
  func testConcurrentDayDeletionCannotRemoveClosureSettlement() throws {
    let s = try store()
    let offline = try EventStore(envelope: Envelope(actor: "offline-delete", clock: s.envelope.clock, events: s.events))
    let generation = s.projection.generation(for: .day("2025-02-01"))!
    try s.setAccountClosed("a", closed: true, day: "2025-02-01", today: "2025-03-01", context: s.editContext(for: .account("a")))
    try offline.append(.remove(.day("2025-02-01"), generation: generation))
    try s.merge(offline.events)
    XCTAssertEqual(s.projection.snapshot.records.last?.date, "2025-02-01")
    XCTAssertEqual(s.projection.snapshot.records.last?.outflows["a"], 1210)
    XCTAssertEqual(PortfolioReadModel(snapshot: s.projection.snapshot).points.last?.total, 0)
    XCTAssertEqual(try Projection(events: s.events.reversed()).snapshot, s.projection.snapshot)
    XCTAssertTrue(s.events.contains { if case .remove(.day, _) = $0.operation { return true }; return false })
  }
  func testReclosingUsesZeroAfterSuppressedOfflineBalance() throws {
    let s = try store()
    let offline = try EventStore(envelope: Envelope(actor: "offline-reclose", clock: s.envelope.clock, events: s.events))
    try s.setAccountClosed("a", closed: true, day: "2025-02-02", today: "2025-03-01", context: s.editContext(for: .account("a")))
    try offline.applyQuickEntry(id: "offline-reclose-entry", accountID: "a", day: "2025-02-03", total: 900, today: "2025-02-03")
    try s.merge(offline.events)
    try s.setAccountClosed("a", closed: false, day: "2025-02-04", today: "2025-03-01", context: s.editContext(for: .account("a")))
    let before = PortfolioReadModel(snapshot: s.projection.snapshot).points.last!.totalPL
    try s.setAccountClosed("a", closed: true, day: "2025-02-05", today: "2025-03-01", context: s.editContext(for: .account("a")))
    XCTAssertEqual(s.projection.snapshot.records.last?.outflows["a"] ?? 0, 0)
    XCTAssertEqual(PortfolioReadModel(snapshot: s.projection.snapshot).points.last?.totalPL, before)
  }
}

extension AccountLifecycleTests {
  func testClosureKeepsExactLegacyDayIdentifierForPermanentSettlementProtection() throws {
    let raw = "2025-02-01T12:30:00Z"
    let s = try EventStore()
    try s.replace(Snapshot(accounts: [Account(id: "a", name: "Legacy")], records: [DayRecord(date: raw, totals: ["a": 100])]))
    try s.setAccountClosed("a", closed: true, day: "2025-02-01", today: "2025-03-01", context: s.editContext(for: .account("a")))
    XCTAssertEqual(s.projection.snapshot.accounts[0].closureRecords["2025-02-01"], raw)
    XCTAssertEqual(s.projection.snapshot.records.last?.date, raw)
    XCTAssertTrue(s.isClosureDay(raw))
    XCTAssertThrowsError(try s.append(.remove(.day(raw), generation: s.projection.generation(for: .day(raw))!)))
    let archive = try Archive.snapshot(from: JSONEncoder().encode(s.projection.snapshot))
    let restored = try EventStore()
    try restored.replace(archive)
    XCTAssertTrue(restored.isClosureDay(raw))
  }
}

extension AccountLifecycleTests {
  func testClosedAccountsAreHiddenFromCurrentListsAndBreakdownButKeepHistoricalValues() throws {
    let s = try EventStore()
    try s.replace(Snapshot(accounts: [
      Account(id: "closed", name: "Closed savings", accountType: 1),
      Account(id: "open", name: "Open investments", accountType: 2),
      Account(id: "debt", name: "Closed loan", isAsset: false, accountType: 9),
    ], records: [DayRecord(date: "2025-01-01", totals: ["closed": 100, "open": 200, "debt": 50])]))
    for id in ["closed", "debt"] {
      try s.setAccountClosed(id, closed: true, day: "2025-01-02", today: "2026-10-30", context: s.editContext(for: .account(id)))
    }
    let model = PortfolioReadModel(snapshot: s.projection.snapshot)
    XCTAssertEqual(model.snapshot.openAccounts().map(\.id), ["open"])
    XCTAssertEqual(model.accountAllocation, ["Open investments": 200])
    XCTAssertEqual(model.typeAllocation, [2: 200])
    XCTAssertEqual(model.snapshot.accounts.count, 3)
    XCTAssertEqual(model.accountHistories["closed"]?.first?.total, 100)
    XCTAssertEqual(model.points.first?.total, 250)
  }
}
