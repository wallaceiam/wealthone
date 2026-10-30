import Foundation

/// Wealth+ exports dated account balances. Summary columns are never imported as accounts.
public struct WealthCSVDocument: Sendable {
  public struct Row: Sendable {
    public let day: String
    public let balances: [String: Decimal]
  }
  public let accountNames: [String]
  public let rows: [Row]
  public func missingAccountNames(in snapshot: Snapshot) -> [String] {
    let names = Set(snapshot.accounts.map { Self.normalizedName($0.name) })
    return accountNames.filter { !names.contains(Self.normalizedName($0)) }
  }
  static func normalizedName(_ name: String) -> String {
    name.split(whereSeparator: \.isWhitespace).joined(separator: " ").folding(options: [.caseInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX"))
  }
  public static func parse(_ data: Data) throws -> WealthCSVDocument {
    guard var text = String(data: data, encoding: .utf8) else { throw CoreError.invalid("Use a UTF-8 Wealth+ CSV export.") }
    if text.first == "\u{feff}" { text.removeFirst() }
    let table = try fields(text)
    guard let header = table.first, header.count >= 6,
      header.prefix(4).map({ $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }) == ["date", "total", "assets", "liabilities"],
      let note = header.firstIndex(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "note" }), note > 4,
      header.dropFirst(note + 1).allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
      throw CoreError.invalid("Expected Wealth+ columns: Date, Total, Assets, Liabilities, account names, Note.")
    }
    let names = header[4..<note].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    let normalized = names.map(normalizedName)
    guard normalized.allSatisfy({ !$0.isEmpty }), Set(normalized).count == names.count else { throw CoreError.invalid("CSV account names must be nonempty and unique.") }
    let formatter = DateFormatter()
    formatter.calendar = PortfolioCalculator.dayCalendar
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = PortfolioCalculator.dayCalendar.timeZone
    formatter.dateFormat = "d MMM yyyy"; formatter.isLenient = false
    var rows: [Row] = [], seen = Set<String>()
    for (index, row) in table.dropFirst().enumerated() {
      if row.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) { continue }
      guard row.count == header.count else { throw CoreError.invalid("CSV row \(index + 2) has an unexpected number of columns.") }
      let dateText = row[0].trimmingCharacters(in: .whitespacesAndNewlines)
      guard dateText.range(of: #"^[0-9]{1,2} [A-Za-z]{3} [0-9]{4}$"#, options: .regularExpression) != nil,
        let date = formatter.date(from: dateText) else { throw CoreError.invalid("Invalid date on CSV row \(index + 2).") }
      let day = PortfolioCalculator.dayKey(date)
      guard seen.insert(day).inserted else { throw CoreError.invalid("The CSV contains more than one snapshot for \(day).") }
      guard row[note].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        row.dropFirst(note + 1).allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
        throw CoreError.invalid("CSV row \(index + 2) contains notes or extra data. Notes are not supported by this balance import; keep the original export.")
      }
      var balances: [String: Decimal] = [:]
      for (offset, name) in names.enumerated() {
        let value = row[offset + 4].trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty { continue }
        guard value.range(of: #"^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)$"#, options: .regularExpression) != nil,
          let amount = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")), !amount.isNaN else {
          throw CoreError.invalid("Invalid balance for \(name) on CSV row \(index + 2).")
        }
        balances[name] = amount
      }
      rows.append(Row(day: day, balances: balances))
    }
    guard !rows.isEmpty else { throw CoreError.invalid("The CSV contains no dated balances.") }
    return WealthCSVDocument(accountNames: names, rows: rows.sorted { $0.day < $1.day })
  }
  /// Strict RFC-style quoted fields, escaped quotes, CRLF and embedded newlines.
  private static func fields(_ text: String) throws -> [[String]] {
    let chars = Array(text)
    var result: [[String]] = [], row: [String] = [], field = "", quoted = false, endedQuote = false, i = 0
    func endField() { row.append(field); field = ""; endedQuote = false }
    func endRow() { endField(); result.append(row); row = [] }
    while i < chars.count {
      let c = chars[i]
      if quoted {
        if c == "\"" {
          if i + 1 < chars.count && chars[i + 1] == "\"" { field.append("\""); i += 1 }
          else { quoted = false; endedQuote = true }
        } else { field.append(c) }
      } else if c == "," { endField() }
      else if c == "\n" || c == "\r" || c == "\r\n" {
        endRow()
        if c == "\r", i + 1 < chars.count, chars[i + 1] == "\n" { i += 1 }
      } else if c == "\"", field.isEmpty && !endedQuote { quoted = true }
      else {
        guard !endedQuote, c != "\"" else { throw CoreError.invalid("Malformed quoted CSV field.") }
        field.append(c)
      }
      i += 1
    }
    guard !quoted else { throw CoreError.invalid("The CSV ends inside a quoted field.") }
    if !row.isEmpty || !field.isEmpty || endedQuote { endRow() }
    return result
  }
}

public enum CSVBalanceUnits: String, Sendable { case accountCurrency, reportingCurrency }

/// Immutable proposal tied to the exact portfolio that was reviewed.
public struct WealthCSVImportPlan: Sendable {
  public let baseline: Snapshot
  public let updates: [DayRecord]
  public let accountCount, newDateCount, newBalanceCount, differentBalanceCount, unchangedBalanceCount: Int
  public let overwriteExisting: Bool
  public init(document: WealthCSVDocument, snapshot: Snapshot, overwriteExisting: Bool = false,
    units: CSVBalanceUnits = .accountCurrency, quote: ExchangeRateQuote? = nil) throws {
    if let quote { try quote.validate() }
    let grouped = Dictionary(grouping: snapshot.accounts, by: { WealthCSVDocument.normalizedName($0.name) })
    let missing = document.missingAccountNames(in: snapshot)
    guard missing.isEmpty else { throw CoreError.invalid("These accounts are missing: " + missing.joined(separator: ", ") + ". Review and create them before importing balances.") }
    let ambiguous = document.accountNames.filter { grouped[WealthCSVDocument.normalizedName($0)]!.count != 1 }
    guard ambiguous.isEmpty else { throw CoreError.invalid("More than one existing account matches: " + ambiguous.joined(separator: ", ") + ". Give each account a unique name first.") }
    let accounts = Dictionary(uniqueKeysWithValues: document.accountNames.map { ($0, grouped[WealthCSVDocument.normalizedName($0)]![0]) })
    let stored = Dictionary(grouping: PortfolioCalculator.dated(snapshot.records), by: { PortfolioCalculator.dayKey($0.date) })
    let required = Set(snapshot.accounts.map(\.currency) + [snapshot.reportingCurrency]).subtracting(["GBP"])
    var updates: [DayRecord] = [], newDates = 0, newBalances = 0, differences = 0, unchanged = 0
    for row in document.rows {
      guard (stored[row.day]?.count ?? 0) <= 1 else { throw CoreError.invalid("More than one stored entry represents \(row.day). Review those entries before importing.") }
      let existing = stored[row.day]?.first?.record
      var rates = existing ?? DayRecord(date: row.day)
      if let quote {
        for code in required where rates.exchangeRates[code] == nil {
          if let rate = quote.ratesToGBP[code] {
            rates.exchangeRates[code] = rate
            rates.exchangeRateDates[code] = quote.date
            rates.exchangeRateSources[code] = quote.source
          }
        }
      }
      var update = DayRecord(date: existing?.date ?? row.day)
      for (name, sourceAmount) in row.balances {
        let account = accounts[name]!
        guard !account.isClosed(on: row.day) else { throw CoreError.invalid("\(name) was closed on \(row.day). Review its status in Settings before importing that date.") }
        let value: Decimal
        if units == .reportingCurrency, sourceAmount != 0 {
          guard let rate = rates.conversion(from: snapshot.reportingCurrency, to: account.currency) else { throw CoreError.invalid("Fetch reference rates to convert CSV amounts to account currencies.") }
          value = sourceAmount * rate
          guard !value.isNaN else { throw CoreError.invalid("A converted CSV balance is invalid.") }
        } else { value = sourceAmount }
        if let old = existing?.totals[account.id] {
          if old == value { unchanged += 1; continue }
          differences += 1
          if !overwriteExisting { continue }
        } else { newBalances += 1 }
        update.totals[account.id] = value
      }
      guard !update.totals.isEmpty else { continue }
      for code in required where existing?.exchangeRates[code] == nil {
        guard let rate = rates.exchangeRates[code] else { throw CoreError.invalid("Fetch reference rates before importing balances with \(code). Existing saved rates will be kept.") }
        update.exchangeRates[code] = rate
        update.exchangeRateDates[code] = rates.exchangeRateDates[code]
        update.exchangeRateSources[code] = rates.exchangeRateSources[code]
      }
      if existing == nil { newDates += 1 }
      updates.append(update)
    }
    self.baseline = snapshot; self.updates = updates; self.overwriteExisting = overwriteExisting
    accountCount = accounts.count; newDateCount = newDates; newBalanceCount = newBalances
    differentBalanceCount = differences; unchangedBalanceCount = unchanged
  }
}
