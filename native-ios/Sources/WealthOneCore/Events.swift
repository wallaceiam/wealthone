import Foundation

public enum Operation: Codable, Equatable, Sendable {
  case replace(Snapshot)
  case create(Entity, generation: String, fields: [String: Value])
  case edit(Entity, generation: String, fields: [String: Value])
  case remove(Entity, generation: String)
}
public struct Event: Codable, Equatable, Sendable {
  public let version: Int
  public let id: String
  public let actor: String
  public let counter: UInt64
  public let parents: [String]
  public let epoch: String
  public let operation: Operation
  public let recordedAt: Date
  public init(
    id: String = UUID().uuidString, actor: String, counter: UInt64, parents: [String],
    epoch: String, operation: Operation, recordedAt: Date = Date(timeIntervalSince1970: 0),
    version: Int = 1
  ) {
    self.id = id
    self.actor = actor
    self.counter = counter
    self.parents = parents
    self.epoch = epoch
    self.operation = operation
    self.recordedAt = recordedAt
    self.version = version
  }
}
func canonical(_ a: Event, _ b: Event) -> Bool {
  if a.counter != b.counter { return a.counter < b.counter }
  if a.actor != b.actor { return a.actor.utf8.lexicographicallyPrecedes(b.actor.utf8) }
  return a.id.utf8.lexicographicallyPrecedes(b.id.utf8)
}
func validateOperation(_ operation: Operation) throws {
  if case .create(.account, _, let fields) = operation {
    guard case .string(let name)? = fields["name"],
      !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else { throw CoreError.invalid("Account creation requires name") }
    try validateAccountClassification(fields)
  }
  switch operation {
  case .replace(let snapshot): try Archive.validate(snapshot)
  case .create(let entity, let generation, let fields),
    .edit(let entity, let generation, let fields):
    guard !generation.isEmpty else { throw CoreError.invalid("Empty generation") }
    try validateEntity(entity)
    for (key, value) in fields {
      guard !key.isEmpty else { throw CoreError.invalid("Empty field") }
      if case .decimal(let amount) = value, amount.isNaN {
        throw CoreError.invalid("Invalid decimal")
      }
      switch entity {
      case .account:
        if key.hasPrefix("closureRecord:"), case .string(let raw) = value,
          validLifecycleDate(String(key.dropFirst(14))), Archive.validHistoricalDate(raw) { continue }
        if key.hasPrefix("closed:"), case .bool = value,
          validLifecycleDate(String(key.dropFirst(7))) { continue }
        switch (key, value) {
        case ("name", .string(let name)):
          guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CoreError.invalid("Blank account name")
          }
        case ("currency", .string(let code)) where PortfolioCurrency.valid(code): break
        case ("provider", .string), ("isAsset", .bool): break
        case ("accountType", .decimal(let amount)): _ = try validatedAccountType(amount)
        default: throw CoreError.invalid("Invalid account field")
        }
      case .day:
        let parts = key.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2, !parts[1].isEmpty else { throw CoreError.invalid("Invalid day field") }
        switch (parts[0], value) {
        case ("totals", .decimal), ("inflows", .decimal), ("outflows", .decimal),
          ("totals", .null), ("inflows", .null), ("outflows", .null): break
        case ("fx", .decimal(let rate)) where PortfolioCurrency.valid(parts[1]) && rate > 0 && (parts[1] != "GBP" || rate == 1): break
        case ("fxDate", .string(let day)) where PortfolioCurrency.valid(parts[1]) && Archive.validHistoricalDate(day): break
        case ("fxSource", .string(let source)) where PortfolioCurrency.valid(parts[1]) && !source.isEmpty: break
        case ("fx", .null), ("fxDate", .null), ("fxSource", .null):
          guard PortfolioCurrency.valid(parts[1]) else { throw CoreError.invalid("Invalid currency") }
        default: throw CoreError.invalid("Invalid day value")
        }
      case .goal:
        if key == "reportingCurrency" {
          guard case .string(let code) = value, PortfolioCurrency.valid(code) else { throw CoreError.invalid("Invalid reporting currency") }
        }
      }
    }
  case .remove(let entity, let generation):
    guard !generation.isEmpty else { throw CoreError.invalid("Empty generation") }
    try validateEntity(entity)
  }
}
func validateEntity(_ entity: Entity) throws {
  switch entity {
  case .account(let id): guard !id.isEmpty else { throw CoreError.invalid("Empty entity") }
  case .day(let date):
    guard Archive.validHistoricalDate(date) else {
      throw CoreError.invalid("Invalid historical date")
    }
  case .goal: break
  }
}

func validatedAccountType(_ amount: Decimal) throws -> Int {
  guard !amount.isNaN, let type = (0...9).first(where: { Decimal($0) == amount }) else {
    throw CoreError.invalid("Invalid account type")
  }
  return type
}
func validateAccountClassification(_ fields: [String: Value]) throws {
  let asset = fields["isAsset"]?.bool ?? true
  let type = try validatedAccountType(fields["accountType"]?.decimal ?? (asset ? 0 : 7))
  guard asset == (type < 7) else { throw CoreError.invalid("Account kind/type mismatch") }
}
func validateValues(_ values: [String: Value]) throws {
  for (key, value) in values {
    guard !key.isEmpty else { throw CoreError.invalid("Empty field") }
    if case .decimal(let decimal) = value, decimal.isNaN {
      throw CoreError.invalid("Invalid decimal")
    }
  }
}

func validLifecycleDate(_ day: String) -> Bool {
  day.range(of: "^[0-9]{4}-[0-9]{2}-[0-9]{2}$", options: .regularExpression) != nil && Archive.validHistoricalDate(day)
}
