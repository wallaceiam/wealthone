import SwiftUI
import UniformTypeIdentifiers
import WealthOneCore

struct SettingsView: View {
  @EnvironmentObject var model: AppModel
  @State private var adding = false
  @State private var syncing = false
  var body: some View {
    List {
      Section("iCloud") {
        Text(model.syncStatus)
        HStack {
          Button("Sync now") {
            syncing = true
            Task {
              await model.synchronize()
              syncing = false
            }
          }.disabled(syncing || model.storageUnavailable)
          if syncing { ProgressView() }
        }
        if model.bufferedCount > 0 {
          Text("\(model.bufferedCount) changes are waiting for related history to finish syncing.")
        }
        NavigationLink("Review conflicting changes (\(model.conflicts.count))") {
          ConflictReviewView()
        }.accessibilityIdentifier("Conflicts (\(model.conflicts.count))")
      }
      Section("Accounts") {
        ForEach(model.snapshot.accounts.filter { !$0.isClosed() }, id: \.id) { account in
          NavigationLink(account.name) { AccountEditorView(account: account) }
        }
        Button("Add account") { adding = true }
      }
      if model.snapshot.accounts.contains(where: { $0.isClosed() }) {
        Section("Closed accounts") {
          ForEach(model.snapshot.accounts.filter { $0.isClosed() }, id: \.id) { account in
            NavigationLink { AccountEditorView(account: account) } label: {
              HStack { Text(account.name); Spacer(); Text("Closed").foregroundStyle(.secondary).font(.caption) }
            }.accessibilityIdentifier("Closed account " + account.name)
          }
        }
      }
      Section { NavigationLink("Currencies") { CurrencySettingsView() } }
      Section("Data") {
        NavigationLink("Recover previous iCloud data") { LegacyRecoveryHost() }
        NavigationLink("Import Wealth+ CSV") { WealthCSVImportView() }
        NavigationLink("Backups") { BackupView() }.accessibilityIdentifier("Import and export JSON")
        NavigationLink("Permanent edit log (\(model.events.count))") { AuditView() }
      }
      Section { NavigationLink("About WealthOne") { AboutView() } }
    }.wealthScreen().wealthNavigationTitle("Settings", displayMode: .large).sheet(isPresented: $adding) {
      NavigationStack { AccountEditorView(account: nil) }
    }
  }
}
struct BackupView: View {
  @EnvironmentObject var model: AppModel
  @State private var importing = false
  @State private var exporting = false
  @State private var document = HistoryDocument(data: Data())
  @State private var preview: ImportPreview?
  @State private var completion: String?
  var body: some View {
    Form {
      if model.storageUnavailable {
        Section("Restore unavailable storage") {
          Text(
            "Saved history could not be opened. Editing and export are unavailable. Import a backup to restore storage; the unreadable original will be preserved in the application support folder."
          )
        }
      }
      if let completion {
        Section {
          Label(completion, systemImage: "checkmark.circle").foregroundStyle(WealthTheme.blue)
        }
      }
      Section { NavigationLink("Import Wealth+ CSV") { WealthCSVImportView() } }
      Section("Backup") {
        Text(
          "Export includes the complete edit history. Keep a copy somewhere you trust.")
        Button("Export backup") {
          do {
            document = HistoryDocument(data: try model.exportHistory())
            exporting = true
          } catch { model.error = error.localizedDescription }
        }
        .disabled(model.storageUnavailable)
        Button("Import backup") { importing = true }
      }
      if let preview {
        Section("Review import") {
          Text(
            model.storageUnavailable
              ? "Restore storage from this backup"
              : (preview.fullHistory
                ? "Merge full edit history" : "Replace current portfolio from backup"))
          LabeledContent("Accounts", value: String(preview.snapshot.accounts.count))
          LabeledContent("Dated entries", value: String(preview.snapshot.records.count))
          LabeledContent(
            "Goal settings", value: preview.snapshot.goal.isEmpty ? "None in backup" : "Included")
          if preview.fullHistory { LabeledContent("Events", value: String(preview.eventCount)) }
          Text(
            model.storageUnavailable
              ? "A validated backup will replace unavailable storage only after the unreadable original has been preserved. Confirm to restore."
              : preview.fullHistory
                ? "Events will merge with this device. Concurrent edits remain reviewable."
                : "Current accounts and dated entries will be replaced. Your existing history remains in the edit log. The imported file cannot supply edits from before its export."
          )
          Button(
            model.storageUnavailable
              ? "Restore backup and preserve original"
              : (preview.fullHistory ? "Merge History" : "Replace Portfolio")
          ) {
            model.confirmImport(preview)
            if model.error == nil {
              self.preview = nil
              completion = "Backup imported"
            }
          }
          Button("Cancel", role: .cancel) { self.preview = nil }
        }
      }
    }.wealthScreen().wealthNavigationTitle("Backups")
      .fileExporter(
        isPresented: $exporting, document: document, contentType: .json,
        defaultFilename: "WealthOne-history"
      ) { result in
        switch result {
        case .failure(let error): model.error = error.localizedDescription
        case .success: completion = "Backup exported"
        }
      }
      .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
        do {
          let url = try result.get()
          let access = url.startAccessingSecurityScopedResource()
          defer { if access { url.stopAccessingSecurityScopedResource() } }
          preview = try model.importPreview(Data(contentsOf: url))
        } catch { model.error = error.localizedDescription }
      }
  }
}
func entityTitle(_ entity: Entity) -> String {
  switch entity {
  case .account: "Account"
  case .day(let day):
    "Snapshot · " + PortfolioCalculator.date(day).formatted(date: .abbreviated, time: .omitted)
  case .goal: "Retirement goal"
  }
}
func valueTitle(_ value: Value) -> String {
  switch value {
  case .string(let s): s
  case .decimal(let d): amount(d)
  case .bool(let b): b ? "Yes" : "No"
  case .null: "No recorded value"
  }
}
struct HistoryPresentation {
  let accounts: [Account]
  let events: [Event]
  var reportingCurrency = "GBP"
  func name(_ id: String) -> String {
    if let account = accounts.first(where: { $0.id == id }) { return account.name }
    for event in events.reversed() {
      switch event.operation {
      case .create(.account(let accountID), _, let fields),
        .edit(.account(let accountID), _, let fields):
        if accountID == id, case .string(let name) = fields["name"] { return name + " (archived)" }
      case .replace(let snapshot):
        if let account = snapshot.accounts.first(where: { $0.id == id }) {
          return account.name + " (archived)"
        }
      default: break
      }
    }
    return "Archived account"
  }
  func entity(_ entity: Entity) -> String {
    if case .account(let id) = entity { return name(id) }
    return entityTitle(entity)
  }
  func field(_ key: String) -> String {
    let parts = key.split(separator: ":", maxSplits: 1).map(String.init)
    if parts.count == 2 {
      if parts[0] == "closureRecord" { return "Closing entry · " + parts[1] }
      if parts[0] == "closed" { return "Closed from " + parts[1] }
      if parts[0] == "fx" { return "Exchange rate · " + parts[1] + " to GBP" }
      if parts[0] == "fxDate" { return "Rate date · " + parts[1] }
      if parts[0] == "fxSource" { return "Rate source · " + parts[1] }
      return name(parts[1]) + " · "
        + (["totals": "Total", "inflows": "Deposit", "outflows": "Withdrawal"][parts[0]] ?? parts[0])
        + " (" + (accounts.first { $0.id == parts[1] }?.currency ?? "account units") + ")"
    }
    return [
      "name": "Account name", "provider": "Provider", "isAsset": "Asset",
      "accountType": "Account type", "birthDate": "Birth date", "currentAge": "Current age",
      "retirementAge": "Retirement age", "currency": "Account currency", "reportingCurrency": "Main currency", "earnings": "Annual earnings (" + reportingCurrency + ")",
      "contributions": "Monthly contribution (" + reportingCurrency + ")", "statePensionAmount": "State pension (" + reportingCurrency + ")", "lifeStyle": "Lifestyle (% of earnings)",
      "investmentStyle": "Investment style", "pension": "Pension (%)",
    ][key] ?? key
  }
  func value(_ value: Value, key: String) -> String {
    if case .decimal(let decimal) = value {
      let parts = key.split(separator: ":", maxSplits: 1).map(String.init)
      if parts.count == 2 {
        if parts[0] == "fx" { return "1 " + parts[1] + " = " + amount(decimal) + " GBP" }
        return amount(decimal) + " " + (accounts.first { $0.id == parts[1] }?.currency ?? "account units")
      }
      if ["earnings", "contributions", "statePensionAmount"].contains(key) {
        return amount(decimal) + " " + reportingCurrency
      }
      if key == "accountType", let index = Int(amount(decimal)),
        accountTypes.indices.contains(index)
      {
        return accountTypes[index]
      }
      if ["lifeStyle", "pension"].contains(key) { return amount(decimal) + "%" }
      if ["retirementAge", "currentAge"].contains(key) { return amount(decimal) + " years" }
    }
    if key == "birthDate", case .string(let day) = value {
      return PortfolioCalculator.date(day).formatted(date: .abbreviated, time: .omitted)
    }
    return valueTitle(value)
  }
  func title(_ operation: WealthOneCore.Operation) -> String {
    switch operation {
    case .replace: "Imported portfolio"
    case .create(let e, _, _): "Added " + entity(e)
    case .edit(let e, _, _): "Updated " + entity(e)
    case .remove(let e, _): "Deleted " + entity(e)
    }
  }
  func at(_ event: Event, before: Bool = false) -> HistoryPresentation {
    let lookup = Dictionary(uniqueKeysWithValues: events.map { ($0.id, $0) })
    var ids = Set<String>()
    func visit(_ id: String) {
      guard ids.insert(id).inserted, let item = lookup[id] else { return }
      item.parents.forEach(visit)
    }
    if before { event.parents.forEach(visit) } else { visit(event.id) }
    let snapshot = try? Projection(events: events.filter { ids.contains($0.id) }).snapshot
    return HistoryPresentation(accounts: snapshot?.accounts ?? accounts, events: events,
      reportingCurrency: snapshot?.reportingCurrency ?? reportingCurrency)
  }
  func before(_ event: Event, entity: Entity, generation: String, field: String) -> Value? {
    // Reconstruct only causal parents, so concurrent changes are never mislabeled as the prior value.
    let lookup = Dictionary(uniqueKeysWithValues: events.map { ($0.id, $0) })
    var ids = Set<String>()
    func visit(_ id: String) {
      guard ids.insert(id).inserted, let parent = lookup[id] else { return }
      parent.parents.forEach(visit)
    }
    event.parents.forEach(visit)
    return (try? Projection(events: events.filter { ids.contains($0.id) }))?.fields[
      FieldKey(entity: entity, generation: generation, field: field)]
  }
}
struct AuditView: View {
  @EnvironmentObject var model: AppModel
  var display: HistoryPresentation {
    HistoryPresentation(accounts: model.snapshot.accounts, events: model.events, reportingCurrency: model.snapshot.reportingCurrency)
  }
  var body: some View {
    List {
      Section {
        Text(
          "Every saved change is retained, including corrections. Times reflect the clock on the device where each change was made."
        ).font(BrandFont.body(13, relativeTo: .footnote)).foregroundStyle(.secondary)
      }
      ForEach(model.events.reversed(), id: \.id) { event in
        NavigationLink {
          EventDetailView(event: event)
        } label: {
          VStack(alignment: .leading, spacing: 8) {
            Text(display.title(event.operation)).font(BrandFont.body(16, weight: .semibold))
            Text(
              event.recordedAt.timeIntervalSince1970 == 0
                ? "Timestamp unavailable" : event.recordedAt.formatted()
            ).font(BrandFont.body(12, relativeTo: .caption)).foregroundStyle(.secondary)
          }.padding(.vertical, 8)
        }
      }
    }.wealthScreen().wealthNavigationTitle("Edit log")
  }
}
struct EventDetailView: View {
  @EnvironmentObject var model: AppModel
  let event: Event
  @State private var historical: HistoryPresentation?
  @State private var beforeDisplay: HistoryPresentation?
  var display: HistoryPresentation {
    historical ?? HistoryPresentation(accounts: model.snapshot.accounts, events: model.events, reportingCurrency: model.snapshot.reportingCurrency)
  }
  var body: some View {
    List {
      Section {
        Text(display.title(event.operation)).font(BrandFont.heading(25))
        LabeledContent(
          "Saved",
          value: event.recordedAt.timeIntervalSince1970 == 0
            ? "Timestamp unavailable" : event.recordedAt.formatted())
      }
      switch event.operation {
      case .replace(let snapshot):
        Section("Imported baseline") {
          LabeledContent("Accounts", value: String(snapshot.accounts.count))
          LabeledContent("Dated snapshots", value: String(snapshot.records.count))
          Text("Earlier edits were not present in this state backup.")
          NavigationLink("Inspect imported values") { BaselineDetailView(snapshot: snapshot) }
        }
      case .create(let entity, let generation, let fields),
        .edit(let entity, let generation, let fields):
        Section(display.entity(entity)) {
          ForEach(fields.keys.sorted(), id: \.self) { key in
            VStack(alignment: .leading, spacing: 8) {
              Text(display.field(key)).font(BrandFont.body(14, weight: .semibold))
              if let old = display.before(event, entity: entity, generation: generation, field: key)
              {
                Text("Before: " + (beforeDisplay ?? display).value(old, key: key)).foregroundStyle(.secondary)
              } else {
                Text("Before: No recorded value").foregroundStyle(.secondary)
              }
              Text("After: " + display.value(fields[key]!, key: key))
            }.padding(.vertical, 6)
          }
        }
      case .remove(let entity, _):
        Section("Deleted") {
          Text(display.entity(entity))
          Text("Earlier values remain available in the edit log.").foregroundStyle(.secondary)
        }
      }
      Section {
        DisclosureGroup("Technical details") {
          LabeledContent("Event", value: event.id)
          LabeledContent("Device", value: event.actor)
          LabeledContent("Revision", value: String(event.counter))
          LabeledContent("Epoch", value: event.epoch)
          switch event.operation {
          case .create(let entity, let generation, _), .edit(let entity, let generation, _),
            .remove(let entity, let generation):
            LabeledContent("Entity", value: String(describing: entity))
            LabeledContent("Generation", value: generation)
          default: EmptyView()
          }
          ForEach(event.parents, id: \.self) {
            Text("Parent: " + $0).font(BrandFont.body(11, relativeTo: .caption2))
          }
        }
      }
    }.wealthScreen().wealthNavigationTitle("Change details")
      .task {
        let base = HistoryPresentation(accounts: model.snapshot.accounts, events: model.events, reportingCurrency: model.snapshot.reportingCurrency)
        historical = base.at(event); beforeDisplay = base.at(event, before: true)
      }
  }
}
struct ConflictReviewView: View {
  @EnvironmentObject var model: AppModel
  var display: HistoryPresentation {
    HistoryPresentation(accounts: model.snapshot.accounts, events: model.events, reportingCurrency: model.snapshot.reportingCurrency)
  }
  var keys: [FieldKey] {
    model.conflicts.keys.sorted {
      display.entity($0.entity) + $0.field < display.entity($1.entity) + $1.field
    }
  }
  var body: some View {
    List {
      if keys.isEmpty {
        ContentUnavailableView(
          "No conflicts", systemImage: "checkmark.circle",
          description: Text(
            "No action is needed. All saved alternatives remain in your edit history."))
      }
      ForEach(keys, id: \.self) { key in
        Section(display.entity(key.entity) + " · " + display.field(key.field)) {
          Text(
            "Choosing a value saves a new resolution. Every alternative remains in your edit history."
          ).font(BrandFont.body(13, relativeTo: .footnote))
          ForEach(model.conflicts[key] ?? [], id: \.event.id) { version in
            VStack(alignment: .leading, spacing: 10) {
              if model.store?.projection.fields[key] == version.value {
                Label("Currently displayed", systemImage: "checkmark.circle").foregroundStyle(
                  WealthTheme.blue
                ).font(BrandFont.body(12, relativeTo: .caption))
              }
              Text(display.value(version.value, key: key.field)).font(BrandFont.heading(22))
              Text(
                version.event.recordedAt.timeIntervalSince1970 == 0
                  ? "Timestamp unavailable" : version.event.recordedAt.formatted()
              ).font(BrandFont.body(12, relativeTo: .caption)).foregroundStyle(.secondary)
              Button("Keep this value") { model.resolve(key, value: version.value) }.buttonStyle(
                .bordered)
              DisclosureGroup("Technical details") {
                Text("Device: " + version.event.actor)
                Text("Event: " + version.event.id)
                Text("Field: " + key.field)
              }.font(BrandFont.body(11, relativeTo: .caption2))
            }.padding(.vertical, 10)
          }
        }
      }
    }.wealthScreen().wealthNavigationTitle("Review conflicts")
  }
}
struct AboutView: View {
  var body: some View {
    Form {
      Section("WealthOne") {
        Text("Your wealth, in one place.").font(BrandFont.heading(25, relativeTo: .title2))
        Text("Portfolio tracking with local history and iCloud sync.")
        LabeledContent(
          "Version",
          value: (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "1.0") + " ("
            + (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1") + ")")
      }
      Section("Calculations") {
        Text(
          "Calculation version 2 corrects yearly compounding, opening balances, profit, calendar age and goal funding percentages. UK tax years start on 6 April. Missing balances carry forward; returns use an end-of-interval cash-flow estimate. Original entries and edit history are preserved."
        )
      }
      Section("Privacy") {
        Text(
          "Portfolio history is saved on this device and synchronized through your iCloud account. JSON exports contain your financial data and permanent edit history."
        )
      }
    }.wealthScreen().wealthNavigationTitle("About")
  }
}

struct BaselineDetailView: View {
  let snapshot: Snapshot
  var body: some View {
    List {
      Section("Accounts") {
        ForEach(snapshot.accounts, id: \.id) { account in
          VStack(alignment: .leading) {
            Text(account.name)
            Text(account.provider + " · " + (account.isAsset ? "Asset" : "Liability")).font(
              .caption)
            DisclosureGroup("Technical details") {
              Text(account.id).font(BrandFont.body(11, relativeTo: .caption2)).foregroundStyle(
                .secondary)
            }
          }
        }
      }
      ForEach(snapshot.records, id: \.date) { day in
        Section(PortfolioCalculator.date(day.date).formatted(date: .abbreviated, time: .omitted)) {
          ForEach(["Totals", "Inflows", "Outflows"], id: \.self) { category in
            let values =
              category == "Totals" ? day.totals : category == "Inflows" ? day.inflows : day.outflows
            ForEach(values.keys.sorted(), id: \.self) { id in
              LabeledContent(
                category + " · "
                  + (snapshot.accounts.first { $0.id == id }?.name ?? "Archived account"),
                value: amount(values[id]!) + " " + (snapshot.accounts.first { $0.id == id }?.currency ?? "account units"))
            }
          }
          if day.totals.isEmpty && day.inflows.isEmpty && day.outflows.isEmpty {
            Text("No recorded values")
          }
        }
      }
      Section("Goal inputs") {
        ForEach(snapshot.goal.keys.sorted(), id: \.self) { key in
          let display = HistoryPresentation(accounts: snapshot.accounts, events: [], reportingCurrency: snapshot.reportingCurrency)
          LabeledContent(display.field(key), value: display.value(snapshot.goal[key]!, key: key))
        }
      }
    }.wealthScreen().wealthNavigationTitle("Baseline values")
  }
}

struct CurrencySettingsView: View {
  @EnvironmentObject var model: AppModel
  @State private var selected = "GBP"
  @State private var texts: [String: String] = [:]
  @State private var quoteDate = localDayKey()
  @State private var source = "Manual"
  @State private var fetching = false
  @State private var status: String?
  @State private var confirmingRefresh = false
  var quote: ExchangeRateQuote? {
    var rates: [String: Decimal] = ["GBP": 1]
    for (code, text) in texts where !text.isEmpty {
      guard let value = ExchangeRateQuote.manualRate(text) else { return nil }
      rates[code] = value
    }
    return ExchangeRateQuote(ratesToGBP: rates, date: quoteDate, source: source)
  }
  var body: some View {
    Form {
      Section("Main currency") {
        Picker("Portfolio currency", selection: $selected) {
          ForEach(PortfolioCurrency.codes, id: \.self) { Text($0).tag($0) }
        }
        Button("Apply main currency") {
          guard let quote else { status = "Enter valid rates first."; return }
          do {
            try model.changeReportingCurrency(selected, quote: quote)
            status = model.error ?? "Main currency saved. Goal earnings and contributions were converted using these rates. Fill missing historical rates below if needed."
          } catch { status = error.localizedDescription }
        }.disabled(selected == model.snapshot.reportingCurrency)
        Text("Accounts retain their own currency. Goal earnings, contributions and pension assumptions use the main currency.").font(.caption).foregroundStyle(.secondary)
      }
      Section("Exchange rates") {
        Button("Fetch current exchange rates") {
          fetching = true
          Task {
            defer { fetching = false }
            do {
              let quote = try await model.exchangeRateQuote(refresh: true)
              texts = quote.ratesToGBP.filter { $0.key != "GBP" }.mapValues(amount)
              quoteDate = quote.date; source = quote.source; status = nil
            } catch { status = error.localizedDescription }
          }
        }.disabled(fetching)
        if fetching { ProgressView() }
        ForEach(PortfolioCurrency.codes.filter { $0 != "GBP" }, id: \.self) { code in
          TextField("GBP per " + code, text: Binding(get: { texts[code] ?? "" }, set: {
            texts[code] = $0; source = "Manual"; quoteDate = localDayKey()
          })).keyboardType(.decimalPad).accessibilityLabel("GBP per " + code)
        }
        Text(source + " · " + quoteDate).font(.caption).foregroundStyle(.secondary)
        Text("Rates express GBP per one unit of each currency. For example, 0.54 means CAD 1 = GBP 0.54. Bank of Canada daily reference rates are approximate; no balances are sent to the rate provider.").font(.caption).foregroundStyle(.secondary)
      }
      Section("Historical entries") {
        Button("Fill missing saved rates") {
          guard let quote else { status = "Enter valid rates first."; return }
          model.saveHistoricalRates(quote, refreshExisting: false)
          status = model.error ?? "Missing rates saved. Existing saved rates were kept."
        }
        Button("Refresh all saved rates") { confirmingRefresh = true }
        Text("Fill uses the quote above for entries that have no saved rate. Refresh deliberately revalues existing entries using that quote. Each change stays in the permanent edit history.").font(.caption).foregroundStyle(.secondary)
      }
      if let status { Section { Text(status) } }
    }.wealthScreen().wealthNavigationTitle("Currencies")
      .onAppear { selected = model.snapshot.reportingCurrency }
      .confirmationDialog("Revalue all entries using these rates? Previous rates remain in edit history.", isPresented: $confirmingRefresh, titleVisibility: .visible) {
        Button("Refresh all saved rates") {
          guard let quote else { status = "Enter valid rates first."; return }
          model.saveHistoricalRates(quote, refreshExisting: true)
          status = model.error ?? "Saved rates refreshed."
        }
      }
  }
}


private struct CSVAccountCreation: Identifiable {
  let id = UUID()
  let name: String
}
struct WealthCSVImportView: View {
  @EnvironmentObject var model: AppModel
  @State private var importing = false
  @State private var document: WealthCSVDocument?
  @State private var filename = ""
  @State private var plan: WealthCSVImportPlan?
  @State private var overwriteExisting = false
  @State private var offerAccountCreation = false
  @State private var creatingAccount: CSVAccountCreation?
  @State private var creationFlowActive = false
  @State private var lastCreationName: String?
  @State private var units: CSVBalanceUnits = .accountCurrency
  @State private var quote: ExchangeRateQuote?
  @State private var fetching = false
  @State private var failure: String?
  @State private var completion: String?
  var missingAccounts: [String] { document?.missingAccountNames(in: model.snapshot) ?? [] }
  func createNextAccount() {
    guard let name = missingAccounts.first else { creationFlowActive = false; review(); return }
    lastCreationName = name
    creatingAccount = CSVAccountCreation(name: name)
  }
  func accountCreationDismissed() {
    if creationFlowActive, let lastCreationName, !missingAccounts.contains(lastCreationName) {
      createNextAccount()
    } else {
      creationFlowActive = false
      review()
    }
  }
  var currencies: [String] {
    Set(model.snapshot.accounts.map(\.currency) + [model.snapshot.reportingCurrency]).subtracting(["GBP"]).sorted()
  }
  func review() {
    plan = nil
    guard let document else { return }
    do {
      plan = try model.csvImportPlan(document, overwriteExisting: overwriteExisting, units: units, quote: quote)
      failure = nil
    } catch { failure = error.localizedDescription }
  }
  var body: some View {
    Form {
      Section {
        Button("Choose Wealth+ CSV") { importing = true }
        Text("Accounts are matched by name. If any are missing, you can review and create them before importing balances.")
          .font(.caption).foregroundStyle(.secondary)
      }
      if let completion { Section { Text(completion) } }
      if let failure { Section("Cannot import yet") { Text(failure).foregroundStyle(.red) } }
      if let document {
        if !missingAccounts.isEmpty {
          Section("Missing accounts") {
            ForEach(missingAccounts, id: \.self) { Text($0) }
            Button("Create missing accounts") { offerAccountCreation = true }
            Text("Review each account’s name, currency and type before saving. Balances are imported only after every account exists and you confirm the import.")
              .font(.caption).foregroundStyle(.secondary)
          }
        }
        Section("Source") {
          Text(filename)
          LabeledContent("Snapshots", value: String(document.rows.count))
          if let first = document.rows.first, let last = document.rows.last {
            LabeledContent("First date", value: first.day)
            LabeledContent("Last date", value: last.day)
          }
          ForEach(document.accountNames, id: \.self) { Text($0) }
        }
        Section("Balance amounts") {
          Picker("CSV amounts are in", selection: $units) {
            Text("Each account’s currency").tag(CSVBalanceUnits.accountCurrency)
            Text("Main currency (" + model.snapshot.reportingCurrency + ")").tag(CSVBalanceUnits.reportingCurrency)
          }.onChange(of: units) { review() }
          Text("The CSV contains no currency labels. Check these units before importing. Main-currency amounts are converted to each account’s currency using saved or fetched rates.")
            .font(.caption).foregroundStyle(.secondary)
          Toggle("Update existing balances", isOn: $overwriteExisting).onChange(of: overwriteExisting) { review() }
          Text(overwriteExisting ? "Different balances for matching accounts and dates will be updated. Previous values remain in the permanent edit log." : "Existing recorded balances are kept. Only missing balances and dates will be added.")
            .font(.caption).foregroundStyle(.secondary)
        }
        if !currencies.isEmpty {
          Section("Reference rates") {
            Button(fetching ? "Fetching rates…" : "Fetch reference rates") {
              fetching = true
              Task {
                defer { fetching = false }
                do { quote = try await model.exchangeRateQuote(); review() }
                catch { failure = error.localizedDescription }
              }
            }.disabled(fetching)
            if let quote {
              Text(quote.source + " · " + quote.date).font(.caption).foregroundStyle(.secondary)
            }
            Text("Missing rates use the current reference quote at import time, including for older snapshots. Already saved rates stay fixed. The CSV has no historical exchange rates.")
              .font(.caption).foregroundStyle(.secondary)
          }
        }
        if let plan {
          Section("Review import") {
            LabeledContent("Matched existing accounts", value: String(plan.accountCount))
            LabeledContent("New dates", value: String(plan.newDateCount))
            LabeledContent("New recorded balances", value: String(plan.newBalanceCount))
            LabeledContent(overwriteExisting ? "Existing balances to update" : "Different balances kept", value: String(plan.differentBalanceCount))
            LabeledContent("Identical balances", value: String(plan.unchangedBalanceCount))
            Text("Other accounts, contributions, withdrawals, goal assumptions and account status stay unchanged. Summary Total, Assets and Liabilities columns are not imported.")
              .font(.caption).foregroundStyle(.secondary)
            Button("Import reviewed balances") {
              let count = plan.updates.count
              model.confirmCSVImport(plan)
              if model.error == nil {
                completion = "Imported balances for \(count) dated entries."
                self.plan = nil; self.document = nil
              }
            }.disabled(plan.updates.isEmpty || fetching)
            if plan.updates.isEmpty { Text("No new balances to import with these options.").foregroundStyle(.secondary) }
          }
        }
        Button("Review again", action: review)
      }
    }.wealthScreen().wealthNavigationTitle("Import Wealth+ CSV")
      .confirmationDialog("Create missing accounts?", isPresented: $offerAccountCreation, titleVisibility: .visible) {
        Button("Review and create accounts") { creationFlowActive = true; createNextAccount() }
        Button("Not now", role: .cancel) { creationFlowActive = false }
      } message: {
        Text("These accounts are not in WealthOne: " + missingAccounts.joined(separator: ", ") + ". You can review each one before it is created.")
      }
      .sheet(item: $creatingAccount, onDismiss: accountCreationDismissed) { draft in
        NavigationStack { AccountEditorView(account: nil, initialName: draft.name) }
      }
      .onChange(of: model.revision) {
        guard document != nil else { return }
        plan = nil; failure = "The portfolio changed. Tap Review again before importing."
      }
      .fileImporter(isPresented: $importing, allowedContentTypes: [.commaSeparatedText]) { result in
        document = nil; plan = nil; completion = nil; failure = nil; quote = nil
        do {
          let url = try result.get()
          let access = url.startAccessingSecurityScopedResource()
          defer { if access { url.stopAccessingSecurityScopedResource() } }
          document = try WealthCSVDocument.parse(Data(contentsOf: url))
          filename = url.lastPathComponent
          review()
          offerAccountCreation = !missingAccounts.isEmpty
        } catch { failure = error.localizedDescription }
      }
  }
}
