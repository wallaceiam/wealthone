// Frozen pre-optimization calculation, used only for exact metric parity.
import Foundation
@testable import WealthOneCore

enum ReferencePortfolioCalculator {
  static func date(_ key: String) -> Date {
    if let number = Double(key), number.isFinite, abs(number / 1000) <= 62135596800 { return Date(timeIntervalSince1970: number / 1000) }
    if let date = ISO8601DateFormatter().date(from: key) { return date }
    let fractional = ISO8601DateFormatter()
    fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = fractional.date(from: key) { return date }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.date(from: String(key.prefix(10))) ?? .distantPast
  }
  static var dayCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    return calendar
  }
  static func dayKey(_ date: Date = Date(), calendar: Calendar = dayCalendar) -> String {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }
  static func record(on day: String, records: [DayRecord], calendar: Calendar = dayCalendar) -> DayRecord? {
    records.sorted { date($0.date) < date($1.date) }.first {
      dayKey(date($0.date), calendar: calendar) == day
    }
  }
  static func netWorth(accounts: [Account], records: [DayRecord]) -> [NetWorthPoint] {
    calculate(
      records.sorted { date($0.date) < date($1.date) }.map { day in
        func sum(_ values: [String: Decimal], asset: Bool? = nil) -> Double {
          accounts.filter { asset == nil || $0.isAsset == asset }.reduce(0) {
            $0 + NSDecimalNumber(decimal: values[$1.id] ?? 0).doubleValue
          }
        }
        let assets = sum(day.totals, asset: true)
        let liabilities = sum(day.totals, asset: false)
        let inflows = sum(day.inflows)
        let outflows = sum(day.outflows)
        return NetWorthPoint(
          day: day.date, date: date(day.date), assets: assets, liabilities: liabilities,
          total: assets - liabilities, inflows: inflows, outflows: outflows,
          netflows: inflows - outflows)
      })
  }
  static func accountHistory(accountID: String, records: [DayRecord]) -> [NetWorthPoint] {
    netWorth(accounts: [Account(id: accountID, name: "")], records: records)
  }
  private static func calculate(_ input: [NetWorthPoint]) -> [NetWorthPoint] {
    var points: [NetWorthPoint] = []
    let calendar = Calendar.current
    func year(_ p: NetWorthPoint) -> Int { calendar.component(.year, from: p.date) }
    // Preserve the legacy April 1 tax-year boundary, including its known discrepancy.
    func taxYear(_ p: NetWorthPoint) -> Int {
      year(p) + (calendar.component(.month, from: p.date) >= 4 ? 1 : 0)
    }
    for var c in input {
      let previous = points.last
      let first = points.first
      let beginning = points.first { year($0) == year(c) }
      let base = beginning?.total ?? 0
      c.twrrRaw =
        previous.map { $0.total != 0 ? (c.total - c.netflows - $0.total) / $0.total : 0 } ?? 0
      c.twrrPercent = points.reduce(1) { $0 * (1 + $1.twrrRaw) } * (1 + c.twrrRaw) - 1
      c.yearlyTwrrPercent =
        points.filter { year($0) == year(c) }.reduce(1) { 1 + $0 * $1.twrrRaw } * (1 + c.twrrRaw)
        - 1
      c.yearlyGrowth = c.total - base
      c.yearlyGrowthPercent =
        (beginning?.taxYearNetflows ?? 0) != 0 ? (c.total - base) / beginning!.taxYearNetflows : 0
      c.totalNetflows = (previous?.totalNetflows ?? 0) + c.netflows
      c.yearlyNetflows =
        (previous.map { year($0) == year(c) ? $0.yearlyNetflows : 0 } ?? 0) + c.netflows
      c.taxYearNetflows =
        (previous.map { taxYear($0) == taxYear(c) ? $0.taxYearNetflows : 0 } ?? 0) + c.netflows
      c.totalPL = first.map { c.total - c.totalNetflows - $0.total } ?? 0
      c.totalPLPercent = (first?.total ?? 0) != 0 ? c.totalPL / first!.total : 0
      let yearlyBase = base - (beginning?.yearlyNetflows ?? 0)
      c.yearlyPL = previous == nil ? 0 : c.total - c.yearlyNetflows - yearlyBase
      c.yearlyPLPercent = previous != nil && yearlyBase != 0 ? c.yearlyPL / yearlyBase : 0
      c.changeAmount = previous.map { c.total - $0.total } ?? 0
      c.changePercent = previous.map { $0.total != 0 ? (c.total - $0.total) / $0.total : 0 } ?? 0
      points.append(c)
    }
    return points
  }
}
