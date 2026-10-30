import CoreFoundation
import Foundation

/// Decodes redux-persist's JSON-stringified, lz-string UTF-16 slices.
/// Port of lz-string 1.5's MIT-licensed decoder; see Licenses/lz-string.txt.
public enum LegacyReduxDecoder {
  public enum DecodeError: Error { case invalidData, decompressionLimit }

  public static func decode(_ raw: String) throws -> Snapshot {
    guard let data = raw.data(using: .utf8),
      let root = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      throw DecodeError.invalidData
    }
    // Non-persisted backups already contain state. The oldest backup wraps goal in input.
    if root["accounts"] != nil || root["categories"] != nil {
      return try Archive.snapshot(from: data)
    }
    func slice(_ name: String) throws -> Any? {
      guard let wrapped = root[name] else { return nil }
      if let object = wrapped as? [String: Any] { return object }
      guard let encoded = wrapped as? String else { throw DecodeError.invalidData }
      let fragment = try? JSONSerialization.jsonObject(
        with: Data(encoded.utf8), options: .fragmentsAllowed)
      if let object = fragment as? [String: Any] { return object }
      let compressed = fragment as? String ?? encoded
      return try JSONSerialization.jsonObject(with: Data(decompress(compressed).utf8))
    }
    guard var portfolio = try slice("portfolio") as? [String: Any] else {
      throw DecodeError.invalidData
    }
    if let goal = try slice("goal") { portfolio["goal"] = goal }
    return try Archive.snapshot(from: jsonDataPreservingNumbers(portfolio))
  }

  private static func jsonDataPreservingNumbers(_ object: Any) throws -> Data {
    func normalized(_ value: Any) -> Any {
      if let number = value as? NSNumber {
        if CFGetTypeID(number) == CFBooleanGetTypeID() { return number }
        return NSDecimalNumber(
          string: number.stringValue, locale: Locale(identifier: "en_US_POSIX"))
      }
      if let dictionary = value as? [String: Any] { return dictionary.mapValues(normalized) }
      if let array = value as? [Any] { return array.map(normalized) }
      return value
    }
    return try JSONSerialization.data(withJSONObject: normalized(object))
  }

  private static func decompress(_ input: String) throws -> String {
    let units = Array(input.utf16)
    guard !units.isEmpty else { throw DecodeError.invalidData }
    var index = 0
    var mask = 16384
    func read(_ count: Int) throws -> Int {
      guard count <= 24 else { throw DecodeError.decompressionLimit }
      var bits = 0
      for bit in 0..<count {
        guard index < units.count, units[index] >= 32 else { throw DecodeError.invalidData }
        if (Int(units[index]) - 32) & mask != 0 { bits |= 1 << bit }
        mask >>= 1
        if mask == 0 {
          mask = 16384
          index += 1
        }
      }
      return bits
    }
    let first = try read(2)
    if first == 2 { return "" }
    guard first == 0 || first == 1 else { throw DecodeError.invalidData }
    var word = [UInt16(try read(first == 0 ? 8 : 16))]
    var dictionary: [[UInt16]] = [[], [], [], word]
    var result = word
    var width = 3
    var remaining = 4
    while index < units.count {
      var code = try read(width)
      if code == 2 { return String(decoding: result, as: UTF16.self) }
      if code == 0 || code == 1 {
        dictionary.append([UInt16(try read(code == 0 ? 8 : 16))])
        code = dictionary.count - 1
        remaining -= 1
      }
      if remaining == 0 {
        remaining = 1 << width
        width += 1
      }
      let entry: [UInt16]
      if code < dictionary.count {
        entry = dictionary[code]
      } else if code == dictionary.count {
        entry = word + [word[0]]
      } else {
        throw DecodeError.invalidData
      }
      guard let firstUnit = entry.first else { throw DecodeError.invalidData }
      guard result.count + entry.count <= 32 * 1024 * 1024, dictionary.count < 1_000_000 else {
        throw DecodeError.decompressionLimit
      }
      result.append(contentsOf: entry)
      dictionary.append(word + [firstUnit])
      remaining -= 1
      word = entry
      if remaining == 0 {
        remaining = 1 << width
        width += 1
      }
    }
    throw DecodeError.invalidData
  }
}
