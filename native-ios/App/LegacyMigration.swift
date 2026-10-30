import Foundation
import SwiftUI
import WealthOneCore

private final class RecoveryObservation: LegacyRecoveryObservation, @unchecked Sendable {
  // NotificationCenter removal is thread-safe; tokens are immutable and never expose payloads.
  let tokens: [NSObjectProtocol]
  init(_ tokens: [NSObjectProtocol] = []) { self.tokens = tokens }
  func cancel() { tokens.forEach { NotificationCenter.default.removeObserver($0) } }
  deinit { cancel() }
}

@MainActor
private final class AppleLegacyRecoverySource: LegacyRecoverySource {
  var isSupported: Bool {
    #if targetEnvironment(simulator)
      false
    #else
      true
    #endif
  }
  var accountIdentity: NSObject? {
    #if targetEnvironment(simulator)
      nil
    #else
      FileManager.default.ubiquityIdentityToken as? NSObject
    #endif
  }
  func synchronize() -> Bool {
    #if targetEnvironment(simulator)
      false
    #else
      NSUbiquitousKeyValueStore.default.synchronize()
    #endif
  }
  func readValues() -> [String: String] {
    #if targetEnvironment(simulator)
      [:]
    #else
      var values: [String: String] = [:]
      for key in LegacyRecoveryReport.keys {
        values[key] = NSUbiquitousKeyValueStore.default.string(
          forKey: "@com.manicakes.iCloudStorage/" + key)
      }
      return values
    #endif
  }
  func observe(_ handler: @escaping @MainActor @Sendable (LegacyRecoveryChange) -> Void)
    -> any LegacyRecoveryObservation
  {
    #if targetEnvironment(simulator)
      return RecoveryObservation()
    #else
      let center = NotificationCenter.default
      let values = center.addObserver(
        forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
        object: NSUbiquitousKeyValueStore.default, queue: .main
      ) { notification in
        let reason = notification.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int
        let change: LegacyRecoveryChange =
          reason == NSUbiquitousKeyValueStoreAccountChange
          ? .accountChanged
          : reason == NSUbiquitousKeyValueStoreQuotaViolationChange ? .quotaExceeded : .changed
        Task { @MainActor in handler(change) }
      }
      let account = center.addObserver(
        forName: .NSUbiquityIdentityDidChange, object: nil, queue: .main
      ) { _ in
        Task { @MainActor in handler(.accountChanged) }
      }
      return RecoveryObservation([values, account])
    #endif
  }
}

@MainActor
final class LegacyRecoveryModel: ObservableObject {
  @Published private(set) var phase: LegacyRecoverySession.Phase = .idle
  @Published private(set) var report = LegacyRecoveryReport()
  @Published private(set) var revision = 0
  @Published private(set) var quotaWarning = false
  private let session: LegacyRecoverySession
  private var deadline: Task<Void, Never>?
  init() {
    session = LegacyRecoverySession(source: AppleLegacyRecoverySource())
    session.onChange = { [weak self] in self?.publish() }
  }
  deinit { deadline?.cancel() }
  func start() {
    deadline?.cancel()
    session.start()
    let token = session.revision
    guard session.phase == .waiting else { return }
    deadline = Task { [weak self] in
      do { try await Task.sleep(for: .seconds(45)) } catch { return }
      guard let self, self.session.revision == token else { return }
      self.session.finishWaiting()
    }
  }
  func canUse(revision: Int) -> Bool { session.canUse(revision: revision) }
  private func publish() {
    phase = session.phase
    report = session.report
    revision = session.revision
    quotaWarning = session.quotaWarning
  }
}
