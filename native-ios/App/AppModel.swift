import SwiftUI
import UniformTypeIdentifiers
import WealthOneCore

@MainActor
final class AppModel: ObservableObject {
  @Published private(set) var portfolio = PortfolioReadModel()
  var snapshot: Snapshot { portfolio.snapshot }
  private var portfolioCache = PortfolioReadModelCache()
  @Published var error: String?
  @Published private(set) var syncStatus = "Saved on this device"
  @Published private(set) var migrationStatus = "Checking for existing data…"
  @Published private(set) var needsMigration = false
  @Published private(set) var revision = 0
  @Published private(set) var storageUnavailable = false
  private(set) var store: EventStore?
  private let rates = ExchangeRateProvider()
  private let transport: CloudEventTransport
  private var syncing = false
  private let directory: URL
  private var watchBridge: PhoneWatchBridge?

  init() {
    #if DEBUG && targetEnvironment(simulator)
      if let testID = ProcessInfo.processInfo.environment["WEALTHONE_UI_TEST_STORE"],
        UUID(uuidString: testID) != nil
      {
        directory = URL.applicationSupportDirectory.appendingPathComponent(
          "WealthOneUITests/" + testID, isDirectory: true)
      } else {
        directory = URL.applicationSupportDirectory.appendingPathComponent(
          "WealthOne", isDirectory: true)
      }
    #else
      directory = URL.applicationSupportDirectory.appendingPathComponent(
        "WealthOne", isDirectory: true)
    #endif
    transport = CloudEventTransport(directory: directory)
    do {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      let repository = JSONFileRepository(url: directory.appendingPathComponent("history.json"))
      let envelope =
        FileManager.default.fileExists(atPath: repository.url.path)
        ? try repository.load() : Envelope()
      store = try EventStore(envelope: envelope, commit: { try repository.save($0) })
      publish()
    } catch {
      storageUnavailable = true
      syncStatus = "Storage unavailable — restore a backup in Settings"
      self.error =
        "Your saved history could not be opened. It has not been replaced. \(error.localizedDescription)"
    }
  }

  var events: [Event] { store?.events ?? [] }
  var conflicts: [FieldKey: [FieldVersion]] { store?.projection.conflicts ?? [:] }
  var bufferedCount: Int { store?.projection.bufferedEventIDs.count ?? 0 }

  func start() async {
    watchBridge = PhoneWatchBridge(model: self)
    guard let store else { return }
    if store.events.isEmpty {
      needsMigration = true
      migrationStatus =
        "Recover your previous WealthOne data from iCloud, import a JSON backup, or start a new portfolio. Recovery lets you review data before importing it."
    } else {
      needsMigration = false
      migrationStatus = "Existing native history opened"
    }
    await synchronize()
    if !store.events.isEmpty { needsMigration = false }
  }

  func importRecoveredLegacy(_ candidate: LegacyRecoveredCandidate) throws -> String {
    guard let store, !storageUnavailable else {
      throw CoreError.invalid(
        "Current storage is unavailable. Export the recovered JSON and restore it through Backups.")
    }
    let folder = directory.appendingPathComponent("RecoveryBackups", isDirectory: true)
    let url = folder.appendingPathComponent(
      "WealthOne-before-recovery-" + UUID().uuidString + ".json")
    try LegacyRecoveryImport.apply(candidate, to: store) { data in
      try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
      try data.write(to: url, options: .atomic)
    }
    needsMigration = false
    publish()
    Task { await synchronize() }
    return url.lastPathComponent
  }

  func startEmpty() {
    perform { store in _ = try store.replace(Snapshot()) }
    if !(store?.events.isEmpty ?? true) { needsMigration = false }
  }

  func synchronize() async {
    // Local calendar changes must refresh even while iCloud is offline or already syncing.
    refreshPortfolio()
    guard !syncing, let store else { return }
    syncing = true
    defer { syncing = false }
    syncStatus = "Syncing with iCloud…"
    let sent = store.events
    do {
      let incoming = try await transport.synchronize(sent)
      if try store.merge(incoming) { publish() } else { refreshPortfolio() }
      syncStatus =
        store.events.count == Set((sent + incoming).map(\.id)).count
        ? "Last iCloud sync: \(Date().formatted(date: .omitted, time: .shortened))"
        : "New local edits are waiting to sync"
    } catch {
      syncStatus = error.localizedDescription
    }
  }

  func editContext(_ entity: Entity) -> EditContext? { store?.editContext(for: entity) }

  func saveAccount(_ account: Account, context: EditContext?) {
    saveFields(
      [
        "name": .string(account.name), "provider": .string(account.provider),
        "isAsset": .bool(account.isAsset), "accountType": .decimal(Decimal(account.accountType)),
        "currency": .string(account.currency),
      ], context: context)
  }

  private func saveFields(_ fields: [String: Value], context: EditContext?) {
    guard let context else {
      error = "Storage is unavailable. Restore a backup in Settings."
      return
    }
    perform { try $0.submit(fields, context: context) }
  }

  func isClosureDay(_ date: String) -> Bool { store?.isClosureDay(date) ?? true }
  func hasAccountHistory(_ id: String) -> Bool { store?.hasAccountHistory(id) ?? true }
  func setAccountClosed(_ id: String, closed: Bool, day: String, context: EditContext?) {
    guard let context else { error = "Reopen account settings to review its current state."; return }
    perform { try $0.setAccountClosed(id, closed: closed, day: day, context: context) }
  }
  func deleteAccount(_ id: String) {
    perform { store in
      guard let generation = store.projection.generation(for: .account(id)) else { return }
      try store.append(.remove(.account(id), generation: generation))
    }
  }

  func saveDay(_ day: DayRecord, context: EditContext?) {
    var fields: [String: Value] = [:]
    for (prefix, values) in [
      ("totals", day.totals), ("inflows", day.inflows), ("outflows", day.outflows),
    ] {
      for (id, value) in values { fields[prefix + ":" + id] = .decimal(value) }
    }
    for (code, rate) in day.exchangeRates { fields["fx:" + code] = .decimal(rate) }
    for (code, date) in day.exchangeRateDates { fields["fxDate:" + code] = .string(date) }
    for (code, source) in day.exchangeRateSources { fields["fxSource:" + code] = .string(source) }
    for key in context?.fields.keys ?? [String: Value]().keys where fields[key] == nil {
      fields[key] = .null
    }
    saveFields(fields, context: context)
  }

  func deleteDay(_ date: String) {
    perform { store in
      guard let generation = store.projection.generation(for: .day(date)) else { return }
      try store.append(.remove(.day(date), generation: generation))
    }
  }

  func exchangeRateQuote(refresh: Bool = false) async throws -> ExchangeRateQuote {
    try await rates.quote(refresh: refresh)
  }
  func saveHistoricalRates(_ quote: ExchangeRateQuote, refreshExisting: Bool) {
    perform { try $0.saveExchangeRates(quote, refreshExisting: refreshExisting) }
  }
  func changeReportingCurrency(_ code: String, quote: ExchangeRateQuote) throws {
    try quote.validate()
    let old = snapshot.reportingCurrency
    guard PortfolioCurrency.valid(code), let context = editContext(.goal) else { throw CoreError.invalid("Currency settings are unavailable") }
    let oldRate = old == "GBP" ? Decimal(1) : quote.ratesToGBP[old]
    let newRate = code == "GBP" ? Decimal(1) : quote.ratesToGBP[code]
    guard let oldRate, let newRate, newRate > 0 else { throw CoreError.invalid("A conversion rate is missing") }
    var fields: [String: Value] = ["reportingCurrency": .string(code)]
    for (key, fallback): (String, Decimal) in [("earnings", 55000), ("contributions", 0), ("statePensionAmount", 8500)] {
      let original: Decimal
      if case .decimal(let value) = snapshot.goal[key] { original = value } else { original = fallback }
      fields[key] = .decimal(original * oldRate / newRate)
    }
    saveFields(fields, context: context)
  }

  func saveGoal(_ fields: [String: Value], context: EditContext?) {
    saveFields(fields, context: context)
  }

  func resolve(_ key: FieldKey, value: Value) { perform { _ = try $0.resolve(key, value: value) } }

  func applyWatchEntry(_ command: WatchEntryCommand) async throws {
    guard let store else { throw CoreError.invalid("The iPhone store is unavailable.") }
    func acknowledgeDuplicate() throws -> Bool {
      guard store.events.contains(where: { $0.id == command.id }) else { return false }
      try store.applyQuickEntry(id: command.id, accountID: command.accountID, day: command.day,
        total: command.total, today: localDayKey())
      return true
    }
    if try acknowledgeDuplicate() { return }
    guard let account = snapshot.accounts.first(where: { $0.id == command.accountID }),
      (command.currency ?? "GBP") == account.currency else { throw CoreError.invalid("The account currency changed. Open the iPhone app to review this entry.") }
    let currencies = Set(snapshot.accounts.filter { !$0.isClosed(on: command.day) }.map(\.currency) + [snapshot.reportingCurrency]).subtracting(["GBP"])
    let existing = PortfolioCalculator.record(on: command.day, records: snapshot.records)
    let needsRate = currencies.contains { existing?.exchangeRates[$0] == nil }
    let quote = needsRate ? try await rates.quote() : nil
    guard self.store === store else { throw CoreError.invalid("The portfolio changed while fetching rates. Try again.") }
    if try acknowledgeDuplicate() { return }
    guard snapshot.accounts.first(where: { $0.id == command.accountID })?.currency == (command.currency ?? "GBP") else {
      throw CoreError.invalid("The account currency changed while fetching rates. Review this entry on iPhone.")
    }
    try store.applyQuickEntry(
      id: command.id, accountID: command.accountID, day: command.day,
      total: command.total, today: localDayKey(), quote: quote)
    publish()
    Task { await synchronize() }
  }

  func exportHistory() throws -> Data {
    guard let store else {
      throw CoreError.invalid("Storage is unavailable. Restore a backup before exporting.")
    }
    return try Archive.export(events: store.events)
  }

  func csvImportPlan(_ document: WealthCSVDocument, overwriteExisting: Bool, units: CSVBalanceUnits, quote: ExchangeRateQuote?) throws -> WealthCSVImportPlan {
    guard store != nil, !storageUnavailable else { throw CoreError.invalid("Restore storage before importing CSV balances.") }
    return try WealthCSVImportPlan(document: document, snapshot: snapshot, overwriteExisting: overwriteExisting, units: units, quote: quote)
  }
  func confirmCSVImport(_ plan: WealthCSVImportPlan) {
    perform { try $0.importCSV(plan) }
    if error == nil { needsMigration = false }
  }
  func importPreview(_ data: Data) throws -> ImportPreview {
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    if object?["version"] as? Int == 2 {
      let imported = try Archive.events(from: data)
      let projection = try Projection(events: imported)
      return ImportPreview(
        data: data, snapshot: projection.snapshot, eventCount: imported.count, fullHistory: true)
    }
    let snapshot = try Archive.snapshot(from: data)
    return ImportPreview(data: data, snapshot: snapshot, eventCount: 0, fullHistory: false)
  }

  func confirmImport(_ preview: ImportPreview) {
    if storageUnavailable {
      error = nil
      do {
        let repository = JSONFileRepository(url: directory.appendingPathComponent("history.json"))
        let candidate = try EventStore()
        if preview.fullHistory {
          try candidate.merge(Archive.events(from: preview.data))
        } else {
          try candidate.replace(preview.snapshot)
        }
        let backup = try repository.recover(candidate.envelope)
        store = try EventStore(envelope: repository.load(), commit: { try repository.save($0) })
        storageUnavailable = false
        needsMigration = false
        migrationStatus =
          "Restored backup. Original unreadable history preserved as " + backup.lastPathComponent
        publish()
        Task { await synchronize() }
      } catch { self.error = "The backup could not be restored: \(error.localizedDescription)" }
      return
    }
    perform { store in
      if preview.fullHistory {
        try store.merge(Archive.events(from: preview.data))
      } else {
        var snapshot = preview.snapshot
        if snapshot.goal.isEmpty { snapshot.goal = store.projection.snapshot.goal }
        try store.replace(snapshot)
      }
    }
    if error == nil { needsMigration = false }
  }

  private func perform(_ action: (EventStore) throws -> Void) {
    guard let store else {
      error = "Storage is unavailable. Restore a backup in Settings."
      return
    }
    error = nil
    do {
      try action(store)
      publish()
      Task { await synchronize() }
    } catch { self.error = "The change could not be saved: \(error.localizedDescription)" }
  }

  private func publish() {
    if !(store?.events.isEmpty ?? true) { needsMigration = false }
    refreshPortfolio()
    revision += 1
  }

  private func refreshPortfolio() {
    if portfolioCache.update(store?.projection.snapshot ?? Snapshot()) {
      portfolio = portfolioCache.model
      watchBridge?.publishSnapshot()
    }
  }
}

struct ImportPreview: Identifiable {
  let id = UUID()
  let data: Data
  let snapshot: Snapshot
  let eventCount: Int
  let fullHistory: Bool
}

struct HistoryDocument: FileDocument {
  static let readableContentTypes: [UTType] = [.json]
  var data: Data
  init(data: Data) { self.data = data }
  init(configuration: ReadConfiguration) throws {
    data = configuration.file.regularFileContents ?? Data()
  }
  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    FileWrapper(regularFileWithContents: data)
  }
}
