# Populated Portfolio Performance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans for direct implementation with independent final review.

**Goal:** Remove reproducible UI stalls after importing a populated portfolio without changing formulas, dates or history semantics.
**Architecture:** Parse dates once per calculation, retain legacy rolling-metric arithmetic using running state, index projection fields, skip unchanged merges, and publish one immutable cached portfolio read model for all screens and Watch payloads.
**Tech Stack:** Foundation/SwiftUI/Swift Charts, existing native targets.
**Spec:** User reports launch, tabs, scrolling and saves/sync all slow after import. Local benchmark with private344-record portfolio confirms repeated main-thread calculations and no-op replays. Financial records stay outside repo; synthetic tests only.

## Global Constraints
- Preserve exact legacy April1 boundary, yearly recurrence, account-history sign and floating-point operation order.
- No history pruning, destructive migration, cloud identity or signing changes.
- Keep existing uncommitted feature branch and unrelated edits.
- Core remains usable off main actor. No shared mutable formatter globals.

## Review Focus
- Prefix/year fold arithmetic including empty/zero/negative/sparse/year-boundary values (Task1 reference parity).
- Cached read models invalidate on snapshot/calendar changes and include losing-event/conflict updates (Task2 cache/publication checks).
- No-op merges still reject collisions and advance observed clocks when needed (Task1 store tests).
- Generation/tombstone/causal semantics unchanged by projection indexing (Task1 full regressions).
- Populated UI and Watch reuse prepared data; no date sorting/calculation inside row closures (Task2 source/runtime checks).

### Task1: Algorithms and store
- [x] Add synthetic parity/reference, read-model/cache and no-op-write regressions before production changes.
- [x] Parse each record date once for ordering; compute all metrics in linear passes using the original arithmetic order. Leave public date parsing semantics intact.
- [x] Index versions by entity for day-generation normalization and projected fields by entity for materialization, without changing eligibility/winners.
- [x] Skip projection/file commit on unchanged event merges; preserve collision validation and clock-only updates.
- [x] Run native suite and before/after private benchmark; compare actual point fields privately without logging balances.

### Task2: Shared read model and native integration
- [x] Add immutable PortfolioReadModel: snapshot, ordered records, net worth/account histories, year sections, latest record, account/type allocation and totals. Reuse parsed dates across account histories. Cache by snapshot and calendar/timezone context.
- [x] AppModel publishes read model only when data/context changes, updates audit revision for new history, and avoids redundant publication on no-op sync.
- [x] Home, Breakdown, History, Goals, account detail and PhoneWatchBridge consume cached data. Retain original selection/metric and date identifiers.
- [x] Verify populated synthetic344-record UI journey, chart selection/range, save/reopen and edit invalidation; inspect timing separately from pass/fail.

### Task3: Review and delivery
- [x] Independent focused review; fix material findings with regressions.
- [x] Run full suite and physical/simulator build, document measured gains and remaining boundaries. Keep uncommitted.
