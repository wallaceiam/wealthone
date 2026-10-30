import Charts
import SwiftUI
import WealthOneCore

func formattedMoney(_ value: Double, currency: String) -> String {
  value.isFinite ? value.formatted(.currency(code: currency).precision(.fractionLength(0))) : "Unavailable"
}
func money(_ value: Double) -> String { formattedMoney(value, currency: "GBP") }
func amount(_ value: Decimal) -> String { NSDecimalNumber(decimal: value).stringValue }
let accountTypes = [
  "Cash", "Savings", "General Investment Account", "ISA", "LISA", "Pension", "Property", "Mortgage",
  "Credit Card", "Loan",
]

struct RootTabView: View {
  var body: some View {
    TabView {
      NavigationStack { HomeView() }
        .tabItem { Label("Home", systemImage: "house.fill") }
      NavigationStack { BreakdownView() }
        .tabItem { Label("Breakdown", systemImage: "chart.pie.fill") }
      NavigationStack { GoalsView() }
        .tabItem { Label("Goals", systemImage: "target") }
      NavigationStack { HistoryView() }
        .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
      NavigationStack { SettingsView() }
        .tabItem { Label("Settings", systemImage: "gearshape.fill") }
    }.tint(WealthTheme.blue)
  }
}
struct WorthChart: View {
  let points: [NetWorthPoint]
  var currency = "GBP"
  func money(_ value: Double) -> String { formattedMoney(value, currency: currency) }
  @State private var metric = "Value"
  @State private var range = "1Y"
  @State private var selectedDate: Date?
  var visible: [NetWorthPoint] {
    guard range != "All", let end = points.last?.date else { return points }
    let months = ["1M": 1, "3M": 3, "6M": 6, "1Y": 12][range] ?? 12
    let start = Calendar.current.date(byAdding: .month, value: -months, to: end) ?? end
    return points.filter { $0.date >= start }
  }
  func selected(in visible: [NetWorthPoint]) -> NetWorthPoint? {
    guard let selectedDate else { return visible.last }
    return visible.min {
      abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
    }
  }
  func chartDomain(for visible: [NetWorthPoint]) -> ClosedRange<Double> {
    let values = visible.map(chartValue).filter(\.isFinite)
    let low = values.min() ?? 0
    let high = values.max() ?? 1
    let padding = max((high - low) * 0.15, max(abs(low), abs(high)) * 0.05, 1)
    return (low - padding)...(high + padding)
  }
  var body: some View {
    let visible = visible.filter { chartValue($0).isFinite }
    let selected = selected(in: visible)
    let chartDomain = chartDomain(for: visible)
    VStack(alignment: .leading, spacing: 16) {
      HStack(alignment: .firstTextBaseline, spacing: 12) {
        if let start = visible.first?.date, let end = visible.last?.date {
          Text(
            start == end
              ? "1 snapshot"
              : start.formatted(date: .abbreviated, time: .omitted) + " – "
                + end.formatted(date: .abbreviated, time: .omitted)
          )
          .font(BrandFont.body(12, relativeTo: .caption)).foregroundStyle(.secondary)
        }
        Spacer(minLength: 8)
        Menu {
          Picker("Chart metric", selection: $metric) {
            Text("Value").tag("Value")
            Text("Profit / loss").tag("Profit / loss")
            Text("Return %").tag("Return %")
          }
        } label: {
          HStack(spacing: 6) {
            Text(metric).font(BrandFont.body(14, weight: .medium))
            FeatherIcon(name: "chevron-down", size: 14)
          }.frame(minHeight: 44)
        }.accessibilityLabel("Chart metric").accessibilityValue(metric)
      }
      if metric != "Value" {
        Text(
          "Cumulative performance since the first recorded snapshot; the range filters displayed dates."
        ).font(BrandFont.body(12, relativeTo: .caption)).foregroundStyle(.secondary)
      }
      if visible.isEmpty {
        ContentUnavailableView(
          "Your wealth over time", systemImage: "chart.xyaxis.line",
          description: Text("Add a dated snapshot to start your chart."))
      } else {
        if selectedDate != nil, let selected {
          VStack(alignment: .leading, spacing: 4) {
            Text(
              metric == "Return %"
                ? chartValue(selected).formatted() + "%" : money(chartValue(selected))
            )
            .font(BrandFont.heading(22))
            Text(selected.date.formatted(date: .abbreviated, time: .omitted)).font(
              BrandFont.body(12, relativeTo: .caption)
            ).foregroundStyle(.secondary)
          }.accessibilityElement(children: .combine).accessibilityIdentifier("Chart selected value")
        }
        Chart(visible) { point in
          AreaMark(
            x: .value("Date", point.date), yStart: .value(metric, chartDomain.lowerBound),
            yEnd: .value(metric, chartValue(point))
          )
          .foregroundStyle(
            LinearGradient(
              colors: [WealthTheme.blue.opacity(0.18), .clear], startPoint: .top, endPoint: .bottom)
          )
          LineMark(x: .value("Date", point.date), y: .value(metric, chartValue(point)))
            .foregroundStyle(WealthTheme.blue).lineStyle(StrokeStyle(lineWidth: 2.5))
          if visible.count == 1 || point.id == selected?.id {
            PointMark(x: .value("Date", point.date), y: .value(metric, chartValue(point)))
              .foregroundStyle(WealthTheme.blue).symbolSize(65)
          }
        }.chartYScale(domain: chartDomain)
          .chartYAxis {
            AxisMarks { value in
              AxisGridLine()
              AxisValueLabel {
                if let number = value.as(Double.self) {
                  Text(metric == "Return %" ? number.formatted() + "%" : money(number))
                }
              }
            }
          }
          .chartXSelection(value: $selectedDate).frame(height: 210)
          .accessibilityLabel(metric + " over time")
      }
      Picker("Chart range", selection: $range) {
        ForEach(["1M", "3M", "6M", "1Y", "All"], id: \.self) { Text($0).tag($0) }
      }.pickerStyle(.segmented)
        .onChange(of: range) { _, _ in selectedDate = nil }
    }
  }
  func chartValue(_ point: NetWorthPoint) -> Double {
    switch metric {
    case "Profit / loss": point.totalPL
    case "Return %": point.twrrPercent * 100
    default: point.total
    }
  }
}
struct HomeView: View {
  @EnvironmentObject var model: AppModel
  func money(_ value: Double) -> String { formattedMoney(value, currency: model.snapshot.reportingCurrency) }
  @State private var addingAccount = false
  @State private var addingEntry = false
  var points: [NetWorthPoint] {
    model.portfolio.points
  }
  var latest: DayRecord? {
    model.portfolio.latestRecord
  }
  func total(_ asset: Bool) -> Double {
    asset ? (points.last?.assets ?? 0) : (points.last?.liabilities ?? 0)
  }
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        if model.storageUnavailable {
          VStack(alignment: .leading, spacing: 12) {
            Label("Storage unavailable", systemImage: "externaldrive.badge.exclamationmark")
              .font(.headline)
            Text("Restore a backup to continue editing. Your original history will be preserved.")
            NavigationLink("Restore a backup") { BackupView() }
          }.padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        if model.needsMigration {
          VStack(alignment: .leading, spacing: 12) {
            Text("Welcome to WealthOne").font(.title2.bold())
            Text(model.migrationStatus).foregroundStyle(.secondary)
            NavigationLink("Recover previous iCloud data") { LegacyRecoveryHost() }
            NavigationLink("Import a backup") { BackupView() }
            Button("Start a new portfolio") { model.startEmpty() }
          }.padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        VStack(alignment: .leading, spacing: 6) {
          Text("Net worth").foregroundStyle(.secondary)
          Text(money(points.last?.total ?? 0)).font(.largeTitle.bold()).monospacedDigit()
            .minimumScaleFactor(0.65).lineLimit(1)
            .accessibilityLabel("Net worth " + money(points.last?.total ?? 0))
          asOf.foregroundStyle(.secondary)
          if let last = points.last, let previous = points.dropLast().last {
            Label {
              Text("\(money(last.changeAmount)) · \(last.changePercent.formatted(.percent))")
            } icon: {
              Image(systemName: last.changeAmount < 0 ? "arrow.down" : "arrow.up")
            }.font(.subheadline.weight(.semibold)).foregroundStyle(WealthTheme.blue)
            Text("Since " + previous.date.formatted(date: .abbreviated, time: .omitted))
              .font(.caption).foregroundStyle(.secondary)
          }
        }
        WorthChart(points: points, currency: model.snapshot.reportingCurrency)
        if points.contains(where: { !$0.total.isFinite }) {
          NavigationLink("Save missing exchange rates") { CurrencySettingsView() }
        }
        Text("Blank balances use the last recorded value. Returns estimate cash flows at the end of each snapshot interval.")
          .font(.caption).foregroundStyle(.secondary)
        ViewThatFits(in: .horizontal) {
          HStack(alignment: .top, spacing: 24) {
            summary(true)
            Divider()
            summary(false)
          }.fixedSize(horizontal: false, vertical: true)
          VStack(alignment: .leading, spacing: 16) {
            summary(true)
            summary(false)
          }
        }
        Divider()
        VStack(alignment: .leading, spacing: 0) {
          HStack {
            Text("Accounts").font(.title2.bold())
            Spacer()
            Button("Add") { addingAccount = true }.accessibilityLabel("Add account")
              .disabled(model.storageUnavailable)
          }.padding(.bottom, 16)
          if model.snapshot.openAccounts().isEmpty {
            ContentUnavailableView {
              Label(model.snapshot.accounts.isEmpty ? "No accounts yet" : "No open accounts", systemImage: "chart.bar")
            } description: {
              Text(model.snapshot.accounts.isEmpty ? "Add an account, then record a snapshot to start your history." : "Reopen an account in Settings, or add a new one.")
            } actions: {
              Button("Add account") { addingAccount = true }
                .disabled(model.storageUnavailable)
            }
          }
          ForEach(model.snapshot.openAccounts(), id: \.id) { account in
            Divider()
            NavigationLink {
              AccountDetailView(account: account)
            } label: {
              HStack(spacing: 12) {
                Image(systemName: account.isAsset ? "chart.bar.fill" : "creditcard")
                  .font(.title3).foregroundStyle(WealthTheme.blue)
                  .frame(width: 40, height: 40)
                  .background(WealthTheme.paleBlue, in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 4) {
                  Text(account.name).font(.body.weight(.medium)).foregroundStyle(.primary)
                  Text(
                    account.provider.isEmpty
                      ? (account.isAsset ? "Asset" : "Liability") : account.provider
                  )
                  .font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 4) {
                  Text(latest?.totals[account.id].map { formattedMoney(NSDecimalNumber(decimal: $0).doubleValue, currency: account.currency) } ?? "Not recorded")
                    .font(.body.weight(.medium)).monospacedDigit().foregroundStyle(.primary)
                  if let recorded = model.portfolio.balanceDates[account.id], recorded != points.last?.date {
                    Text("Recorded " + recorded.formatted(date: .abbreviated, time: .omitted))
                      .font(.caption).foregroundStyle(.secondary)
                  }
                }
                Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                  .foregroundStyle(.tertiary)
              }.padding(.vertical, 12).contentShape(Rectangle())
            }.buttonStyle(.plain)
          }
        }
      }.frame(maxWidth: 820).padding(.horizontal, 20).padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }.background(WealthTheme.background)
      .wealthScreen().wealthNavigationTitle("WealthOne", displayMode: .large)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Add snapshot", systemImage: "plus") { addingEntry = true }
            .accessibilityIdentifier("Add dated entry").disabled(model.storageUnavailable)
        }
      }
      .sheet(isPresented: $addingAccount) { NavigationStack { AccountEditorView(account: nil) } }
      .sheet(isPresented: $addingEntry) { NavigationStack { EntryEditorView(record: nil) } }
  }
  var asOf: some View {
    Text(
      points.last.map { "As of " + $0.date.formatted(date: .abbreviated, time: .omitted) }
        ?? "No snapshots yet"
    ).font(.caption)
  }
  func summary(_ asset: Bool) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(asset ? "Assets" : "Liabilities").font(.subheadline).foregroundStyle(.secondary)
      Text(money(total(asset))).font(.title3.bold()).monospacedDigit()
    }.frame(maxWidth: .infinity, alignment: .leading)
  }
}
struct AccountEditorView: View {
  @EnvironmentObject var model: AppModel
  @Environment(\.dismiss) var dismiss
  let account: Account?
  var initialName = ""
  @State private var newID = UUID().uuidString
  @State private var name = ""
  @State private var provider = ""
  @State private var asset = true
  @State private var type = 0
  @State private var currency = "GBP"
  @State private var deleting = false
  @State private var changingStatus = false
  @State private var context: EditContext?
  @State private var initialized = false
  var dirty: Bool {
    initialized
      && (name != (account?.name ?? "") || provider != (account?.provider ?? "")
        || asset != (account?.isAsset ?? true) || type != (account?.accountType ?? 0) || currency != (account?.currency ?? "GBP"))
  }
  var body: some View {
    Form {
      VStack(alignment: .leading, spacing: 8) {
        Text("Account name").font(BrandFont.body(12, relativeTo: .caption))
        TextField("Account name", text: $name)
      }
      VStack(alignment: .leading, spacing: 8) {
        Text("Provider").font(BrandFont.body(12, relativeTo: .caption))
        TextField("Provider", text: $provider)
      }
      Picker(
        "Account category",
        selection: Binding(
          get: { asset },
          set: {
            asset = $0
            type = $0 ? 0 : 7
          })
      ) {
        Text("Asset").tag(true)
        Text("Liability").tag(false)
      }.pickerStyle(.segmented)
      Picker("Currency", selection: $currency) {
        ForEach(PortfolioCurrency.codes, id: \.self) { Text($0).tag($0) }
      }.accessibilityIdentifier("Account currency")
      if account != nil && currency != account?.currency {
        Text("Existing amounts keep their numbers in the selected currency. Save missing rates in Settings to convert historical portfolio totals.").font(.caption).foregroundStyle(.secondary)
      }
      Picker("Type", selection: $type) {
        ForEach(accountTypes.indices.filter { asset ? $0 < 7 : $0 >= 7 }, id: \.self) {
          Text(accountTypes[$0]).tag($0)
        }
        if !accountTypes.indices.contains(type) { Text("Other (\(type))").tag(type) }
      }
      if let account {
        Section("Account status") {
          LabeledContent("Status", value: account.isClosed() ? "Closed" : "Open")
          Button(account.isClosed() ? "Reopen account" : "Close account") { changingStatus = true }
            .disabled(dirty)
          Text("Closing keeps all historical entries, saves a zero balance and records the remaining balance as an outflow. Reopen here to enter balances again.")
            .font(.caption).foregroundStyle(.secondary)
        }
        if !model.hasAccountHistory(account.id) {
          Button("Delete account", role: .destructive) { deleting = true }
        } else {
          Text("Accounts with historical entries can be closed and cannot be deleted.").font(.caption).foregroundStyle(.secondary)
        }
      }
    }.wealthScreen().protectDraft(dirty) { dismiss() }.wealthNavigationTitle(
      account == nil ? "Add account" : "Edit account"
    )
    .toolbar {
      ToolbarItem(placement: .cancellationAction) { if !dirty { Button("Cancel") { dismiss() } } }
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") {
          model.saveAccount(
            Account(
              id: account?.id ?? newID, name: name, provider: provider,
              isAsset: asset, accountType: type, currency: currency), context: context)
          if model.error == nil { dismiss() }
        }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
      }
    }
    .onAppear {
      guard !initialized else { return }
      initialized = true
      context = model.editContext(.account(account?.id ?? newID))
      if let account {
        name = account.name
        provider = account.provider
        asset = account.isAsset
        type = account.accountType
        currency = account.currency
      } else {
        name = initialName
      }
    }
    .sheet(isPresented: $changingStatus) {
      if let account {
        NavigationStack {
          AccountLifecycleView(account: account, closing: !account.isClosed()) {
            changingStatus = false
            dismiss()
          }
        }
      }
    }
    .confirmationDialog(
      "Delete this account? Its edit history is retained.", isPresented: $deleting,
      titleVisibility: .visible
    ) {
      Button("Delete", role: .destructive) {
        if let account {
          model.deleteAccount(account.id)
          dismiss()
        }
      }
    }
  }
}
struct AccountLifecycleView: View {
  @EnvironmentObject var model: AppModel
  @Environment(\.dismiss) var dismiss
  let account: Account
  let closing: Bool
  let completed: () -> Void
  @State private var date = Date()
  @State private var context: EditContext?
  var earliest: Date {
    let recordDates = model.portfolio.orderedRecords.filter {
      $0.totals[account.id] != nil || $0.inflows[account.id] != nil || $0.outflows[account.id] != nil
    }.map { PortfolioCalculator.dayCalendar.startOfDay(for: PortfolioCalculator.date($0.date)) }
    let statusDates = account.closureDates.keys.map { PortfolioCalculator.date($0) }
    return (recordDates + statusDates).max() ?? PortfolioCalculator.date("1900-01-01")
  }
  var remaining: Decimal {
    PortfolioCalculator.balance(of: account, on: localDayKey(date), records: model.snapshot.records)
  }
  var body: some View {
    Form {
      Section(account.name) {
        if earliest <= Date() {
          DatePicker(closing ? "Closing date" : "Reopening date", selection: $date, in: earliest...Date(), displayedComponents: .date)
        } else {
          Text("This account has future entries. Review them before changing its status.")
        }
        if closing {
          LabeledContent("Closing outflow", value: formattedMoney(NSDecimalNumber(decimal: remaining).doubleValue, currency: account.currency))
          LabeledContent("Closing balance", value: formattedMoney(0, currency: account.currency))
          Text("The remaining balance is added to any outflow already recorded on this date. All earlier entries stay available. This does not transfer funds to another account.")
        } else {
          Text("The account becomes available for entries from this date. Its balance stays at zero until you record a new balance.")
        }
      }
      Button(closing ? "Confirm close" : "Confirm reopen", role: closing ? .destructive : nil) {
        model.setAccountClosed(account.id, closed: closing, day: localDayKey(date), context: context)
        if model.error == nil { completed() }
      }.disabled(context == nil || earliest > Date())
    }.wealthScreen().wealthNavigationTitle(closing ? "Close account" : "Reopen account")
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
      .onAppear { context = model.editContext(.account(account.id)) }
  }
}
struct EntryEditorView: View {
  @EnvironmentObject var model: AppModel
  @Environment(\.dismiss) var dismiss
  let record: DayRecord?
  @State private var date = Date()
  @State private var capturedDate = Date()
  @State private var initialDate = Date()
  @State private var pendingDate: Date?
  @State private var changingDate = false
  @State private var mode = "Total"
  @State private var edits: [String: String] = [:]
  @State private var deleting = false
  @State private var context: EditContext?
  @State private var capturedAccounts: [Account] = []
  @State private var capturedRecord: DayRecord?
  @State private var rateTexts: [String: String] = [:]
  @State private var rateDates: [String: String] = [:]
  @State private var rateSources: [String: String] = [:]
  @State private var rateQuote: ExchangeRateQuote?
  @State private var fetchingRates = false
  @State private var rateError: String?
  @State private var rateRequestID = UUID()
  @State private var initialized = false
  let modes = ["Total", "Inflows", "Outflows"]
  var dirty: Bool {
    !edits.isEmpty || rateQuote != nil
      || (initialized && record == nil && localDayKey(date) != localDayKey(initialDate))
  }
  var effectiveRecord: DayRecord? { capturedRecord }
  func capture() {
    if let record { date = PortfolioCalculator.date(record.date) }
    capturedDate = date
    capturedAccounts = model.snapshot.accounts.filter { !$0.isClosed(on: localDayKey(date)) }
    capturedRecord =
      record ?? PortfolioCalculator.record(on: localDayKey(date), records: model.snapshot.records)
    context = model.editContext(.day(capturedRecord?.date ?? localDayKey(date)))
    rateTexts = (capturedRecord?.exchangeRates ?? [:]).mapValues(amount)
    rateDates = capturedRecord?.exchangeRateDates ?? [:]
    rateSources = capturedRecord?.exchangeRateSources ?? [:]
    rateQuote = nil
    rateRequestID = UUID()
    if !requiredCurrencies.isEmpty && requiredCurrencies.contains(where: { rateTexts[$0] == nil }) {
      Task { await fetchRates(refresh: false) }
    }
  }
  var requiredCurrencies: [String] {
    Set(capturedAccounts.map(\.currency) + [model.snapshot.reportingCurrency]).subtracting(["GBP"]).sorted()
  }
  func fetchRates(refresh: Bool) async {
    guard !fetchingRates else { return }
    let requestID = rateRequestID
    fetchingRates = true
    defer { fetchingRates = false }
    do {
      let quote = try await model.exchangeRateQuote(refresh: refresh)
      guard rateRequestID == requestID else { return }
      rateQuote = quote
      for code in requiredCurrencies where refresh || rateTexts[code] == nil {
        rateTexts[code] = quote.ratesToGBP[code].map(amount)
        rateDates[code] = quote.date
        rateSources[code] = quote.source
      }
      rateError = nil
    } catch { rateError = error.localizedDescription }
  }
  func original(_ id: String, _ category: String) -> Decimal? {
    switch category {
    case "Inflows": effectiveRecord?.inflows[id]
    case "Outflows": effectiveRecord?.outflows[id]
    default: effectiveRecord?.totals[id]
    }
  }
  var body: some View {
    Form {
      if record == nil {
        DatePicker("Date", selection: $date, displayedComponents: .date).onChange(of: date) {
          old, new in
          guard localDayKey(new) != localDayKey(capturedDate) else { return }
          if !edits.isEmpty {
            pendingDate = new
            date = old
            changingDate = true
          } else {
            capture()
          }
        }
      } else {
        LabeledContent(
          "Snapshot date",
          value: PortfolioCalculator.date(record!.date).formatted(
            date: .abbreviated, time: .omitted))
      }
      Picker("Values", selection: $mode) { ForEach(modes, id: \.self) { Text($0) } }.pickerStyle(
        .segmented)
      ForEach(AccountProviderGroup.make(capturedAccounts)) { group in
        Section(group.provider) {
          ForEach(group.accounts, id: \.id) { account in
            VStack(alignment: .leading, spacing: 8) {
              Text(account.name + " · " + mode + " (" + account.currency + ")").font(
                BrandFont.body(12, relativeTo: .caption))
              TextField(
                account.name,
                text: Binding(
                  get: { edits[mode + account.id] ?? original(account.id, mode).map(amount) ?? "" },
                  set: { edits[mode + account.id] = $0 })
              ).keyboardType(.numbersAndPunctuation).accessibilityLabel(account.name + " " + mode)
              if let text = edits[mode + account.id],
                !text.trimmingCharacters(in: .whitespaces).isEmpty, EntryAmount.parse(text) == nil
              {
                Text("Enter a valid " + account.currency + " amount.").font(BrandFont.body(12, relativeTo: .caption))
                  .foregroundStyle(.red)
              }
            }
          }
        }
      }
      Text("Leave blank for no recorded value; the last recorded balance is carried forward.")
        .font(.caption).foregroundStyle(.secondary)
      if let existing = effectiveRecord {
        let closed = model.snapshot.accounts.filter { $0.isClosed(on: localDayKey(date)) && (existing.totals[$0.id] != nil || existing.inflows[$0.id] != nil || existing.outflows[$0.id] != nil) }
        if !closed.isEmpty {
          Section("Closed accounts · recorded values") {
            ForEach(closed, id: \.id) { account in
              LabeledContent(account.name + " · " + mode, value: original(account.id, mode).map { formattedMoney(NSDecimalNumber(decimal: $0).doubleValue, currency: account.currency) } ?? "—")
            }
            Text("These amounts belong to a closed account and are preserved. Reopen the account in Settings to add new balances.").font(.caption).foregroundStyle(.secondary)
          }
        }
      }
      if !requiredCurrencies.isEmpty {
        Section("Saved exchange rates") {
          ForEach(requiredCurrencies, id: \.self) { code in
            TextField("GBP per " + code, text: Binding(get: { rateTexts[code] ?? "" }, set: {
              rateTexts[code] = $0
              rateRequestID = UUID()
              rateDates[code] = localDayKey()
              rateSources[code] = "Manual"
              rateQuote = ExchangeRateQuote(ratesToGBP: [:], date: localDayKey(), source: "Manual")
            })).keyboardType(.decimalPad).accessibilityLabel("GBP per " + code)
            if let date = rateDates[code] {
              Text("1 " + code + " in GBP · rate dated " + date).font(.caption).foregroundStyle(.secondary)
            }
          }
          Button("Refresh exchange rates") { Task { await fetchRates(refresh: true) } }.disabled(fetchingRates)
          if fetchingRates { ProgressView() }
          if let rateError { Text(rateError).font(.caption).foregroundStyle(.secondary) }
          Text("Rates are saved with this entry and stay fixed until you refresh and save. Published reference rates are approximate.").font(.caption).foregroundStyle(.secondary)
        }
      }
      if let record {
        if model.isClosureDay(record.date) {
          Text("This dated entry records an account closure and is retained with its history.").font(.caption).foregroundStyle(.secondary)
        } else {
          Button("Delete dated entry", role: .destructive) { deleting = true }
        }
      }
    }.wealthScreen().protectDraft(dirty) { dismiss() }.wealthNavigationTitle(
      record == nil ? "Add entry" : "Edit entry"
    )
    .onAppear {
      if !initialized {
        initialDate = date
        initialized = true
        capture()
      }
    }
    .toolbar {
      ToolbarItem(placement: .cancellationAction) { if !dirty { Button("Cancel") { dismiss() } } }
      ToolbarItem(placement: .confirmationAction) { Button("Save", action: save) }
    }
    .confirmationDialog(
      "Change snapshot date and discard entered amounts?", isPresented: $changingDate,
      titleVisibility: .visible
    ) {
      Button("Change Date", role: .destructive) {
        edits = [:]
        if let pendingDate {
          date = pendingDate
          capture()
        }
        pendingDate = nil
      }
      Button("Keep Editing", role: .cancel) { pendingDate = nil }
    }
    .confirmationDialog(
      "Delete this dated entry? Its history is retained.", isPresented: $deleting,
      titleVisibility: .visible
    ) {
      Button("Delete", role: .destructive) {
        if let record {
          model.deleteDay(record.date)
          dismiss()
        }
      }
    }
  }
  func save() {
    var day = effectiveRecord ?? DayRecord(date: localDayKey(date))
    for account in capturedAccounts {
      for category in modes {
        guard let text = edits[category + account.id] else { continue }
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        var value: Decimal?
        if !trimmed.isEmpty {
          guard let parsed = EntryAmount.parse(trimmed) else {
            model.error = "Enter a valid amount for \(account.name)."
            return
          }
          value = parsed
        }
        switch category {
        case "Inflows": day.inflows[account.id] = value
        case "Outflows": day.outflows[account.id] = value
        default: day.totals[account.id] = value
        }
      }
    }
    for code in requiredCurrencies {
      guard let text = rateTexts[code], let rate = ExchangeRateQuote.manualRate(text) else {
        model.error = "Enter a positive GBP rate for " + code
        return
      }
      day.exchangeRates[code] = rate
      day.exchangeRateDates[code] = rateDates[code]
      day.exchangeRateSources[code] = rateSources[code]
    }
    model.saveDay(day, context: context)
    if model.error == nil { dismiss() }
  }
}
struct AccountDetailView: View {
  @EnvironmentObject var model: AppModel
  let account: Account
  func money(_ value: Double) -> String { formattedMoney(value, currency: account.currency) }
  @State private var editing = false
  var points: [NetWorthPoint] {
    model.portfolio.accountHistories[account.id] ?? []
  }
  var body: some View {
    List {
      if let point = points.last {
        Section {
          Text(money(point.total)).font(BrandFont.heading(36, relativeTo: .largeTitle))
          Text("Recorded " + (model.portfolio.balanceDates[account.id] ?? point.date).formatted(date: .abbreviated, time: .omitted)).font(
            BrandFont.body(13, relativeTo: .footnote)
          ).foregroundStyle(.secondary)
          if !account.provider.isEmpty { Text(account.provider).foregroundStyle(.secondary) }
        }
      }
      Section { WorthChart(points: points, currency: account.currency) }
      if let point = points.last { MetricsView(point: point, currency: account.currency) }
    }
    .wealthScreen().wealthNavigationTitle(account.name).toolbar {
      Button("Edit") { editing = true }
    }
    .sheet(isPresented: $editing) {
      NavigationStack {
        AccountEditorView(account: model.snapshot.accounts.first { $0.id == account.id } ?? account)
      }
    }
  }
}
struct MetricsView: View {
  let point: NetWorthPoint
  var currency = "GBP"
  func money(_ value: Double) -> String { formattedMoney(value, currency: currency) }
  var body: some View {
    Section("Performance · " + currency) {
      Text(
        "Change compares this snapshot with the previous recorded snapshot. Returns are estimates that treat recorded cash flows as occurring at the end of each snapshot interval. Blank balances carry forward the last recorded value. Year metrics use the available opening snapshot; an exact calendar-year result requires a year-end valuation."
      ).font(BrandFont.body(12, relativeTo: .caption)).foregroundStyle(.secondary)
      LabeledContent("Value", value: money(point.total))
      LabeledContent("Change", value: money(point.changeAmount))
      LabeledContent("Change %", value: point.changePercent.formatted(.percent))
      LabeledContent("Estimated time-weighted return", value: point.twrrPercent.formatted(.percent))
      if let baseline = point.yearBaselineDate {
        LabeledContent("Year baseline", value: baseline.formatted(date: .abbreviated, time: .omitted))
      }
      LabeledContent("Estimated year return", value: point.yearlyTwrrPercent.formatted(.percent))
      LabeledContent("Year growth", value: money(point.yearlyGrowth))
      LabeledContent("Year growth %", value: point.yearlyGrowthPercent.formatted(.percent))
      LabeledContent("Inflows", value: money(point.inflows))
      LabeledContent("Outflows", value: money(point.outflows))
      LabeledContent("Total net flows", value: money(point.totalNetflows))
      LabeledContent("Year net flows", value: money(point.yearlyNetflows))
      LabeledContent("Tax year net flows", value: money(point.taxYearNetflows))
      LabeledContent("Profit / loss", value: money(point.totalPL))
      LabeledContent("Profit / loss %", value: point.totalPLPercent.formatted(.percent))
      LabeledContent("Year profit / loss", value: money(point.yearlyPL))
      LabeledContent("Year profit / loss %", value: point.yearlyPLPercent.formatted(.percent))
    }
  }
}
