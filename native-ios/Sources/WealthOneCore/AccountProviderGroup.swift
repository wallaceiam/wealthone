import Foundation

/// Presentation groups for captured entry accounts; no stored metadata is changed.
public struct AccountProviderGroup: Identifiable, Sendable {
  public let id: String
  public let provider: String
  public let accounts: [Account]
  public static func make(_ accounts: [Account]) -> [AccountProviderGroup] {
    func label(_ value: String) -> String { value.split(whereSeparator: \.isWhitespace).joined(separator: " ") }
    func key(_ value: String) -> String { label(value).folding(options: [.caseInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX")) }
    let groups = Dictionary(grouping: accounts, by: { key($0.provider) })
    return groups.keys.sorted { left, right in
      if left.isEmpty { return false }
      if right.isEmpty { return true }
      return left.compare(right, options: .numeric) == .orderedAscending
    }.map { id in
      let values = groups[id]!.sorted { left, right in
        let order = left.name.compare(right.name, options: [.caseInsensitive, .numeric])
        return order == .orderedSame ? left.id < right.id : order == .orderedAscending
      }
      let provider = id.isEmpty ? "Other accounts" : values.map { label($0.provider) }.sorted().first!
      return AccountProviderGroup(id: id, provider: provider, accounts: values)
    }
  }
}
