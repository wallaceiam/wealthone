import Foundation

public struct GoalAccumulation: Sendable {
  public let average, poor: Double
  public static func calculate(capital: Double, monthlyContribution: Double, style: Int, years: Double) -> GoalAccumulation? {
    guard capital.isFinite, monthlyContribution.isFinite, monthlyContribution >= 0,
      (0...6).contains(style), years.isFinite, years >= 0,
      years <= Double(GoalProjectionTables.balance_data.count) else { return nil }
    func value(_ offset: Int) -> Double {
      let column = style * 2 + offset
      let balance = interpolate(years, zero: 1000) { GoalProjectionTables.balance_data[$0][column] }
      let contributions = interpolate(years, zero: 0) { GoalProjectionTables.contribution_data[$0][column] }
      return balance * capital / 1000 + contributions * monthlyContribution * 12
    }
    return GoalAccumulation(average: value(0), poor: value(1))
  }
  static func interpolate(_ horizon: Double, zero: Double, value: (Int) -> Double) -> Double {
    let whole = Int(horizon.rounded(.down))
    let fraction = horizon - Double(whole)
    let lower = whole == 0 ? zero : value(whole - 1)
    return fraction > 0 ? lower + (value(whole) - lower) * fraction : lower
  }
}

public struct GoalHistoryPoint: Identifiable, Sendable {
  public let id: String
  public let date: Date
  public let actual: Double?
  public let average, poor: Double
}
public enum GoalHistoryComparison {
  /// A back-calculated illustration using today's assumptions, not a saved historic forecast.
  public static func calculate(points: [NetWorthPoint], settings: [String: Value], calendar: Calendar = PortfolioCalculator.dayCalendar) -> [GoalHistoryPoint] {
    guard let first = points.first, first.total.isFinite else { return [] }
    let styleValue = NSDecimalNumber(decimal: settings["investmentStyle"]?.decimal ?? 3).doubleValue
    let contribution = NSDecimalNumber(decimal: settings["contributions"]?.decimal ?? 0).doubleValue
    guard styleValue.isFinite, (0...6).contains(styleValue) else { return [] }
    func estimate(on date: Date) -> GoalAccumulation? {
      guard date >= first.date else { return nil }
      let whole = calendar.dateComponents([.year], from: first.date, to: date).year ?? 0
      guard let anniversary = calendar.date(byAdding: .year, value: whole, to: first.date),
        let next = calendar.date(byAdding: .year, value: whole + 1, to: first.date) else { return nil }
      let years = Double(whole) + date.timeIntervalSince(anniversary) / next.timeIntervalSince(anniversary)
      return GoalAccumulation.calculate(capital: first.total, monthlyContribution: contribution, style: Int(styleValue), years: years)
    }
    var result = points.compactMap { point -> GoalHistoryPoint? in
      guard let value = estimate(on: point.date) else { return nil }
      return GoalHistoryPoint(id: point.day, date: point.date, actual: point.total.isFinite ? point.total : nil, average: value.average, poor: value.poor)
    }
    guard let last = points.last, let retirement = retirementDate(settings: settings, calendar: calendar),
      retirement > last.date, estimate(on: retirement) != nil else { return result }
    // Annual samples keep long histories inexpensive; include the exact retirement anniversary.
    var year = 1
    while let date = calendar.date(byAdding: .year, value: year, to: last.date), date < retirement {
      if let value = estimate(on: date) {
        result.append(GoalHistoryPoint(id: PortfolioCalculator.dayKey(date, calendar: calendar), date: date, actual: nil, average: value.average, poor: value.poor))
      }
      year += 1
    }
    let value = estimate(on: retirement)!
    result.append(GoalHistoryPoint(id: PortfolioCalculator.dayKey(retirement, calendar: calendar), date: retirement, actual: nil, average: value.average, poor: value.poor))
    return result
  }
  public static func retirementDate(settings: [String: Value], calendar: Calendar = PortfolioCalculator.dayCalendar) -> Date? {
    let birth = settings["birthDate"]?.string ?? "1978-12-26"
    let age = NSDecimalNumber(decimal: settings["retirementAge"]?.decimal ?? 65).doubleValue
    guard Archive.validHistoricalDate(birth), age.isFinite, (0...150).contains(age) else { return nil }
    let date = PortfolioCalculator.date(birth)
    let whole = Int(age.rounded(.down))
    guard let anniversary = calendar.date(byAdding: .year, value: whole, to: date),
      let next = calendar.date(byAdding: .year, value: whole + 1, to: date) else { return nil }
    return anniversary.addingTimeInterval((age - Double(whole)) * next.timeIntervalSince(anniversary))
  }
}
