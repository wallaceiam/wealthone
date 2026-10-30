import Foundation
import WatchConnectivity
import WealthOneCore

@MainActor
final class PhoneWatchBridge: NSObject, WCSessionDelegate {
  private weak var model: AppModel?
  init(model: AppModel) {
    self.model = model
    super.init()
    if WCSession.isSupported() {
      WCSession.default.delegate = self
      WCSession.default.activate()
    }
  }
  func publishSnapshot() {
    guard WCSession.isSupported(), WCSession.default.activationState == .activated,
      WCSession.default.isPaired, WCSession.default.isWatchAppInstalled, let model
    else { return }
    let source = model.snapshot
    let history = model.portfolio.points.suffix(12).filter { $0.total.isFinite }.map {
      WatchSnapshot.Point(date: $0.day, total: $0.total)
    }
    let latest = history.last?.total ?? 0
    let prior = history.count > 1 ? history[history.count - 2].total : latest
    let snapshot = WatchSnapshot(
      total: latest, change: latest - prior, history: Array(history.suffix(12)),
      accounts: source.accounts.filter { !$0.isClosed() }.map { .init(id: $0.id, name: $0.name, currency: $0.currency) }, updatedAt: Date(),
      currency: source.reportingCurrency, valuationUnavailable: model.portfolio.points.last.map { !$0.total.isFinite } ?? false)
    do {
      try WCSession.default.updateApplicationContext(["snapshot": JSONEncoder().encode(snapshot)])
    } catch { /* The next store change or activation retries latest context. */  }
  }
  nonisolated func session(
    _ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    Task { @MainActor in self.publishSnapshot() }
  }
  nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
  nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }
  nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
    Task { @MainActor in self.publishSnapshot() }
  }
  nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
    guard let data = userInfo["command"] as? Data else { return }
    Task { @MainActor in
      let command: WatchEntryCommand
      do { command = try JSONDecoder().decode(WatchEntryCommand.self, from: data) } catch { return }
      let result: WatchAcknowledgment
      do {
        guard let model = self.model else { return }
        try await model.applyWatchEntry(command)
        result = .init(id: command.id, saved: true, message: "Saved on iPhone")
      } catch { result = .init(id: command.id, saved: false, message: error.localizedDescription) }
      if let data = try? JSONEncoder().encode(result) {
        WCSession.default.transferUserInfo(["ack": data])
      }
      self.publishSnapshot()
    }
  }
}
