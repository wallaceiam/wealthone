import CloudKit
import Foundation
import WealthOneCore

/// Only immutable events cross the network. Read models never leave this device.
actor CloudEventTransport {
  static let containerID = "iCloud.ca.mymojo.wealthone.native"
  private let zoneID = CKRecordZone.ID(zoneName: "WealthOneEvents")
  private let ownerURL: URL

  init(directory: URL) { ownerURL = directory.appendingPathComponent("cloud-owner.txt") }

  func synchronize(_ local: [Event]) async throws -> [Event] {
    #if targetEnvironment(simulator)
    throw SyncError.unavailable
    #else
    let container = CKContainer(identifier: Self.containerID)
    guard try await container.accountStatus() == .available else {
      throw SyncError.unavailable
    }
    let owner = try await container.userRecordID().recordName
    if FileManager.default.fileExists(atPath: ownerURL.path) {
      guard try String(contentsOf: ownerURL, encoding: .utf8) == owner else {
        throw SyncError.accountChanged
      }
    } else {
      try Data(owner.utf8).write(to: ownerURL, options: .atomic)
    }
    let database = container.privateCloudDatabase
    _ = try await database.save(CKRecordZone(zoneID: zoneID))
    // Enumerate the zone, not a record type. Fresh databases have no WealthEvent
    // schema until the first upload, so querying that type would deadlock setup.
    return try await EventSynchronization.run(local: local, fetchPage: { cursor in
      try await self.downloadPage(from: database, after: cursor)
    }, upload: { event in
      try await self.upload(event, to: database)
    })
    #endif
  }

  private func downloadPage(from database: CKDatabase, after cursor: Data?) async throws -> EventSyncPage {
    let token: CKServerChangeToken?
    if let cursor {
      guard let decoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: cursor) else {
        throw SyncError.corruptEvent
      }
      token = decoded
    } else { token = nil }
    let page = try await database.recordZoneChanges(inZoneWith: zoneID, since: token, desiredKeys: ["payload"], resultsLimit: 200)
    var events: [Event] = []
    for (_, result) in page.modificationResultsByID {
      let record = try result.get().record
      guard record.recordType == "WealthEvent", let asset = record["payload"] as? CKAsset, let url = asset.fileURL else {
        throw SyncError.corruptEvent
      }
      let event = try JSONDecoder().decode(Event.self, from: Data(contentsOf: url))
      guard event.id == record.recordID.recordName else { throw SyncError.corruptEvent }
      events.append(event)
    }
    let next = page.moreComing ? try NSKeyedArchiver.archivedData(withRootObject: page.changeToken, requiringSecureCoding: true) : nil
    return EventSyncPage(events: events, deletedIDs: page.deletions.filter { $0.recordType == "WealthEvent" }.map { $0.recordID.recordName }, next: next)
  }
  private func upload(_ event: Event, to database: CKDatabase) async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: url) }
    try JSONEncoder().encode(event).write(to: url, options: .atomic)
    let record = CKRecord(recordType: "WealthEvent", recordID: CKRecord.ID(recordName: event.id, zoneID: zoneID))
    record["payload"] = CKAsset(fileURL: url)
    do { _ = try await database.save(record) } catch let error as CKError where error.code == .serverRecordChanged {
      let existing = try await database.record(for: record.recordID)
      guard let asset = existing["payload"] as? CKAsset, let storedURL = asset.fileURL,
        try JSONDecoder().decode(Event.self, from: Data(contentsOf: storedURL)) == event else {
        throw SyncError.corruptEvent
      }
    }
  }

  enum SyncError: LocalizedError {
    case unavailable, accountChanged, corruptEvent
    var errorDescription: String? {
      switch self {
      case .unavailable:
        "iCloud is unavailable. Your edits are saved on this device; sync will retry."
      case .accountChanged:
        "Your iCloud account has changed. Sync is paused to keep these accounts separate. Export a backup before moving data to another account."
      case .corruptEvent:
        "An iCloud history record could not be verified. Local history is safe; sync is paused."
      }
    }
  }
}
