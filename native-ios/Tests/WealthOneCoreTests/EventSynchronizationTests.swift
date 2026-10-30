import Foundation
import XCTest
@testable import WealthOneCore

final class EventSynchronizationTests: XCTestCase {
  actor Backend {
    var pages: [EventSyncPage]
    var requests: [Data?] = []
    var uploads: [Event] = []
    init(_ pages: [EventSyncPage]) { self.pages = pages }
    func fetch(_ cursor: Data?) throws -> EventSyncPage {
      requests.append(cursor)
      guard !pages.isEmpty else { throw CoreError.invalid("unexpected page") }
      return pages.removeFirst()
    }
    func save(_ event: Event) { uploads.append(event) }
  }
  func history() throws -> [Event] {
    let s = try EventStore()
    try s.replace(Snapshot(accounts: [Account(id: "a", name: "Savings")], records: [DayRecord(date: "2026-10-30", totals: ["a": 100])]))
    try s.append(.create(.account("b"), generation: "b", fields: ["name": .string("Other")]))
    return s.events
  }
  func testFreshZoneCanUploadInitialHistoryWithoutAnyExistingRecordType() async throws {
    let events = try history()
    let cloud = Backend([EventSyncPage(events: [])])
    let remote = try await EventSynchronization.run(local: events, fetchPage: { try await cloud.fetch($0) }, upload: { await cloud.save($0) })
    XCTAssertTrue(remote.isEmpty)
    let saved = await cloud.uploads
    XCTAssertEqual(saved, events)
    let requests = await cloud.requests
    XCTAssertEqual(requests.count, 1)
    XCTAssertNil(requests[0])
  }
  func testFreshReceiverGetsAllPagesInAnyOrderAndDoesNotReuploadKnownEvents() async throws {
    let events = try history(), token = Data([1])
    let cloud = Backend([EventSyncPage(events: [events[1]], next: token), EventSyncPage(events: [events[0]])])
    let remote = try await EventSynchronization.run(local: [], fetchPage: { try await cloud.fetch($0) }, upload: { await cloud.save($0) })
    let receiver = try EventStore(); try receiver.merge(remote)
    XCTAssertEqual(receiver.projection.snapshot.accounts.count, 2)
    XCTAssertEqual(receiver.projection.snapshot.records.count, 1)
    XCTAssertTrue(receiver.projection.bufferedEventIDs.isEmpty)
    let requests = await cloud.requests; XCTAssertEqual(requests, [nil, token])
    let saved = await cloud.uploads; XCTAssertTrue(saved.isEmpty)
  }
  func testCollisionFailsBeforeUploadingAnythingAndFetchFailuresDoNotPretendEmpty() async throws {
    let events = try history(), original = events[0]
    let collision = Event(id: original.id, actor: original.actor, counter: original.counter, parents: original.parents, epoch: original.epoch, operation: .replace(Snapshot()))
    let cloud = Backend([EventSyncPage(events: [collision])])
    do {
      _ = try await EventSynchronization.run(local: events, fetchPage: { try await cloud.fetch($0) }, upload: { await cloud.save($0) })
      XCTFail("Collision must reject the sync")
    } catch { }
    let uploaded = await cloud.uploads; XCTAssertTrue(uploaded.isEmpty)
    do {
      _ = try await EventSynchronization.run(local: events, fetchPage: { _ in throw CoreError.invalid("offline") }, upload: { await cloud.save($0) })
      XCTFail("Fetch failure must propagate")
    } catch { }
    let afterFailure = await cloud.uploads; XCTAssertTrue(afterFailure.isEmpty)
  }
  func testDeletedImmutableEventCanBeRestoredFromLocalHistoryAndDuplicatePagesAreSafe() async throws {
    let events = try history(), token = Data([2])
    let cloud = Backend([EventSyncPage(events: events, next: token), EventSyncPage(events: [events[0]], deletedIDs: [events[1].id])])
    let remote = try await EventSynchronization.run(local: events, fetchPage: { try await cloud.fetch($0) }, upload: { await cloud.save($0) })
    XCTAssertEqual(remote, [events[0]])
    let saved = await cloud.uploads; XCTAssertEqual(saved, [events[1]])
  }
  func testRepeatedPaginationTokenCannotLoopForever() async throws {
    let token = Data([1]), cloud = Backend([EventSyncPage(events: [], next: Data([1])), EventSyncPage(events: [], next: Data([1]))])
    do {
      _ = try await EventSynchronization.run(local: [], fetchPage: { try await cloud.fetch($0) }, upload: { await cloud.save($0) })
      XCTFail("Repeated cursor must fail")
    } catch { }
    let requests = await cloud.requests; XCTAssertEqual(requests, [nil, token])
  }
}
