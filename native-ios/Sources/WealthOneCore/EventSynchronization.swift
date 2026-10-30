import Foundation

/// A page from a record zone, independent of record-type queries or query indexes.
public struct EventSyncPage: Sendable {
  public let events: [Event]
  public let deletedIDs: [String]
  public let next: Data?
  public init(events: [Event], deletedIDs: [String] = [], next: Data? = nil) {
    self.events = events; self.deletedIDs = deletedIDs; self.next = next
  }
}
public enum EventSynchronization {
  public static func run(local: [Event],
    fetchPage: @Sendable (Data?) async throws -> EventSyncPage,
    upload: @Sendable (Event) async throws -> Void) async throws -> [Event] {
    var cursor: Data?, seen = Set<Data>(), remote: [String: Event] = [:]
    repeat {
      try Task.checkCancellation()
      let page = try await fetchPage(cursor)
      for event in page.events {
        if let old = remote[event.id], old != event { throw CoreError.invalid("Event ID collision") }
        remote[event.id] = event
      }
      for id in page.deletedIDs { remote[id] = nil }
      cursor = page.next
      if let cursor, !seen.insert(cursor).inserted { throw CoreError.invalid("iCloud returned a repeated history page. Sync will retry.") }
    } while cursor != nil
    let downloaded = remote.values.sorted(by: canonical)
    // Never upload into a corrupt or conflicting remote history. A failed fetch
    // is an error, not permission to treat an existing cloud account as empty.
    let validation = try EventStore(envelope: Envelope(events: local))
    try validation.merge(downloaded)
    for event in local.sorted(by: canonical) where remote[event.id] == nil {
      try Task.checkCancellation()
      try await upload(event)
    }
    return downloaded
  }
}
