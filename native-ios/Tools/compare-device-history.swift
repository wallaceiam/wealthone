// Read-only: compile with WealthOneCore sources as main.swift. Outputs counts/booleans, never balances or identifiers.
import Foundation
let urls = CommandLine.arguments.dropFirst().map { URL(fileURLWithPath: $0) }
let stores = try urls.map { try EventStore(envelope: JSONDecoder().decode(Envelope.self, from: Data(contentsOf: $0))) }
for (index, store) in stores.enumerated() {
  print("History \(index + 1): \(store.events.count) events, \(store.projection.snapshot.accounts.count) accounts, \(store.projection.snapshot.records.count) dated entries, \(store.projection.bufferedEventIDs.count) buffered")
}
if let first = stores.first {
  let original = Dictionary(uniqueKeysWithValues: first.events.map { ($0.id, $0) })
  for (index, store) in stores.dropFirst().enumerated() {
    let current = Dictionary(uniqueKeysWithValues: store.events.map { ($0.id, $0) })
    print("History 1 vs \(index + 2): all original events preserved=\(original.allSatisfy { current[$0.key] == $0.value }), identical event histories=\(original == current), identical projections=\(first.projection.snapshot == store.projection.snapshot)")
  }
}
