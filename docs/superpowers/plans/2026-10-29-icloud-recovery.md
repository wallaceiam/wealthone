# Legacy iCloud Recovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Recover old iCloud data safely without requiring React Native.
**Architecture:** A Foundation-only session coordinates an injected read-only KVS source. Native SwiftUI presents preview/export and explicit backed-up import. A small original-identity app reuses read-only UI.
**Tech Stack:** Swift/Foundation, NSUbiquitousKeyValueStore, SwiftUI, existing core and project generator.
**Spec:** docs/superpowers/specs/2026-10-29-icloud-recovery-design.md

## Global Constraints
- No legacy KVS writes/deletes; no automatic import or current-history overwrite.
- Native/Watch/cloud IDs unchanged. Original ID only on optional recovery target.
- Keep current iOS26 floor and existing feature branch/uncommitted changes.

## Review Focus
- Race during synchronize / delayed notification / retry cancellation (Task1 tests).
- Account changes invalidate both candidates and pending UI import (Task1/2 tests).
- Corrupt primary key doesn't hide valid backup; originals remain exportable (Task1 tests).
- Existing native portfolio remains untouched until confirmed, backed-up replacement (Task1/2 tests).
- Real signing vs simulator limitations and original-ID utility separation (Task2/3 builds/UI).

### Task 1: Tested read-only recovery session and import transaction
- [x] Create native-ios/Tests/WealthOneCoreTests/LegacyRecoveryTests.swift. Use fake KVS source, no actual account access. Watch tests fail for missing APIs.
- [x] Create native-ios/Sources/WealthOneCore/LegacyRecovery.swift: source protocol, session states/candidates/raw export, observer-before-sync, account invalidation, a deterministic waiting-expired event driven by the adapter’s 45-second timer, cleanup, explicit backed-up import helper.
- [x] Run focused and full package suite; verify delayed arrival, failures and archive/backup invariants.

### Task 2: Native recovery UI and adapters
- [x] Replace native-ios/App/LegacyMigration.swift with Apple source + observable adapter. No simulator KVS access; account/sync status accurately worded. Notifications registered before sync.
- [x] Add App/Views/LegacyRecoveryBrowser.swift (generic source/preview/export UI, independent of AppModel) and LegacyRecoveryHost.swift (explicit native import confirmation/backup).
- [x] Update AppModel and Home/Settings so recovery is available after native initialization and never imports automatically. Keep store recovery semantics.
- [x] Add/run UI scenario opening recovery after creating native data; simulator diagnostic visible, existing history retained.

### Task 3: Original-identity fallback and verification
- [x] Add native-ios/RecoveryApp entry point, Info and KVS-only entitlement; extend generator with shared files/Core product and read-only browser. Add WealthOneRecovery scheme. Edit existing project incrementally to preserve references while Xcode may be open.
- [x] Build native app/Watch and recovery utility unsigned; verify actual bundle IDs/entitlements. Do not claim signing/cloud recovery success.
- [x] Run final package/UI checks; request independent focused review, resolve material findings, document exact device instructions and results. Leave changes uncommitted.
