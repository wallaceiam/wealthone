# WealthOne Apple Watch Companion and Release Transition Plan

> **Updated architecture:** The approved [event-sourcing plan](./2026-10-28-wealthone-event-sourcing-plan.md) supersedes mutable SwiftData persistence, state-only native backup, and store interfaces below. These earlier plans retain legacy behavior and screen requirements; implement through immutable events and local projections.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a useful Apple Watch companion and transition the native app safely to replace the React Native release.

**Architecture:** The Watch shows data synchronized by the iPhone app and sends quick-entry commands through WatchConnectivity. The iPhone applies commands through `PortfolioStore`, so today-entry merge rules, validation, and CloudKit sync stay centralized. Release identity and entitlements are changed only after feature and migration gates pass.

**Tech Stack:** Swift 6, SwiftUI, WatchConnectivity, WidgetKit complications, SwiftData / CloudKit on iPhone, watchOS 10+ companion target.

**Spec:** [2026-10-28-wealthone-native-ios-design.md](../specs/2026-10-28-wealthone-native-ios-design.md)

## Global Constraints

- iOS minimum is 17 or later; the user is comfortable raising it later if a concrete feature or support decision justifies it.
- Keep the React Native app available during transition; preserve its source and Git history.
- Android is excluded; do not create a Kotlin replacement.
- Watch quick entry selects one existing account, records today's total, and preserves other accounts and inflow/outflow values for that date.
- The production native release must retain bundle identifier `ca.mymojo.wealthone` and signing team `2LG9PUJ57N` to update the existing iOS app.

## Review Focus

- WatchConnectivity may deliver a pending command more than once; apply commands idempotently using a stable command ID.
- If the phone is unreachable, the Watch must retain a clear pending/success state and never claim CloudKit sync completed before the phone saves the entry.
- Complication refresh is system scheduled; display the last synchronized timestamp so stale values are not presented as live.
- Existing today's totals and flows must survive a Watch entry for one account.
- The old app and new app cannot be installed side-by-side under the same bundle ID; validate upgrade behavior on a test device before production cutover.

---

### Task 1: Add the Watch target and phone communication service

**Files:**
- Modify: `native-ios/WealthOne.xcodeproj`
- Create: `native-ios/WealthOneWatch/WealthOneWatchApp.swift`
- Create: `native-ios/WealthOne/Watch/WatchConnectivityService.swift`
- Create: `native-ios/WealthOneWatch/WatchCommand.swift`

**Interfaces:**
- `WatchSnapshot` contains current net worth, latest change amount/date, recent `NetWorthPoint` values, current account IDs/names, and `updatedAt`.
- `WatchEntryCommand` contains `commandID: UUID`, `accountID: String`, `date: Date`, and `total: Double`.
- `WatchConnectivityService` publishes the latest `WatchSnapshot` and queues `WatchEntryCommand` with `WCSession.transferUserInfo`, which can deliver while the phone app is suspended; the phone acknowledges a command only after its local store save succeeds.

- [ ] Add a paired watchOS 10+ SwiftUI target and activate `WCSession` from the iPhone app.
- [ ] Publish updated `WatchSnapshot` application context when the iPhone store changes; include a timestamp and only the data needed by Watch.
- [ ] Receive queued commands on the iPhone, reject unknown accounts/non-finite totals/non-today dates, deduplicate by `commandID`, and route accepted entries to `PortfolioStore`; return a saved/failed acknowledgment to the Watch after local persistence.
- [ ] Manually verify phone/watch pairing, initial context transfer, a phone-offline queued command, and reconnect delivery without duplicate entries.

### Task 2: Build the Watch glance and complication

**Files:**
- Create: `native-ios/WealthOneWatch/Views/WatchHomeView.swift`
- Create: `native-ios/WealthOneWatch/Views/RecentHistoryView.swift`
- Create: `native-ios/WealthOneWatch/Widgets/NetWorthComplication.swift`

- [ ] Show current net worth, latest change, a compact history view, and the last synchronized time.
- [ ] Add a complication that shows the last synchronized net worth and launches the Watch app; use WidgetKit timeline refresh requests after new context arrives.
- [ ] Manually verify zero-data, stale-snapshot, updated-snapshot, and representative small/large Watch layout states.

### Task 3: Build idempotent single-account quick entry

**Files:**
- Create: `native-ios/WealthOneWatch/Views/QuickEntryView.swift`
- Modify: `native-ios/WealthOne/Watch/WatchConnectivityService.swift`
- Modify: `native-ios/WealthOne/Data/PortfolioStore.swift`

**Interfaces:**
- Add `PortfolioStore.applyWatchEntry(_ command: WatchEntryCommand) throws`.
- For the local calendar's current day, call `setEntryValue` for the selected account's total. Leave that date's other account totals, inflows, and outflows unchanged. Persist processed `commandID` values to make delivery idempotent.

- [ ] Build account selection and numeric value entry; default the date to today and do not expose a date picker.
- [ ] Add pending, saved, and retryable failure states. A command is marked saved only after the iPhone store save succeeds.
- [ ] Manually verify a new day entry, an update to one account on an existing day, repeated command delivery, phone unreachable/reconnect, acknowledgment only after save, and preservation of existing flows.

### Task 4: Validate CloudKit sync and prepare release cutover

**Files:**
- Modify: `native-ios/WealthOne/WealthOne.entitlements`
- Modify: `native-ios/WealthOne.xcodeproj`
- Modify: `ios/wealthone.xcodeproj/project.pbxproj` only for retirement of old release configurations after approval.
- Modify: root `package.json` and Android release config only if needed to remove Android build/release entry points after cutover.

- [ ] Configure and verify the iCloud Key-Value Store migration entitlement and a dedicated CloudKit container for the same Apple Developer team; do not clear the old store.
- [ ] Distribute a side-by-side native beta under a development bundle ID using the legacy Key-Value Store entitlement and the production CloudKit container. While both apps are installed, manually verify direct migration and export-from-RN/import-to-native fallback.
- [ ] Verify edits made on iPhone appear on iPad and vice versa, including after offline edits and app relaunch. Resolve any conflict behavior before release.
- [ ] Before cutover, prompt users to save the legacy `.json` export and keep it available in Files. Then verify the production native update under `ca.mymojo.wealthone` with team `2LG9PUJ57N`; the production app must connect to the same CloudKit container populated by the beta.
- [ ] Keep the currently released React Native app available until direct migration, JSON fallback, and same-container CloudKit sync are accepted.
- [ ] Retire Android build/release support without deleting legacy React Native code or user data. Do not remove the old iOS app path until the native upgrade and restore routes are accepted.
