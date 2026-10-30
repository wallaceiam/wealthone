import Foundation
import XCTest

@testable import WealthOneShared

final class SnapshotFreshnessTests: XCTestCase {
  private let locale = Locale(identifier: "en_GB")
  private var calendar: Calendar {
    var value = Calendar(identifier: .gregorian)
    value.timeZone = TimeZone(secondsFromGMT: 0)!
    return value
  }
  private func date(_ text: String) -> Date { ISO8601DateFormatter().date(from: text)! }

  func testTodayShowsTheUpdateTime() {
    XCTAssertEqual(
      SnapshotFreshness.label(
        updatedAt: date("2026-10-29T09:40:00Z"),
        now: date("2026-10-29T12:00:00Z"), locale: locale, calendar: calendar), "9:40")
  }
  func testOlderSnapshotIncludesDateAndTime() {
    let label = SnapshotFreshness.label(
      updatedAt: date("2026-10-28T09:40:00Z"),
      now: date("2026-10-29T12:00:00Z"), locale: locale, calendar: calendar)
    XCTAssertTrue(label.contains("28 Oct 2026"), label)
    XCTAssertTrue(label.contains("9:40"), label)
  }
  func testCompactStaleLabelRetainsTheYear() {
    let label = SnapshotFreshness.label(
      updatedAt: date("2025-10-29T09:40:00Z"),
      now: date("2026-10-29T12:00:00Z"), compact: true, locale: locale, calendar: calendar)
    XCTAssertTrue(label.contains("2025"), label)
    XCTAssertFalse(label.contains("9:40"), label)
  }
}
