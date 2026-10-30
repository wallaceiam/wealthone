import CoreFoundation
import Foundation

public enum Archive {
  private struct StateArchive: Decodable { let snapshot: Snapshot }
  private struct Backup: Codable {
    let version: Int
    let events: [Event]
  }
  public static func export(events: [Event]) throws -> Data {
    _ = try Projection(events: events)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return try encoder.encode(Backup(version: 2, events: events))
  }
  public static func events(from data: Data) throws -> [Event] {
    let archive = try JSONDecoder().decode(Backup.self, from: data)
    guard archive.version == 2 else { throw CoreError.invalid("Unsupported archive version") }
    _ = try Projection(events: archive.events)
    return archive.events
  }
  public static func validate(_ snapshot: Snapshot) throws {
    let dates = HistoricalDateValidator()
    guard Set(snapshot.accounts.map(\.id)).count == snapshot.accounts.count,
      Set(snapshot.records.map(\.date)).count == snapshot.records.count,
      snapshot.accounts.allSatisfy({
        !$0.id.isEmpty && !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
          && $0.closureDates.keys.allSatisfy { validLifecycleDate($0) }
          && $0.closureRecords.allSatisfy { validLifecycleDate($0.key) && dates.isValid($0.value) }
          && PortfolioCurrency.valid($0.currency) && ($0.isAsset ? 0...6 : 7...9).contains($0.accountType)
      }), snapshot.records.allSatisfy({ dates.isValid($0.date) })
    else { throw CoreError.invalid("Invalid baseline identifiers") }
    guard PortfolioCurrency.valid(snapshot.reportingCurrency) else { throw CoreError.invalid("Invalid reporting currency") }
    try validateValues(snapshot.goal)
    let ids = Set(snapshot.accounts.map(\.id))
    for d in snapshot.records {
      guard d.exchangeRates.allSatisfy({ PortfolioCurrency.valid($0.key) && !$0.value.isNaN && $0.value > 0 && ($0.key != "GBP" || $0.value == 1) }),
        d.exchangeRateDates.allSatisfy({ PortfolioCurrency.valid($0.key) && dates.isValid($0.value) }),
        d.exchangeRateSources.allSatisfy({ PortfolioCurrency.valid($0.key) && !$0.value.isEmpty }) else {
        throw CoreError.invalid("Invalid saved rate metadata")
      }
      for map in [d.totals, d.inflows, d.outflows] {
        guard Set(map.keys).isSubset(of: ids), map.values.allSatisfy({ !$0.isNaN }) else {
          throw CoreError.invalid("Invalid baseline amounts")
        }
      }
    }
  }
  static func validHistoricalDate(_ string: String) -> Bool {
    HistoricalDateValidator().isValid(string)
  }
  private struct HistoricalDateValidator {
    let formatter: DateFormatter = {
      let value = DateFormatter()
      value.locale = Locale(identifier: "en_US_POSIX")
      value.timeZone = TimeZone(secondsFromGMT: 0)
      value.dateFormat = "yyyy-MM-dd"
      value.isLenient = false
      return value
    }()
    let iso = ISO8601DateFormatter()
    let fractional: ISO8601DateFormatter = {
      let value = ISO8601DateFormatter()
      value.formatOptions.insert(.withFractionalSeconds)
      return value
    }()
    func isValid(_ string: String) -> Bool {
      if string.range(of: "^-?[0-9]{11,16}$", options: .regularExpression) != nil { return true }
      if let date = formatter.date(from: string), formatter.string(from: date) == string { return true }
      return iso.date(from: string) != nil || fractional.date(from: string) != nil
    }
  }
  public static func snapshot(from data: Data) throws -> Snapshot {
    guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw CoreError.invalid("Expected object")
    }
    for key in ["version", "schemaVersion"] {
      if let raw = root[key] {
        guard let version = raw as? Int, version == 1 else {
          throw CoreError.invalid("Unsupported state version")
        }
      }
    }
    let body = (root["snapshot"] as? [String: Any]) ?? root
    // Decode native archives from their original bytes. Re-serializing NSNumber values
    // can turn an exact decimal such as 0.03 into 0.029999999999999999.
    let decoder = JSONDecoder()
    let native =
      root["snapshot"] != nil
      ? (try? decoder.decode(StateArchive.self, from: data))?.snapshot
      : (try? decoder.decode(Snapshot.self, from: data))
    if let native {
      try validate(native)
      return native
    }
    let categories = (body["categories"] as? [[String: Any]])?.filter {
      $0["id"] != nil && !($0["id"] is NSNull)
    }
    let rawAccounts = (body["accounts"] as? [[String: Any]]) ?? categories
    guard let rawAccounts, let rows = body["records"] as? [[String: Any]] else {
      throw CoreError.invalid("Missing accounts or records")
    }
    let accounts = try rawAccounts.enumerated().map { i, a -> Account in
      guard let name = a["name"] as? String,
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        let kind = a["isAsset"] as? NSNumber, CFGetTypeID(kind) == CFBooleanGetTypeID(),
        let isAsset = a["isAsset"] as? Bool
      else { throw CoreError.invalid("Invalid account") }
      let id: String
      if let string = a["id"] as? String, !string.isEmpty {
        id = string
      } else if categories != nil, let number = a["id"] as? NSNumber {
        id = "legacy-" + number.stringValue
      } else {
        throw CoreError.invalid("Missing account ID")
      }
      let type: Int
      if let supplied = a["accountType"] {
        let raw = (supplied as? [String: Any])?["id"] ?? supplied
        guard let number = raw as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(),
          let decimal = Decimal(string: number.stringValue)
        else { throw CoreError.invalid("Invalid account type") }
        type = try validatedAccountType(decimal)
      } else {
        type = isAsset ? 0 : 7
      }
      guard (isAsset ? 0...6 : 7...9).contains(type) else {
        throw CoreError.invalid("Invalid account type")
      }
      return Account(
        id: id, name: name, provider: a["provider"] as? String ?? "", isAsset: isAsset,
        accountType: type, currency: (a["currency"] as? String) ?? "GBP")
    }
    let accountIDs = Set(accounts.map(\.id))
    let offset = (rows.first?["totals"] as? [Any])?.first is NSNull ? 1 : 0
    func amount(_ x: Any) throws -> Decimal {
      if let n = x as? NSNumber, CFGetTypeID(n) == CFBooleanGetTypeID() {
        throw CoreError.invalid("Boolean amount")
      }
      let string = (x as? String) ?? (x as? NSNumber)?.stringValue
      guard let string,
        string.range(
          of: "^[+-]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?$",
          options: .regularExpression) != nil,
        let decimal = Decimal(string: string, locale: Locale(identifier: "en_US_POSIX")),
        !decimal.isNaN
      else { throw CoreError.invalid("Invalid decimal") }
      return decimal
    }
    func values(_ x: Any?) throws -> [String: Decimal] {
      guard let x else { return [:] }
      if let map = x as? [String: Any] { return try map.mapValues { try amount($0) } }
      guard let array = x as? [Any] else { throw CoreError.invalid("Invalid record values") }
      var result: [String: Decimal] = [:]
      var seen = Set<String>()
      for (i, value) in array.enumerated() {
        if value is NSNull { continue }
        if let item = value as? [String: Any] {
          guard let id = (item["accountID"] ?? item["id"]) as? String, let n = item["amount"],
            accountIDs.contains(id), seen.insert(id).inserted
          else { throw CoreError.invalid("Invalid amount entry") }
          // The old app persisted blank cells as {id, amount: null}, not zero.
          if n is NSNull { continue }
          result[id] = try amount(n)
        } else {
          guard categories != nil, i - offset >= 0, i - offset < accounts.count else {
            throw CoreError.invalid("Category offset")
          }
          let id = accounts[i - offset].id
          guard seen.insert(id).inserted else { throw CoreError.invalid("Duplicate amount entry") }
          result[id] = try amount(value)
        }
      }
      return result
    }
    let records = try rows.map { row -> DayRecord in
      guard let date = (row["date"] as? String) ?? (row["date"] as? NSNumber)?.stringValue else {
        throw CoreError.invalid("Missing date")
      }
      return try DayRecord(
        date: date, totals: values(row["totals"]), inflows: values(row["inflows"]),
        outflows: values(row["outflows"]))
    }
    var goal: [String: Value] = [:]
    if let supplied = body["goal"] {
      guard let rawGoal = supplied as? [String: Any] else {
        throw CoreError.invalid("Goal must be an object")
      }
      let input: [String: Any]
      if let wrapped = rawGoal["input"] {
        guard let object = wrapped as? [String: Any] else {
          throw CoreError.invalid("Goal input must be an object")
        }
        input = object
      } else {
        input = rawGoal
      }
      for (key, x) in input {
        if x is NSNull {
          goal[key] = .null
        } else if let n = x as? NSNumber, CFGetTypeID(n) == CFBooleanGetTypeID() {
          goal[key] = .bool(n.boolValue)
        } else if let string = x as? String {
          goal[key] = .string(string)
        } else if let number = x as? NSNumber {
          goal[key] = .decimal(try amount(number))
        } else {
          throw CoreError.invalid("Unsupported goal value")
        }
      }
    }
    let result = Snapshot(accounts: accounts, records: records, goal: goal)
    try validate(result)
    return result
  }
}
