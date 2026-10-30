import Foundation

public enum LegacyRecoveryChange: Sendable { case changed, accountChanged, quotaExceeded }
public protocol LegacyRecoveryObservation: AnyObject, Sendable { func cancel() }

@MainActor
public protocol LegacyRecoverySource: AnyObject {
  var isSupported: Bool { get }
  var accountIdentity: NSObject? { get }
  func synchronize() -> Bool
  func readValues() -> [String: String]
  func observe(_ handler: @escaping @MainActor @Sendable (LegacyRecoveryChange) -> Void)
    -> any LegacyRecoveryObservation
}

public struct LegacyRecoveredCandidate: Identifiable, Sendable {
  public var id: String { source }
  public let source: String
  public let snapshot: Snapshot
  public let archive: Data
}

public struct LegacyRecoveryReport: Sendable {
  public static let keys = ["persist:wealthone_data", "wealthone", "backup"]
  public var candidates: [LegacyRecoveredCandidate] = []
  public var unreadableSources: [String] = []
  public var originalArchive: Data?
  public init() {}
  private struct StateArchive: Encodable {
    let version = 1
    let snapshot: Snapshot
  }

  public static func scan(_ values: [String: String]) -> Self {
    var result = Self()
    let known = values.filter { keys.contains($0.key) }
    if !known.isEmpty {
      result.originalArchive = try? JSONSerialization.data(
        withJSONObject: [
          "format": "WealthOneLegacyKVS", "version": 1, "values": known,
        ], options: [.sortedKeys])
    }
    for key in keys {
      guard let raw = known[key] else { continue }
      do {
        let snapshot = try LegacyReduxDecoder.decode(raw)
        try Archive.validate(snapshot)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let archive = try encoder.encode(StateArchive(snapshot: snapshot))
        result.candidates.append(.init(source: key, snapshot: snapshot, archive: archive))
      } catch { result.unreadableSources.append(key) }
    }
    return result
  }
}

/// Discovery never writes to the source or to a native EventStore.
@MainActor
public final class LegacyRecoverySession {
  public enum Phase: String, Sendable {
    case idle, waiting, found, noDataYet, invalidData, accountUnavailable, accessRejected
    case accountChanged, quotaExceeded, unsupported
  }
  public private(set) var phase: Phase = .idle
  public private(set) var report = LegacyRecoveryReport()
  public private(set) var revision = 0
  public private(set) var quotaWarning = false
  public var onChange: (@MainActor () -> Void)?
  private let source: any LegacyRecoverySource
  private var observation: (any LegacyRecoveryObservation)?
  private var identity: NSObject?
  private var lastKnownIdentity: NSObject?
  private var needsAccountRefresh = false
  public init(source: any LegacyRecoverySource) { self.source = source }
  deinit { observation?.cancel() }

  public func start() {
    observation?.cancel()
    revision += 1
    report = LegacyRecoveryReport()
    quotaWarning = false
    guard source.isSupported else {
      invalidate(.unsupported)
      return
    }
    guard let identity = source.accountIdentity else {
      invalidate(.accountUnavailable)
      return
    }
    if let previous = lastKnownIdentity, !identity.isEqual(previous) { needsAccountRefresh = true }
    lastKnownIdentity = identity
    self.identity = identity
    phase = .waiting
    let token = revision
    observation = source.observe { [weak self] change in
      guard let self, self.revision == token else { return }
      switch change {
      case .accountChanged: self.invalidate(.accountChanged)
      case .changed:
        self.needsAccountRefresh = false
        self.refresh()
      case .quotaExceeded:
        self.quotaWarning = true
        if !self.needsAccountRefresh { self.refresh() }
        guard self.revision == token else { return }
        if self.report.candidates.isEmpty {
          self.phase = .quotaExceeded
          self.onChange?()
        }
      }
    }
    // Install observation first: a cached initial update can be delivered during synchronize().
    guard source.synchronize() else {
      invalidate(.accessRejected)
      return
    }
    guard revision == token else { return }
    if needsAccountRefresh { onChange?() } else { refresh() }
  }
  public func stop() { invalidate(.idle) }
  public func finishWaiting() {
    if phase == .waiting {
      phase = .noDataYet
      onChange?()
    }
    // Keep observing. A deadline is not proof that the remote store is empty.
  }
  public func canUse(revision: Int) -> Bool {
    !needsAccountRefresh && self.revision == revision && report.originalArchive != nil
      && identity.map { source.accountIdentity?.isEqual($0) == true } == true
  }
  private func refresh() {
    guard identity.map({ source.accountIdentity?.isEqual($0) == true }) == true else {
      invalidate(.accountChanged)
      return
    }
    let token = revision
    let scanned = LegacyRecoveryReport.scan(source.readValues())
    guard revision == token else { return }
    guard identity.map({ source.accountIdentity?.isEqual($0) == true }) == true else {
      invalidate(.accountChanged)
      return
    }
    report = scanned
    if !report.candidates.isEmpty {
      phase = .found
    } else if !report.unreadableSources.isEmpty {
      phase = .invalidData
    } else if phase != .noDataYet && phase != .quotaExceeded {
      phase = .waiting
    }
    onChange?()
  }
  private func invalidate(_ phase: Phase) {
    if phase == .accountChanged { needsAccountRefresh = true }
    observation?.cancel()
    observation = nil
    identity = nil
    revision += 1
    report = LegacyRecoveryReport()
    self.phase = phase
    onChange?()
  }
}

public enum LegacyRecoveryImport {
  public static func apply(
    _ candidate: LegacyRecoveredCandidate, to store: EventStore,
    saveBackup: (Data) throws -> Void
  ) throws {
    // Decode the exported copy again; a failed backup or validation never changes the store.
    var snapshot = try Archive.snapshot(from: candidate.archive)
    if snapshot.goal.isEmpty { snapshot.goal = store.projection.snapshot.goal }
    try saveBackup(Archive.export(events: store.events))
    try store.replace(snapshot)
  }
}
