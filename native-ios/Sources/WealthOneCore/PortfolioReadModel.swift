import Foundation

/// Immutable derived values shared by every screen for a single portfolio/calendar revision.
public struct PortfolioReadModel: Sendable {
  public struct HistorySection: Identifiable, Sendable {
    public var id: Int { year }
    public let year: Int
    public let points: [NetWorthPoint]
  }
  public let snapshot: Snapshot
  public let points: [NetWorthPoint]
  public let orderedRecords: [DayRecord]
  public let convertedBalances: [String: Double]
  public let accountAllocation: [String: Double]
  public let typeAllocation: [Int: Double]
  public let balanceDates: [String: Date]
  public let latestRecord: DayRecord?
  public let accountHistories: [String: [NetWorthPoint]]
  public let goalHistory: [GoalHistoryPoint]
  public let historySections: [HistorySection]
  public init(snapshot: Snapshot = Snapshot(), calendar: Calendar = PortfolioCalculator.dayCalendar) {
    self.snapshot = snapshot
    let dated = PortfolioCalculator.dated(snapshot.records)
    orderedRecords = dated.map(\.record)
    let valued = PortfolioCalculator.valued(dated, accounts: snapshot.accounts)
    latestRecord = valued.last?.record
    var dates: [String: Date] = [:]
    for item in dated {
      for id in item.record.totals.keys { dates[id] = item.date }
    }
    balanceDates = dates
    var converted: [String: Double] = [:]
    var byAccount: [String: Double] = [:], byType: [Int: Double] = [:]
    for account in snapshot.accounts {
      let amount = valued.last?.record.totals[account.id] ?? 0
      let rate = valued.last?.record.conversion(from: account.currency, to: snapshot.reportingCurrency)
      let value = amount == 0 ? 0 : rate.map { NSDecimalNumber(decimal: amount * $0).doubleValue } ?? .nan
      converted[account.id] = value
      guard account.isAsset, !account.isClosed() else { continue }
      byAccount[account.name, default: 0] += value
      byType[account.accountType, default: 0] += value
    }
    convertedBalances = converted
    accountAllocation = byAccount
    typeAllocation = byType
    points = PortfolioCalculator.netWorth(accounts: snapshot.accounts, datedRecords: valued, calendar: calendar, reportingCurrency: snapshot.reportingCurrency)
    accountHistories = Dictionary(uniqueKeysWithValues: snapshot.accounts.map { account in
      // The existing account detail treats liability balances as positive raw amounts.
      (account.id, PortfolioCalculator.netWorth(accounts: [Account(id: account.id, name: "")], datedRecords: valued, calendar: calendar))
    })
    goalHistory = GoalHistoryComparison.calculate(points: points, settings: snapshot.goal, calendar: calendar)
    let grouped = Dictionary(grouping: points.reversed(), by: { calendar.component(.year, from: $0.date) })
    historySections = grouped.keys.sorted(by: >).map { HistorySection(year: $0, points: grouped[$0]!) }
  }
}

public struct PortfolioReadModelCache: Sendable {
  public private(set) var model = PortfolioReadModel()
  public private(set) var revision = 0
  private var calendar: Calendar?
  public init() {}
  @discardableResult public mutating func update(_ snapshot: Snapshot, calendar: Calendar = PortfolioCalculator.dayCalendar) -> Bool {
    guard self.calendar != calendar || model.snapshot != snapshot else { return false }
    model = PortfolioReadModel(snapshot: snapshot, calendar: calendar)
    self.calendar = calendar
    revision += 1
    return true
  }
}
