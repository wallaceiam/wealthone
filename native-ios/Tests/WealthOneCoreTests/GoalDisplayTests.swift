import XCTest

@testable import WealthOneCore

final class GoalDisplayTests: XCTestCase {
  func testSmallPortfolioEstimatesAreAvailableBeforeLegacyRounding() {
    let result = GoalProjectionCalculator.calculate(
      settings: [:], currentNetWorth: 102,
      asOf: PortfolioCalculator.date("2026-10-28"))
    // Independent fixture from the original TypeScript accumulation tables.
    XCTAssertEqual(result.savingsPoorEstimate.amount, 122.394273618, accuracy: 1e-8)
    XCTAssertEqual(result.savingsAverageEstimate.amount, 189.118312914, accuracy: 1e-8)
    XCTAssertGreaterThan(result.savingsPoorEstimate.percentage, 0)
    XCTAssertEqual(result.savingsPoorEstimate.percentage, 0.01674550960073887, accuracy: 1e-12)
    XCTAssertEqual(result.projectedSavingsPoor, 0)  // Existing calculator contract retained.
    XCTAssertEqual(result.projectedSavingsAverage, 0)
  }
  func testZeroPortfolioWithoutContributionsIsActuallyZero() {
    let result = GoalProjectionCalculator.calculate(
      settings: [:], currentNetWorth: 0,
      asOf: PortfolioCalculator.date("2026-10-28"))
    XCTAssertEqual(result.savingsPoorEstimate.amount, 0)
    XCTAssertEqual(result.savingsAverageEstimate.amount, 0)
  }
  func testUnavailableEstimateDoesNotBecomeZero() {
    let result = GoalProjectionCalculator.calculate(
      settings: ["investmentStyle": .decimal(99)], currentNetWorth: 102)
    XCTAssertFalse(result.savingsPoorEstimate.amount.isFinite)
    XCTAssertFalse(result.incomeAverageEstimate.percentage.isFinite)
  }
}
