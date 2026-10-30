import Foundation

public struct NetWorthPoint: Identifiable, Sendable {
  public var id: String { day }
  public let day: String
  public let date: Date
  public let assets, liabilities, total, inflows, outflows, netflows: Double
  public var changeAmount = 0.0, changePercent = 0.0, twrrRaw = 0.0, twrrPercent = 0.0
  public var yearlyTwrrPercent = 0.0, yearlyGrowth = 0.0, yearlyGrowthPercent = 0.0
  public var totalNetflows = 0.0, yearlyNetflows = 0.0, taxYearNetflows = 0.0
  public var yearBaselineDate: Date?
  public var totalPL = 0.0, totalPLPercent = 0.0, yearlyPL = 0.0, yearlyPLPercent = 0.0
}
public enum PortfolioCalculator {
  public static func date(_ key: String) -> Date {
    DateParser().parse(key)
  }
  // Each batch owns its formatters; no shared mutable formatter state crosses actors.
  private struct DateParser {
    let iso = ISO8601DateFormatter()
    let fractional: ISO8601DateFormatter = {
      let value = ISO8601DateFormatter()
      value.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      return value
    }()
    let day: DateFormatter = {
      let value = DateFormatter()
      value.locale = Locale(identifier: "en_US_POSIX")
      value.dateFormat = "yyyy-MM-dd"
      return value
    }()
    func parse(_ key: String) -> Date {
      if let number = Double(key), number.isFinite, abs(number / 1000) <= 62135596800 {
        return Date(timeIntervalSince1970: number / 1000)
      }
      if let value = iso.date(from: key) { return value }
      if let value = fractional.date(from: key) { return value }
      return day.date(from: String(key.prefix(10))) ?? .distantPast
    }
  }
  public static var dayCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    return calendar
  }
  public static func dayKey(_ date: Date = Date(), calendar: Calendar = dayCalendar) -> String {
    dayFormatter(calendar).string(from: date)
  }
  private static func dayFormatter(_ calendar: Calendar) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }
  public static func record(on day: String, records: [DayRecord], calendar: Calendar = dayCalendar) -> DayRecord? {
    let formatter = dayFormatter(calendar)
    return dated(records).first { formatter.string(from: $0.date) == day }?.record
  }
  public static func netWorth(accounts: [Account], records: [DayRecord], reportingCurrency: String = "GBP") -> [NetWorthPoint] {
    netWorth(accounts: accounts, datedRecords: valued(dated(records), accounts: accounts), calendar: dayCalendar, reportingCurrency: reportingCurrency)
  }
  static func dated(_ records: [DayRecord]) -> [(record: DayRecord, date: Date)] {
    let parser = DateParser()
    return records.map { (record: $0, date: parser.parse($0.date)) }.sorted { $0.date < $1.date }
  }
  /// Fill only derived balances. Flows remain observations for their own interval.
  static func valued(_ records: [(record: DayRecord, date: Date)], accounts: [Account] = []) -> [(record: DayRecord, date: Date)] {
    var balances: [String: Decimal] = [:]
    var rates: [String: Decimal] = [:]
    let lifecycleAccounts = accounts.filter { !$0.closureDates.isEmpty }
    let formatter = lifecycleAccounts.isEmpty ? nil : dayFormatter(dayCalendar)
    return records.map { item in
      balances.merge(item.record.totals, uniquingKeysWith: { _, recorded in recorded })
      var record = item.record
      if let formatter {
        let day = formatter.string(from: item.date)
        for account in lifecycleAccounts where account.isClosed(on: day) {
          balances[account.id] = 0
          // Ignore late offline flows while closed; retain the closure-day settlement.
          if account.closureDates[day] != true {
            record.inflows[account.id] = nil
            record.outflows[account.id] = nil
          }
        }
      }
      record.totals = balances
      rates.merge(record.exchangeRates, uniquingKeysWith: { _, recorded in recorded })
      record.exchangeRates = rates
      return (record, item.date)
    }
  }
  static func netWorth(accounts: [Account], datedRecords: [(record: DayRecord, date: Date)], calendar: Calendar, reportingCurrency: String = "GBP") -> [NetWorthPoint] {
    calculate(
      datedRecords.map { item in
        let day = item.record
        func sum(_ values: [String: Decimal], asset: Bool? = nil) -> Double {
          accounts.filter { asset == nil || $0.isAsset == asset }.reduce(0) {
            let value = values[$1.id] ?? 0
            guard value != 0 else { return $0 }
            guard let rate = day.conversion(from: $1.currency, to: reportingCurrency) else { return Double.nan }
            return $0 + NSDecimalNumber(decimal: value * rate).doubleValue
          }
        }
        let assets = sum(day.totals, asset: true)
        let liabilities = sum(day.totals, asset: false)
        let inflows = sum(day.inflows)
        let outflows = sum(day.outflows)
        return NetWorthPoint(
          day: day.date, date: item.date, assets: assets, liabilities: liabilities,
          total: assets - liabilities, inflows: inflows, outflows: outflows,
          netflows: inflows - outflows)
      }, calendar: calendar)
  }
  /// Lifecycle-adjusted account units, shared by closure confirmation and settlement.
  public static func balance(of account: Account, on day: String, records: [DayRecord]) -> Decimal {
    let formatter = dayFormatter(dayCalendar)
    let prior = dated(records).filter { formatter.string(from: $0.date) <= day }
    return valued(prior, accounts: [account]).last?.record.totals[account.id] ?? 0
  }
  public static func accountHistory(accountID: String, records: [DayRecord]) -> [NetWorthPoint] {
    netWorth(accounts: [Account(id: accountID, name: "")], records: records)
  }
  private static func calculate(_ input: [NetWorthPoint], calendar: Calendar) -> [NetWorthPoint] {
    var points: [NetWorthPoint] = []
    var baselines: [Int: (total: Double, date: Date, openingFlow: Double)] = [:]
    var yearProducts: [Int: Double] = [:]
    var product = 1.0
    var previousYear: Int?, previousTaxYear: Int?
    for var c in input {
      let previous = points.last
      let first = points.first
      let year = calendar.component(.year, from: c.date)
      let month = calendar.component(.month, from: c.date)
      let day = calendar.component(.day, from: c.date)
      let taxYear = year + (month > 4 || (month == 4 && day >= 6) ? 1 : 0)
      // The first ever snapshot already contains its opening flows. Later years
      // measure from the last available observation before the year starts.
      let baseline = baselines[year] ?? (
        total: previous?.total ?? c.total, date: previous?.date ?? c.date,
        openingFlow: previous == nil ? c.netflows : 0)
      baselines[year] = baseline
      c.yearBaselineDate = baseline.date
      let base = baseline.total
      c.twrrRaw =
        previous.map { $0.total != 0 ? (c.total - c.netflows - $0.total) / $0.total : 0 } ?? 0
      c.twrrPercent = product * (1 + c.twrrRaw) - 1
      c.yearlyTwrrPercent =
        (yearProducts[year] ?? 1) * (1 + c.twrrRaw)
        - 1
      c.yearlyGrowth = c.total - base
      c.yearlyGrowthPercent = base != 0 ? c.yearlyGrowth / base : 0
      c.totalNetflows = (previous?.totalNetflows ?? 0) + c.netflows
      c.yearlyNetflows =
        (previous.map { previousYear == year ? $0.yearlyNetflows : 0 } ?? 0) + c.netflows
      c.taxYearNetflows =
        (previous.map { previousTaxYear == taxYear ? $0.taxYearNetflows : 0 } ?? 0) + c.netflows
      c.totalPL = first.map { c.total - $0.total - (c.totalNetflows - $0.netflows) } ?? 0
      c.totalPLPercent = (first?.total ?? 0) != 0 ? c.totalPL / first!.total : 0
      c.yearlyPL = c.total - base - (c.yearlyNetflows - baseline.openingFlow)
      c.yearlyPLPercent = base != 0 ? c.yearlyPL / base : 0
      c.changeAmount = previous.map { c.total - $0.total } ?? 0
      c.changePercent = previous.map { $0.total != 0 ? (c.total - $0.total) / $0.total : 0 } ?? 0
      product *= 1 + c.twrrRaw
      yearProducts[year] = (yearProducts[year] ?? 1) * (1 + c.twrrRaw)
      previousYear = year
      previousTaxYear = taxYear
      points.append(c)
    }
    return points
  }
}
