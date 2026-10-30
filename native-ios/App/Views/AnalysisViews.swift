import Charts
import SwiftUI
import WealthOneCore

struct BreakdownView: View {
  @EnvironmentObject var model: AppModel
  func money(_ value: Double) -> String { formattedMoney(value, currency: model.snapshot.reportingCurrency) }
  @State private var byType = false
  var groups: [(String, Double)] {
    var values = model.portfolio.accountAllocation
    if byType {
      values = [:]
      for (type, value) in model.portfolio.typeAllocation {
        let name = accountTypes.indices.contains(type) ? accountTypes[type] : "Other"
        values[name, default: 0] += value
      }
    }
    return values.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
  }
  var body: some View {
    let groups = groups
    let positiveTotal = groups.reduce(0) { $0 + max(0, $1.1) }
    let colors = Dictionary(uniqueKeysWithValues: groups.enumerated().map {
      ($0.element.0, WealthTheme.chartColors[$0.offset % WealthTheme.chartColors.count])
    })
    let allocationColor: (String) -> Color = { colors[$0] ?? WealthTheme.blue }
    List {
      Picker("Allocation", selection: $byType) {
        Text("By account").tag(false)
        Text("By type").tag(true)
      }.pickerStyle(.segmented).listRowSeparator(.hidden)
      Section {
        if groups.contains(where: { !$0.1.isFinite }) {
          NavigationLink("Save missing exchange rates") { CurrencySettingsView() }
        }
        if positiveTotal.isFinite && positiveTotal > 0 {
          Chart(groups.filter { $0.1 > 0 }, id: \.0) { group in
            SectorMark(angle: .value("Value", group.1), innerRadius: .ratio(0.62), angularInset: 1)
              .foregroundStyle(by: .value("Account", group.0))
              .accessibilityLabel(group.0)
              .accessibilityValue(
                money(group.1) + ", " + (group.1 / positiveTotal).formatted(.percent))
          }.chartForegroundStyleScale(domain: groups.map(\.0), mapping: allocationColor)
            .chartLegend(.hidden).frame(height: 260)
            .chartOverlay { _ in
              VStack(spacing: 4) {
                Text("Assets").font(.caption).foregroundStyle(.secondary)
                Text(money(positiveTotal)).font(.title3.bold()).monospacedDigit()
                  .minimumScaleFactor(0.7).lineLimit(1)
              }.frame(maxWidth: 150).allowsHitTesting(false).accessibilityHidden(true)
            }
            .accessibilityLabel("Positive asset allocation in the main currency")
            .listRowSeparator(.hidden)
        } else {
          ContentUnavailableView(
            "No positive asset balances", systemImage: "chart.pie",
            description: Text("Record an asset balance to see your allocation.")
          )
          .listRowSeparator(.hidden)
        }
        ForEach(groups, id: \.0) { group in
          HStack(spacing: 12) {
            Circle().fill(allocationColor(group.0))
              .frame(width: 10, height: 10).accessibilityHidden(true)
            Text(group.0)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
              Text(money(group.1)).monospacedDigit()
              if positiveTotal > 0 && group.1 > 0 {
                Text((group.1 / positiveTotal).formatted(.percent.precision(.fractionLength(1))))
                  .font(.caption).foregroundStyle(.secondary)
              }
            }
          }.padding(.vertical, 6).accessibilityElement(children: .combine)
        }
      } header: {
        Text("Asset allocation").font(.headline).foregroundStyle(.primary)
      }
      Section {
        ForEach(model.snapshot.openAccounts().filter { !$0.isAsset }, id: \.id) { account in
          LabeledContent(
            account.name,
            value: money(model.portfolio.convertedBalances[account.id] ?? 0))
        }
        if !model.snapshot.openAccounts().contains(where: { !$0.isAsset }) {
          Text("No liabilities recorded").foregroundStyle(.secondary)
        }
      } header: {
        Text("Liabilities").font(.headline).foregroundStyle(.primary)
      }
    }.listStyle(.plain).wealthScreen().wealthNavigationTitle("Breakdown", displayMode: .large)
  }
}
struct HistoryView: View {
  @EnvironmentObject var model: AppModel
  func money(_ value: Double) -> String { formattedMoney(value, currency: model.snapshot.reportingCurrency) }
  @State private var metric = "Total"
  let metrics = ["Total", "Change", "Percent", "Net flows"]
  var body: some View {
    List {
      Picker("Metric", selection: $metric) { ForEach(metrics, id: \.self) { Text($0) } }
        .pickerStyle(.menu)
      Text(
        "Change and percent compare each snapshot with the previous recorded snapshot. Values use your main currency."
      ).font(BrandFont.body(12, relativeTo: .caption)).foregroundStyle(.secondary)
      ForEach(model.portfolio.historySections) { section in
        Section(String(section.year)) {
          ForEach(section.points) {
            point in
            NavigationLink {
              EntryEditorView(record: model.snapshot.records.first { $0.date == point.day })
            } label: {
              HStack {
                Text(point.date.formatted(date: .abbreviated, time: .omitted))
                Spacer()
                Text(value(point))
              }
            }.accessibilityIdentifier("History entry " + point.day)
          }
        }
      }
      if model.portfolio.points.isEmpty {
        ContentUnavailableView(
          "No dated entries", systemImage: "calendar",
          description: Text("Add an entry from Home to begin your history."))
      }
    }.listStyle(.plain).wealthScreen().wealthNavigationTitle("History", displayMode: .large)
      .toolbar { NavigationLink("Edit log") { AuditView() } }
  }
  func value(_ point: NetWorthPoint) -> String {
    switch metric {
    case "Change": money(point.changeAmount)
    case "Percent": point.changePercent.formatted(.percent)
    case "Net flows": money(point.netflows)
    default: money(point.total)
    }
  }
}
struct GoalsView: View {
  @EnvironmentObject var model: AppModel
  func money(_ value: Double) -> String { formattedMoney(value, currency: model.snapshot.reportingCurrency) }
  @State private var income = false
  @State private var editing = false
  var currentNetWorth: Double {
    model.portfolio.points.last?.total ?? 0
  }
  var projection: GoalProjection {
    GoalProjectionCalculator.calculate(
      settings: model.snapshot.goal, currentNetWorth: currentNetWorth)
  }
  var currentValue: Double {
    guard income else { return currentNetWorth }
    if case .decimal(let earnings) = model.snapshot.goal["earnings"] {
      return NSDecimalNumber(decimal: earnings).doubleValue
    }
    return 55000  // Same default earnings assumption as the existing goal calculator/editor.
  }
  var currentLabel: String { income ? "Current annual earnings" : "Current savings" }
  var scenarios: [(name: String, amount: Double, percentage: Double?)] {
    let p = projection
    return income
      ? [
        ("Goal", p.projectedIncomeGoal, nil),
        ("Poor", p.incomePoorEstimate.amount, p.incomePoorEstimate.percentage),
        ("Average", p.incomeAverageEstimate.amount, p.incomeAverageEstimate.percentage),
      ]
      : [
        ("Goal", p.projectedSavingsGoal, nil),
        ("Poor", p.savingsPoorEstimate.amount, p.savingsPoorEstimate.percentage),
        ("Average", p.savingsAverageEstimate.amount, p.savingsAverageEstimate.percentage),
      ]
  }
  var body: some View {
    List {
      Picker("Projection", selection: $income) {
        Text("Savings").tag(false)
        Text("Annual income").tag(true)
      }.pickerStyle(.segmented)
      Section("Retirement projection") {
        if scenarios.contains(where: { !$0.amount.isFinite }) {
          Text(
            "Some projections are unavailable. Review your birth date, retirement age and financial assumptions. Imported values are preserved until you edit them."
          )
          .font(BrandFont.body(13, relativeTo: .footnote)).foregroundStyle(.secondary)
          Button("Review goal inputs") { editing = true }
        }
        Chart {
          ForEach(scenarios.filter { $0.amount.isFinite }, id: \.name) { item in
            BarMark(x: .value("Scenario", item.name), y: .value(model.snapshot.reportingCurrency, item.amount))
              .foregroundStyle(by: .value("Scenario", item.name))
              .accessibilityLabel(item.name).accessibilityValue(money(item.amount))
          }
          if currentValue.isFinite {
            RuleMark(y: .value(currentLabel, currentValue))
              .foregroundStyle(WealthTheme.ink)
              .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
              .annotation(position: .top, alignment: .trailing) {
                Text("Current · " + money(currentValue)).font(
                  BrandFont.body(11, relativeTo: .caption)
                )
                .foregroundStyle(.primary).padding(.horizontal, 5).padding(.vertical, 3)
                .background(WealthTheme.background, in: RoundedRectangle(cornerRadius: 5))
              }
              .accessibilityLabel(currentLabel).accessibilityValue(money(currentValue))
          }
        }
        .chartForegroundStyleScale(
          domain: ["Goal", "Poor", "Average"],
          range: [
            WealthTheme.chartColors[1], WealthTheme.chartColors[2], WealthTheme.chartColors[0],
          ]
        )
        .chartLegend(.hidden)
        .chartYAxis {
          AxisMarks { tick in
            AxisGridLine()
            AxisValueLabel { if let value = tick.as(Double.self) { Text(money(value)) } }
          }
        }.frame(height: 240)
        Text(currentLabel + " is shown by the dashed line.")
          .font(.caption).foregroundStyle(.secondary).listRowSeparator(.hidden)
        ForEach(scenarios, id: \.name) { item in
          HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(item.name)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 5) {
              Text(item.amount.isFinite ? money(item.amount) : "Unavailable")
                .font(BrandFont.body(16, weight: .medium))
              if let percent = item.percentage {
                Text(percentage(percent)).font(BrandFont.body(12, relativeTo: .caption))
                  .foregroundStyle(.secondary)
              }
            }
          }.accessibilityElement(children: .combine).accessibilityIdentifier(
            "Goal scenario " + item.name)
        }
      }
      GoalHistoryComparisonView(points: model.portfolio.goalHistory, currency: model.snapshot.reportingCurrency)
      Section {
        Text(
          "Scenario percentages show how much of your target is funded; 100% means the target is met. The Current line shows your savings balance, or your annual earnings assumption in Income mode."
        ).font(BrandFont.body(12, relativeTo: .caption)).foregroundStyle(.secondary)
        Text(
          "Illustrative projections use legacy assumptions, including zero inflation, 1% real salary growth and the legacy state-pension assumption from retirement age 68. They are estimates, not guaranteed returns."
        ).font(BrandFont.body(13, relativeTo: .footnote)).foregroundStyle(.secondary)
      }
    }.listStyle(.plain).wealthScreen().wealthNavigationTitle("Goals", displayMode: .large).toolbar {
      Button("Edit") { editing = true }
    }
    .sheet(isPresented: $editing) { NavigationStack { GoalEditorView() } }
  }
  func percentage(_ value: Double) -> String {
    guard value.isFinite else { return "Unavailable" }
    if value > 0 && value < 0.01 { return "<0.01%" }
    return value.formatted(.number.precision(.fractionLength(0...2))) + "%"
  }
}
struct GoalEditorView: View {
  @EnvironmentObject var model: AppModel
  @Environment(\.dismiss) var dismiss
  @State private var birth = PortfolioCalculator.date("1978-12-26")
  @State private var draft = GoalDraft()
  @State private var initialBirth = PortfolioCalculator.date("1978-12-26")
  @State private var context: EditContext?
  @State private var initialized = false
  @State private var draftCurrency = "GBP"
  var invalidFields: Set<String> { draft.invalidKeys(currentAge: age) }
  var dirty: Bool { draft.isDirty }
  let styles = [
    "Safety first", "Defensive", "Cautious", "Slightly cautious", "Moderate", "Adventurous",
    "Very adventurous",
  ]
  var age: Int { GoalProjectionCalculator.currentAge(birthDate: localDayKey(birth)) }
  func number(_ key: String, fallback: Double) -> Double {
    let range = draft.range(key, currentAge: age)
    return min(range.upperBound, max(range.lowerBound, draft.number(key, fallback: fallback)))
  }
  func binding(_ key: String, fallback: Double) -> Binding<Double> {
    Binding(get: { number(key, fallback: fallback) }, set: { draft.setNumber($0, for: key) })
  }
  @ViewBuilder func goalSlider(_ key: String, title: String, fallback: Double, step: Double)
    -> some View
  {
    let constraints = draft.slider(key, fallback: fallback, preferredStep: step, currentAge: age)
    if let legalStep = constraints.step {
      Slider(value: binding(key, fallback: fallback), in: constraints.range, step: legalStep)
        .accessibilityLabel(title)
    } else {
      Text("No slider adjustment is available within this range. Use the exact value above.").font(
        BrandFont.body(12, relativeTo: .caption)
      ).foregroundStyle(.secondary)
    }
  }
  func exactInput(_ title: String, key: String, fallback: Double, unit: String) -> some View {
    let range = draft.range(key, currentAge: age)
    return VStack(alignment: .leading, spacing: 8) {
      Text(title + " · " + unit).font(BrandFont.body(12, relativeTo: .caption))
      TextField(
        title,
        text: Binding(
          get: { draft.displayText(key, fallback: fallback) }, set: { draft.setText($0, for: key) })
      )
      .keyboardType(.numbersAndPunctuation).accessibilityLabel(title + " " + unit)
      if invalidFields.contains(key) {
        Text(
          "Enter a value from " + range.lowerBound.formatted() + " to "
            + range.upperBound.formatted() + "."
        )
        .foregroundStyle(.red).font(BrandFont.body(12, relativeTo: .caption))
      }
    }
  }
  var body: some View {
    Form {
      DatePicker("Birth date", selection: $birth, in: ...Date(), displayedComponents: .date)
        .onChange(of: birth) { _, _ in
          draft.setBirth(
            day: localDayKey(birth), originalDisplayedDay: localDayKey(initialBirth),
            currentAge: age)
        }
      LabeledContent("Current age", value: String(age))
      Section("Retirement age") {
        exactInput("Retirement age", key: "retirementAge", fallback: 65, unit: "years")
        goalSlider("retirementAge", title: "Retirement age", fallback: 65, step: 1)
      }
      Section("Annual earnings") {
        exactInput("Annual earnings", key: "earnings", fallback: 55000, unit: draftCurrency + " per year")
        goalSlider("earnings", title: "Annual earnings", fallback: 55000, step: 500)
      }
      Section("Monthly contribution") {
        exactInput("Monthly contribution", key: "contributions", fallback: 0, unit: draftCurrency + " per month")
        goalSlider("contributions", title: "Monthly contribution", fallback: 0, step: 50)
      }
      Section("Investment style") {
        Picker("Style", selection: binding("investmentStyle", fallback: 3)) {
          ForEach(styles.indices, id: \.self) { Text(styles[$0]).tag(Double($0)) }
        }
      }
      Section("Lifestyle: \(Int(number("lifeStyle", fallback: 40)))% of earnings") {
        Slider(value: binding("lifeStyle", fallback: 40), in: 0...100, step: 1).accessibilityLabel(
          "Retirement lifestyle percentage")
      }
    }.wealthScreen().protectDraft(dirty) { dismiss() }.wealthNavigationTitle("Edit goal")
      .onAppear {
        guard !initialized else { return }
        initialized = true
        context = model.editContext(.goal)
        draftCurrency = model.snapshot.reportingCurrency
        draft = GoalDraft(original: model.snapshot.goal)
        switch draft.original["birthDate"] {
        case .string(let value): initialBirth = PortfolioCalculator.date(value)
        case .decimal(let value): initialBirth = PortfolioCalculator.date(amount(value))
        default: break
        }
        if initialBirth > Date()
          || GoalProjectionCalculator.currentAge(birthDate: localDayKey(initialBirth)) == 0
        {
          initialBirth = PortfolioCalculator.date("1978-12-26")
        }
        birth = initialBirth
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { if !dirty { Button("Cancel") { dismiss() } } }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            // Send only edited fields. This retains imported decimals and hidden pension inputs.
            do {
              let changed = try draft.changes(currentAge: age)
              if !changed.isEmpty { model.saveGoal(changed, context: context) }
              if model.error == nil { dismiss() }
            } catch { model.error = error.localizedDescription }
          }.disabled(!invalidFields.isEmpty)
        }
      }
  }
}

struct GoalHistoryComparisonView: View {
  let points: [GoalHistoryPoint]
  let currency: String
  var body: some View {
    let data = points.filter { $0.average.isFinite && $0.poor.isFinite }
    let actuals = data.filter { $0.actual != nil }
    let values = data.flatMap { [$0.actual, $0.average, $0.poor].compactMap { $0 } }
    let low = min(values.min() ?? 0, 0)
    let high = values.max() ?? 1
    let padding = max((high - low) * 0.05, 1)
    let domain = low...(max(high + padding, low + 1))
    Section("Actual vs projected wealth") {
      if let first = data.first, let last = data.last {
        Text("From " + first.date.formatted(date: .abbreviated, time: .omitted) + " to " + last.date.formatted(date: .abbreviated, time: .omitted))
          .font(.caption).foregroundStyle(.secondary)
        Chart {
          ForEach(data) { point in
            if let actual = point.actual {
            if actuals.count == 1 {
              PointMark(x: .value("Date", point.date), y: .value("Wealth", actual))
                .foregroundStyle(by: .value("Scenario", "Actual"))
            }
            LineMark(x: .value("Date", point.date), y: .value("Wealth", actual), series: .value("Scenario", "Actual"))
              .foregroundStyle(by: .value("Scenario", "Actual")).lineStyle(StrokeStyle(lineWidth: 2.5))
            }
            LineMark(x: .value("Date", point.date), y: .value("Wealth", point.average), series: .value("Scenario", "Average"))
              .foregroundStyle(by: .value("Scenario", "Average")).lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            LineMark(x: .value("Date", point.date), y: .value("Wealth", point.poor), series: .value("Scenario", "Poor"))
              .foregroundStyle(by: .value("Scenario", "Poor")).lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 4]))
          }
          if let latest = actuals.last, latest.date < last.date {
            RuleMark(x: .value("Latest entry", latest.date))
              .foregroundStyle(.secondary).lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
              .annotation(position: .top, alignment: .leading) { Text("Latest entry").font(.caption2).foregroundStyle(.secondary) }
          }
        }.chartYScale(domain: domain).chartForegroundStyleScale(domain: ["Actual", "Average", "Poor"], range: WealthTheme.chartColors)
          .chartYAxis { AxisMarks { tick in AxisGridLine(); AxisValueLabel { if let value = tick.as(Double.self) { Text(formattedMoney(value, currency: currency)) } } } }
          .frame(height: 230).accessibilityLabel("Actual versus projected wealth")
        if let latest = actuals.last, let actual = latest.actual {
          LabeledContent("Actual", value: formattedMoney(actual, currency: currency))
          LabeledContent("Average projection", value: formattedMoney(latest.average, currency: currency))
          LabeledContent(actual >= latest.average ? "Ahead of average" : "Behind average", value: formattedMoney(abs(actual - latest.average), currency: currency))
          Text("Comparison at " + latest.date.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundStyle(.secondary)
        }
        if last.actual == nil {
          LabeledContent("Retirement", value: last.date.formatted(date: .abbreviated, time: .omitted))
          LabeledContent("Average at retirement", value: formattedMoney(last.average, currency: currency))
          LabeledContent("Poor at retirement", value: formattedMoney(last.poor, currency: currency))
        }
      } else {
        Text("Add dated snapshots with saved exchange rates to compare actual wealth with your projections.").foregroundStyle(.secondary)
      }
      Text("Starts at your first recorded balance. The historical projection recalculates using your current monthly contribution and investment style; it is not a forecast saved in the past. The curves continue to retirement age; actual values stop at your latest recorded entry. Actual changes include contributions and currency movements.")
        .font(.caption).foregroundStyle(.secondary)
    }
  }
}
