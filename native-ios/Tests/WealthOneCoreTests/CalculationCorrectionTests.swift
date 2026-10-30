import Foundation
import XCTest
@testable import WealthOneCore

final class CalculationCorrectionTests: XCTestCase {
  private let account = Account(id: "a", name: "Savings")
  private func record(_ day: String, _ total: Decimal, inflow: Decimal = 0, outflow: Decimal = 0) -> DayRecord {
    DayRecord(date: day, totals: ["a": total], inflows: ["a": inflow], outflows: ["a": outflow])
  }
  private func calculate(_ records: [DayRecord]) -> [NetWorthPoint] {
    PortfolioCalculator.netWorth(accounts: [account], records: records)
  }
  func testYearReturnGeometricallyLinksAcrossFlatInterval() {
    let points = calculate([record("2026-01-01",100),record("2026-02-01",110),record("2026-03-01",110),record("2026-04-01",121)])
    XCTAssertEqual(points.last!.yearlyTwrrPercent,0.21,accuracy:1e-12)
    XCTAssertEqual(points.last!.yearlyGrowthPercent,0.21,accuracy:1e-12)
    XCTAssertEqual(points.last!.twrrPercent,0.21,accuracy:1e-12)
  }
  func testYearOpeningIsConsistentAcrossFirstAndFollowingObservations() {
    let points = calculate([record("2025-12-31",100),record("2026-01-01",110),record("2026-02-01",121)])
    XCTAssertEqual(points[0].yearlyGrowth,0)
    XCTAssertEqual(points[1].yearlyGrowth,10)
    XCTAssertEqual(points[1].yearlyPL,10)
    XCTAssertEqual(points[2].yearlyGrowth,21)
    XCTAssertEqual(points[2].yearlyPL,21)
    XCTAssertEqual(points[2].yearlyGrowthPercent,0.21,accuracy:1e-12)
    XCTAssertEqual(points[2].yearlyPLPercent,0.21,accuracy:1e-12)
    XCTAssertEqual(points[2].yearlyTwrrPercent,0.21,accuracy:1e-12)
  }
  func testProfitExcludesFlowsAlreadyIncludedInOpeningSnapshot() {
    let points=calculate([record("2026-01-01",100,inflow:100),record("2026-02-01",100),record("2026-03-01",125,inflow:20)])
    XCTAssertEqual(points[1].totalPL,0)
    XCTAssertEqual(points[1].yearlyPL,0)
    XCTAssertEqual(points[2].totalPL,5)
    XCTAssertEqual(points[2].yearlyPL,5)
    XCTAssertEqual(points[2].totalNetflows,120) // All recorded flows remain inspectable.
    XCTAssertEqual(points[2].totalPLPercent,0.05,accuracy:1e-12)
  }
  func testYearProfitIncludesFirstIntervalFlowsOnce() {
    let points=calculate([record("2025-12-31",100),record("2026-01-01",130,inflow:20),record("2026-02-01",145,inflow:10,outflow:5)])
    XCTAssertEqual(points[1].yearlyPL,10)
    XCTAssertEqual(points[2].yearlyPL,20)
    XCTAssertEqual(points[2].yearlyNetflows,25)
    XCTAssertEqual(points[2].yearlyGrowth,45)
    XCTAssertEqual(points[2].yearlyGrowthPercent,0.45,accuracy:1e-12)
  }
  func testTaxYearResetsOnAprilSixthIncludingLeapYear() {
    for year in [2024,2026] {
      let points=calculate([record("\(year)-03-31",100,inflow:10),record("\(year)-04-01",110,inflow:10),record("\(year)-04-05",120,inflow:10),record("\(year)-04-06",130,inflow:10)])
      XCTAssertEqual(points.map(\.taxYearNetflows),[10,20,30,10])
    }
  }
  func testLaterCalendarYearStartsItsOwnReturnProduct() {
    let points=calculate([record("2025-12-30",100),record("2025-12-31",200),record("2026-01-01",220),record("2026-02-01",242)])
    XCTAssertEqual(points.last!.yearlyTwrrPercent,0.21,accuracy:1e-12)
    XCTAssertEqual(points.last!.twrrPercent,1.42,accuracy:1e-12)
  }
  func testMissingBalancesCarryForwardWhileExplicitZeroAndFlowsStayExplicit() {
    let accounts=[Account(id:"a",name:"A"),Account(id:"b",name:"B")]
    let records=[DayRecord(date:"2026-01-01",totals:["a":100,"b":200],inflows:["b":200]),
      DayRecord(date:"2026-02-01",totals:["a":110]),
      DayRecord(date:"2026-03-01",totals:["b":0])]
    let model=PortfolioReadModel(snapshot:Snapshot(accounts:accounts,records:records))
    XCTAssertEqual(model.points.map(\.total),[300,310,110])
    XCTAssertEqual(model.points.map(\.inflows),[200,0,0])
    XCTAssertEqual(model.accountHistories["b"]!.map(\.total),[200,200,0])
    XCTAssertEqual(model.latestRecord?.totals,["a":110,"b":0])
    XCTAssertEqual(model.snapshot.records,records) // Derived filling never writes invented observations.
    XCTAssertNil(model.snapshot.records[1].totals["b"])
  }
  func testCarryForwardNeverInventsBalancesBeforeFirstObservation() {
    let points=calculate([DayRecord(date:"2026-01-01"),record("2026-02-01",100),DayRecord(date:"2026-03-01")])
    XCTAssertEqual(points.map(\.total),[0,100,100])
  }
  func testBirthdaysUseCalendarYearsRatherThanEpochDuration() {
    XCTAssertEqual(GoalProjectionCalculator.currentAge(birthDate:"1971-10-28",asOf:PortfolioCalculator.date("2025-10-27")),53)
    XCTAssertEqual(GoalProjectionCalculator.currentAge(birthDate:"1971-10-28",asOf:PortfolioCalculator.date("2025-10-28")),54)
    XCTAssertEqual(GoalProjectionCalculator.currentAge(birthDate:"2000-02-29",asOf:PortfolioCalculator.date("2026-02-28")),26)
  }
  private func goalSettings(retirement: Decimal = 40, pension: Decimal = 0, lifestyle: Decimal = 40) -> [String:Value] {
    ["birthDate":.string("1986-10-28"),"retirementAge":.decimal(retirement),"earnings":.decimal(50000),"contributions":.decimal(200),"investmentStyle":.decimal(3),"pension":.decimal(pension),"lifeStyle":.decimal(lifestyle)]
  }
  private let asOf = PortfolioCalculator.date("2026-10-28")
  func testRetiringNowDoesNotGrowCapitalOrAddFutureContributions() {
    let result=GoalProjectionCalculator.calculate(settings:goalSettings(),currentNetWorth:100000,asOf:asOf)
    XCTAssertEqual(result.savingsAverageEstimate.amount,100000)
    XCTAssertEqual(result.savingsPoorEstimate.amount,100000)
  }
  func testPastAndUnsupportedHorizonsAreUnavailableRatherThanClamped() {
    for retirement: Decimal in [39,16,96,121] {
      let result=GoalProjectionCalculator.calculate(settings:goalSettings(retirement:retirement),currentNetWorth:100000,asOf:asOf)
      XCTAssertFalse(result.savingsAverageEstimate.amount.isFinite)
    }
    var invalidBirth=goalSettings(retirement:65)
    invalidBirth["birthDate"] = .string("not-a-date")
    XCTAssertFalse(GoalProjectionCalculator.calculate(settings:invalidBirth,currentNetWorth:100000,asOf:asOf).savingsAverageEstimate.amount.isFinite)
  }
  func testFullyFundedGoalIsOneHundredPercentAndPensionEquationReconciles() {
    // At zero accumulation horizon, solve the target with literal 56-year drawdown factor.
    // 40% of 50k less 15% pension = 12,500 income from capital; factor is 21.77149806 / 1000.
    let capital=12500 / (21.77149806 / 1000)
    let result=GoalProjectionCalculator.calculate(settings:goalSettings(pension:15),currentNetWorth:capital,asOf:asOf)
    XCTAssertEqual(result.savingsAverageEstimate.percentage,100,accuracy:1e-9)
    XCTAssertEqual(result.incomeAverageEstimate.amount,20000,accuracy:1e-8)
    XCTAssertEqual(result.incomeAverageEstimate.percentage,100,accuracy:1e-9)
  }
  func testZeroIncomeTargetHasFiniteFullyFundedProgress() {
    var settings=goalSettings(lifestyle:0)
    settings["earnings"] = .decimal(0)
    let result=GoalProjectionCalculator.calculate(settings:settings,currentNetWorth:0,asOf:asOf)
    XCTAssertEqual(result.savingsAverageEstimate.percentage,100)
    XCTAssertEqual(result.incomeAverageEstimate.percentage,100)
  }
}
