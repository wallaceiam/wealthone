// Compile with WealthOneCore sources as main.swift. Read-only: never prints balances or writes imports.
import Foundation
let file = URL(fileURLWithPath: CommandLine.arguments[1])
let document = try WealthCSVDocument.parse(Data(contentsOf: file))
print("CSV: \(document.accountNames.count) account columns, \(document.rows.count) snapshots, \(document.rows.first!.day) through \(document.rows.last!.day)")
if CommandLine.arguments.count > 2 {
  let snapshot = try Archive.snapshot(from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2])))
  do {
    let plan = try WealthCSVImportPlan(document: document, snapshot: snapshot)
    print("Existing-account validation passed: \(plan.accountCount) matched; \(plan.newDateCount) new dates")
  } catch { print("Import blocked: " + error.localizedDescription) }
}
