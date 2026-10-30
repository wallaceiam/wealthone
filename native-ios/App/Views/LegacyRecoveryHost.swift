import SwiftUI
import WealthOneCore

struct LegacyRecoveryHost: View {
  @EnvironmentObject var model: AppModel
  @StateObject private var recovery = LegacyRecoveryModel()
  @State private var selection: RecoveredImportSelection?
  var body: some View {
    LegacyRecoveryBrowser(recovery: recovery) { candidate, revision in
      selection = RecoveredImportSelection(candidate: candidate, revision: revision)
    }
    .sheet(item: $selection) { selected in
      NavigationStack {
        RecoveredImportReview(selection: selected, recovery: recovery).environmentObject(model)
      }
    }
    .onChange(of: recovery.revision) { _, _ in selection = nil }
  }
}
private struct RecoveredImportSelection: Identifiable {
  let id = UUID()
  let candidate: LegacyRecoveredCandidate
  let revision: Int
}
private struct RecoveredImportReview: View {
  let selection: RecoveredImportSelection
  @ObservedObject var recovery: LegacyRecoveryModel
  @EnvironmentObject var model: AppModel
  @Environment(\.dismiss) private var dismiss
  @State private var confirming = false
  @State private var failure: String?
  @State private var completed: String?
  private var valid: Bool { recovery.canUse(revision: selection.revision) }
  var body: some View {
    Form {
      Section("Recovered portfolio") {
        LabeledContent("Accounts", value: String(selection.candidate.snapshot.accounts.count))
        LabeledContent("Dated entries", value: String(selection.candidate.snapshot.records.count))
        if selection.candidate.snapshot.goal.isEmpty {
          Text("This copy has no goal settings. Your current goal settings will be kept.")
        }
      }
      Section("Current portfolio") {
        LabeledContent("Accounts", value: String(model.snapshot.accounts.count))
        LabeledContent("Dated entries", value: String(model.snapshot.records.count))
        Text(
          "Import replaces the current accounts and dated entries. Existing edits remain in permanent history. A separate full-history backup is saved on this device before importing."
        )
        NavigationLink("Export current history first") { BackupView() }
      }
      if model.storageUnavailable {
        Section {
          Text(
            "Current storage is unreadable. Export the recovered JSON, then restore it through Backups so the unreadable original is preserved."
          )
          NavigationLink("Open Backups") { BackupView() }
        }
      }
      if let completed {
        Section { Label(completed, systemImage: "checkmark.circle") }
      } else {
        Section {
          if !valid {
            Text("The recovery account or search changed. Close this review and search again.")
          }
          Button("Import recovered portfolio", role: .destructive) { confirming = true }
            .disabled(!valid || model.storageUnavailable)
        }
      }
    }.navigationTitle("Review recovery").navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(completed == nil ? "Cancel" : "Done") { dismiss() }
        }
      }
      .confirmationDialog(
        "Replace the current portfolio?", isPresented: $confirming, titleVisibility: .visible
      ) {
        Button("Back up and import", role: .destructive) {
          guard recovery.canUse(revision: selection.revision) else {
            failure = "The iCloud account or search changed. Search again before importing."
            return
          }
          do {
            let backup = try model.importRecoveredLegacy(selection.candidate)
            completed = "Recovered portfolio imported. Previous history backup: " + backup
          } catch { failure = error.localizedDescription }
        }
      } message: {
        Text("The import will stop if the current history backup cannot be saved.")
      }
      .alert(
        "Recovery import failed",
        isPresented: Binding(get: { failure != nil }, set: { if !$0 { failure = nil } })
      ) {
        Button("OK") { failure = nil }
      } message: {
        Text(failure ?? "")
      }
  }
}
