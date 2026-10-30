import Foundation
import XCTest
@testable import WealthOneCore

final class GoalHistoryTests: XCTestCase {
  func testHistoricalComparisonStartsAtActualBaselineAndUsesCurrentAssumptions() {
    let account=Account(id:"a",name:"Savings")
    let points=PortfolioCalculator.netWorth(accounts:[account],records:[
      DayRecord(date:"2025-01-01",totals:["a":100000]),DayRecord(date:"2026-01-01",totals:["a":110000])])
    let result=GoalHistoryComparison.calculate(points:points,settings:["investmentStyle":.decimal(3),"contributions":.decimal(0)])
    XCTAssertEqual(result.compactMap(\.actual).count,2)
    XCTAssertEqual(result[0].average,100000)
    XCTAssertEqual(result[0].poor,100000)
    XCTAssertEqual(result[1].actual,110000)
    XCTAssertEqual(result[1].average,103489.5029,accuracy:1e-6)
    XCTAssertEqual(result[1].poor,93401.75974,accuracy:1e-6)
    let changed=GoalHistoryComparison.calculate(points:points,settings:["investmentStyle":.decimal(3),"contributions":.decimal(200)])
    XCTAssertEqual(changed[0].average,100000)
    XCTAssertEqual(changed[1].average,105973.2509696,accuracy:1e-6)
  }
  func testFractionalAccumulationInterpolatesFromZeroRatherThanAddingAWholeYear() {
    let estimate=GoalAccumulation.calculate(capital:100000,monthlyContribution:0,style:3,years:0.5)
    XCTAssertEqual(estimate!.average,101744.75145,accuracy:1e-6)
    XCTAssertEqual(estimate!.poor,96700.87987,accuracy:1e-6)
    XCTAssertNil(GoalAccumulation.calculate(capital:100000,monthlyContribution:0,style:3,years:81))
  }
}

extension GoalHistoryTests {
  func testComparisonContinuesToRetirementWithoutInventingActuals() {
    let points = PortfolioCalculator.netWorth(accounts: [Account(id: "a", name: "Savings")], records: [
      DayRecord(date: "2025-01-01", totals: ["a": 100000]), DayRecord(date: "2026-01-01", totals: ["a": 110000])])
    let settings: [String: Value] = ["birthDate": .string("1978-12-26"), "retirementAge": .decimal(65), "contributions": .decimal(200)]
    let result = GoalHistoryComparison.calculate(points: points, settings: settings)
    XCTAssertEqual(result.last?.id, "2043-12-26")
    XCTAssertEqual(result.compactMap(\.actual), [100000, 110000])
    XCTAssertNil(result.last?.actual)
    let years = 18.0 + PortfolioCalculator.date("2043-12-26").timeIntervalSince(PortfolioCalculator.date("2043-01-01")) / PortfolioCalculator.date("2044-01-01").timeIntervalSince(PortfolioCalculator.date("2043-01-01"))
    let expected = GoalAccumulation.calculate(capital: 100000, monthlyContribution: 200, style: 3, years: years)!
    XCTAssertEqual(result.last!.average, expected.average, accuracy: 0.001)
  }
  func testPastOrInvalidRetirementKeepsActualHistoryAndLeapBirthdayEndsOnAnniversary() {
    let points = PortfolioCalculator.netWorth(accounts: [Account(id: "a", name: "Savings")], records: [DayRecord(date: "2026-01-01", totals: ["a": 100])])
    for age in [20, 151] {
      let result = GoalHistoryComparison.calculate(points: points, settings: ["birthDate": .string("1980-02-29"), "retirementAge": .decimal(Decimal(age))])
      XCTAssertEqual(result.count, 1)
    }
    let result = GoalHistoryComparison.calculate(points: points, settings: ["birthDate": .string("1980-02-29"), "retirementAge": .decimal(65)])
    XCTAssertEqual(result.last?.id, "2045-02-28")
  }
}
