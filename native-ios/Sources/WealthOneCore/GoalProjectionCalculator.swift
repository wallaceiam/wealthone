import Foundation

/// Full precision scenario amounts and percentages funded; rounded fields are presentation values.
public struct GoalScenarioEstimate: Sendable {
  public let amount: Double
  public let percentage: Double
}
public struct GoalProjection: Sendable {
  public let savingsPoorEstimate, savingsAverageEstimate: GoalScenarioEstimate
  public let incomePoorEstimate, incomeAverageEstimate: GoalScenarioEstimate
  public let projectedIncomeGoal, projectedIncomePoor, projectedIncomePoorPercentage: Double
  public let projectedIncomeAverage, projectedIncomeAveragePercentage: Double
  public let projectedSavingsGoal, projectedSavingsPoor, projectedSavingsPoorPercentage: Double
  public let projectedSavingsAverage, projectedSavingsAveragePercentage: Double
}
public enum GoalProjectionCalculator {
  private static var unavailable: GoalProjection {
    GoalProjection(
      savingsPoorEstimate: .init(amount: .nan, percentage: .nan),
      savingsAverageEstimate: .init(amount: .nan, percentage: .nan),
      incomePoorEstimate: .init(amount: .nan, percentage: .nan),
      incomeAverageEstimate: .init(amount: .nan, percentage: .nan),
      projectedIncomeGoal: .nan, projectedIncomePoor: .nan,
      projectedIncomePoorPercentage: .nan, projectedIncomeAverage: .nan,
      projectedIncomeAveragePercentage: .nan, projectedSavingsGoal: .nan,
      projectedSavingsPoor: .nan, projectedSavingsPoorPercentage: .nan,
      projectedSavingsAverage: .nan, projectedSavingsAveragePercentage: .nan)
  }
  public static func currentAge(birthDate: String, asOf: Date = Date()) -> Int {
    birthdayAge(birthDate: birthDate, asOf: asOf) ?? 0
  }
  private static func birthdayAge(birthDate: String, asOf: Date) -> Int? {
    guard Archive.validHistoricalDate(birthDate), asOf.timeIntervalSince1970.isFinite else { return nil }
    let calendar = PortfolioCalculator.dayCalendar
    let birth = calendar.startOfDay(for: PortfolioCalculator.date(birthDate))
    let today = calendar.startOfDay(for: asOf)
    let years = calendar.component(.year, from: today) - calendar.component(.year, from: birth)
    guard birth <= today, (0...150).contains(years),
      let anniversary = calendar.date(byAdding: .year, value: years, to: birth) else { return nil }
    // Calendar addition treats February 28 as the anniversary in a non-leap year.
    return today < anniversary ? years - 1 : years
  }
  public static func calculate(
    settings: [String: Value], currentNetWorth: Double, asOf: Date = Date()
  ) -> GoalProjection {
    func number(_ key: String, _ fallback: Double) -> Double {
      guard case .decimal(let d) = settings[key] else { return fallback }
      return NSDecimalNumber(decimal: d).doubleValue
    }
    let birth: String
    switch settings["birthDate"] {
    case .string(let value): birth = value
    case .decimal(let value): birth = NSDecimalNumber(decimal: value).stringValue
    default: birth = "1978-12-26"
    }
    let ranges: [String: ClosedRange<Double>] = [
      "retirementAge": 0...150, "investmentStyle": 0...6, "lifeStyle": 0...100,
      "statePensionAmount": 0...1e12, "earnings": 0...1e12, "contributions": 0...1e12, "pension": 0...100,
    ]
    for (key, range) in ranges where settings[key] != nil {
      let value = number(key, 0)
      guard value.isFinite, range.contains(value) else { return unavailable }
    }
    guard let age = birthdayAge(birthDate: birth, asOf: asOf), currentNetWorth.isFinite else { return unavailable }
    let retirement = number("retirementAge", 65)
    let years = retirement - Double(age)
    let retireYears = 96 - retirement
    let maxYears = GoalProjectionTables.balance_data.count
    guard years >= 0, years <= Double(maxYears), retireYears >= 1,
      retireYears <= Double(GoalProjectionTables.distribution_data[0].count) else { return unavailable }
    let income = number("earnings", 55000) * pow(1.01, years)
    let lifestyle = number("lifeStyle", 40)
    let pension = number("pension", 0)
    let goal = lifestyle / 100 * income
    let state = retirement < 68 ? 0.0 : number("statePensionAmount", 8500)
    let style = min(6, max(0, Int(number("investmentStyle", 3)))) * 2
    let distribution = GoalAccumulation.interpolate(retireYears, zero: 0) { GoalProjectionTables.distribution_data[0][$0] }
    let pensionIncome = pension / 100 * income
    let savingsGoal = 1000 * max(0, (goal - pensionIncome - state) / distribution)
    guard let accumulation = GoalAccumulation.calculate(capital: currentNetWorth,
      monthlyContribution: number("contributions", 0), style: style / 2, years: years) else { return unavailable }
    let average = accumulation.average
    let poor = accumulation.poor
    let averageIncome = distribution * average / 1000 + pensionIncome + state
    let poorIncome = distribution * poor / 1000 + pensionIncome + state
    func funded(_ amount: Double, target: Double) -> Double {
      target > 0 ? amount / target * 100 : 100
    }
    func round(_ value: Double, _ unit: Double = 1) -> Double { floor(value / unit + 0.5) * unit }
    return GoalProjection(
      savingsPoorEstimate: .init(
        amount: poor, percentage: funded(poor, target: savingsGoal)),
      savingsAverageEstimate: .init(
        amount: average, percentage: funded(average, target: savingsGoal)),
      incomePoorEstimate: .init(amount: poorIncome, percentage: funded(poorIncome, target: goal)),
      incomeAverageEstimate: .init(
        amount: averageIncome, percentage: funded(averageIncome, target: goal)),
      projectedIncomeGoal: round(goal, 100), projectedIncomePoor: round(poorIncome, 100),
      projectedIncomePoorPercentage: round(funded(poorIncome, target: goal)),
      projectedIncomeAverage: round(averageIncome, 100),
      projectedIncomeAveragePercentage: round(funded(averageIncome, target: goal)),
      projectedSavingsGoal: round(savingsGoal, 1000), projectedSavingsPoor: round(poor, 1000),
      projectedSavingsPoorPercentage: round(funded(poor, target: savingsGoal)),
      projectedSavingsAverage: round(average, 1000),
      projectedSavingsAveragePercentage: round(funded(average, target: savingsGoal)))
  }
}
