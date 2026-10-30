// Diagnostic audit, not a pass/fail unit test: MISMATCH lines reproduce current formula issues.
// Compile a temporary copy named main.swift alongside Sources/WealthOneCore/*.swift.
// Expected values use the conventions explained in docs/implementation/calculation-audit.md.
// Optional argument: a state archive path; only structural metadata is printed for that archive.
import Foundation
let asset = Account(id: "a", name: "Savings")
func record(_ date: String, _ total: Decimal, inflow: Decimal = 0, outflow: Decimal = 0) -> DayRecord {
  DayRecord(date: date, totals: ["a":total], inflows: ["a":inflow], outflows: ["a":outflow])
}
func points(_ records: [DayRecord]) -> [NetWorthPoint] {
  PortfolioCalculator.netWorth(accounts: [asset], records: records)
}
func compare(_ label: String, _ actual: Double, _ expected: Double) {
  let pass = abs(actual - expected) < 1e-9
  print("\(pass ? "PASS" : "MISMATCH") | \(label) | actual=\(actual) | expected=\(expected)")
}
compare("Net worth = assets less liabilities", PortfolioCalculator.netWorth(accounts: [asset, Account(id:"l",name:"Loan",isAsset:false,accountType:9)], records: [DayRecord(date:"2026-01-01",totals:["a":1000,"l":300])])[0].total,700)
let flat = points([record("2026-01-01",100),record("2026-02-01",110),record("2026-03-01",110),record("2026-04-01",121)])
compare("No-flow cumulative return",flat.last!.twrrPercent,0.21)
compare("No-flow year return (same year)",flat.last!.yearlyTwrrPercent,0.21)
compare("No-flow year growth percent",flat.last!.yearlyGrowthPercent,0.21)
compare("No-flow profit/loss",flat.last!.totalPL,21)
let initial = points([record("2026-01-01",100,inflow:100),record("2026-02-01",100)])
compare("Profit since first snapshot, deposit included in opening balance",initial.last!.totalPL,0)
let crossing = points([record("2025-12-31",100),record("2026-01-01",110),record("2026-02-01",121)])
compare("New-year first snapshot growth",crossing[1].yearlyGrowth,10)
compare("New-year first snapshot profit",crossing[1].yearlyPL,10)
compare("New-year following snapshot profit",crossing[2].yearlyPL,21)
compare("New-year following snapshot growth",crossing[2].yearlyGrowth,21)
let tax = points([record("2026-03-31",100,inflow:10),record("2026-04-01",110,inflow:10),record("2026-04-05",120,inflow:10),record("2026-04-06",130,inflow:10)])
compare("UK tax flows at April 1",tax[1].taxYearNetflows,20)
compare("UK tax flows at April 5",tax[2].taxYearNetflows,30)
compare("UK tax flows at April 6",tax[3].taxYearNetflows,10)
let endFlow=points([record("2026-01-01",100),record("2026-02-01",120,inflow:20)])
compare("End-of-period contribution without growth return",endFlow.last!.twrrPercent,0)
compare("End-of-period contribution without growth profit",endFlow.last!.totalPL,0)
let startFlow=points([record("2026-01-01",100),record("2026-02-01",220,inflow:100)])
compare("Beginning-of-period deposit plus 10% growth (timing assumption)",startFlow.last!.twrrPercent,0.1)
let asOf=PortfolioCalculator.date("2026-10-28")
let zeroHorizon=GoalProjectionCalculator.calculate(settings:["birthDate":.string("1986-10-28"),"retirementAge":.decimal(40),"earnings":.decimal(50000),"contributions":.decimal(200),"investmentStyle":.decimal(3)],currentNetWorth:100000,asOf:asOf)
compare("Retiring now: projected savings equal current capital, no future contributions",zeroHorizon.savingsAverageEstimate.amount,100000)
let settings:[String:Value]=["birthDate":.string("1986-10-28"),"retirementAge":.decimal(65),"earnings":.decimal(55000),"contributions":.decimal(0),"investmentStyle":.decimal(3),"lifeStyle":.decimal(40)]
let unit = GoalProjectionCalculator.calculate(settings: settings,currentNetWorth:1000,asOf:asOf)
// Use unrounded target implied by current percentage to avoid rounding the independent ratio.
let exactTarget=(0.4 * 55000 * pow(1.01,25)) / (36.00349639 / 1000)
let funded=GoalProjectionCalculator.calculate(settings:settings,currentNetWorth:exactTarget / unit.savingsAverageEstimate.amount * 1000,asOf:asOf)
compare("Savings progress when projected capital exactly meets target",funded.savingsAverageEstimate.percentage,100)
var calendar=Calendar(identifier:.gregorian);calendar.timeZone=TimeZone(secondsFromGMT:0)!
var ageExamples=0
for birth in ["1960-03-01","1978-12-26","1980-03-01","1986-10-28","2000-02-29"] {
 for now in ["2025-02-28","2026-02-28","2026-03-01","2026-10-27","2026-10-28","2026-12-25"] {
  let expected=calendar.dateComponents([.year],from:PortfolioCalculator.date(birth),to:PortfolioCalculator.date(now)).year!
  let actual=GoalProjectionCalculator.currentAge(birthDate:birth,asOf:PortfolioCalculator.date(now))
  if actual != expected && ageExamples < 3 { compare("Age born \(birth) as of \(now)",Double(actual),Double(expected));ageExamples += 1 }
 }
}
print("Scenario table dimensions: balance=\(GoalProjectionTables.balance_data.count), contributions=\(GoalProjectionTables.contribution_data.count), distribution=\(GoalProjectionTables.distribution_data.map(\.count))")
compare("Age on day before birthday",Double(GoalProjectionCalculator.currentAge(birthDate:"1971-10-28",asOf:PortfolioCalculator.date("2025-10-27"))),53)
let sameCapital=GoalProjectionCalculator.calculate(settings:["birthDate":.string("1986-10-28"),"retirementAge":.decimal(40),"earnings":.decimal(50000),"contributions":.decimal(0),"investmentStyle":.decimal(3)],currentNetWorth:100000,asOf:asOf)
compare("Retiring now without contributions still grows assets",sameCapital.savingsAverageEstimate.amount,100000)
let pensionSettings:[String:Value]=["birthDate":.string("1986-10-28"),"retirementAge":.decimal(68),"earnings":.decimal(55000),"pension":.decimal(15),"investmentStyle":.decimal(3),"lifeStyle":.decimal(40)]
let pensionUnit = GoalProjectionCalculator.calculate(settings:pensionSettings,currentNetWorth:1000,asOf:asOf)
let pensionTarget=(0.25 * 55000 * pow(1.01,28) - 8500) / (39.43296523 / 1000)
let pensionFunded=GoalProjectionCalculator.calculate(settings:pensionSettings,currentNetWorth:pensionTarget / pensionUnit.savingsAverageEstimate.amount * 1000,asOf:asOf)
let exactIncomeGoal = 0.4 * 55000 * pow(1.01,28)
compare("Pension-inclusive savings target reconciles to income target",pensionFunded.incomeAverageEstimate.amount,exactIncomeGoal)
if CommandLine.arguments.count > 1 {
 let source=try Archive.snapshot(from:Data(contentsOf:URL(fileURLWithPath:CommandLine.arguments[1])))
 let ordered=PortfolioReadModel(snapshot:source).orderedRecords
 print("PRIVATE DATA METADATA ONLY: accounts=\(source.accounts.count); records=\(ordered.count); records with missing account totals=\(ordered.filter { $0.totals.count < source.accounts.count }.count); initial nonzero flow fields=\((ordered.first?.inflows.values.filter{$0 != 0}.count ?? 0)+(ordered.first?.outflows.values.filter{$0 != 0}.count ?? 0)); liability accounts=\(source.accounts.filter{!$0.isAsset}.count)")
}
