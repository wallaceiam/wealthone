import XCTest

@testable import WealthOneCore

final class ReviewRegressionTests: XCTestCase {
  func testConcurrentDayCreationsShareLifecycle() throws {
    for sameGeneration in [false, true] {
      let base = Event(
        id: "base", actor: "base", counter: 1, parents: [], epoch: "root",
        operation: .replace(
          Snapshot(accounts: [Account(id: "a", name: "A"), Account(id: "b", name: "B")])))
      let left = Event(
        id: "left", actor: "L", counter: 2, parents: [base.id], epoch: base.id,
        operation: .create(
          .day("2020-01-01"), generation: "left",
          fields: ["totals:a": .decimal(10), "outflows:a": .decimal(4)]))
      let rightGeneration = sameGeneration ? "left" : "right"
      let right = Event(
        id: "right", actor: "R", counter: 2, parents: [base.id], epoch: base.id,
        operation: .create(
          .day("2020-01-01"), generation: rightGeneration,
          fields: ["totals:b": .decimal(20), "totals:a": .decimal(11)]))
      let edit = Event(
        id: "edit", actor: "L", counter: 3, parents: [left.id], epoch: base.id,
        operation: .edit(.day("2020-01-01"), generation: "left", fields: ["inflows:a": .decimal(3)])
      )
      let expected = try Projection(events: [base, left, right, edit])
      XCTAssertEqual(expected.snapshot.records.first?.totals, ["a": 11, "b": 20])
      XCTAssertEqual(expected.snapshot.records.first?.inflows, ["a": 3])
      XCTAssertEqual(expected.conflicts.count, 1)
      XCTAssertEqual(expected.snapshot.records.first?.outflows, ["a": 4])
      XCTAssertEqual(expected, try Projection(events: [edit, right, left, base, left]))
      let store = try EventStore()
      try store.merge([base, left, right, edit])
      let gen = try XCTUnwrap(store.projection.generation(for: .day("2020-01-01")))
      _ = try store.append(.remove(.day("2020-01-01"), generation: gen))
      XCTAssertTrue(store.projection.snapshot.records.isEmpty)
      _ = try store.append(
        .create(.day("2020-01-01"), generation: "recreated", fields: ["totals:b": .decimal(50)]))
      let late = Event(
        id: "late", actor: "late", counter: 100, parents: [left.id], epoch: base.id,
        operation: .edit(
          .day("2020-01-01"), generation: "left", fields: ["totals:a": .decimal(900)]))
      try store.merge([late])
      XCTAssertEqual(store.projection.snapshot.records.first?.totals, ["b": 50])
    }
  }
  func testSharedAccountAndDateValidation() throws {
    let invalid: [WealthOneCore.Operation] = [
      .create(.account("a"), generation: "g", fields: [:]),
      .create(.account("a"), generation: "g", fields: ["name": .string(" ")]),
      .create(
        .account("a"), generation: "g",
        fields: ["name": .string("a"), "accountType": .decimal(1.5)]),
      .create(
        .account("a"), generation: "g",
        fields: ["name": .string("a"), "accountType": .decimal(999)]),
      .create(
        .account("a"), generation: "g",
        fields: ["name": .string("a"), "isAsset": .bool(false), "accountType": .decimal(0)]),
      .create(.day("garbage"), generation: "g", fields: [:]),
    ]
    for operation in invalid {
      XCTAssertThrowsError(try EventStore().append(operation))
      let event = Event(
        id: "e", actor: "a", counter: 1, parents: [], epoch: "root", operation: operation)
      XCTAssertThrowsError(try Projection(events: [event]))
      XCTAssertThrowsError(try Archive.export(events: [event]))
    }
    let store = try EventStore()
    _ = try store.append(.create(.account("a"), generation: "g", fields: ["name": .string("A")]))
    _ = try store.append(
      .edit(.account("a"), generation: "g", fields: ["provider": .string("partial")]))
    XCTAssertEqual(store.projection.snapshot.accounts.first?.provider, "partial")
    XCTAssertThrowsError(
      try store.append(.edit(.account("a"), generation: "g", fields: ["isAsset": .bool(false)])))
  }
  func testMalformedGoalsRejectAcrossEntryPaths() throws {
    for goal in ["42", "[]", "{\"input\":42}", "{\"input\":{\"retirementAge\":{\"bad\":42}}}"] {
      let raw = "{\"accounts\":[],\"records\":[],\"goal\":\(goal)}"
      XCTAssertThrowsError(try Archive.snapshot(from: Data(raw.utf8)))
      XCTAssertThrowsError(try LegacyReduxDecoder.decode(raw))
    }
    XCTAssertThrowsError(try Archive.validate(Snapshot(goal: ["retirementAge": .decimal(.nan)])))
    XCTAssertThrowsError(
      try EventStore().replace(Snapshot(goal: ["retirementAge": .decimal(.nan)])))
    let snapshot = try Archive.snapshot(
      from: Data(
        "{\"accounts\":[],\"records\":[],\"goal\":{\"input\":{\"birthDate\":\"2000-01-01\",\"retirementAge\":65,\"flag\":true,\"optional\":null}}}"
          .utf8))
    XCTAssertEqual(snapshot.goal["flag"], .bool(true))
    XCTAssertEqual(snapshot.goal["optional"], .null)
  }
}
extension ReviewRegressionTests {
  func testConcurrentClassificationUsesTypeAndAllowsPartialFollowup() throws {
    let base = Event(
      id: "base", actor: "base", counter: 1, parents: [], epoch: "root",
      operation: .create(
        .account("a"), generation: "g",
        fields: ["name": .string("A"), "isAsset": .bool(true), "accountType": .decimal(0)]))
    let liability = Event(
      id: "liability", actor: "A", counter: 2, parents: [base.id], epoch: "root",
      operation: .edit(
        .account("a"), generation: "g",
        fields: ["isAsset": .bool(false), "accountType": .decimal(7)]))
    let asset = Event(
      id: "asset", actor: "B", counter: 2, parents: [base.id], epoch: "root",
      operation: .edit(.account("a"), generation: "g", fields: ["accountType": .decimal(1)]))
    let store = try EventStore()
    try store.merge([asset, base, liability])
    XCTAssertEqual(store.projection.snapshot.accounts.first?.isAsset, true)
    _ = try store.append(
      .edit(.account("a"), generation: "g", fields: ["provider": .string("partial")]))
    XCTAssertEqual(store.projection.snapshot.accounts.first?.provider, "partial")
  }
}
