import XCTest
@testable import WealthOneCore
import WealthOneShared

final class AdapterRegressionTests: XCTestCase {
  func testEditedAmountsUseLegacyTruncationAndStrictSyntax() {
    XCTAssertEqual(EntryAmount.parse("123.9"), 123)
    XCTAssertEqual(EntryAmount.parse("-123.9"), -123)
    XCTAssertEqual(EntryAmount.parse(".9"), 0)
    XCTAssertEqual(EntryAmount.parse("100000000000000000000.9"), Decimal(string: "100000000000000000000"))
    XCTAssertNil(EntryAmount.parse("12oops"))
    XCTAssertNil(EntryAmount.parse("1e3"))
    XCTAssertNil(EntryAmount.parse(""))
  }
  func testStaleDraftPreservesRemoteFieldsAndConcurrentIntent() throws {
    let store = try EventStore()
    try store.replace(Snapshot(accounts: [Account(id: "a", name: "Original")], records: [DayRecord(date: "2026-10-28", totals: ["a": 10])]))
    let draft = store.editContext(for: .day("2026-10-28"))
    let generation = try XCTUnwrap(draft.generation)
    try store.append(.edit(.day("2026-10-28"), generation: generation, fields: ["inflows:a": .decimal(5), "totals:a": .decimal(30)]))
    try store.submit(["totals:a": .decimal(11)], context: draft)
    XCTAssertEqual(store.projection.snapshot.records.first?.inflows["a"], 5)
    XCTAssertNotNil(store.projection.conflicts[FieldKey(entity: .day("2026-10-28"), generation: generation, field: "totals:a")])
  }
  func testStaleDayDraftRejectsUnobservedOrReplacedAccountsWithoutSaving() throws {
    let store = try EventStore()
    try store.replace(Snapshot(accounts: [Account(id: "a", name: "A")], records: [DayRecord(date: "2026-10-28", totals: ["a": 10])]))
    let draft = store.editContext(for: .day("2026-10-28"))
    try store.append(.create(.account("b"), generation: "new-b", fields: ["name": .string("B"), "provider": .string(""), "isAsset": .bool(true), "accountType": .decimal(0)]))
    let count = store.events.count
    XCTAssertThrowsError(try store.submit(["totals:b": .decimal(20)], context: draft))
    XCTAssertEqual(store.events.count, count)
    try store.submit(["totals:a": .decimal(11)], context: draft)
    XCTAssertEqual(store.projection.snapshot.records[0].totals["a"], 11)
    let refreshed = store.editContext(for: .day("2026-10-28"))
    try store.submit(["totals:b": .decimal(20)], context: refreshed)
    XCTAssertEqual(store.projection.snapshot.records[0].totals["b"], 20)
    let beforeReplacement = store.editContext(for: .day("2026-10-28"))
    // Exercise replacement arriving from an older client, which permitted historical deletion.
    let previous = store.events.last!
    try store.merge([Event(id: "legacy-b-removal", actor: "old-client", counter: previous.counter + 1,
      parents: [previous.id], epoch: store.projection.epoch, operation: .remove(.account("b"), generation: "new-b"))])
    try store.append(.create(.account("b"), generation: "replacement-b", fields: ["name": .string("New B"), "provider": .string(""), "isAsset": .bool(true), "accountType": .decimal(0)]))
    XCTAssertThrowsError(try store.submit(["totals:b": .decimal(21)], context: beforeReplacement))
  }
  func testStaleDraftRejectsDeletionAndReplacement() throws {
    let store = try EventStore()
    try store.replace(Snapshot(accounts: [Account(id: "a", name: "Original")]))
    let draft = store.editContext(for: .account("a"))
    try store.append(.remove(.account("a"), generation: draft.generation!))
    XCTAssertThrowsError(try store.submit(["name": .string("Stale")], context: draft))
    try store.replace(Snapshot(accounts: [Account(id: "a", name: "Replacement")]))
    XCTAssertThrowsError(try store.submit(["name": .string("Stale")], context: draft))
  }
  func testParsedLocalDayRetainsMillisecondsAndOffsetIdentifier() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/London")!
    let records = [DayRecord(date: "2026-06-30T23:30:00Z"), DayRecord(date: "946598400000")]
    XCTAssertEqual(PortfolioCalculator.record(on: "2026-07-01", records: records, calendar: calendar)?.date, records[0].date)
    XCTAssertEqual(PortfolioCalculator.record(on: "2026-07-01", records: [DayRecord(date: "2026-06-30T23:00:00.000Z")], calendar: calendar)?.date, "2026-06-30T23:00:00.000Z")
    let millis = String(Int(PortfolioCalculator.date("2026-07-01T10:00:00Z").timeIntervalSince1970 * 1000))
    XCTAssertEqual(PortfolioCalculator.record(on: "2026-07-01", records: [DayRecord(date: millis)], calendar: calendar)?.date, millis)
    XCTAssertEqual(PortfolioCalculator.netWorth(accounts: [], records: records).last?.day, records[0].date)
  }
  func testExtremeImportedGoalIsUnavailableWithoutTrapping() throws {
    let data = Data(#"{"accounts":[],"records":[],"goal":{"investmentStyle":100000000000000000000,"retirementAge":100000000000000000000,"lifeStyle":100000000000000000000,"birthDate":100000000000000000000}}"#.utf8)
    let snapshot = try Archive.snapshot(from: data)
    let projection = GoalProjectionCalculator.calculate(settings: snapshot.goal, currentNetWorth: 0)
    XCTAssertFalse(projection.projectedIncomeGoal.isFinite)
    XCTAssertLessThanOrEqual(GoalProjectionCalculator.currentAge(birthDate: "100000000000000000000"), 150)
  }
  func testQuickEntryPreservesMigratedDayAndRetriesDurably() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/London")!
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let repository = JSONFileRepository(url: directory.appendingPathComponent("history.json"))
    let store = try EventStore(commit: { try repository.save($0) })
    try store.replace(Snapshot(accounts: [Account(id: "a", name: "A"), Account(id: "b", name: "B")], records: [DayRecord(date: "2026-06-30T23:30:00Z", totals: ["a": 10, "b": 20], inflows: ["b": 5])]))
    try store.applyQuickEntry(id: "watch-1", accountID: "a", day: "2026-07-01", total: 11, today: "2026-07-01", calendar: calendar)
    let restarted = try EventStore(envelope: repository.load(), commit: { try repository.save($0) })
    let count = restarted.events.count
    try restarted.applyQuickEntry(id: "watch-1", accountID: "a", day: "2026-07-01", total: 11, today: "2026-07-02", calendar: calendar)
    XCTAssertEqual(restarted.events.count, count)
    XCTAssertEqual(restarted.projection.snapshot.records.count, 1)
    XCTAssertEqual(restarted.projection.snapshot.records[0].totals, ["a": 11, "b": 20])
    XCTAssertEqual(restarted.projection.snapshot.records[0].inflows, ["b": 5])
    XCTAssertThrowsError(try restarted.applyQuickEntry(id: "watch-2", accountID: "a", day: "2026-07-01", total: 12, today: "2026-07-02", calendar: calendar))
  }
  func testInvalidRecoveryDoesNotTouchUnreadableOriginal() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let repository = JSONFileRepository(url: directory.appendingPathComponent("history.json"))
    let original = Data("corrupt".utf8)
    try original.write(to: repository.url)
    XCTAssertThrowsError(try repository.recover(Envelope(version: 999)))
    XCTAssertEqual(try Data(contentsOf: repository.url), original)
    XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), ["history.json"])
  }
  func testRecoveryPreservesUnreadableOriginalAndInstallsValidatedBackup() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let repository = JSONFileRepository(url: directory.appendingPathComponent("history.json"))
    let original = Data("{truncated".utf8)
    try original.write(to: repository.url)
    let backup = try repository.recover(Envelope())
    XCTAssertEqual(try Data(contentsOf: backup), original)
    XCTAssertEqual(try repository.load().events.count, 0)
  }
}
