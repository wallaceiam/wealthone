// Compile alongside Sources/WealthOneCore/*.swift (as main.swift), then pass a NEW history.json path.
// Creates synthetic data only. Use an isolated WEALTHONE_UI_TEST_STORE UUID, never a normal store.
import Foundation
let accounts = (0..<7).map { Account(id: "synthetic-\($0)", name: "Account \($0 + 1)") }
let formatter = DateFormatter()
formatter.locale = Locale(identifier: "en_US_POSIX")
formatter.timeZone = TimeZone(secondsFromGMT: 0)
formatter.dateFormat = "yyyy-MM-dd"
let first = formatter.date(from: "2020-01-01")!
let records: [DayRecord] = (0..<344).map { index in
  let values = Dictionary(uniqueKeysWithValues: accounts.enumerated().map {
    ($0.element.id, Decimal(10000 + index * 100 + $0.offset * 1000))
  })
  return DayRecord(date: formatter.string(from: first.addingTimeInterval(Double(index) * 7 * 86400)), totals: values)
}
let store = try EventStore()
try store.replace(Snapshot(accounts: accounts, records: records))
let url = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
try JSONEncoder().encode(store.envelope).write(to: url, options: .withoutOverwriting)
print("Created synthetic fixture: 7 accounts, 344 dated records")
