# WealthOne Native iOS and watchOS Implementation Roadmap

> **Updated architecture:** The approved [event-sourcing plan](./2026-10-28-wealthone-event-sourcing-plan.md) supersedes mutable SwiftData persistence, state-only native backup, and store interfaces below. These earlier plans retain legacy behavior and screen requirements; implement through immutable events and local projections.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the React Native WealthOne release with a native iPhone/iPad app and Apple Watch companion while preserving portfolio history, iCloud continuity, and a JSON recovery route.

**Architecture:** Build a standalone SwiftUI iOS application and companion watchOS target alongside the existing React Native source. The iOS app owns SwiftData models, CloudKit sync, financial calculations, legacy iCloud decoding, and JSON archives; the Watch sends quick-entry commands through the paired iPhone app. Ship the native app under the existing production identity only after signed migration and feature-parity checks.

**Tech Stack:** Swift 6 / SwiftUI, SwiftData, CloudKit, WidgetKit, WatchConnectivity, existing React Native / TypeScript for the transition export bridge.

**Spec:** [2026-10-28-wealthone-native-ios-design.md](../specs/2026-10-28-wealthone-native-ios-design.md)

## Global Constraints

- The native app will target iOS 17 or later so it can use SwiftData.
- Use SwiftData with the user's private CloudKit database for automatic sync between their iPhone and iPad signed into the same iCloud account.
- Keep versioned JSON export/import as a portable backup and migration fallback.
- Never delete, clear, or rewrite legacy iCloud values as part of migration.
- Never silently replace existing native data with an imported backup.
- Keep the React Native files in the repository during transition and preserve their Git history. Retire its build/release path only after native feature parity and data migration are accepted.
- Android is excluded; the React Native source remains available during the transition.
- Preserve every valid dated record, including sparse values, and existing goal inputs.
- The user approved a Watch glance, current-net-worth complication, and quick entry of one existing account's value for today.

## Review Focus

- Missing or malformed iCloud keys, compressed Redux state, and stale backup values must not be mistaken for a successful migration; cover in the migration-source task.
- Sparse records, removed account references, same-day timestamps, and daylight-saving boundaries must preserve historical amounts and existing date grouping; cover in the model/archive task.
- An invalid or cancelled JSON import must leave native data untouched; cover in the archive task.
- Offline CloudKit sync or simultaneous iPhone/iPad edits must not silently discard an entire device's portfolio; cover in the sync task.
- A delayed or repeated Watch quick-entry command must update only the chosen account total for today and preserve other values and flows; cover in the Watch task.

---

## Workstream sequence

**Architecture revision required:** The user wants permanent, replayable history of every saved edit and has clarified that only one person edits, on one device at a time. Use authoritative immutable domain events and rebuildable local projections. These plans still assume mutable SwiftData domain records. Before implementation, finalize the proposed causal/Lamport ordering rule in the spec and revise all dependent store, migration, archive, and Watch interfaces together. Include lifecycle/import boundaries and full event-log backups; account for stale state when switching devices even without simultaneous editing.

This product has three separable implementation plans. Complete them in this order:

1. [Data foundation and migration](./2026-10-28-wealthone-data-migration-plan.md). This establishes the SwiftData model/archive interfaces and makes a working legacy export path available.
2. [Native iOS experience](./2026-10-28-wealthone-ios-experience-plan.md). This consumes the store and calculation interfaces from workstream 1.
3. [Apple Watch companion and release transition](./2026-10-28-wealthone-watch-transition-plan.md). Watch depends on the store interface and iPhone app shell; release cutover depends on all workstreams.

The current React Native working tree already contains edits in multiple screens. Re-read and preserve those diffs when wiring the temporary Export action; do not reset, overwrite, or reformat unrelated changes.

## Release gates

- Before the native app is configured to replace the App Store build, confirm the production bundle identifier `ca.mymojo.wealthone`, signing team `2LG9PUJ57N`, iCloud Key-Value Store entitlement, and CloudKit container with the app owner.
- Side-by-side development builds need a separate bundle identifier. Direct legacy Key-Value Store access must be proven with an entitlement that names the original store or with a signed test installation using the original app identity; a different bundle identifier alone is not evidence of access.
- Keep the existing React Native release available until migration, CloudKit sync, Watch quick entry, and iOS feature parity have been checked on the owner's iPhone and iPad.
- Retire Android build/release support without deleting unrelated portfolio history or legacy source.

## Suggested execution approach

Use subagent-driven implementation after this roadmap is approved: the migration, iOS screen, and Watch workstreams have clear file boundaries, while CloudKit identity, shared domain interfaces, and final release checks need a coordinator. Do not run the three workstreams concurrently until the shared data interface is fixed in workstream 1.
