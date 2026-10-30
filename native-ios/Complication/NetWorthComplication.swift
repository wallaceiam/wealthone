import SwiftUI
import WidgetKit

struct NetWorthEntry: TimelineEntry {
  let date: Date
  let snapshot: WatchSnapshot?
}
struct NetWorthProvider: TimelineProvider {
  func placeholder(in context: Context) -> NetWorthEntry { .init(date: Date(), snapshot: nil) }
  func getSnapshot(in context: Context, completion: @escaping (NetWorthEntry) -> Void) {
    completion(entry())
  }
  func getTimeline(in context: Context, completion: @escaping (Timeline<NetWorthEntry>) -> Void) {
    completion(Timeline(entries: [entry()], policy: .after(Date().addingTimeInterval(1800))))
  }
  private func entry() -> NetWorthEntry {
    let snapshot = UserDefaults(suiteName: WatchSnapshot.storageGroup)?.data(forKey: "snapshot")
      .flatMap { try? JSONDecoder().decode(WatchSnapshot.self, from: $0) }
    return .init(date: Date(), snapshot: snapshot)
  }
}
struct NetWorthComplicationView: View {
  let entry: NetWorthEntry
  @Environment(\.widgetFamily) private var family
  var body: some View {
    Group {
      if let snapshot = entry.snapshot, snapshot.valuationUnavailable != true {
        switch family {
        case .accessoryInline:
          Text(
            "WealthOne \(snapshot.total.formatted(.currency(code: snapshot.currency ?? "GBP").precision(.fractionLength(0)))) · \(SnapshotFreshness.label(updatedAt: snapshot.updatedAt))"
          )
        case .accessoryCircular:
          VStack(spacing: 1) {
            Image(systemName: "chart.line.uptrend.xyaxis").widgetAccentable()
            Text(
              snapshot.total,
              format: .currency(code: snapshot.currency ?? "GBP").notation(.compactName).precision(
                .fractionLength(0...1))
            )
            .font(.caption.weight(.semibold)).minimumScaleFactor(0.5).lineLimit(1)
            Text(SnapshotFreshness.label(updatedAt: snapshot.updatedAt, compact: true)).font(
              .system(size: 9)
            ).minimumScaleFactor(0.5)
              .lineLimit(1)
          }
        default:
          VStack(alignment: .leading, spacing: 1) {
            Label("WealthOne", systemImage: "chart.line.uptrend.xyaxis")
              .font(.caption2).widgetAccentable()
            Text(snapshot.total, format: .currency(code: snapshot.currency ?? "GBP").precision(.fractionLength(0)))
              .font(.headline).minimumScaleFactor(0.5).lineLimit(1)
            Text("Updated \(SnapshotFreshness.label(updatedAt: snapshot.updatedAt))")
              .font(.caption2)
          }
        }
      } else {
        if family == .accessoryInline {
          Text("WealthOne · Open app")
        } else {
          VStack(spacing: 2) {
            Image(systemName: "chart.line.uptrend.xyaxis").widgetAccentable()
            Text("Open app").font(.caption2)
          }
        }
      }
    }.containerBackground(for: .widget) { Color.clear }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("WealthOne net worth")
      .accessibilityValue(
        entry.snapshot.map { snapshot in
          (snapshot.valuationUnavailable == true ? "Exchange rates needed" : snapshot.total.formatted(.currency(code: snapshot.currency ?? "GBP").precision(.fractionLength(0))))
            + ", last updated " + snapshot.updatedAt.formatted(date: .complete, time: .shortened)
        } ?? "Open the app to sync")
  }
}
@main
struct NetWorthComplication: Widget {
  let kind = "WealthOneNetWorth"
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: NetWorthProvider()) {
      NetWorthComplicationView(entry: $0)
    }
    .configurationDisplayName("WealthOne")
    .description("Net worth and the time it last synced from your iPhone.")
    .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
  }
}
