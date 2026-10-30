import Foundation
import XCTest

@testable import WealthOneCore

@MainActor
final class LegacyRecoveryTests: XCTestCase {
  final class Observation: LegacyRecoveryObservation, @unchecked Sendable {
    private let lock = NSLock()
    private var value = false
    var cancelled: Bool { lock.withLock { value } }
    func cancel() { lock.withLock { value = true } }
  }
  final class Source: LegacyRecoverySource {
    var isSupported = true
    var accountIdentity: NSObject? = NSString(string: "account-a")
    var accepted = true
    var values: [String: String] = [:]
    var duringSync: (() -> Void)?
    var duringRead: (() -> Void)?
    var observers: [(Observation, @MainActor @Sendable (LegacyRecoveryChange) -> Void)] = []
    func synchronize() -> Bool {
      duringSync?()
      return accepted
    }
    func readValues() -> [String: String] {
      duringRead?()
      return values
    }
    func observe(_ handler: @escaping @MainActor @Sendable (LegacyRecoveryChange) -> Void)
      -> any LegacyRecoveryObservation
    {
      let token = Observation()
      observers.append((token, handler))
      return token
    }
    func emit(_ change: LegacyRecoveryChange) {
      for (token, handler) in observers where !token.cancelled { handler(change) }
    }
  }
  private func fixture(_ name: String = "Recovered") -> String {
    "{\"accounts\":[{\"id\":\"a\",\"name\":\"\(name)\",\"isAsset\":true,\"accountType\":0}],\"records\":[{\"date\":\"2026-10-28\",\"totals\":{\"a\":123.45},\"inflows\":{},\"outflows\":{}}],\"goal\":{}}"
  }
  func testObserverIsInstalledBeforeSyncAndLateValuesAreDiscovered() throws {
    let source = Source()
    let session = LegacyRecoverySession(source: source)
    source.duringSync = {
      XCTAssertEqual(source.observers.filter { !$0.0.cancelled }.count, 1)
      source.values = ["backup": self.fixture()]
      source.emit(.changed)
    }
    session.start()
    XCTAssertEqual(session.phase, .found)
    XCTAssertEqual(session.report.candidates.first?.snapshot.accounts.first?.name, "Recovered")
  }
  func testTimeoutIsNotAbsenceAndLaterDownloadStillAppears() {
    let source = Source()
    let session = LegacyRecoverySession(source: source)
    session.start()
    XCTAssertEqual(session.phase, .waiting)
    session.finishWaiting()
    XCTAssertEqual(session.phase, .noDataYet)
    source.values["backup"] = fixture()
    source.emit(.changed)
    XCTAssertEqual(session.phase, .found)
  }
  func testAccountChangeInvalidatesCandidateAndPreventsUse() {
    let source = Source()
    source.values["backup"] = fixture()
    let session = LegacyRecoverySession(source: source)
    session.start()
    let revision = session.revision
    XCTAssertTrue(session.canUse(revision: revision))
    source.accountIdentity = NSString(string: "account-b")
    XCTAssertFalse(session.canUse(revision: revision))  // Even before notification is delivered.
    source.emit(.accountChanged)
    XCTAssertEqual(session.phase, .accountChanged)
    XCTAssertTrue(session.report.candidates.isEmpty)
    XCTAssertNotEqual(session.revision, revision)
  }
  func testRetryAfterAccountChangeWaitsForACloudUpdate() {
    let source = Source()
    source.values["backup"] = fixture("Account A")
    let session = LegacyRecoverySession(source: source)
    session.start()
    source.accountIdentity = NSString(string: "account-b")
    source.emit(.accountChanged)
    session.start()
    XCTAssertEqual(session.phase, .waiting)
    XCTAssertTrue(session.report.candidates.isEmpty)
    source.values["backup"] = fixture("Account B")
    source.emit(.changed)
    XCTAssertEqual(session.report.candidates.first?.snapshot.accounts.first?.name, "Account B")
  }

  func testRetryBeforeAccountCallbackDoesNotAuthorizeOldCache() {
    let source = Source()
    source.values["backup"] = fixture("Account A")
    let session = LegacyRecoverySession(source: source)
    session.start()
    source.accountIdentity = NSString(string: "account-b")
    session.start()
    XCTAssertEqual(session.phase, .waiting)
    XCTAssertTrue(session.report.candidates.isEmpty)
    XCTAssertFalse(session.canUse(revision: session.revision))
    source.values["backup"] = fixture("Account B")
    source.emit(.changed)
    XCTAssertEqual(session.report.candidates.first?.snapshot.accounts.first?.name, "Account B")
  }
  func testAccountUnavailableBetweenAccountsDoesNotForgetOwner() {
    let source = Source()
    source.values["backup"] = fixture("Account A")
    let session = LegacyRecoverySession(source: source)
    session.start()
    source.accountIdentity = nil
    session.start()
    source.accountIdentity = NSString(string: "account-b")
    session.start()
    XCTAssertTrue(session.report.candidates.isEmpty)
    XCTAssertFalse(session.canUse(revision: session.revision))
  }
  func testAccountInvalidationDuringReadCannotPublishOldCandidates() {
    let source = Source()
    source.values["backup"] = fixture()
    let session = LegacyRecoverySession(source: source)
    source.duringRead = {
      source.accountIdentity = NSString(string: "account-b")
      source.emit(.accountChanged)
    }
    session.start()
    XCTAssertEqual(session.phase, .accountChanged)
    XCTAssertTrue(session.report.candidates.isEmpty)
  }
  func testQuotaCallbackDoesNotMaskDetectedAccountChange() {
    let source = Source()
    source.values["backup"] = fixture()
    let session = LegacyRecoverySession(source: source)
    session.start()
    source.accountIdentity = NSString(string: "account-b")
    source.emit(.quotaExceeded)
    XCTAssertEqual(session.phase, .accountChanged)
    XCTAssertTrue(session.report.candidates.isEmpty)
  }

  func testRetryCancelsOldObservationAndFailedSyncIsExplicit() {
    let source = Source()
    let session = LegacyRecoverySession(source: source)
    session.start()
    session.start()
    XCTAssertTrue(source.observers[0].0.cancelled)
    source.accepted = false
    session.start()
    XCTAssertEqual(session.phase, .accessRejected)
    XCTAssertTrue(session.report.candidates.isEmpty)
  }
  func testMissingAccountAndUnsupportedSourceNeverOfferImport() {
    let source = Source()
    source.accountIdentity = nil
    let session = LegacyRecoverySession(source: source)
    session.start()
    XCTAssertEqual(session.phase, .accountUnavailable)
    source.isSupported = false
    session.start()
    XCTAssertEqual(session.phase, .unsupported)
  }
  func testQuotaNotificationCannotExposeThePreviousAccountsCache() {
    let source = Source()
    source.values["backup"] = fixture("Account A")
    let session = LegacyRecoverySession(source: source)
    session.start()
    source.accountIdentity = NSString(string: "account-b")
    source.emit(.accountChanged)
    session.start()
    source.emit(.quotaExceeded)
    XCTAssertTrue(session.report.candidates.isEmpty)
    XCTAssertFalse(session.canUse(revision: session.revision))
  }
  func testFirstAccountBecomingAvailableCanReadItsCachedValues() {
    let source = Source()
    source.accountIdentity = nil
    let session = LegacyRecoverySession(source: source)
    session.start()
    source.accountIdentity = NSString(string: "account-a")
    source.values["backup"] = fixture()
    session.start()
    XCTAssertEqual(session.phase, .found)
  }

  func testCorruptPrimaryKeepsOriginalAndValidBackupRoundTrips() throws {
    let values = ["persist:wealthone_data": "bad", "backup": fixture()]
    let report = LegacyRecoveryReport.scan(values)
    XCTAssertEqual(report.unreadableSources, ["persist:wealthone_data"])
    let candidate = try XCTUnwrap(report.candidates.first)
    XCTAssertEqual(candidate.source, "backup")
    XCTAssertEqual(try Archive.snapshot(from: candidate.archive), candidate.snapshot)
    let raw = try XCTUnwrap(report.originalArchive)
    let root = try XCTUnwrap(JSONSerialization.jsonObject(with: raw) as? [String: Any])
    XCTAssertEqual(root["values"] as? [String: String], values)
  }
  func testAllCandidatesRetainSourcePriorityAndScanningDoesNotImport() throws {
    let source = Source()
    source.values = ["backup": fixture("Older"), "persist:wealthone_data": fixture("Latest")]
    let store = try EventStore()
    let session = LegacyRecoverySession(source: source)
    session.start()
    XCTAssertEqual(session.report.candidates.map(\.source), ["persist:wealthone_data", "backup"])
    XCTAssertTrue(store.events.isEmpty)
  }
  func testBackupFailurePreventsReplacementAndSuccessPreservesHistory() throws {
    let store = try EventStore()
    try store.replace(Snapshot(accounts: [Account(id: "old", name: "Current")]))
    let before = store.envelope
    let recovered = try XCTUnwrap(LegacyRecoveryReport.scan(["backup": fixture()]).candidates.first)
    enum Failure: Error { case diskFull }
    XCTAssertThrowsError(
      try LegacyRecoveryImport.apply(
        recovered, to: store, saveBackup: { _ in throw Failure.diskFull }))
    XCTAssertEqual(store.envelope, before)
    var backup: Data?
    try LegacyRecoveryImport.apply(recovered, to: store, saveBackup: { backup = $0 })
    XCTAssertEqual(try Archive.events(from: XCTUnwrap(backup)), before.events)
    XCTAssertEqual(store.events.count, before.events.count + 1)
    XCTAssertEqual(store.projection.snapshot.accounts.first?.name, "Recovered")
    XCTAssertEqual(store.projection.snapshot.records.first?.totals["a"], Decimal(string: "123.45"))
  }
}
