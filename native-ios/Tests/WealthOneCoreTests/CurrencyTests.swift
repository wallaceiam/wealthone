import Foundation
import XCTest
@testable import WealthOneCore

final class CurrencyTests: XCTestCase {
  func testOldArchivesStillDecodeAsGBPWithoutRates() throws {
    let source=Data(#"{"accounts":[{"id":"a","name":"Savings","provider":"","isAsset":true,"accountType":0}],"records":[{"date":"2026-01-01","totals":{"a":100},"inflows":{},"outflows":{}}],"goal":{}}"#.utf8)
    let snapshot=try Archive.snapshot(from:source)
    XCTAssertEqual(snapshot.accounts[0].currency,"GBP")
    XCTAssertEqual(snapshot.reportingCurrency,"GBP")
    XCTAssertTrue(snapshot.records[0].exchangeRates.isEmpty)
  }
  func testSavedRatesConvertPortfolioButAccountHistoryRemainsNativeCurrency() {
    let accounts=[Account(id:"a",name:"GBP"),Account(id:"c",name:"CAD",currency:"CAD")]
    let records=[DayRecord(date:"2026-01-01",totals:["a":100,"c":200],exchangeRates:["CAD":0.5]),
      DayRecord(date:"2026-02-01",totals:["a":100,"c":220],inflows:["c":20],exchangeRates:["CAD":0.6])]
    let model=PortfolioReadModel(snapshot:Snapshot(accounts:accounts,records:records))
    XCTAssertEqual(model.points.map(\.total),[200,232])
    XCTAssertEqual(model.points[1].inflows,12)
    XCTAssertEqual(model.points[1].totalPL,20) // Includes the GBP valuation change caused by FX.
    XCTAssertEqual(model.accountHistories["c"]!.map(\.total),[200,220])
    XCTAssertEqual(model.accountAllocation["CAD"],132)
    let reportCAD=PortfolioReadModel(snapshot:Snapshot(accounts:accounts,records:records,goal:["reportingCurrency":.string("CAD")]))
    XCTAssertEqual(reportCAD.points[1].total,232 / 0.6,accuracy:1e-9)
  }
  func testMissingRateNeverGuessesParityAndExplicitRateStaysFrozen() throws {
    let accounts=[Account(id:"c",name:"CAD",currency:"CAD")]
    let missing=Snapshot(accounts:accounts,records:[DayRecord(date:"2026-01-01",totals:["c":200])])
    XCTAssertFalse(PortfolioReadModel(snapshot:missing).points[0].total.isFinite)
    let store=try EventStore()
    try store.replace(missing)
    let quote=ExchangeRateQuote(ratesToGBP:["CAD":0.5],date:"2026-10-29",source:"Manual")
    try store.saveExchangeRates(quote,refreshExisting:false)
    let before=store.events.count
    try store.saveExchangeRates(ExchangeRateQuote(ratesToGBP:["CAD":0.6],date:"2026-10-30",source:"Manual"),refreshExisting:false)
    XCTAssertEqual(store.events.count,before)
    XCTAssertEqual(store.projection.snapshot.records[0].exchangeRates["CAD"],0.5)
    try store.saveExchangeRates(ExchangeRateQuote(ratesToGBP:["CAD":0.6],date:"2026-10-30",source:"Manual"),refreshExisting:true)
    XCTAssertEqual(store.projection.snapshot.records[0].exchangeRates["CAD"],0.6)
    XCTAssertEqual(try EventStore(envelope:store.envelope).projection.snapshot,store.projection.snapshot)
    XCTAssertEqual(try Archive.events(from:Archive.export(events:store.events)),store.events)
  }
  func testRateOnlyUpdatesDoNotDependOnCurrencyCodeBeingAnAccountID() throws {
    let store=try EventStore()
    try store.replace(Snapshot(accounts:[Account(id:"c",name:"CAD",currency:"CAD")],records:[DayRecord(date:"2026-01-01",totals:["c":200])]))
    try store.saveExchangeRates(ExchangeRateQuote(ratesToGBP:["CAD":0.5],date:"2026-01-01",source:"Manual"),refreshExisting:false)
    XCTAssertEqual(PortfolioReadModel(snapshot:store.projection.snapshot).points[0].total,100)
    XCTAssertThrowsError(try store.saveExchangeRates(ExchangeRateQuote(ratesToGBP:["CAD":0],date:"2026-01-01",source:"Manual"),refreshExisting:true))
  }
  func testBulkRateSaveIsAtomicAndCommitsOnlyOnce() throws {
    var writes=0
    let store=try EventStore(commit:{ _ in writes += 1 })
    try store.replace(Snapshot(accounts:[Account(id:"c",name:"CAD",currency:"CAD")],records:[DayRecord(date:"2026-01-01",totals:["c":200]),DayRecord(date:"2026-02-01",totals:["c":220])]))
    let count=writes
    try store.saveExchangeRates(ExchangeRateQuote(ratesToGBP:["CAD":0.5],date:"2026-10-29",source:"Manual"),refreshExisting:false)
    XCTAssertEqual(writes,count+1)
    XCTAssertEqual(store.projection.snapshot.records.map{$0.exchangeRates["CAD"]},[0.5,0.5])
  }
  func testWatchQuickEntrySavesRateOnceAndDuplicateDeliveryDoesNotRefreshIt() throws {
    let store=try EventStore()
    try store.replace(Snapshot(accounts:[Account(id:"c",name:"CAD",currency:"CAD")]))
    let quote=ExchangeRateQuote(ratesToGBP:["CAD":0.5],date:"2026-10-29",source:"Manual")
    try store.applyQuickEntry(id:"watch-cad",accountID:"c",day:"2026-10-29",total:200,today:"2026-10-29",quote:quote)
    let count=store.events.count
    try store.applyQuickEntry(id:"watch-cad",accountID:"c",day:"2026-10-29",total:200,today:"2026-10-30",quote:ExchangeRateQuote(ratesToGBP:["CAD":0.6],date:"2026-10-30",source:"Manual"))
    XCTAssertEqual(store.events.count,count)
    XCTAssertEqual(store.projection.snapshot.records[0].exchangeRates["CAD"],0.5)
    XCTAssertEqual(PortfolioReadModel(snapshot:store.projection.snapshot).points[0].total,100)
  }
  func testFailedBulkQuoteCommitLeavesEveryRecordAndHistoryUntouched() throws {
    let initial=try EventStore()
    try initial.replace(Snapshot(accounts:[Account(id:"c",name:"CAD",currency:"CAD")],records:[DayRecord(date:"2026-01-01",totals:["c":100]),DayRecord(date:"2026-02-01",totals:["c":200])]))
    let failing=try EventStore(envelope:initial.envelope,commit:{ _ in throw CoreError.invalid("Disk full") })
    XCTAssertThrowsError(try failing.saveExchangeRates(ExchangeRateQuote(ratesToGBP:["CAD":0.5],date:"2026-10-29",source:"Manual"),refreshExisting:false))
    XCTAssertEqual(failing.envelope,initial.envelope)
    XCTAssertEqual(failing.projection.snapshot,initial.projection.snapshot)
  }
  func testReportingCurrencyUsesConvertedStatePensionAssumption() {
    let settings:[String:Value]=["birthDate":.string("1958-10-28"),"retirementAge":.decimal(68),"statePensionAmount":.decimal(17000),"earnings":.decimal(0),"lifeStyle":.decimal(0)]
    let result=GoalProjectionCalculator.calculate(settings:settings,currentNetWorth:0,asOf:PortfolioCalculator.date("2026-10-28"))
    XCTAssertEqual(result.incomeAverageEstimate.amount,17000)
  }
  func testQuoteSelectsNewestUsableDateRatherThanResponseOrder() throws {
    let data=Data(#"{"observations":[{"d":"2026-10-28","FXGBPCAD":{"v":"2.0"}},{"d":"2026-10-29","FXUSDCAD":{"v":"1.4"}},{"d":"2026-04-30","FXGBPCAD":{"v":"1.8"}}]}"#.utf8)
    let quote=try ExchangeRateQuote.bankOfCanada(data)
    XCTAssertEqual(quote.date,"2026-10-28")
    XCTAssertEqual(quote.ratesToGBP["CAD"],0.5)
  }
  func testDayDraftRejectsAnAccountCurrencyChangedWhileEditing() throws {
    let store=try EventStore()
    try store.replace(Snapshot(accounts:[Account(id:"a",name:"A")],records:[DayRecord(date:"2026-01-01",totals:["a":100])]))
    let context=store.editContext(for:.day("2026-01-01"))
    try store.append(.edit(.account("a"),generation:store.projection.generation(for:.account("a"))!,fields:["currency":.string("CAD")]))
    XCTAssertThrowsError(try store.submit(["totals:a":.decimal(101)],context:context))
  }
  func testGoalDraftRejectsMonetaryEditsAfterReportingCurrencyChanges() throws {
    let store=try EventStore()
    try store.replace(Snapshot(goal:["earnings":.decimal(50000)]))
    let draft=store.editContext(for:.goal)
    try store.submit(["reportingCurrency":.string("CAD"),"earnings":.decimal(100000)],context:store.editContext(for:.goal))
    XCTAssertThrowsError(try store.submit(["earnings":.decimal(55000)],context:draft))
    XCTAssertEqual(store.projection.snapshot.goal["earnings"],.decimal(100000))
    try store.submit(["investmentStyle":.decimal(4)],context:draft) // Independent assumptions still merge.
    XCTAssertEqual(store.projection.snapshot.goal["investmentStyle"],.decimal(4))
  }
  func testManualRateRejectsTrailingTextAndNonpositiveValues() {
    XCTAssertEqual(ExchangeRateQuote.manualRate(" 0.54231 "),Decimal(string:"0.54231"))
    XCTAssertNil(ExchangeRateQuote.manualRate("0.5CAD"))
    XCTAssertNil(ExchangeRateQuote.manualRate("0"))
    XCTAssertNil(ExchangeRateQuote.manualRate("-0.5"))
  }
  func testBankOfCanadaQuoteUsesCADCrossRatesAndPreservesSourceDate() throws {
    let data=Data(#"{"observations":[{"d":"2026-10-28","FXGBPCAD":{"v":"2.0"},"FXUSDCAD":{"v":"1.4"},"FXEURCAD":{"v":"1.6"}}]}"#.utf8)
    let quote=try ExchangeRateQuote.bankOfCanada(data)
    XCTAssertEqual(quote.ratesToGBP["GBP"],1)
    XCTAssertEqual(quote.ratesToGBP["CAD"],0.5)
    XCTAssertEqual(quote.ratesToGBP["USD"],0.7)
    XCTAssertEqual(quote.ratesToGBP["EUR"],0.8)
    XCTAssertEqual(quote.date,"2026-10-28")
  }
}
