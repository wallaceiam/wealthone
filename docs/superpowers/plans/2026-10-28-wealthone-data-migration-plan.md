# WealthOne Data Foundation and Migration Implementation Plan

> **Updated architecture:** The approved [event-sourcing plan](./2026-10-28-wealthone-event-sourcing-plan.md) supersedes mutable SwiftData persistence, state-only native backup, and store interfaces below. These earlier plans retain legacy behavior and screen requirements; implement through immutable events and local projections.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the native data foundation and preserve user data through direct legacy iCloud migration with JSON import/export fallback.

**Architecture:** Add a standalone SwiftUI app target and a CloudKit-backed SwiftData store with stable account and entry identifiers. Decode the legacy Key-Value Store state without mutating it, validate a complete candidate archive before saving, and provide versioned JSON import/export; make the existing React Native Export action produce that archive format during transition.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, CloudKit, Foundation Codable, existing React Native / TypeScript, iOS 17+.

**Spec:** [2026-10-28-wealthone-native-ios-design.md](../specs/2026-10-28-wealthone-native-ios-design.md)

## Global Constraints

- The native app will target iOS 17 or later so it can use SwiftData.
- Use SwiftData with the user's private CloudKit database for automatic sync between their iPhone and iPad signed into the same iCloud account.
- Keep versioned JSON export/import as a portable backup and migration fallback.
- Never delete, clear, or rewrite legacy iCloud values as part of migration.
- Never silently replace existing native data with an imported backup.
- Preserve every valid dated record, including sparse values, and existing goal inputs.
- Keep the React Native files in the repository during transition and preserve their Git history.

## Review Focus

- Missing iCloud data, malformed UTF-16 compressed state, and unsupported store envelopes must fall through to JSON without setting the migration marker.
- Invalid account references and sparse totals/inflow/outflow arrays must be rejected or preserved according to the archive decoder's explicit rules, never silently shifted to another account.
- Import cancellation or persistence failure must leave the pre-import native dataset intact.
- Dates must group by local calendar day using the legacy `justDate`/`sameDay` behavior, including timezone and daylight-saving transitions.
- A primary Redux persisted state must take precedence over the `wealthone` manual backup; the older `backup` key is last-resort compatibility data.

---

### Task 1: Produce a usable legacy JSON export

**Files:**
- Modify: `src/Screens/Settings/SettingsScreen.tsx`
- Create: `src/Redux/WealthOneArchive.ts`
- Create: `src/NativeModules/LegacyJSONExporter.ts`
- Create: `ios/wealthone/LegacyJSONExporter.m`
- Modify: `ios/wealthone.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces: `createWealthOneArchive(state: {accounts: IAccount[]; records: IRecord[]; goal: IGoalInput}): string`, returning JSON with `schemaVersion: 1`, `accounts`, `records`, and `goal`.
- Existing Export Settings row calls the archive builder and the native module writes a temporary `.json` file and presents the system share sheet for that file.

- [ ] Wire the existing `export` action to `createWealthOneArchive` and `LegacyJSONExporter.share(json:filename:)`; map the complete account, record, and goal state into Settings without changing import or backup behavior.
- [ ] Implement the native exporter to write UTF-8 JSON to a temporary file, present `UIActivityViewController` on the main thread, and anchor the iPad popover to the Settings Export row.
- [ ] Manually verify that the share sheet exposes a real `.json` file that can be saved to Files/AirDrop and imported by the new native app; preserve unrelated existing working-tree changes.

### Task 2: Add a standalone native application shell and persistence models

**Files:**
- Create: `native-ios/WealthOne.xcodeproj`
- Create: `native-ios/WealthOne/WealthOneApp.swift`
- Create: `native-ios/WealthOne/RootTabView.swift`
- Create: `native-ios/WealthOne/Models/PortfolioAccount.swift`
- Create: `native-ios/WealthOne/Models/PortfolioDay.swift`
- Create: `native-ios/WealthOne/Models/PortfolioEntry.swift`
- Create: `native-ios/WealthOne/Models/GoalSettings.swift`
- Create: `native-ios/WealthOne/Data/PortfolioStore.swift`
- Create: `native-ios/WealthOne/Resources/Assets.xcassets/`

**Interfaces:**
- Produces `PortfolioDay` with stable local-day key and normalized date, and `PortfolioEntryValue` as a Codable value: `id: String`, `dayKey: String`, `accountID: String`, `kind: EntryValueKind`, `amount: Double`.
- `PortfolioDay` records every historical date, even if that day's total/inflow/outflow arrays are empty or sparse. Store one `PortfolioEntryValue` per present account/kind amount; a missing value remains absent.
- `PortfolioAccount` stores `id: String`, `name: String`, `provider: String`, `isAsset: Bool`, and `accountType: Int` (legacy type IDs 0–9).
- `PortfolioDay` stores `id: String`, `dayKey: String`, and normalized `date: Date`. `PortfolioEntry` stores `id`, `dayKey`, `accountID`, `kind`, and `amount`.
- `GoalSettings` stores the goal inputs from `IGoalInput`; retain `pension` even though the legacy editor does not expose it.
- `EntryValueKind` has `total`, `inflow`, and `outflow` cases.
- `PortfolioStore` exposes `accounts() throws -> [PortfolioAccount]`, `days() throws -> [PortfolioDay]`, `entries(on date: Date) throws -> [PortfolioEntryValue]`, `saveAccount(_ account: PortfolioAccount) throws`, `setEntryValue(dayKey: String, accountID: String, kind: EntryValueKind, amount: Double?) throws`, `deleteAccount(id: String) throws`, `deleteEntry(date: Date) throws`, `replaceAll(with archive: WealthOneArchive) throws`, and `makeArchive() throws -> WealthOneArchive` on the main actor. A nil amount deletes only that account/kind cell; it does not delete the day.
- Store dates by local calendar day and account values by stable account ID. Account deletion removes its values from every date, matching the legacy reducer. Do not use CloudKit-incompatible unique constraints as the only duplicate protection; perform app-level upserts by stable ID.

- [ ] Create an independent SwiftUI target at `native-ios/` with a development bundle identifier, iOS 17 deployment target, and an empty root view; leave the React Native Xcode project runnable.
- [ ] Add simple SwiftData models and a `PortfolioStore` backed by a private CloudKit container. Keep goal inputs as a single logical settings record and account total/flow values as independently mergeable entries.
- [ ] Manually verify the native target builds and launches without Metro, creates the CloudKit-backed store when signed in, and still opens local data when CloudKit is unavailable.

### Task 3: Define and implement the versioned archive codec

**Files:**
- Create: `native-ios/WealthOne/Data/WealthOneArchive.swift`
- Create: `native-ios/WealthOne/Data/WealthOneArchiveCodec.swift`
- Modify: `native-ios/WealthOne/Data/PortfolioStore.swift`

**Interfaces:**
- `WealthOneArchive: Codable` contains `schemaVersion: Int`, `accounts: [AccountArchive]`, `records: [RecordArchive]`, and optional `goal: GoalArchive?`.
- `RecordArchive` contains `date: Date`, `totals: [AccountAmountArchive]`, `inflows: [AccountAmountArchive]`, and `outflows: [AccountAmountArchive]`; each account amount contains `accountID: String` and `amount: Double`.
- `WealthOneArchiveCodec.decode(_ data: Data) throws -> WealthOneArchive` accepts schema version 1, current `{accounts, records, goal}` state, and legacy `{categories, records}` data.
- `WealthOneArchiveCodec.encode(_ archive: WealthOneArchive) throws -> Data` emits only the documented schema version 1 format.
- `PortfolioStore.replaceAll(with archive: WealthOneArchive) throws` validates fully before changing objects and rolls back its context if persistence fails. If `archive.goal` is absent, retain the current native goal settings.

- [ ] Decode versioned JSON, current state JSON, and `categories`/`records` legacy JSON. Normalize a missing provider to `""`; assign legacy assets to account type ID `0` (Cash) and liabilities to ID `7` (Mortgage). If legacy JSON has no goal, retain the current native goal settings.
- [ ] Decode dates from ISO-8601 strings (with or without fractional seconds) and legacy millisecond timestamps, then normalize day grouping to the user's local calendar as the legacy importer does. Treat null amount cells as absent values while preserving the dated record.
- [ ] For `categories`/`records` imports, preserve the old array mapping: filter categories without IDs, apply offset 1 when the first totals cell is null, apply that same offset to totals/inflows/outflows, and ignore null cells. Reject out-of-range indexes rather than shifting values to another account.
- [ ] Preserve every valid date and sparse amount. Reject non-finite amounts, malformed dates, duplicate account IDs, invalid required account fields, and record values that reference unknown accounts with a user-readable error.
- [ ] Add an import confirmation preview with account count, record count, and goal presence before replacement; cancellation performs no writes.
- [ ] Manually verify a round trip through export and import, a legacy JSON import, and that malformed JSON or cancel leaves existing data unchanged.

### Task 4: Decode the React Native iCloud store and migrate once

**Files:**
- Create: `native-ios/WealthOne/Data/LegacyICloudStoreReader.swift`
- Create: `native-ios/WealthOne/Data/LegacyReduxStateDecoder.swift`
- Create: `native-ios/WealthOne/Data/MigrationCoordinator.swift`
- Modify: `native-ios/WealthOne/WealthOneApp.swift`
- Modify: `native-ios/WealthOne/WealthOne.entitlements`

**Interfaces:**
- `LegacyICloudStoreReader.read(key:) async throws -> String?` reads `NSUbiquitousKeyValueStore.default` and calls `synchronize()` before the first read.
- `LegacyReduxStateDecoder.decode(_ raw: String) throws -> WealthOneArchive` receives the value returned for a logical key, decodes Redux Persist's outer JSON, and decompresses transformed substates using the repo's LZ-string UTF-16 format. The store reader, not the value decoder, adds the KVS key prefix `@com.manicakes.iCloudStorage/`.
- `MigrationCoordinator.migrateIfNeeded() async -> MigrationOutcome` returns `.notNeeded`, `.migrated(summary:)`, or `.needsJSONImport(reason:)`.
- Candidate order: `persist:wealthone_data` persisted Redux state, then `wealthone` explicit backup, then `backup` legacy key. The iCloud library prefixes each logical key with `@com.manicakes.iCloudStorage/`. Never delete or rewrite those keys.

- [ ] Confirm actual Redux Persist key/envelope format from repository dependency versions and the native entitlement required to read the production Key-Value Store identifier from a development build; record the verified key names in code comments. Decode the old `backup` shape's `goal.input` and the newer `wealthone` backup's top-level `goal` separately.
- [ ] Implement decompression and decode each persisted slice (`portfolio`, `goal`, `backup`) into the archive model; retain dates and IDs.
- [ ] Validate and save the first valid candidate in one local transaction. Mark migration complete only after the native store save succeeds; allow CloudKit upload to complete asynchronously.
- [ ] On no iCloud account, no candidate, decode error, invalid data, or save error, return a recoverable JSON-import state. Do not report success or alter legacy keys.
- [ ] Manually verify with a signed installation using the correct legacy iCloud entitlement and a known test store value; verify primary/fallback ordering and confirm historical record/account/goal counts after save.

### Task 5: Add native first-launch, file import, and JSON export flows

**Files:**
- Create: `native-ios/WealthOne/Views/Migration/MigrationView.swift`
- Create: `native-ios/WealthOne/Views/Settings/ImportExportView.swift`
- Create: `native-ios/WealthOne/Data/ArchiveDocument.swift`
- Modify: `native-ios/WealthOne/WealthOneApp.swift`

**Interfaces:**
- First-launch flow invokes `MigrationCoordinator` before showing Home.
- `ArchiveDocument` reads/writes `application/json` using the codec from Task 3.
- Import fallback offers file selection and a secondary paste field for JSON shared from the legacy React Native Export sheet.

- [ ] Show migration status and a clear Import JSON action only when direct migration has no valid source; allow retry and skip without losing a future import path.
- [ ] Use the iOS file importer for JSON and the share sheet for JSON export. Validate/preview before saving.
- [ ] Manually verify direct migration, no-data fallback, file import, pasted legacy export, export to Files/share destination, cancellation, and restart after successful migration.

## Completion gate

Do not start the iOS screen-parity workstream until the store/archive interfaces above are stable and the signed legacy-store read path has a credible device-level validation plan.
