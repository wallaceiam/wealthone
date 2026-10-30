import XCTest

@testable import WealthOneCore

final class CalculationTests: XCTestCase {
  func testSparsePortfolioCarriesBalanceAndKeepsAprilFlowsInSameTaxYear() {
    let account = Account(id: "a", name: "Savings")
    let records = [
      DayRecord(date: "2026-03-31", totals: ["a": 100], inflows: ["a": 10]),
      DayRecord(date: "2026-04-01", totals: ["a": 130], inflows: ["a": 20]),
      DayRecord(date: "2026-04-02"),
    ]
    let points = PortfolioCalculator.netWorth(accounts: [account], records: records)
    XCTAssertEqual(points[1].totalPL, 10)
    XCTAssertEqual(points[1].twrrPercent, 0.1, accuracy: 0.000001)
    XCTAssertEqual(points[1].taxYearNetflows, 30)
    XCTAssertEqual(points[2].total, 130)
  }
  func testPortfolioCalendarYearAndSinceBaselineMetrics() {
    let records = [
      DayRecord(date: "2025-12-31", totals: ["a": 100], inflows: ["a": 10]),
      DayRecord(date: "2026-01-01", totals: ["a": 150], inflows: ["a": 20]),
      DayRecord(date: "2026-03-31", totals: ["a": 165]),
      DayRecord(date: "2026-04-01", totals: ["a": 200], inflows: ["a": 10]),
    ]
    let points = PortfolioCalculator.netWorth(
      accounts: [Account(id: "a", name: "Savings")], records: records)
    let final = points[3]
    XCTAssertEqual(final.twrrPercent, 0.646666666666667, accuracy: 1e-12)
    XCTAssertEqual(final.yearlyTwrrPercent, 0.646666666666667, accuracy: 1e-12)
    XCTAssertEqual(final.yearlyGrowthPercent, 1.0, accuracy: 1e-12)
    XCTAssertEqual(final.yearlyPLPercent, 0.7, accuracy: 1e-12)
    XCTAssertEqual(final.totalNetflows, 40)
    XCTAssertEqual(final.yearlyNetflows, 30)
    XCTAssertEqual(final.taxYearNetflows, 40)
    XCTAssertEqual(final.totalPL, 70)
    XCTAssertEqual(final.yearlyPL, 70)
    XCTAssertEqual(points[1].yearlyPL, 30) // Opening value is the prior year-end observation.
  }
  func testLiabilitiesDecimalsAndMissingValues() {
    let accounts = [
      Account(id: "a", name: "Asset"),
      Account(id: "l", name: "Loan", isAsset: false, accountType: 9),
    ]
    let records = [
      DayRecord(date: "2026-01-01", totals: ["a": Decimal(string: "100.25")!, "l": 30]),
      DayRecord(date: "2026-02-01", totals: ["l": 20]),
    ]
    let points = PortfolioCalculator.netWorth(accounts: accounts, records: records)
    XCTAssertEqual(points[0].total, 70.25)
    XCTAssertEqual(points[1].total, 80.25)
    XCTAssertEqual(
      PortfolioCalculator.accountHistory(accountID: "l", records: records)[0].total, 30)
  }
  func testGoalWholeYearTablesWithFundingPercentages() {
    let result = GoalProjectionCalculator.calculate(
      settings: [
        "birthDate": .string("1986-10-28"), "retirementAge": .decimal(65),
        "earnings": .decimal(55000), "contributions": .decimal(200), "investmentStyle": .decimal(3),
        "lifeStyle": .decimal(40),
      ], currentNetWorth: 100000, asOf: PortfolioCalculator.date("2026-10-28"))
    XCTAssertEqual(result.projectedIncomeGoal, 28200)
    XCTAssertEqual(result.projectedIncomePoor, 8500)
    XCTAssertEqual(result.projectedIncomeAverage, 13300)
    XCTAssertEqual(result.projectedSavingsGoal, 784000)
    XCTAssertEqual(result.projectedSavingsPoor, 236000)
    XCTAssertEqual(result.projectedSavingsAverage, 369000)
    XCTAssertEqual(result.projectedIncomePoorPercentage, 30)
    XCTAssertEqual(result.projectedIncomeAveragePercentage, 47)
    XCTAssertEqual(result.projectedSavingsPoorPercentage, 30)
    XCTAssertEqual(result.projectedSavingsAveragePercentage, 47)
  }
  func testGoalConsistentPensionTargetAndStateBenefit() {
    let result = GoalProjectionCalculator.calculate(
      settings: [
        "birthDate": .string("1976-10-28"), "retirementAge": .decimal(68),
        "earnings": .decimal(100000), "contributions": .decimal(500), "pension": .decimal(15),
        "investmentStyle": .decimal(5), "lifeStyle": .decimal(70),
      ], currentNetWorth: 250000, asOf: PortfolioCalculator.date("2026-10-28"))
    XCTAssertEqual(result.projectedIncomeGoal, 83700)
    XCTAssertEqual(result.projectedIncomePoor, 42100)
    XCTAssertEqual(result.projectedIncomeAverage, 57000)
    XCTAssertEqual(result.projectedSavingsGoal, 1_453_000)
    XCTAssertEqual(result.projectedSavingsPoor, 398000)
    XCTAssertEqual(result.projectedSavingsAverage, 774000)
    XCTAssertEqual(result.projectedIncomePoorPercentage, 50)
    XCTAssertEqual(result.projectedIncomeAveragePercentage, 68)
    XCTAssertEqual(result.projectedSavingsPoorPercentage, 27)
    XCTAssertEqual(result.projectedSavingsAveragePercentage, 53)
  }
}
