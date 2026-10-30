# WealthOne native iOS migration design

## Intent

Replace the shipped React Native WealthOne application with a native iOS app because the current cross-platform app is out of date. Android is intentionally retired. Keep the existing React Native app and its source/history available during the transition, then retain its source and Git history after the native app becomes the replacement.

Preserve existing user data, especially dated account snapshots used by History and net worth calculations. On first launch, try to migrate directly from the existing iCloud Key-Value Store. If that path is unavailable or its contents cannot be decoded and validated, offer JSON import as a fallback.

## Goals

- Deliver WealthOne as a SwiftUI iOS app with native navigation, forms, charts, date selection, and file import/export.
- Add a companion watchOS app for a quick net worth/history glance, a complication, and a quick account snapshot entry.
- Preserve accounts, account types, providers, asset/liability status, every dated total/inflow/outflow record, and retirement goal inputs.
- Automatically attempt a one-time read of the legacy iCloud data before prompting for manual import.
- Provide a reliable JSON import/export path that accepts the legacy WealthOne backup and supported legacy export shape.
- Preserve the existing app source and Git history during migration. Do not remove or overwrite the React Native app until the native app is ready to replace it.
- Retire Android support; no Kotlin app is in scope.

## Non-goals

- New financial aggregation or account-linking services.
- Changes to net worth, cash flow, tax-year, or retirement projection formulas beyond reproducing current behavior.
- An Android replacement.
- Full account editing, goal editing, or chart configuration from Apple Watch.
- A product redesign unrelated to making the native app usable and current.

## Anti-goals

- Never delete, clear, or rewrite legacy iCloud values as part of migration.
- Never silently replace existing native data with an imported backup.
- Never report migration success merely because an iCloud key exists; imported account and history data must pass validation and be saved in the native store.
- Never leave users without an export path. The current React Native Settings screen lists Export but does not implement its action.

## Current application behavior and constraints

- Main areas: Home portfolio/net worth, account detail and entry editing, Breakdown, Goals and goal editing, History and historical-entry editing, Settings, About, and data import/export/backup/restore.
- The main tab order is Home, Breakdown, Goals, History, Settings.
- Portfolio state consists of accounts and dated records. Each record contains per-account totals, inflows, and outflows. Deleting an account removes its values from records; deleting an entry removes that date.
- Goal inputs include birth date, current age, retirement age, earnings, contributions, pension, investment style, and lifestyle. Projection calculations use existing bundled financial assumptions and must retain their current outputs.
- The React Native store uses `react-native-icloudstore`, which wraps `NSUbiquitousKeyValueStore`. Redux Persist stores compressed state under its persistence key. A separate `wealthone` iCloud key stores an uncompressed backup object; a legacy `backup` key is also read by the old migration action.
- The current bundle identifier is `ca.mymojo.wealthone`, signed by team `2LG9PUJ57N`; the ubiquitous key-value store identifier is derived from the team and bundle identifier. A release that replaces the installed app must retain the app identity and signing team. Development builds can use a separate bundle identifier.
- The iOS project currently has a 12.4 deployment target. The native app will target iOS 17 or later so it can use SwiftData. The user chose iOS 17 as the minimum and is comfortable raising it later if a feature or device-support decision justifies the change.
- Current import accepts both a full `{accounts, records, goal}`-style state and a legacy `categories`/`records` format, with generated account IDs and date normalization. The current Export menu item is not wired to any action.

## Approaches considered

1. **SwiftUI and watchOS replacement with direct iCloud migration and JSON fallback (selected).** Read the legacy iCloud Key-Value Store on first launch, validate and save a compatible state, then offer JSON import if no valid legacy state is found. Add the approved Watch glance and quick-entry experience. This is the requested dual-path approach and gives existing users the easiest path while retaining a recovery route.
2. **SwiftUI replacement with JSON migration only.** Simpler and independent of legacy iCloud entitlements, but requires users to export from the old app before replacing it and then import the file manually.
3. **Keep React Native as the long-term app or port Android too.** Rejected because the intent is to retire React Native across platforms and Android is not used or wanted.

## Proposed implementation

### Native project and transition

- Add a separate SwiftUI application target/project alongside the current React Native app so the old app remains runnable during development and migration.
- Use a development bundle identifier for side-by-side testing. Before replacing the installed App Store app, use the existing production bundle identifier and signing team so iOS treats it as an app update.
- Keep the React Native files in the repository during transition and preserve their Git history. Retire its build/release path only after native feature parity and data migration are accepted.
- Before transition, wire the legacy Settings Export action so users whose direct iCloud migration fails can create a versioned `.json` file and share it through the system share sheet.
- Build a native data layer with explicit account, dated record, and goal models. Keep calculations in a separate domain layer so screens do not duplicate financial formulas.
- Use an immutable event log with the user's private CloudKit database for automatic sync between their iPhone and iPad signed into the same iCloud account. Keep rebuildable read projections local; local persistence need not use SwiftData-managed CloudKit mirroring. Keep versioned JSON export/import as a portable backup and migration fallback. Set iOS 17 as the minimum; supporting earlier releases would require Core Data or a Codable file store and is out of scope based on the user's current device requirements.
- Add a companion watchOS target using SwiftUI. Keep watch interactions focused on glanceable data and one quick-entry flow; the iPhone remains the full editing experience.

### Migration rollout

- Release the wired JSON export in the existing React Native app before replacing it.
- Run a side-by-side native beta with a development bundle identifier, the legacy Key-Value Store entitlement, and the same private CloudKit container planned for production. While both apps are installed, a user can export from React Native and import into the beta if direct migration fails.
- Keep the exported JSON file available through the production app update. Move the final native build to the existing production bundle identifier only after direct migration, JSON fallback, and CloudKit sync have been exercised in the beta.
- This staged rollout is the recovery path for users who reach native onboarding after the legacy app has been replaced.

### First-launch migration

1. If a native dataset already exists, open the app normally and do not repeat migration.
2. Otherwise, read only the legacy keys needed for restoration from `NSUbiquitousKeyValueStore`: the Redux Persist value and the explicit `wealthone` backup (and `backup` only as a compatibility source).
3. Decode the Redux Persist and compressed substate format used by this repo, accounting for both Redux Persist's `persist:` key prefix and the wrapper prefix in `react-native-icloudstore`. Read the auto-persisted `persist:wealthone_data` value as the primary source because it is updated by normal app use; fall back to the explicit `wealthone` backup if the primary state is missing or invalid, then try the older `backup` key.
4. Validate required fields, IDs, numeric values, record dates, and references from record values to accounts. Preserve all valid dated records, including sparse values; do not recalculate or drop account history during migration.
5. Save the full result to native persistence in a single transaction. Verify saved counts and key fields before marking migration complete.
6. If direct migration finds no usable data, cannot access iCloud, or fails validation/save, show a clear migration state with an Import JSON action. Keep the failure reason available for the UI, but do not expose technical internals.
7. Do not remove or mutate legacy keys. Provide an optional migration summary (account count, record count, and goal settings present) so users can confirm the result.

### JSON fallback and backup

- Provide a system file importer for JSON and a JSON export through the iOS share sheet. The legacy app's Export action must share a `.json` file that can be opened by the native importer.
- Accept the current WealthOne backup shape and the legacy categories/records export shape.
- Parse and validate into a temporary dataset first. Show a preview and ask the user to replace the current dataset before saving; cancel leaves current data untouched.
- Export a versioned, documented JSON schema containing accounts, all records, goal inputs, and schema version. Include importer compatibility for existing JSON without a version field.
- Do not rely on a clipboard-only text screen. A paste option may remain secondary if convenient.

### Apple Watch companion

- Show current net worth, the most recent change, and a compact recent-history view. Add a complication for the current net worth.
- Provide a quick entry flow that selects one existing account, accepts its current total, and records the value for today. Today is the default and only supported entry date on Watch.
- Save through the paired iPhone app so Watch entry uses the same validation, persistence, and CloudKit sync path as iPhone data.
- When updating today's record, change only the selected account's total. Preserve other account totals and existing inflow/outflow values for that date. If no record exists for today, create one with the entered account total.
- Do not add account creation/deletion, goal editing, or full portfolio editing to Watch.

### Native features to carry forward

- Home: current total net worth, asset/liability account groups, account values, and net worth growth history.
- Account management: add/edit/remove accounts, provider, asset/liability, and type; add/edit dated portfolio entries and account totals/inflows/outflows.
- Breakdown: asset mix by type and account, plus liability breakdown by account.
- Goals: savings/income projection modes, poor/average scenarios, chart, and editable goal assumptions.
- History: yearly grouped snapshots with total, change amount, change percent, or netflows; open a historical entry for editing.
- Settings: account management, backup/restore status, JSON import/export, and About.
- Apple Watch: net worth/history glance, current-value complication, and one-account quick snapshot entry.
- Preserve the current look and color/font identity where it works, while using native iOS interaction patterns.

## Acceptance criteria

- A new SwiftUI app target can run independently of Metro and React Native.
- A companion watchOS app can display current net worth/history and submit a current-day account snapshot through the iPhone app.
- A user with valid legacy iCloud data sees it imported automatically, including every account, historical record, and saved goal input.
- If direct reading is unavailable or invalid, the user can import the legacy app's JSON export and gets a clear success/failure result without losing existing native data.
- The app exports a versioned JSON file that can be imported again, preserving accounts, record dates/amounts, and goal inputs.
- Home, Breakdown, Goals, History, account editing, historical-entry editing, and Settings provide feature parity with the existing iOS app.
- Android is excluded; the React Native source remains available during the transition.
- The native app is not configured for App Store replacement until the production bundle identifier, signing team, iCloud entitlement, and migration behavior are confirmed.
- A side-by-side beta can read migrated data from the same private CloudKit container and gives users access to the old app's JSON export while direct migration is being validated.

## Resolved decisions and implementation constraints

- The user has chosen iOS 17+ and wants automatic iCloud sync across their iPhone and iPad. Reconsider the minimum only when a concrete feature or support decision justifies it. This assumes both devices use the same iCloud account; sharing with another person's Apple ID would require a separate CloudKit sharing design.
- The user approved including an Apple Watch companion with a glance, complication, and quick snapshot entry. This design limits Watch entry to one existing account and today's value, preserving the rest of that day's record.
- Keep a manual export/import route for portable backups. The native implementation should use JSON files and the iOS share/file picker; it does not need to preserve the old manual iCloud key-value backup as a separate mechanism unless implementation discovers a concrete reason.
- Direct migration must be proven against real legacy values in a signed build using the same iCloud identity. The repository reveals the key-value wrapper and formats but does not include a user's actual iCloud contents.
- The legacy Export action is currently unwired and must be implemented before the transition so JSON fallback can be used in practice.
- The app has one human editor, who expects to edit an account on only one device at a time. Multi-user collaboration is outside scope. Delayed synchronization and switching devices while offline can still expose stale state, so synchronization must converge deterministically without replacing the whole portfolio.

## Event sourcing and CQRS — approved ordering

The user wants permanent, replayable history of every saved edit. Use immutable, versioned domain events as the source of truth and rebuildable local read models for screen queries. The existing implementation plans still describe mutable SwiftData domain records and require revision before implementation. Permanent history applies to committed edits, rather than individual unsaved keystrokes.

- CQRS can separate validated write commands from screen queries while retaining the current persistence design. This does not require separate databases or a message broker.
- An event-sourced alternative would persist immutable, versioned domain events as the authoritative data and derive rebuildable local read models. This would support an edit audit trail and replay, but requires explicit ordering, deduplication, event schema evolution, correction/deletion semantics, and import/reset boundaries.
- Preserve the distinction between existing dated portfolio snapshots and a future edit-event log: legacy migration can establish a baseline but cannot recover edits that the legacy app never recorded.
- Any event-sourced implementation must tolerate duplicated, delayed, and out-of-order delivery. Device clocks and CloudKit arrival order alone must not determine event causality. Local saves should update local views immediately; other devices may lag until synchronization completes.

### Recommended deterministic value rule

The user approved this rule and authorized implementation:

- Resolve edits per logical field. An account snapshot value is keyed by account ID, explicit calendar day, and total/inflow/outflow kind. Editing one field does not overwrite other fields.
- Each event has an immutable event ID, a persisted installation/actor ID, a durable Lamport counter, and explicit causal parent references to all known heads for the field it changes. Advance the local logical clock past all observed counters before assigning a new event; save the event and clock atomically. Reinstallation or loss of counter state creates a new actor ID.
- A later edit that references earlier field heads supersedes them. For independent edits, choose the greatest lexicographic tuple `(lamportCounter, actorID, eventID)` using a specified canonical byte ordering, while retaining all events. This is a deterministic display fallback, not a claim about real-world edit time or user intent.
- Keep concurrent, differing values visible in the edit history and flag them for optional review. A subsequent resolution event references all conflicting heads and records the selected value. Ordinary sequential edits require no conflict prompt.
- Missing parents are pending dependencies, not evidence of concurrency. Buffer incomplete causal chains and reproject affected fields when dependencies arrive; receiving the same complete valid event set must always yield the same result regardless of arrival order or duplicates.
- Calendar day/effective date and wall-clock edit timestamp are separate metadata; neither decides the winner. Undo/correction appends a new event and never mutates the original event.
- Field assignment is only one event rule. Account deletion/restoration, date deletion, and dataset import/replacement need explicit lifecycle/epoch rules before implementation, so late events cannot accidentally resurrect deleted or replaced data. JSON full backups must preserve the event log, event schema versions, and identifiers; a current-state-only export cannot satisfy permanent replayable history.
