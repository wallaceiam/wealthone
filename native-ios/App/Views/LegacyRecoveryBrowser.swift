import SwiftUI
import UniformTypeIdentifiers
import WealthOneCore

/// Shared read-only browser. The original-identity utility supplies no import callback.
struct LegacyRecoveryBrowser: View {
  @ObservedObject var recovery: LegacyRecoveryModel
  var onImport: ((LegacyRecoveredCandidate, Int) -> Void)?
  @State private var exporting = false
  @State private var document = RecoveryJSONDocument(data: Data())
  @State private var error: String?
  var body: some View {
    List {
      Section {
        Text(
          "Search for data saved by the previous WealthOne app using this iCloud account. The old app does not need to be installed."
        )
        Text("Searching and exporting do not change your iCloud data or your current portfolio.")
          .font(.footnote).foregroundStyle(.secondary)
        if recovery.phase == .waiting { ProgressView("Waiting for iCloud…") }
        Text(status).accessibilityIdentifier("Legacy recovery status")
        Button(recovery.phase == .idle ? "Search iCloud" : "Search again") { recovery.start() }
          .disabled(recovery.phase == .waiting)
      }
      if recovery.quotaWarning {
        Section {
          Text(
            "iCloud reported a storage quota issue. Any readable copies are shown below; this does not prove the old data is missing."
          )
        }
      }
      if !recovery.report.candidates.isEmpty {
        Section("Recovered copies") {
          ForEach(recovery.report.candidates) { candidate in
            NavigationLink {
              LegacyRecoveryDetail(
                candidate: candidate, revision: recovery.revision,
                recovery: recovery, onImport: onImport)
            } label: {
              VStack(alignment: .leading, spacing: 5) {
                Text(
                  candidate.source == "persist:wealthone_data"
                    ? "Saved portfolio" : "Backup · " + candidate.source
                )
                .font(.headline)
                Text(
                  "\(candidate.snapshot.accounts.count) accounts · \(candidate.snapshot.records.count) dated entries"
                )
                .font(.subheadline).foregroundStyle(.secondary)
              }
            }
          }
        }
      }
      if !recovery.report.unreadableSources.isEmpty {
        Section("Some copies could not be read") {
          Text(
            "Found data in: " + recovery.report.unreadableSources.joined(separator: ", ")
              + ". Export the original data below to keep a copy for further recovery.")
        }
      }
      if let original = recovery.report.originalArchive {
        Section("Original data") {
          Button("Export original iCloud data") {
            guard recovery.canUse(revision: recovery.revision) else { return }
            document = RecoveryJSONDocument(data: original)
            exporting = true
          }
          Text(
            "This preserves the original saved values for recovery support. Use a recovered copy's JSON export to import into WealthOne."
          )
          .font(.footnote).foregroundStyle(.secondary)
        }
      }
      Section("Access details") {
        Text("Use the same Apple Account as the old app, with iCloud enabled for WealthOne.")
        Text(
          "The new app must be signed for access to the original key-value store. If access is rejected, use the WealthOneRecovery Xcode scheme, which uses the original app identity."
        )
        .font(.footnote).foregroundStyle(.secondary)
        LabeledContent("Original app", value: "ca.mymojo.wealthone").font(.caption)
      }
    }.navigationTitle("Recover iCloud Data").navigationBarTitleDisplayMode(.inline)
      .task { if recovery.phase == .idle { recovery.start() } }
      .onChange(of: recovery.revision) { _, _ in
        exporting = false
        document = RecoveryJSONDocument(data: Data())
      }
      .fileExporter(
        isPresented: $exporting, document: document, contentType: .json,
        defaultFilename: "WealthOne-original-iCloud-data"
      ) { if case .failure(let failure) = $0 { error = failure.localizedDescription } }
      .alert(
        "Export failed",
        isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })
      ) {
        Button("OK") { error = nil }
      } message: {
        Text(error ?? "")
      }
  }
  private var status: String {
    switch recovery.phase {
    case .idle: "Ready to search."
    case .waiting:
      "iCloud downloads can take time. Keep the app open; recovered copies will appear automatically."
    case .found: "Recovered data is available for review. Nothing has been imported."
    case .noDataYet:
      "No old data has arrived yet. This does not mean it was deleted. This screen is still listening for iCloud updates; you can retry later."
    case .invalidData:
      "Old data was found but could not be decoded. Export the original data to preserve it."
    case .accountUnavailable:
      "An iCloud account is not available to this build. Check Settings → Apple Account → iCloud and the app's signing capabilities, then search again."
    case .accessRejected:
      "iCloud did not accept the sync request. Check the signing team's original key-value storage entitlement, or try the WealthOneRecovery scheme. This is not proof that your data is missing."
    case .accountChanged:
      "The iCloud account changed. Recovered previews were cleared. Confirm the correct account, then search again."
    case .quotaExceeded:
      "iCloud reported a storage quota issue and no readable copy has arrived yet. Keep any exported backups and try again later."
    case .unsupported:
      "Legacy iCloud recovery requires a signed app on your iPhone or iPad. The simulator cannot access the old iCloud store."
    }
  }
}

private struct LegacyRecoveryDetail: View {
  @State private var candidate: LegacyRecoveredCandidate
  @State private var revision: Int
  @ObservedObject var recovery: LegacyRecoveryModel
  let onImport: ((LegacyRecoveredCandidate, Int) -> Void)?
  @State private var exporting = false
  @State private var document = RecoveryJSONDocument(data: Data())
  @State private var exportError: String?
  init(
    candidate: LegacyRecoveredCandidate, revision: Int, recovery: LegacyRecoveryModel,
    onImport: ((LegacyRecoveredCandidate, Int) -> Void)?
  ) {
    _candidate = State(initialValue: candidate)
    _revision = State(initialValue: revision)
    self.recovery = recovery
    self.onImport = onImport
  }
  private var valid: Bool { recovery.canUse(revision: revision) }
  private var chronologicalRecords: [DayRecord] {
    candidate.snapshot.records.sorted {
      PortfolioCalculator.date($0.date) < PortfolioCalculator.date($1.date)
    }
  }
  var body: some View {
    List {
      if !valid {
        Text(
          "This preview is no longer current. Return and search again before exporting or importing."
        )
      }
      Section("Recovered copy") {
        LabeledContent("Source", value: candidate.source)
        LabeledContent("Accounts", value: String(candidate.snapshot.accounts.count))
        LabeledContent("Dated entries", value: String(candidate.snapshot.records.count))
        LabeledContent(
          "Goal settings", value: candidate.snapshot.goal.isEmpty ? "None in this copy" : "Included"
        )
        if let first = chronologicalRecords.first?.date, let last = chronologicalRecords.last?.date
        {
          LabeledContent(
            "Saved dates",
            value: PortfolioCalculator.date(first).formatted(date: .abbreviated, time: .omitted)
              + " – " + PortfolioCalculator.date(last).formatted(date: .abbreviated, time: .omitted)
          )
        }
        Text("This is a frozen copy from your search. Export it before making changes.").font(
          .footnote
        ).foregroundStyle(.secondary)
      }
      Section("Accounts") {
        ForEach(candidate.snapshot.accounts, id: \.id) { account in
          VStack(alignment: .leading, spacing: 4) {
            Text(account.name)
            if !account.provider.isEmpty {
              Text(account.provider).font(.caption).foregroundStyle(.secondary)
            }
          }
        }
      }
      Section("Latest recovered entries") {
        ForEach(
          Array(
            candidate.snapshot.records.sorted {
              PortfolioCalculator.date($0.date) > PortfolioCalculator.date($1.date)
            }.prefix(5)), id: \.date
        ) { record in
          VStack(alignment: .leading, spacing: 6) {
            Text(
              PortfolioCalculator.date(record.date).formatted(date: .abbreviated, time: .omitted)
            ).font(.headline)
            ForEach(candidate.snapshot.accounts, id: \.id) { account in
              if let total = record.totals[account.id] {
                LabeledContent(account.name, value: total.formatted(.currency(code: "GBP")))
              }
            }
          }
        }
        Text("The export includes all recovered entries, deposits, withdrawals and goal settings.")
          .font(.footnote).foregroundStyle(.secondary)
      }
      Section {
        Button("Export recovered JSON") {
          guard recovery.canUse(revision: revision) else { return }
          document = RecoveryJSONDocument(data: candidate.archive)
          exporting = true
        }.disabled(!valid)
        if let onImport {
          Button("Review import into WealthOne") {
            guard recovery.canUse(revision: revision) else { return }
            onImport(candidate, revision)
          }.disabled(!valid)
        }
      }
    }.navigationTitle("Recovered copy").navigationBarTitleDisplayMode(.inline)
      .onChange(of: recovery.revision) { _, _ in
        exporting = false
        document = RecoveryJSONDocument(data: Data())
      }
      .fileExporter(
        isPresented: $exporting, document: document, contentType: .json,
        defaultFilename: "WealthOne-recovered"
      ) { if case .failure(let error) = $0 { exportError = error.localizedDescription } }
      .alert(
        "Export failed",
        isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })
      ) {
        Button("OK") { exportError = nil }
      } message: {
        Text(exportError ?? "")
      }
  }
}

struct RecoveryJSONDocument: FileDocument {
  static let readableContentTypes: [UTType] = [.json]
  var data: Data
  init(data: Data) { self.data = data }
  init(configuration: ReadConfiguration) throws {
    data = configuration.file.regularFileContents ?? Data()
  }
  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    FileWrapper(regularFileWithContents: data)
  }
}
