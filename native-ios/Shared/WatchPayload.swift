import Foundation

struct WatchSnapshot: Codable {
  struct AccountChoice: Codable, Identifiable {
    let id: String
    let name: String
    var currency: String? = nil
  }
  struct Point: Codable, Identifiable {
    let date: String
    let total: Double
    var id: String { date }
  }
  let total: Double
  let change: Double
  let history: [Point]
  let accounts: [AccountChoice]
  let updatedAt: Date
  var currency: String? = nil
  var valuationUnavailable: Bool? = nil
  static let storageGroup = "group.ca.mymojo.wealthone.native.watch"
}

struct WatchEntryCommand: Codable {
  let id: String
  let accountID: String
  let day: String
  let total: Decimal
  var currency: String? = nil
}

struct WatchAcknowledgment: Codable {
  let id: String
  let saved: Bool
  let message: String
}

func localDayKey(_ date: Date = Date()) -> String {
  let formatter = DateFormatter()
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.calendar = Calendar(identifier: .gregorian)
  formatter.dateFormat = "yyyy-MM-dd"
  return formatter.string(from: date)
}

/// User-entered values follow legacy parseInt truncation; archive decimals stay untouched.
public enum EntryAmount {
  public static func parse(_ text: String) -> Decimal? {
    let trimmed = text.trimmingCharacters(in: .whitespaces)
    guard trimmed.range(of: #"^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)$"#, options: .regularExpression) != nil,
      var value = Decimal(string: trimmed, locale: Locale(identifier: "en_GB")), !value.isNaN else { return nil }
    var truncated = Decimal()
    NSDecimalRound(&truncated, &value, 0, value < 0 ? .up : .down)
    return truncated
  }
}
