import Foundation

/// Cached balances must show their date once the last update is no longer today.
enum SnapshotFreshness {
  static func label(
    updatedAt: Date, now: Date = Date(), compact: Bool = false,
    locale: Locale = .current, calendar: Calendar = .current
  ) -> String {
    let today = calendar.isDate(updatedAt, inSameDayAs: now)
    let style = Date.FormatStyle(
      date: today ? .omitted : (compact ? .numeric : .abbreviated),
      time: today || !compact ? .shortened : .omitted, locale: locale,
      calendar: calendar, timeZone: calendar.timeZone)
    return style.format(updatedAt)
  }
}
