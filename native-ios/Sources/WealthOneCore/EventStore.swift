import Foundation

public struct Envelope: Codable, Equatable, Sendable {
  public let version: Int
  public let actor: String
  public let clock: UInt64
  public let events: [Event]
  public init(
    actor: String = UUID().uuidString, clock: UInt64 = 0, events: [Event] = [], version: Int = 1
  ) {
    self.actor = actor
    self.clock = clock
    self.events = events
    self.version = version
  }
}
public final class EventStore {
  public private(set) var envelope: Envelope
  public private(set) var projection: Projection
  public var events: [Event] { envelope.events }
  private let commit: (Envelope) throws -> Void
  public init(
    envelope: Envelope = Envelope(), commit: @escaping (Envelope) throws -> Void = { _ in }
  ) throws {
    guard envelope.version == 1, !envelope.actor.isEmpty,
      envelope.events.filter({ $0.actor == envelope.actor }).allSatisfy({
        $0.counter <= envelope.clock
      })
    else { throw CoreError.invalid("Invalid installation state") }
    self.envelope = envelope
    self.projection = try Projection(events: envelope.events)
    self.commit = commit
  }
  @discardableResult public func append(_ operation: Operation, id: String = UUID().uuidString, parents explicitParents: [String]? = nil)
    throws -> Event
  {
    if let existing = events.first(where: { $0.id == id }) {
      guard existing.operation == operation else { throw CoreError.invalid("Command ID reused") }
      return existing
    }
    try validateOperation(operation)
    switch operation {
    case .remove(.account(let id), _):
      guard !hasAccountHistory(id) else { throw CoreError.invalid("This account has historical entries. Close it instead of deleting it.") }
    case .remove(.day(let rawDay), _):
      guard !isClosureDay(rawDay) else { throw CoreError.invalid("This entry records an account closure and must be kept with its history.") }
    default: break
    }
    switch operation {
    case .create(let entity, _, let values), .edit(let entity, _, let values):
      if case .day(let date) = entity {
        if projection.generation(for: entity) == nil {
          let formatter = DateFormatter()
          formatter.locale = Locale(identifier: "en_US_POSIX")
          formatter.timeZone = TimeZone(secondsFromGMT: 0)
          formatter.dateFormat = "yyyy-MM-dd"
          formatter.isLenient = false
          guard let parsed = formatter.date(from: date), formatter.string(from: parsed) == date
          else { throw CoreError.invalid("Use yyyy-MM-dd for a new day") }
        }
        for key in values.keys {
          let parts = key.split(separator: ":", maxSplits: 1).map(String.init)
          if parts.first.map({ ["fx", "fxDate", "fxSource"].contains($0) }) == true { continue }
          guard parts.count == 2, projection.generation(for: .account(parts[1])) != nil else {
            throw CoreError.invalid("Missing account")
          }
          let day = PortfolioCalculator.dayKey(PortfolioCalculator.date(date))
          if projection.snapshot.accounts.first(where: { $0.id == parts[1] })?.isClosed(on: day) == true {
            throw CoreError.invalid("This account was closed on this date. Reopen it in Settings before adding entries.")
          }
        }
      }
    default: break
    }
    switch operation {
    case .edit(let entity, let gen, _), .remove(let entity, let gen):
      guard projection.generation(for: entity) == gen else {
        throw CoreError.invalid("Missing or deleted generation")
      }
    case .create(let entity, let gen, _):
      guard !gen.isEmpty, projection.generation(for: entity) == nil,
        !events.contains(where: { event in
          switch event.operation {
          case .create(let oldEntity, let oldGeneration, _):
            return oldEntity == entity && oldGeneration == gen
          case .remove(let oldEntity, let oldGeneration):
            return oldEntity == entity && oldGeneration == gen
          default: return false
          }
        })
      else { throw CoreError.invalid("Entity already exists") }
    case .replace(let snapshot): try Archive.validate(snapshot)
    }
    let maxClock = max(envelope.clock, events.map(\.counter).max() ?? 0)
    guard maxClock < UInt64.max else { throw CoreError.invalid("Clock exhausted") }
    let integrated = events.filter { !projection.bufferedEventIDs.contains($0.id) }
    let parents = Set(integrated.flatMap(\.parents))
    let heads = integrated.filter { !parents.contains($0.id) }.map(\.id).sorted()
    let e = Event(
      id: id, actor: envelope.actor, counter: maxClock + 1, parents: explicitParents ?? heads, epoch: projection.epoch,
      operation: operation, recordedAt: Date())
    try persist(events + [e], clock: e.counter)
    return e
  }
  public func editContext(for entity: Entity) -> EditContext {
    let integrated = events.filter { !projection.bufferedEventIDs.contains($0.id) }
    let parents = Set(integrated.flatMap(\.parents))
    let generation = projection.generation(for: entity)
    var fields: [String: Value] = [:]
    for (key, value) in projection.fields where key.entity == entity && key.generation == generation {
      fields[key.field] = value
    }
    return EditContext(entity: entity, generation: generation, epoch: projection.epoch,
      parents: integrated.filter { !parents.contains($0.id) }.map(\.id).sorted(), fields: fields,
      reportingCurrency: projection.snapshot.reportingCurrency,
      accountClosures: Dictionary(uniqueKeysWithValues: projection.snapshot.accounts.map { ($0.id, $0.closureDates) }),
      accountCurrencies: Dictionary(uniqueKeysWithValues: projection.snapshot.accounts.map { ($0.id, $0.currency) }),
      accountGenerations: Dictionary(uniqueKeysWithValues: projection.snapshot.accounts.compactMap { account in
        projection.generation(for: .account(account.id)).map { (account.id, $0) }
      }))
  }
  public func submit(_ fields: [String: Value], context: EditContext) throws {
    guard projection.epoch == context.epoch,
      projection.generation(for: context.entity) == context.generation else {
      throw CoreError.invalid("This item was deleted or replaced while you were editing. Reopen it to review the current history.")
    }
    let changed = fields.filter { context.fields[$0.key] != $0.value }
    guard !changed.isEmpty else { return }
    if case .goal = context.entity, projection.snapshot.reportingCurrency != context.reportingCurrency,
      changed.keys.contains(where: { ["earnings", "contributions", "statePensionAmount"].contains($0) }) {
      throw CoreError.invalid("The main currency changed while you were editing. Reopen the goal to review amounts in the current currency.")
    }
    if case .day = context.entity {
      for field in changed.keys {
        let parts = field.split(separator: ":", maxSplits: 1).map(String.init)
        if parts.first.map({ ["fx", "fxDate", "fxSource"].contains($0) }) == true { continue }
        guard parts.count == 2, let observed = context.accountGenerations[parts[1]],
          projection.generation(for: .account(parts[1])) == observed,
          projection.snapshot.accounts.first(where: { $0.id == parts[1] })?.currency == context.accountCurrencies[parts[1]],
          projection.snapshot.accounts.first(where: { $0.id == parts[1] })?.closureDates == context.accountClosures[parts[1]] else {
          throw CoreError.invalid("An account was added, closed, reopened, changed currency or deleted while you were editing. Reopen the dated entry to review the current accounts.")
        }
      }
    }
    let operation: Operation = context.generation.map {
      .edit(context.entity, generation: $0, fields: changed)
    } ?? .create(context.entity, generation: UUID().uuidString, fields: changed)
    try append(operation, parents: context.parents)
  }
  /// Phone-side durable Watch command. Duplicate delivery is acknowledged even after midnight.
  public func applyQuickEntry(id: String, accountID: String, day: String, total: Decimal,
    today: String, calendar: Calendar = PortfolioCalculator.dayCalendar, quote: ExchangeRateQuote? = nil) throws {
    if let existing = events.first(where: { $0.id == id }) {
      let fields: [String: Value]
      switch existing.operation {
      case .edit(.day(let original), _, let values), .create(.day(let original), _, let values):
        guard PortfolioCalculator.dayKey(PortfolioCalculator.date(original), calendar: calendar) == day else {
          throw CoreError.invalid("Command ID reused")
        }
        fields = values
      default: throw CoreError.invalid("Command ID reused")
      }
      guard fields["totals:" + accountID] == .decimal(total), fields.keys.allSatisfy({
        $0 == "totals:" + accountID || $0.hasPrefix("fx:") || $0.hasPrefix("fxDate:") || $0.hasPrefix("fxSource:")
      }) else { throw CoreError.invalid("Command ID reused") }
      return
    }
    guard day == today, !total.isNaN,
      projection.snapshot.accounts.contains(where: { $0.id == accountID && !$0.isClosed(on: day) }) else {
      throw CoreError.invalid("This entry is no longer valid. Open the iPhone app to review it.")
    }
    let rawDay = PortfolioCalculator.record(on: day, records: projection.snapshot.records, calendar: calendar)?.date ?? day
    let entity = Entity.day(rawDay)
    var fields: [String: Value] = ["totals:" + accountID: .decimal(total)]
    let required = Set(projection.snapshot.accounts.filter { !$0.isClosed(on: day) }.map(\.currency) + [projection.snapshot.reportingCurrency]).subtracting(["GBP"])
    let existing = projection.snapshot.records.first { $0.date == rawDay }
    if let quote { try quote.validate() }
    for code in required where existing?.exchangeRates[code] == nil {
      guard let quote, let rate = quote.ratesToGBP[code] else { throw CoreError.invalid("Open the iPhone app to save an exchange rate for " + code) }
      fields["fx:" + code] = .decimal(rate)
      fields["fxDate:" + code] = .string(quote.date)
      fields["fxSource:" + code] = .string(quote.source)
    }
    if let generation = projection.generation(for: entity) {
      try append(.edit(entity, generation: generation, fields: fields), id: id)
    } else {
      try append(.create(entity, generation: id, fields: fields), id: id)
    }
  }
  /// One durable transaction for an explicit historical rate fill/refresh. Existing
  /// immutable observations stay in the log; only new rate-edit events are appended.
  public func saveExchangeRates(_ quote: ExchangeRateQuote, refreshExisting: Bool) throws {
    try quote.validate()
    let required = Set(projection.snapshot.accounts.map(\.currency) + [projection.snapshot.reportingCurrency]).subtracting(["GBP"])
    guard required.allSatisfy({ quote.ratesToGBP[$0] != nil }) else { throw CoreError.invalid("A required currency rate is missing") }
    var candidates = events
    var clock = max(envelope.clock, events.map(\.counter).max() ?? 0)
    let integrated = events.filter { !projection.bufferedEventIDs.contains($0.id) }
    let parentIDs = Set(integrated.flatMap(\.parents))
    var heads = integrated.filter { !parentIDs.contains($0.id) }.map(\.id).sorted()
    for record in projection.snapshot.records {
      let currencies = required.filter { refreshExisting || record.exchangeRates[$0] == nil }.sorted()
      guard !currencies.isEmpty, let generation = projection.generation(for: .day(record.date)) else { continue }
      var fields: [String: Value] = [:]
      for code in currencies {
        fields["fx:" + code] = .decimal(quote.ratesToGBP[code]!)
        fields["fxDate:" + code] = .string(quote.date)
        fields["fxSource:" + code] = .string(quote.source)
      }
      let operation = Operation.edit(.day(record.date), generation: generation, fields: fields)
      try validateOperation(operation)
      guard clock < UInt64.max else { throw CoreError.invalid("Clock exhausted") }
      clock += 1
      let event = Event(actor: envelope.actor, counter: clock, parents: heads, epoch: projection.epoch,
        operation: operation, recordedAt: Date())
      candidates.append(event)
      heads = [event.id]
    }
    if candidates.count != events.count { try persist(candidates, clock: clock) }
  }
  public func hasAccountHistory(_ id: String) -> Bool {
    events.contains { event in
      switch event.operation {
      case .replace(let snapshot): return snapshot.records.contains { $0.totals[id] != nil || $0.inflows[id] != nil || $0.outflows[id] != nil }
      case .create(.day, _, let fields), .edit(.day, _, let fields):
        return ["totals:", "inflows:", "outflows:"].contains { fields[$0 + id] != nil && fields[$0 + id] != .null }
      default: return false
      }
    }
  }
  public func isClosureDay(_ rawDay: String) -> Bool {
    projection.snapshot.accounts.contains { $0.closureRecords.values.contains(rawDay) || $0.closureDates[rawDay] == true } || events.contains {
      guard $0.epoch == projection.epoch else { return false }
      switch $0.operation {
      case .edit(.account, _, let fields), .create(.account, _, let fields):
        return fields.contains { $0.key.hasPrefix("closureRecord:") && $0.value == .string(rawDay) }
      default: return false
      }
    }
  }
  /// The zero observation, closing outflow and dated status become visible together or not at all.
  public func setAccountClosed(_ id: String, closed: Bool, day: String, today: String = PortfolioCalculator.dayKey(), context: EditContext) throws {
    guard context.entity == .account(id), context.epoch == projection.epoch,
      context.generation == projection.generation(for: .account(id)),
      let generation = context.generation, let account = projection.snapshot.accounts.first(where: { $0.id == id }),
      context.accountClosures[id] == account.closureDates,
      context.accountCurrencies[id] == account.currency else { throw CoreError.invalid("The account changed. Reopen its settings before closing or reopening it.") }
    guard validLifecycleDate(day), day <= today,
      account.closureDates.keys.allSatisfy({ $0 <= day }), account.isClosed(on: day) != closed else {
      throw CoreError.invalid("Choose a valid date through today after the last account change.")
    }
    let dated = PortfolioCalculator.dated(projection.snapshot.records)
    let accountDates = dated.filter { $0.record.totals[id] != nil || $0.record.inflows[id] != nil || $0.record.outflows[id] != nil }
    guard accountDates.allSatisfy({ PortfolioCalculator.dayKey($0.date) <= day }) else {
      throw CoreError.invalid("Choose a date on or after this account's latest entry.")
    }
    var operations: [Operation] = []
    var statusFields: [String: Value] = ["closed:" + day: .bool(closed)]
    if closed {
      let prior = dated.filter { PortfolioCalculator.dayKey($0.date) <= day }
      let existing = prior.last { PortfolioCalculator.dayKey($0.date) == day }?.record
      let remaining = PortfolioCalculator.balance(of: account, on: day, records: projection.snapshot.records)
      var fields: [String: Value] = ["totals:" + id: .decimal(0)]
      if remaining != 0 { fields["outflows:" + id] = .decimal((existing?.outflows[id] ?? 0) + remaining) }
      // Carry forward saved reference rates; do not fetch or silently refresh history at closure.
      let currencies = Set(projection.snapshot.accounts.map(\.currency) + [projection.snapshot.reportingCurrency]).subtracting(["GBP"])
      for code in currencies where existing?.exchangeRates[code] == nil {
        if let source = prior.reversed().first(where: { $0.record.exchangeRates[code] != nil })?.record {
          fields["fx:" + code] = .decimal(source.exchangeRates[code]!)
          fields["fxDate:" + code] = .string(source.exchangeRateDates[code] ?? PortfolioCalculator.dayKey(PortfolioCalculator.date(source.date)))
          fields["fxSource:" + code] = .string(source.exchangeRateSources[code] ?? "Saved rate")
        }
      }
      let rawDay = existing?.date ?? day
      statusFields["closureRecord:" + day] = .string(rawDay)
      let entity = Entity.day(rawDay)
      operations.append(projection.generation(for: entity).map { .edit(entity, generation: $0, fields: fields) }
        ?? .create(entity, generation: UUID().uuidString, fields: fields))
    }
    operations.append(.edit(.account(id), generation: generation, fields: statusFields))
    var candidates = events
    var clock = max(envelope.clock, events.map(\.counter).max() ?? 0)
    let integrated = events.filter { !projection.bufferedEventIDs.contains($0.id) }
    let parentIDs = Set(integrated.flatMap(\.parents))
    var heads = integrated.filter { !parentIDs.contains($0.id) }.map(\.id).sorted()
    for operation in operations {
      try validateOperation(operation)
      guard clock < UInt64.max else { throw CoreError.invalid("Clock exhausted") }
      clock += 1
      let event = Event(actor: envelope.actor, counter: clock, parents: heads, epoch: projection.epoch, operation: operation, recordedAt: Date())
      candidates.append(event); heads = [event.id]
    }
    try persist(candidates, clock: clock)
  }
  /// Merge a reviewed CSV proposal as one durable transaction. It cannot create accounts.
  public func importCSV(_ plan: WealthCSVImportPlan) throws {
    guard projection.snapshot == plan.baseline else { throw CoreError.invalid("The portfolio changed after this preview. Review the CSV again before importing.") }
    guard !plan.updates.isEmpty else { return }
    var candidates = events
    var clock = max(envelope.clock, events.map(\.counter).max() ?? 0)
    let integrated = events.filter { !projection.bufferedEventIDs.contains($0.id) }
    let parentIDs = Set(integrated.flatMap(\.parents))
    var heads = integrated.filter { !parentIDs.contains($0.id) }.map(\.id).sorted()
    for update in plan.updates {
      let entity = Entity.day(update.date)
      var fields = Dictionary(uniqueKeysWithValues: update.totals.map { ("totals:" + $0.key, Value.decimal($0.value)) })
      for (code, rate) in update.exchangeRates { fields["fx:" + code] = .decimal(rate) }
      for (code, date) in update.exchangeRateDates { fields["fxDate:" + code] = .string(date) }
      for (code, source) in update.exchangeRateSources { fields["fxSource:" + code] = .string(source) }
      let operation: Operation = projection.generation(for: entity).map { .edit(entity, generation: $0, fields: fields) }
        ?? .create(entity, generation: UUID().uuidString, fields: fields)
      try validateOperation(operation)
      guard clock < UInt64.max else { throw CoreError.invalid("Clock exhausted") }
      clock += 1
      let event = Event(actor: envelope.actor, counter: clock, parents: heads, epoch: projection.epoch, operation: operation, recordedAt: Date())
      candidates.append(event); heads = [event.id]
    }
    try persist(candidates, clock: clock)
  }
  @discardableResult public func merge(_ incoming: [Event]) throws -> Bool {
    var map: [String: Event] = [:]
    for event in events { map[event.id] = event }
    for event in incoming {
      if let old = map[event.id], old != event { throw CoreError.invalid("Event ID collision") }
      map[event.id] = event
    }
    let clock = max(envelope.clock, incoming.map(\.counter).max() ?? 0)
    guard map.count != events.count else {
      if clock != envelope.clock {
        let candidate = Envelope(actor: envelope.actor, clock: clock, events: events)
        try commit(candidate)
        envelope = candidate
      }
      return false
    }
    try persist(map.values.sorted(by: canonical), clock: clock)
    return true
  }
  @discardableResult public func replace(_ snapshot: Snapshot) throws -> Event {
    try append(.replace(snapshot))
  }
  @discardableResult public func resolve(_ key: FieldKey, value: Value) throws -> Event {
    try append(.edit(key.entity, generation: key.generation, fields: [key.field: value]))
  }
  private func persist(_ events: [Event], clock: UInt64) throws {
    let projection = try Projection(events: events)
    let candidate = Envelope(actor: envelope.actor, clock: clock, events: events)
    try commit(candidate)
    self.envelope = candidate
    self.projection = projection
  }
}
public struct JSONFileRepository: Sendable {
  public let url: URL
  public init(url: URL) { self.url = url }
  public func load() throws -> Envelope {
    let e = try JSONDecoder().decode(Envelope.self, from: Data(contentsOf: url))
    _ = try EventStore(envelope: e)
    return e
  }
  /// Preserve the unreadable file before installing a validated replacement atomically.
  @discardableResult public func recover(_ envelope: Envelope) throws -> URL {
    _ = try EventStore(envelope: envelope)
    let backup = url.deletingLastPathComponent().appendingPathComponent("history-unreadable-" + UUID().uuidString + ".json")
    try FileManager.default.copyItem(at: url, to: backup)
    try save(envelope)
    _ = try load()
    return backup
  }
  public func save(_ envelope: Envelope) throws {
    _ = try EventStore(envelope: envelope)
    try JSONEncoder().encode(envelope).write(to: url, options: .atomic)
  }
}

/// Captures both the form's lifecycle and the history the user actually saw.
public struct EditContext: Sendable {
  public let entity: Entity
  public let generation: String?
  public let epoch: String
  public let parents: [String]
  public let fields: [String: Value]
  public let reportingCurrency: String
  public let accountClosures: [String: [String: Bool]]
  public let accountCurrencies: [String: String]
  public let accountGenerations: [String: String]
}
