import Foundation

public enum PortfolioCurrency {
  public static let codes = ["GBP", "CAD", "USD", "EUR", "AUD", "NZD", "CHF", "JPY"]
  public static func valid(_ code: String) -> Bool { codes.contains(code) }
}
public struct ExchangeRateQuote: Codable, Equatable, Sendable {
  /// GBP per one unit of currency. GBP is always exactly1.
  public let ratesToGBP: [String: Decimal]
  public let date: String
  public let source: String
  public init(ratesToGBP: [String: Decimal], date: String, source: String) {
    self.ratesToGBP = ratesToGBP; self.date = date; self.source = source
  }
  public static func manualRate(_ text: String) -> Decimal? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.range(of: #"^\+?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)$"#, options: .regularExpression) != nil,
      let rate = Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX")), !rate.isNaN, rate > 0 else { return nil }
    return rate
  }
  public func validate() throws {
    guard Archive.validHistoricalDate(date), !source.isEmpty,
      ratesToGBP.allSatisfy({ PortfolioCurrency.valid($0.key) && !$0.value.isNaN && $0.value > 0 }),
      ratesToGBP["GBP"] == nil || ratesToGBP["GBP"] == 1 else { throw CoreError.invalid("Invalid exchange rate") }
  }
  public static func bankOfCanada(_ data: Data) throws -> ExchangeRateQuote {
    struct Response: Decodable { let observations: [[String: Cell]]
      enum Cell: Decodable {
        case day(String), rate(String)
        init(from decoder: Decoder) throws {
          let single = try decoder.singleValueContainer()
          if let string = try? single.decode(String.self) { self = .day(string) }
          else { self = .rate(try single.decode([String: String].self)["v"] ?? "") }
        }
        var string: String { switch self { case .day(let s), .rate(let s): s } }
      }
    }
    let usable = try JSONDecoder().decode(Response.self, from: data).observations.filter {
      guard let text = $0["FXGBPCAD"]?.string, let value = Decimal(string: text), value > 0 else { return false }
      return $0["d"] != nil
    }
    guard let observation = usable.max(by: { ($0["d"]?.string ?? "") < ($1["d"]?.string ?? "") }),
      let date = observation["d"]?.string,
      let base = observation["FXGBPCAD"].flatMap({ Decimal(string: $0.string) }), base > 0 else {
      throw CoreError.invalid("No GBP exchange rate was returned")
    }
    var rates: [String: Decimal] = ["GBP": 1, "CAD": 1 / base]
    for code in PortfolioCurrency.codes where code != "GBP" && code != "CAD" {
      if let text = observation["FX" + code + "CAD"]?.string, let rate = Decimal(string: text), rate > 0 {
        rates[code] = rate / base
      }
    }
    let result = ExchangeRateQuote(ratesToGBP: rates, date: date, source: "Bank of Canada")
    try result.validate()
    return result
  }
}
extension DayRecord {
  public mutating func apply(_ quote: ExchangeRateQuote, refreshExisting: Bool) {
    for (currency, rate) in quote.ratesToGBP where currency != "GBP" && (refreshExisting || exchangeRates[currency] == nil) {
      exchangeRates[currency] = rate
      exchangeRateDates[currency] = quote.date
      exchangeRateSources[currency] = quote.source
    }
  }
  func conversion(from source: String, to target: String) -> Decimal? {
    if source == target { return 1 }
    let sourceRate = source == "GBP" ? Decimal(1) : exchangeRates[source]
    let targetRate = target == "GBP" ? Decimal(1) : exchangeRates[target]
    guard let sourceRate, let targetRate, sourceRate > 0, targetRate > 0 else { return nil }
    return sourceRate / targetRate
  }
}
