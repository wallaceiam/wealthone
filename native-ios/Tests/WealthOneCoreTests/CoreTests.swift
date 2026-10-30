import XCTest

@testable import WealthOneCore

final class CoreTests: XCTestCase {
  func testCausalConcurrencyBufferAndDuplicate() throws {
    let a = Event(
      id: "a", actor: "A", counter: 1, parents: [], epoch: "root",
      operation: .create(.account("x"), generation: "g", fields: ["name": .string("base")]))
    let b = Event(
      id: "b", actor: "A", counter: 2, parents: ["a"], epoch: "root",
      operation: .edit(.account("x"), generation: "g", fields: ["name": .string("one")]))
    let c = Event(
      id: "c", actor: "B", counter: 2, parents: ["a"], epoch: "root",
      operation: .edit(.account("x"), generation: "g", fields: ["name": .string("two")]))
    XCTAssertEqual(try Projection(events: [b]).bufferedEventIDs, ["b"])
    let p = try Projection(events: [c, a, b, a])
    XCTAssertEqual(p.snapshot.accounts.first?.name, "two")
    XCTAssertEqual(p.conflicts.count, 1)
    XCTAssertEqual(p, try Projection(events: [a, b, c]))
    let d = Event(
      id: "d", actor: "A", counter: 3, parents: ["b", "c"], epoch: "root",
      operation: .edit(.account("x"), generation: "g", fields: ["name": .string("fixed")]))
    XCTAssertTrue(try Projection(events: [d, c, b, a]).conflicts.isEmpty)
  }
  func testDurabilityArchiveAndLifecycle() throws {
    var commitCalls = 0
    let store = try EventStore(commit: { _ in
      commitCalls += 1
      throw CocoaError(.fileWriteUnknown)
    })
    let initialEnvelope = store.envelope
    let initialProjection = store.projection
    XCTAssertThrowsError(
      try store.append(
        .create(
          .account("x"), generation: "g",
          fields: [
            "name": .string("Cash"), "provider": .string("Bank"),
            "isAsset": .bool(true), "accountType": .decimal(0),
          ])))
    XCTAssertEqual(commitCalls, 1)
    XCTAssertEqual(store.envelope, initialEnvelope)
    XCTAssertEqual(store.projection, initialProjection)
    XCTAssertTrue(store.events.isEmpty)
    XCTAssertEqual(store.envelope.clock, 0)
    let ok = try EventStore()
    let a = try ok.append(.create(.account("x"), generation: "g", fields: ["name": .string("old")]))
    _ = try ok.append(.remove(.account("x"), generation: "g"))
    try ok.merge([
      Event(
        id: "late", actor: "B", counter: 2, parents: [a.id], epoch: "root",
        operation: .edit(.account("x"), generation: "g", fields: ["name": .string("late")]))
    ])
    XCTAssertTrue(ok.projection.snapshot.accounts.isEmpty)
    _ = try ok.replace(Snapshot())
    try ok.merge([a])
    XCTAssertTrue(ok.projection.snapshot.accounts.isEmpty)
    XCTAssertEqual(try Archive.events(from: Archive.export(events: ok.events)), ok.events)
    var collision = a
    collision = Event(
      id: a.id, actor: "evil", counter: 1, parents: [], epoch: "root", operation: a.operation)
    XCTAssertThrowsError(try ok.merge([collision]))
    XCTAssertThrowsError(try Archive.events(from: Data("{}".utf8)))
  }
}
extension CoreTests {
  func testRepositoryRestartSparseDecimalAndLegacy() throws {
    let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: url) }
    let repo = JSONFileRepository(url: url)
    let store = try EventStore(commit: repo.save)
    let baseline = Snapshot(
      accounts: [Account(id: "a", name: "cash")],
      records: [DayRecord(date: "2020-03-29T23:00:00Z", totals: ["a": Decimal(string: "123.45")!])],
      goal: ["lifeStyle": .decimal(2)])
    _ = try store.replace(baseline)
    XCTAssertEqual(store.projection.snapshot, baseline)
    let reopened = try EventStore(envelope: repo.load(), commit: repo.save)
    XCTAssertEqual(reopened.envelope.actor, store.envelope.actor)
    let e = try reopened.append(
      .edit(
        .account("a"), generation: reopened.projection.generation(for: .account("a"))!,
        fields: ["provider": .string("bank")]))
    XCTAssertGreaterThan(e.counter, store.envelope.clock)
    let raw = Data(
      """
      {"categories":[{"id":"a","name":"cash","isAsset":true}],"records":[{"date":"1999-12-31T23:00:00Z","totals":[null,12.34],"inflows":[null,null],"outflows":[null,0.01]}]}
      """.utf8)
    let imported = try Archive.snapshot(from: raw)
    XCTAssertEqual(imported.records[0].totals["a"], Decimal(string: "12.34"))
    XCTAssertEqual(imported.records[0].date, "1999-12-31T23:00:00Z")
  }
  func testInvalidEventsAndFailedMergeDoNotPublish() throws {
    let a = Event(
      id: "a", actor: "A", counter: 1, parents: ["b"], epoch: "root",
      operation: .replace(Snapshot()))
    let b = Event(
      id: "b", actor: "A", counter: 2, parents: ["a"], epoch: "root",
      operation: .replace(Snapshot()))
    XCTAssertThrowsError(try Projection(events: [a, b]))
    let s = try EventStore(commit: { _ in throw CocoaError(.fileWriteUnknown) })
    let baseline = Event(
      id: "base", actor: "B", counter: 1, parents: [], epoch: "root",
      operation: .replace(Snapshot()))
    XCTAssertThrowsError(try s.merge([baseline]))
    XCTAssertTrue(s.events.isEmpty)
    XCTAssertThrowsError(
      try EventStore(envelope: Envelope(actor: "B", clock: 0, events: [baseline])))
  }
  func testAllPermutationsAndRecreation() throws {
    let a = Event(
      id: "a", actor: "A", counter: 1, parents: [], epoch: "root",
      operation: .create(.account("a"), generation: "g", fields: ["name": .string("a")]))
    let b = Event(
      id: "b", actor: "A", counter: 2, parents: ["a"], epoch: "root",
      operation: .edit(.account("a"), generation: "g", fields: ["name": .string("b")]))
    let c = Event(
      id: "c", actor: "B", counter: 2, parents: ["a"], epoch: "root",
      operation: .edit(.account("a"), generation: "g", fields: ["provider": .string("c")]))
    let expected = try Projection(events: [a, b, c])
    for permutation in [[a, b, c], [a, c, b], [b, a, c], [b, c, a], [c, a, b], [c, b, a]] {
      XCTAssertEqual(try Projection(events: permutation + permutation), expected)
    }
    let store = try EventStore()
    try store.merge([a, b, c])
    _ = try store.append(.remove(.account("a"), generation: "g"))
    _ = try store.append(
      .create(.account("a"), generation: "new", fields: ["name": .string("fresh")]))
    XCTAssertEqual(store.projection.snapshot.accounts.first?.name, "fresh")
  }
}
extension CoreTests {
  func testAccountRecreationDoesNotResurrectHistoricalAmounts() throws {
    let store = try EventStore()
    let base = try store.replace(
      Snapshot(
        accounts: [Account(id: "a", name: "old")],
        records: [DayRecord(date: "2000-01-01", totals: ["a": 42])]))
    // Older clients could delete populated accounts. Imported history must still replay safely.
    try store.merge([Event(id: "legacy-removal", actor: "old-client", counter: 2, parents: [base.id], epoch: base.id,
      operation: .remove(.account("a"), generation: base.id))])
    _ = try store.append(
      .create(.account("a"), generation: "fresh", fields: ["name": .string("new")]))
    XCTAssertNil(store.projection.snapshot.records.first?.totals["a"])
  }
}
extension CoreTests {
  func testCommandValidationAndEpochExcludesDelayedEdits() throws {
    let store = try EventStore()
    XCTAssertThrowsError(
      try store.append(
        .create(.day("2020-01-01"), generation: "d", fields: ["totals:missing": .decimal(5)])))
    XCTAssertThrowsError(try store.append(.create(.day("invalid"), generation: "d", fields: [:])))
    let a = try store.append(
      .create(.account("a"), generation: "g", fields: ["name": .string("old")]))
    _ = try store.replace(Snapshot(accounts: [Account(id: "b", name: "new")]))
    let late = Event(
      id: "late", actor: "remote", counter: 900, parents: [a.id], epoch: "root",
      operation: .edit(.account("a"), generation: "g", fields: ["name": .string("late")]))
    try store.merge([late])
    XCTAssertEqual(store.projection.snapshot.accounts.map(\.id), ["b"])
    XCTAssertTrue(store.events.contains(late))
  }
}
extension CoreTests {
  func testStrictArchivesAndCategoryOffset() throws {
    for json in [
      "{\"schemaVersion\":99,\"accounts\":[],\"records\":[]}",
      "{\"accounts\":[{\"name\":\"missing id\",\"isAsset\":true}],\"records\":[]}",
      "{\"accounts\":[],\"records\":[{\"date\":\"garbage\"}]}",
      "{\"accounts\":[{\"id\":\"a\",\"name\":\"a\",\"isAsset\":true}],\"records\":[{\"date\":\"2020-01-01\",\"totals\":[{\"id\":\"a\",\"amount\":true}]}]}",
      "{\"accounts\":[{\"id\":\"a\",\"name\":\"a\",\"isAsset\":true}],\"records\":[{\"date\":\"2020-01-01\",\"totals\":[{\"id\":\"a\",\"amount\":\"12oops\"}]}]}",
    ] { XCTAssertThrowsError(try Archive.snapshot(from: Data(json.utf8)), json) }
    let snapshot = try Archive.snapshot(
      from: Data(
        "{\"categories\":[{\"name\":\"dummy\"},{\"id\":\"debt\",\"name\":\"debt\",\"isAsset\":false}],\"records\":[{\"date\":946684800000,\"totals\":[null,12.5]}]}"
          .utf8))
    XCTAssertEqual(snapshot.accounts.count, 1)
    XCTAssertEqual(snapshot.accounts.first?.accountType, 7)
    XCTAssertEqual(snapshot.records.first?.date, "946684800000")
  }
}
