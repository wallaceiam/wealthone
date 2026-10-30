import SwiftUI
import WatchConnectivity
import WidgetKit

@MainActor
final class WatchModel: NSObject, ObservableObject, WCSessionDelegate {
  @Published var snapshot: WatchSnapshot?
  @Published var pending: WatchEntryCommand?
  @Published var status = "Open WealthOne on your iPhone to sync."
  private let defaults = UserDefaults.standard

  override init() {
    super.init()
    snapshot = UserDefaults(suiteName: WatchSnapshot.storageGroup)?.data(forKey: "snapshot").flatMap
    { try? JSONDecoder().decode(WatchSnapshot.self, from: $0) }
    pending = defaults.data(forKey: "pending").flatMap {
      try? JSONDecoder().decode(WatchEntryCommand.self, from: $0)
    }
    if pending != nil { status = "Waiting for iPhone to save" }
    if WCSession.isSupported() {
      WCSession.default.delegate = self
      WCSession.default.activate()
    }
  }

  func submit(accountID: String, amount: String, currency: String) {
    guard pending == nil else { return }
    guard (snapshot?.accounts.first { $0.id == accountID }?.currency ?? "GBP") == currency else {
      status = "Account currency changed. Review the amount before saving."
      return
    }
    guard let value = EntryAmount.parse(amount) else {
      status = "Enter a valid amount."
      return
    }
    let command = WatchEntryCommand(
      id: UUID().uuidString, accountID: accountID, day: localDayKey(), total: value, currency: currency)
    guard let data = try? JSONEncoder().encode(command) else { return }
    // Persist before queueing so an app restart never loses its identity.
    defaults.set(data, forKey: "pending")
    pending = command
    retry()
  }

  func discardPending() {
    guard let pending else { return }
    for transfer in WCSession.default.outstandingUserInfoTransfers {
      if let data = transfer.userInfo["command"] as? Data,
        (try? JSONDecoder().decode(WatchEntryCommand.self, from: data))?.id == pending.id { transfer.cancel() }
    }
    self.pending = nil
    defaults.removeObject(forKey: "pending")
    status = "Check iPhone history before re-entering."
  }

  func retry() {
    guard let command = pending, let data = try? JSONEncoder().encode(command) else { return }
    guard WCSession.default.activationState == .activated else {
      status = "Waiting for iPhone connection"
      return
    }
    WCSession.default.transferUserInfo(["command": data])
    status = "Waiting for iPhone to save"
  }

  private func receiveSnapshot(_ data: Data) {
    guard let decoded = try? JSONDecoder().decode(WatchSnapshot.self, from: data) else { return }
    snapshot = decoded
    UserDefaults(suiteName: WatchSnapshot.storageGroup)?.set(data, forKey: "snapshot")
    WidgetCenter.shared.reloadAllTimelines()
  }

  nonisolated func session(
    _ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    let data = session.receivedApplicationContext["snapshot"] as? Data
    Task { @MainActor in
      if let data { self.receiveSnapshot(data) }
      if self.pending != nil { self.retry() }
    }
  }
  nonisolated func session(
    _ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]
  ) {
    guard let data = applicationContext["snapshot"] as? Data else { return }
    Task { @MainActor in self.receiveSnapshot(data) }
  }
  nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
    guard let data = userInfo["ack"] as? Data,
      let ack = try? JSONDecoder().decode(WatchAcknowledgment.self, from: data)
    else { return }
    Task { @MainActor in
      guard self.pending?.id == ack.id else { return }
      self.status = ack.message
      // Keep the command identity until the phone acknowledges durable success.
      if ack.saved {
        self.pending = nil
        self.defaults.removeObject(forKey: "pending")
      }
    }
  }
}
