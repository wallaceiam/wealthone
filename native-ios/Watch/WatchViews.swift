import Charts
import SwiftUI

struct WatchHomeView: View {
  @EnvironmentObject var model: WatchModel
  @State private var discarding = false
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        if let snapshot = model.snapshot {
          WatchBalanceView(snapshot: snapshot)
          NavigationLink {
            QuickEntryView()
          } label: {
            Label("Quick entry", systemImage: "plus")
              .frame(maxWidth: .infinity, alignment: .leading)
          }.buttonStyle(.glass).disabled(model.pending != nil)
          NavigationLink {
            WatchHistoryView(snapshot: snapshot)
          } label: {
            Label("Recent history", systemImage: "clock.arrow.circlepath")
              .frame(maxWidth: .infinity, alignment: .leading)
          }.buttonStyle(.glass)
        } else {
          ContentUnavailableView {
            Label("Ready to sync", systemImage: "iphone.and.arrow.forward")
          } description: {
            Text("Open WealthOne on your iPhone to see your portfolio here.")
          }
        }
        if model.pending != nil
          || (model.snapshot != nil && model.status != "Open WealthOne on your iPhone to sync.")
        {
          Text(model.status).font(.caption2).foregroundStyle(.secondary)
        }
        if model.pending != nil {
          Button("Retry pending entry", systemImage: "arrow.clockwise") { model.retry() }
            .buttonStyle(.glass)
          Button("Discard pending entry", role: .destructive) { discarding = true }
        }
      }.padding(.horizontal, 4)
    }.navigationTitle("WealthOne")
      .confirmationDialog("Stop retrying this entry? It may already be saved on iPhone. Check history before re-entering.", isPresented: $discarding, titleVisibility: .visible) {
        Button("Discard pending entry", role: .destructive) { model.discardPending() }
      }
  }
}

struct WatchBalanceView: View {
  let snapshot: WatchSnapshot
  var domain: ClosedRange<Double> {
    let values = snapshot.history.map(\.total).filter(\.isFinite)
    let low = values.min() ?? snapshot.total
    let high = values.max() ?? snapshot.total
    let padding = max((high - low) * 0.12, abs(high) * 0.02, 1)
    return (low - padding)...(high + padding)
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Net worth").font(.caption).foregroundStyle(.secondary)
      if snapshot.valuationUnavailable == true {
        Text("Save exchange rates on iPhone").font(.headline)
      } else {
      Text(snapshot.total, format: .currency(code: snapshot.currency ?? "GBP").precision(.fractionLength(0)))
        .font(.title2.bold()).monospacedDigit().minimumScaleFactor(0.65).lineLimit(1)
      Label {
        Text(snapshot.change, format: .currency(code: snapshot.currency ?? "GBP").precision(.fractionLength(0)))
      } icon: {
        Image(systemName: snapshot.change < 0 ? "arrow.down" : "arrow.up")
      }.font(.callout.weight(.semibold)).foregroundStyle(.blue)
      Text("Since previous snapshot").font(.caption2).foregroundStyle(.secondary)
      }
      if !snapshot.history.isEmpty {
        Chart(snapshot.history.filter { $0.total.isFinite }) { point in
          AreaMark(
            x: .value("Date", point.date), yStart: .value("GBP", domain.lowerBound),
            yEnd: .value("GBP", point.total)
          )
          .foregroundStyle(
            .linearGradient(
              colors: [.blue.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
          LineMark(x: .value("Date", point.date), y: .value("GBP", point.total))
            .foregroundStyle(.blue).lineStyle(StrokeStyle(lineWidth: 2))
          if snapshot.history.count == 1 {
            PointMark(x: .value("Date", point.date), y: .value("GBP", point.total))
              .foregroundStyle(.blue)
          }
        }.chartYScale(domain: domain).chartXAxis(.hidden).chartYAxis(.hidden)
          .frame(height: 54).accessibilityLabel("Recent net worth snapshots")
      }
      Text("Updated \(SnapshotFreshness.label(updatedAt: snapshot.updatedAt))")
        .font(.caption2).foregroundStyle(.secondary)
        .accessibilityLabel("Last updated")
        .accessibilityValue(snapshot.updatedAt.formatted(date: .complete, time: .shortened))
    }.accessibilityElement(children: .contain)
  }
}

struct WatchHistoryView: View {
  let snapshot: WatchSnapshot
  var body: some View {
    List {
      ForEach(snapshot.history.reversed()) { point in
        VStack(alignment: .leading, spacing: 5) {
          Text(String(point.date.prefix(10))).font(.caption2).foregroundStyle(.secondary)
          Text(point.total, format: .currency(code: snapshot.currency ?? "GBP").precision(.fractionLength(0)))
            .font(.body.weight(.medium)).monospacedDigit()
        }.padding(.vertical, 3).accessibilityElement(children: .combine)
      }
      if snapshot.history.isEmpty { Text("No snapshots yet").foregroundStyle(.secondary) }
      Text("From your iPhone").font(.caption2).foregroundStyle(.secondary)
    }.navigationTitle("History")
  }
}

struct QuickEntryView: View {
  @EnvironmentObject var model: WatchModel
  @State private var accountID = ""
  @State private var amount = ""
  @State private var currency = "GBP"
  var currentCurrency: String { model.snapshot?.accounts.first { $0.id == accountID }?.currency ?? "GBP" }
  var body: some View {
    Form {
      Picker("Account", selection: $accountID) {
        Text("Choose account").tag("")
        ForEach(model.snapshot?.accounts ?? []) { account in Text(account.name).tag(account.id) }
      }.onChange(of: accountID) { _, _ in
        amount = ""; currency = currentCurrency
      }
      if currency != currentCurrency {
        Text("Account currency changed. Review before saving.").font(.caption2)
        Button("Review currency") { amount = ""; currency = currentCurrency }
      }
      Section("Today's total (" + currency + ")") {
        TextField("Amount", text: $amount).font(.body.weight(.semibold))
          .accessibilityLabel("Today's total (" + currency + ")")
      }
      Text("Updates this account only.").font(.caption2).foregroundStyle(.secondary)
        .listRowBackground(Color.clear)
      Button("Save on iPhone") { model.submit(accountID: accountID, amount: amount, currency: currency) }
        .buttonStyle(.glassProminent).listRowBackground(Color.clear)
        .disabled(accountID.isEmpty || amount.isEmpty || model.pending != nil || currency != currentCurrency)
      Text(model.pending == nil ? "Saved after iPhone confirms." : model.status)
        .font(.caption2).foregroundStyle(.secondary)
      if model.pending != nil {
        Button("Retry pending entry") { model.retry() }.buttonStyle(.glass)
      } else if model.status == "Enter a valid amount." || model.status == "Saved on iPhone" {
        Text(model.status).font(.caption2)
      }
    }.navigationTitle("Quick entry")
  }
}
