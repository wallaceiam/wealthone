import Foundation

public struct FieldVersion: Codable, Equatable, Sendable {
  public let event: Event
  public let value: Value
}
public struct Projection: Equatable, Sendable {
  public private(set) var snapshot = Snapshot()
  public private(set) var fields: [FieldKey: Value] = [:]
  public private(set) var conflicts: [FieldKey: [FieldVersion]] = [:]
  public private(set) var bufferedEventIDs: Set<String> = []
  public private(set) var epoch = "root"
  private var generations: [Entity: String] = [:]
  public func generation(for entity: Entity) -> String? { generations[entity] }
  public init(events: [Event]) throws {
    var all: [String: Event] = [:]
    var actorClocks: [String: [UInt64: String]] = [:]
    for e in events {
      guard e.version == 1, !e.id.isEmpty, !e.actor.isEmpty, e.counter > 0,
        Set(e.parents).count == e.parents.count, !e.parents.contains(e.id)
      else { throw CoreError.invalid("Invalid event") }
      if let old = all[e.id], old != e { throw CoreError.invalid("Event ID collision") }
      if let previous = actorClocks[e.actor]?[e.counter], previous != e.id {
        throw CoreError.invalid("Actor clock reused")
      }
      actorClocks[e.actor, default: [:]][e.counter] = e.id
      try validateOperation(e.operation)
      all[e.id] = e
    }
    var ancestors: [String: Set<String>] = [:]
    var active: [Event] = []
    var remaining = all
    while true {
      let ready = remaining.values.filter { $0.parents.allSatisfy { ancestors[$0] != nil } }.sorted(
        by: canonical)
      if ready.isEmpty { break }
      for e in ready {
        if e.epoch != "root" {
          guard let epochEvent = all[e.epoch], case .replace = epochEvent.operation else {
            throw CoreError.invalid("Unknown epoch")
          }
        }
        var a = Set(e.parents)
        for p in e.parents {
          guard all[p]!.counter < e.counter else {
            throw CoreError.invalid("Nonmonotonic parent clock")
          }
          a.formUnion(ancestors[p]!)
        }
        if e.epoch != "root", !a.contains(e.epoch) {
          throw CoreError.invalid("Epoch must be causal")
        }
        ancestors[e.id] = a
        active.append(e)
        remaining.removeValue(forKey: e.id)
      }
    }
    // A cycle with no missing external dependency is corruption, not a buffer.
    for e in remaining.values {
      var visiting = Set<String>()
      func visit(_ id: String) throws {
        if visiting.contains(id) { throw CoreError.invalid("Causal cycle") }
        guard let x = remaining[id] else { return }
        visiting.insert(id)
        for p in x.parents { try visit(p) }
        visiting.remove(id)
      }
      try visit(e.id)
    }
    // Validate partial account edits against their causal state, independent of delivery order.
    for event in active {
      guard case .edit(.account(let id), let generation, let update) = event.operation else {
        continue
      }
      var candidates: [String: [FieldVersion]] = [:]
      for predecessor in active where ancestors[event.id]!.contains(predecessor.id) {
        var values: [String: Value] = [:]
        switch predecessor.operation {
        case .replace(let baseline) where predecessor.id == generation:
          if let account = baseline.accounts.first(where: { $0.id == id }) {
            values = [
              "isAsset": .bool(account.isAsset), "currency": .string(account.currency),
              "accountType": .decimal(Decimal(account.accountType)),
            ]
          }
        case .create(.account(let priorID), let priorGeneration, let fields)
        where priorID == id && priorGeneration == generation:
          values = fields
          let asset = fields["isAsset"]?.bool ?? true
          if values["isAsset"] == nil { values["isAsset"] = .bool(asset) }
          if values["accountType"] == nil { values["accountType"] = .decimal(asset ? 0 : 7) }
        case .edit(.account(let priorID), let priorGeneration, let fields)
        where priorID == id && priorGeneration == generation: values = fields
        default: break
        }
        for (key, value) in values {
          candidates[key, default: []].append(FieldVersion(event: predecessor, value: value))
        }
      }
      var inherited: [String: Value] = [:]
      for (key, options) in candidates {
        let maxima = options.filter { x in
          !options.contains { ancestors[$0.event.id]!.contains(x.event.id) }
        }
        inherited[key] = maxima.max(by: { canonical($0.event, $1.event) })?.value
      }
      if let type = inherited["accountType"]?.decimal {
        inherited["isAsset"] = .bool(try validatedAccountType(type) < 7)
      }
      inherited.merge(update, uniquingKeysWith: { $1 })
      try validateAccountClassification(inherited)
    }
    bufferedEventIDs = Set(remaining.keys)
    let replacements = active.filter {
      if case .replace = $0.operation { return true }
      return false
    }
    let replacement = replacements.filter { e in
      !replacements.contains { ancestors[$0.id]!.contains(e.id) }
    }.max(by: canonical)
    if let replacement { epoch = replacement.id }
    var versions: [FieldKey: [FieldVersion]] = [:]
    var creates: [Entity: [(String, Event)]] = [:]
    var deleted = Set<String>()
    func add(_ entity: Entity, _ generation: String, _ values: [String: Value], _ event: Event) {
      for (key, value) in values {
        versions[FieldKey(entity: entity, generation: generation, field: key), default: []].append(
          FieldVersion(event: event, value: value))
      }
    }
    if let replacement, case .replace(let baseline) = replacement.operation {
      for account in baseline.accounts {
        let entity = Entity.account(account.id)
        creates[entity] = [(replacement.id, replacement)]
        add(
          entity, replacement.id,
          [
            "name": .string(account.name), "provider": .string(account.provider),
            "isAsset": .bool(account.isAsset), "currency": .string(account.currency),
            "accountType": .decimal(Decimal(account.accountType)),
          ], replacement)
        add(entity, replacement.id, Dictionary(uniqueKeysWithValues: account.closureDates.map { ("closed:" + $0.key, Value.bool($0.value)) }), replacement)
        add(entity, replacement.id, Dictionary(uniqueKeysWithValues: account.closureRecords.map { ("closureRecord:" + $0.key, Value.string($0.value)) }), replacement)
      }
      for day in baseline.records {
        let entity = Entity.day(day.date)
        creates[entity] = [(replacement.id, replacement)]
        var values: [String: Value] = [:]
        for (prefix, map) in [
          ("totals", day.totals), ("inflows", day.inflows), ("outflows", day.outflows),
        ] { for (id, n) in map { values[prefix + ":" + id] = .decimal(n) } }
        for (currency, rate) in day.exchangeRates { values["fx:" + currency] = .decimal(rate) }
        for (currency, date) in day.exchangeRateDates { values["fxDate:" + currency] = .string(date) }
        for (currency, source) in day.exchangeRateSources { values["fxSource:" + currency] = .string(source) }
        add(entity, replacement.id, values, replacement)
      }
      creates[.goal] = [(replacement.id, replacement)]
      add(.goal, replacement.id, baseline.goal, replacement)
    }
    func token(_ entity: Entity, _ gen: String) -> String { String(describing: entity) + "|" + gen }
    for e in active where e.epoch == epoch {
      switch e.operation {
      case .replace: break
      case .create(let entity, let gen, let values):
        creates[entity, default: []].append((gen, e))
        add(entity, gen, values, e)
      case .edit(let entity, let gen, let values): add(entity, gen, values, e)
      case .remove(let entity, let gen): deleted.insert(token(entity, gen))
      }
    }
    // A closing settlement is permanent history. A concurrent whole-day deletion
    // cannot remove the zero/outflow on which a retained closure status depends.
    var protectedDays = Set<Entity>()
    for event in active {
      switch event.operation {
      case .replace(let baseline) where event.id == epoch:
        for account in baseline.accounts {
          protectedDays.formUnion(account.closureRecords.values.map { Entity.day($0) })
        }
      case .create(.account, _, let fields), .edit(.account, _, let fields):
        guard event.epoch == epoch else { continue }
        for (key, value) in fields where key.hasPrefix("closureRecord:") {
          if case .string(let raw) = value { protectedDays.insert(.day(raw)) }
        }
      default: break
      }
    }
    let versionKeysByEntity = Dictionary(grouping: versions.keys, by: { $0.entity })
    var generationSources: [Entity: [Event]] = [:]
    // Day creation IDs are aliases for a lifecycle defined by the removals observed
    // at creation. Concurrent initial creates therefore share fields, while a
    // post-delete create is a new lifecycle even when an old create arrives late.
    for (entity, options) in creates {
      if case .day = entity {
        let removals = active.filter { event in
          guard event.epoch == epoch, !protectedDays.contains(entity) else { return false }
          if case .remove(let target, _) = event.operation { return target == entity }
          return false
        }
        func observedRemovals(_ event: Event) -> Set<String> {
          Set(removals.filter { ancestors[event.id]!.contains($0.id) }.map(\.id))
        }
        var groups: [Set<String>: [(String, Event)]] = [:]
        for option in options { groups[observedRemovals(option.1), default: []].append(option) }
        let maximalGroups = groups.keys.filter { candidate in
          !groups.keys.contains { candidate != $0 && candidate.isSubset(of: $0) }
        }
        guard
          let selected = maximalGroups.max(by: { left, right in
            canonical(
              groups[left]!.map { $0.1 }.max(by: canonical)!,
              groups[right]!.map { $0.1 }.max(by: canonical)!)
          }), let lifecycle = groups[selected],
          let chosen = lifecycle.max(by: { canonical($0.1, $1.1) })
        else { continue }
        let removed = removals.contains { removal in
          guard case .remove(_, let gen) = removal.operation else { return false }
          return lifecycle.contains { $0.0 == gen && ancestors[removal.id]!.contains($0.1.id) }
        }
        guard !removed else { continue }
        generations[entity] = chosen.0
        generationSources[entity] = lifecycle.map { $0.1 }
        var normalized: [FieldKey: [FieldVersion]] = [:]
        for key in versionKeysByEntity[entity] ?? [] {
          let values = versions[key] ?? []
          let eligible = values.filter { value in
            lifecycle.contains { create in
              create.0 == key.generation
                && (value.event.id == create.1.id
                  || ancestors[value.event.id]!.contains(create.1.id))
            }
          }
          normalized[FieldKey(entity: entity, generation: chosen.0, field: key.field), default: []]
            .append(contentsOf: eligible)
        }
        for key in versionKeysByEntity[entity] ?? [] { versions.removeValue(forKey: key) }
        for (key, values) in normalized { versions[key] = values }
      } else if let chosen = options.max(by: { canonical($0.1, $1.1) }),
        !deleted.contains(token(entity, chosen.0))
      {
        generations[entity] = chosen.0
        generationSources[entity] = [chosen.1]
      }
    }
    for (key, options) in versions where generations[key.entity] == key.generation {
      let eligible = options.filter { option in
        guard let sources = generationSources[key.entity],
          sources.contains(where: {
            option.event.id == $0.id || ancestors[option.event.id]!.contains($0.id)
          })
        else { return false }
        if case .day = key.entity {
          let parts = key.field.split(separator: ":", maxSplits: 1).map(String.init)
          if parts.count == 2 && ["totals", "inflows", "outflows"].contains(parts[0]) {
            guard let accountSource = generationSources[.account(parts[1])]?.first,
              option.event.id == accountSource.id
                || ancestors[option.event.id]!.contains(accountSource.id)
            else { return false }
          }
        }
        return true
      }
      let maxima = eligible.filter { x in
        !eligible.contains { ancestors[$0.event.id]!.contains(x.event.id) }
      }.sorted { canonical($0.event, $1.event) }
      if let winner = maxima.last {
        fields[key] = winner.value
        if maxima.contains(where: { $0.value != winner.value }) { conflicts[key] = maxima }
      }
    }
    let fieldsByEntity = Dictionary(grouping: fields, by: { $0.key.entity })
    for (entity, gen) in generations {
      func value(_ name: String) -> Value? {
        fields[FieldKey(entity: entity, generation: gen, field: name)]
      }
      switch entity {
      case .account(let id):
        snapshot.accounts.append(
          Account(
            id: id, name: value("name")?.string ?? "", provider: value("provider")?.string ?? "",
            isAsset: (try validatedAccountType(
              value("accountType")?.decimal ?? ((value("isAsset")?.bool ?? true) ? 0 : 7))) < 7,
            accountType: try validatedAccountType(
              value("accountType")?.decimal ?? ((value("isAsset")?.bool ?? true) ? 0 : 7)),
            currency: value("currency")?.string ?? "GBP",
            closureDates: Dictionary(uniqueKeysWithValues: (fieldsByEntity[entity] ?? []).compactMap { key, value in
              guard key.field.hasPrefix("closed:"), case .bool(let closed) = value else { return nil }
              return (String(key.field.dropFirst(7)), closed)
            }),
            closureRecords: Dictionary(uniqueKeysWithValues: (fieldsByEntity[entity] ?? []).compactMap { key, value in
              guard key.field.hasPrefix("closureRecord:"), case .string(let raw) = value else { return nil }
              return (String(key.field.dropFirst(14)), raw)
            })))
      case .day(let date):
        var d = DayRecord(date: date)
        for (k, v) in fieldsByEntity[entity] ?? [] {
          let parts = k.field.split(separator: ":", maxSplits: 1).map(String.init)
          guard parts.count == 2 else { continue }
          if parts[0] == "fx", case .decimal(let rate) = v { d.exchangeRates[parts[1]] = rate; continue }
          if parts[0] == "fxDate", case .string(let date) = v { d.exchangeRateDates[parts[1]] = date; continue }
          if parts[0] == "fxSource", case .string(let source) = v { d.exchangeRateSources[parts[1]] = source; continue }
          guard case .decimal(let n) = v, generations[.account(parts[1])] != nil else { continue }
          switch parts[0] {
          case "totals": d.totals[parts[1]] = n
          case "inflows": d.inflows[parts[1]] = n
          case "outflows": d.outflows[parts[1]] = n
          default: break
          }
        }
        snapshot.records.append(d)
      case .goal: for (k, v) in fieldsByEntity[.goal] ?? [] { snapshot.goal[k.field] = v }
      }
    }
    snapshot.accounts.sort { $0.id.utf8.lexicographicallyPrecedes($1.id.utf8) }
    snapshot.records.sort { $0.date.utf8.lexicographicallyPrecedes($1.date.utf8) }
  }
}
