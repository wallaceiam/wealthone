import Foundation

/// An editor draft keeps typed text separate from imported values. Validation is
/// derived from the latest dependencies, never cached by a text-field callback.
public struct GoalDraft: Sendable {
  public let original: [String: Value]
  public private(set) var text: [String: String] = [:]
  public private(set) var edits: [String: Value] = [:]
  public var isDirty: Bool { !text.isEmpty || !edits.isEmpty }
  public init(original: [String: Value] = [:]) { self.original = original }

  // Goal assumptions may contain fractional values. EntryAmount intentionally
  // truncates dated account entries to whole pounds, so it is not used here.
  private static func parse(_ text: String) -> Decimal? {
    let trimmed = text.trimmingCharacters(in: .whitespaces)
    guard
      trimmed.range(of: #"^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)$"#, options: .regularExpression)
        != nil,
      let value = Decimal(string: trimmed, locale: Locale(identifier: "en_GB")), !value.isNaN
    else { return nil }
    return value
  }
  public mutating func setText(_ value: String, for key: String) { text[key] = value }
  public mutating func setNumber(_ value: Double, for key: String) {
    text[key] = NSDecimalNumber(decimal: Decimal(value)).stringValue
  }
  public mutating func setBirth(day: String, originalDisplayedDay: String, currentAge: Int) {
    if day == originalDisplayedDay {
      // Remove both edits, retaining the exact original representation or absence.
      edits["birthDate"] = nil
      edits["currentAge"] = nil
    } else {
      edits["birthDate"] = .string(day)
      edits["currentAge"] = .decimal(Decimal(currentAge))
    }
  }
  public func displayText(_ key: String, fallback: Double) -> String {
    if let value = text[key] { return value }
    if case .decimal(let value) = original[key] {
      return NSDecimalNumber(decimal: value).stringValue
    }
    return NSDecimalNumber(decimal: Decimal(fallback)).stringValue
  }
  public func number(_ key: String, fallback: Double) -> Double {
    if let value = text[key] {
      guard let decimal = Self.parse(value) else { return 0 }
      let number = NSDecimalNumber(decimal: decimal).doubleValue
      return number.isFinite ? number : 0
    }
    if case .decimal(let decimal) = original[key] {
      let number = NSDecimalNumber(decimal: decimal).doubleValue
      return number.isFinite ? number : fallback
    }
    return fallback
  }
  public func range(_ key: String, currentAge: Int) -> ClosedRange<Double> {
    switch key {
    case "retirementAge": Double(min(currentAge, 75))...75
    case "lifeStyle", "pension": 0...100
    case "investmentStyle": 0...6
    case "contributions":
      0...max(0, floor(min(150000, max(0, number("earnings", fallback: 55000))) / 12))
    default: 0...150000
    }
  }
  public func invalidKeys(currentAge: Int) -> Set<String> {
    Set(
      text.keys.filter { key in
        guard let value = Self.parse(text[key]!) else { return true }
        let number = NSDecimalNumber(decimal: value).doubleValue
        return !number.isFinite || !range(key, currentAge: currentAge).contains(number)
      })
  }
  public func changes(currentAge: Int) throws -> [String: Value] {
    guard invalidKeys(currentAge: currentAge).isEmpty else {
      throw CoreError.invalid("Review the highlighted goal inputs before saving.")
    }
    var changes = edits
    for (key, value) in text { changes[key] = .decimal(Self.parse(value)!) }
    return changes
  }
  public func slider(_ key: String, fallback: Double, preferredStep: Double, currentAge: Int)
    -> GoalSliderBounds
  {
    let range = range(key, currentAge: currentAge)
    let span = range.upperBound - range.lowerBound
    // SwiftUI's stepped Slider requires a positive step no larger than its span.
    // A zero-span range is represented by no slider; exact input remains available.
    let step = span > 0 ? min(preferredStep, span) : nil
    let value = min(range.upperBound, max(range.lowerBound, number(key, fallback: fallback)))
    return GoalSliderBounds(range: range, step: step, value: value)
  }
}
public struct GoalSliderBounds: Sendable {
  public let range: ClosedRange<Double>
  public let step: Double?
  public let value: Double
}
