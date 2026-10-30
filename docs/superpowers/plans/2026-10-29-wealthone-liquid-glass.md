# WealthOne Liquid Glass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Implement the approved single-blue native Apple interface on iPhone/iPad and Watch, including icons.

**Architecture:** Keep the existing event-sourced core and adapters. Replace shared visual helpers with semantic system fonts, SF Symbols and appearance-aware colours; use native glass navigation and controls. Adapt screen composition without changing commands, projections or transport.

**Tech Stack:** SwiftUI, Swift Charts, WidgetKit, asset catalogs, iOS/watchOS 26, existing Foundation Swift package.

**Spec:** docs/superpowers/specs/2026-10-29-wealthone-liquid-glass-design.md

## Global Constraints

- iOS/iPadOS minimum 26.0; watchOS minimum 26.0.
- Respect system light/dark appearance; blue is the sole decorative hue.
- Preserve calculation semantics, history, migration, IDs, entitlements and dirty-draft safety.
- No mock balances in normal app execution, no new packages, no publishing/signing changes.
- Work in existing codex/native-event-sourcing checkout to preserve the uncommitted native implementation and user legacy edits; leave changes uncommitted.

## Review Focus

- Dark appearance must not retain white cards, invisible titles or unreadable chart annotations (Task 1/2 screenshot review).
- Empty/single/negative/large portfolios must not lose chart/menu/account actions (Task 2 existing and new capture cases).
- Accessibility text and long account names must remain scrollable with reachable save/cancel actions (Task 2 PremiumUITests).
- Watch missing snapshot and durable pending entry must remain understandable and never claim save before acknowledgment (Task 3 state captures/source review).
- Icon masks and complication family/tinted rendering must remain legible and preserve update timestamps (Task 3/4 build and visual checks).

### Task 1: Native foundations and appearance

**Files:** App/BrandAssets.swift, App/Views/WealthTheme.swift, App/WealthOneApp.swift, Tools/generate-project.rb, UITests/AppleStyleTests.swift (all under native-ios).

**Interfaces:** Preserve BrandFont.heading/body and FeatherIcon call signatures temporarily while replacing their internals with system Font and Image(systemName:). WealthTheme.blue/ink/background/paleBlue remain available but become semantic/dynamic. wealthNavigationTitle(_:) uses native titles, large on root and inline on editors/details.

- [x] Add light/dark UI capture checks using isolated stores; capture baseline showing forced light appearance and custom title. Visual inspection is the red gate for this styling task; do not add tests that merely duplicate colour constants.
- [x] Remove custom UIKit navigation/tab backgrounds and font overrides; remove forced light appearance; use semantic defaults and system symbol mapping. Add native title display-mode parameter with root/detail call sites explicit.
- [x] Set generated app/UI-test minimum to iOS 26 and Watch/complication to watchOS 26; regenerate project. Preserve identifiers and signing config.
- [x] Build app and check actual light/dark titles and navigation.

### Task 2: Flat financial screens

**Files:** native-ios/App/Views/PortfolioViews.swift, AnalysisViews.swift, SettingsViews.swift; native-ios/UITests/AppleStyleTests.swift, ChartRefinementTests.swift.

**Interfaces:** Continue consuming AppModel and existing portfolio/goal projections. Use Task 1 semantic style helpers; preserve existing action accessibility identifiers.

- [x] Extend the capture journey for nonempty Home/Breakdown/Goals in both appearances; keep existing menu-position, duplicate-total and £122/£189 assertions. Capture empty/single state and accessibility large text.
- [x] Flatten Home hero/summary/accounts, compact chart controls, native add actions, blue area/line; tone Breakdown/Goal charts with one hue and semantic annotation backing. Adapt all editors/data screens through shared typography/surfaces without changing their handlers.
- [x] Run ChartRefinementTests, PremiumUITests and WealthOneUITests serially; run light/dark AppleStyleTests on phone and targeted iPad navigation/large-text checks. Inspect actual captures rather than treating existence assertions as contrast proof.

### Task 3: Watch and complication

**Files:** native-ios/Watch/WealthOneWatchApp.swift, Complication/NetWorthComplication.swift; new native-ios/Watch/WatchViews.swift if splitting improves focus.

**Interfaces:** Read existing WatchModel.snapshot/status/pending and call submit(accountID:amount:)/retry(). Use existing WatchSnapshot.history/updatedAt; do not change transport schema. Complication consumes NetWorthEntry.

- [x] Record baseline missing-snapshot/overview/pending presentation from existing code and available simulator; keep synthetic fixtures confined to preview/test harnesses.
- [x] Implement glance hierarchy, blue sparkline, native Quick entry/history navigation and black/blue controls; surface current status and retry action. Preserve account-specific total and phone acknowledgment copy.
- [x] Switch complication on widgetFamily: rectangular total/time, circular compact amount with symbol, inline concise amount/time. Use native accessory rendering and no misleading live-sync claim.
- [x] Build both platforms together and capture Watch overview/entry/history/empty states in a separate preview harness if unresolved connectivity prevents normal seeded rendering. Report that limitation explicitly.

### Task 4: Icons and final validation

**Files:** native-ios/Tools/generate-icons.swift (new), App/Assets.xcassets/AppIcon.appiconset, Watch/Assets.xcassets/AppIcon.appiconset (new), Tools/generate-project.rb; docs/design/apple-native and native-ios/README.md.

**Interfaces:** Deterministically draw the existing rising-line motif to unmasked square light/dark iOS and Watch PNGs; asset catalogs select platform/appearance, generator includes both catalogs.

- [x] Validate missing Watch icon configuration as the baseline; add one meaningful resource integration check that catalogs reference decodable artwork of expected square dimensions and required platform appearances.
- [x] Produce deterministic artwork via native vector paths, populate catalogs and Watch icon build setting, regenerate project; retain old assets/source.
- [x] Run full native package suite, final app/Watch build, and required UI scenarios after all changes. Inspect icon crops and saved screenshot gallery; record limitations and exact results.
- [x] Request one fresh independent final review of spec coverage and changed source. Resolve material findings with appropriate regression checks; record deferred minor issues. Leave work uncommitted and report concrete outcomes.
