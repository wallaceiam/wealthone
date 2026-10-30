import Foundation

public enum Value: Codable, Equatable, Sendable {
  case string(String)
  case decimal(Decimal)
  case bool(Bool)
  case null
}
public struct Account: Codable, Equatable, Sendable {
  public var id: String
  public var name: String
  public var provider: String
  public var isAsset: Bool
  public var currency: String
  /// Dated close/reopen decisions; true means closed from that day onward.
  public var closureDates: [String: Bool]
  /// Exact historical day identifiers of closing settlements (including legacy timestamps).
  public var closureRecords: [String: String]
  public func isClosed(on day: String = PortfolioCalculator.dayKey()) -> Bool {
    closureDates.keys.filter { $0 <= day }.max().flatMap { closureDates[$0] } ?? false
  }
  public var accountType: Int
  public init(
    id: String, name: String, provider: String = "", isAsset: Bool = true, accountType: Int = 0, currency: String = "GBP", closureDates: [String: Bool] = [:], closureRecords: [String: String] = [:]
  ) {
    self.id = id
    self.name = name
    self.provider = provider
    self.isAsset = isAsset
    self.accountType = accountType
    self.currency = currency
    self.closureDates = closureDates
    self.closureRecords = closureRecords
  }
  private enum CodingKeys: String, CodingKey { case id, name, provider, isAsset, accountType, currency, closureDates, closureRecords }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(String.self, forKey: .id); name = try c.decode(String.self, forKey: .name)
    provider = try c.decode(String.self, forKey: .provider); isAsset = try c.decode(Bool.self, forKey: .isAsset)
    accountType = try c.decode(Int.self, forKey: .accountType)
    currency = try c.decodeIfPresent(String.self, forKey: .currency) ?? "GBP"
    closureDates = try c.decodeIfPresent([String: Bool].self, forKey: .closureDates) ?? [:]
    closureRecords = try c.decodeIfPresent([String: String].self, forKey: .closureRecords) ?? [:]
  }

}
public struct DayRecord: Codable, Equatable, Sendable {
  public var date: String
  public var totals: [String: Decimal]
  public var inflows: [String: Decimal]
  public var outflows: [String: Decimal]
  public var exchangeRates: [String: Decimal]
  public var exchangeRateDates: [String: String]
  public var exchangeRateSources: [String: String]
  public init(
    date: String, totals: [String: Decimal] = [:], inflows: [String: Decimal] = [:],
    outflows: [String: Decimal] = [:], exchangeRates: [String: Decimal] = [:],
    exchangeRateDates: [String: String] = [:], exchangeRateSources: [String: String] = [:]
  ) {
    self.date = date
    self.totals = totals
    self.inflows = inflows
    self.outflows = outflows
    self.exchangeRates = exchangeRates; self.exchangeRateDates = exchangeRateDates
    self.exchangeRateSources = exchangeRateSources
  }
  private enum CodingKeys: String, CodingKey { case date, totals, inflows, outflows, exchangeRates, exchangeRateDates, exchangeRateSources }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    date = try c.decode(String.self, forKey: .date)
    totals = try c.decode([String: Decimal].self, forKey: .totals)
    inflows = try c.decode([String: Decimal].self, forKey: .inflows)
    outflows = try c.decode([String: Decimal].self, forKey: .outflows)
    exchangeRates = try c.decodeIfPresent([String: Decimal].self, forKey: .exchangeRates) ?? [:]
    exchangeRateDates = try c.decodeIfPresent([String: String].self, forKey: .exchangeRateDates) ?? [:]
    exchangeRateSources = try c.decodeIfPresent([String: String].self, forKey: .exchangeRateSources) ?? [:]
  }

}
public struct Snapshot: Codable, Equatable, Sendable {
  public var reportingCurrency: String { goal["reportingCurrency"]?.string ?? "GBP" }
  public var accounts: [Account]
  public func openAccounts(on day: String = PortfolioCalculator.dayKey()) -> [Account] {
    accounts.filter { !$0.isClosed(on: day) }
  }
  public var records: [DayRecord]
  public var goal: [String: Value]
  public init(accounts: [Account] = [], records: [DayRecord] = [], goal: [String: Value] = [:]) {
    self.accounts = accounts
    self.records = records
    self.goal = goal
  }
}
public enum Entity: Codable, Hashable, Sendable {
  case account(String)
  case day(String)
  case goal
}
public struct FieldKey: Codable, Hashable, Sendable {
  public let entity: Entity
  public let generation: String
  public let field: String
  public init(entity: Entity, generation: String, field: String) {
    self.entity = entity
    self.generation = generation
    self.field = field
  }
}
public enum CoreError: LocalizedError {
  case invalid(String)
  public var errorDescription: String? {
    switch self { case .invalid(let message): return message }
  }
}
extension Value {
  var string: String? {
    if case .string(let x) = self { return x }
    return nil
  }
  var decimal: Decimal? {
    if case .decimal(let x) = self { return x }
    return nil
  }
  var bool: Bool? {
    if case .bool(let x) = self { return x }
    return nil
  }
}
