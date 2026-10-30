# Calculation Corrections Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans for direct implementation and one independent final review. Existing user choice is direct implementation; the request to fix the audited errors authorizes this corrective scope.

**Goal:** Correct the reproducible calculation defects in docs/implementation/calculation-audit.md while retaining fast cached read models and original event history.
**Architecture:** Linear rolling portfolio metrics with explicit first/year opening baselines, geometric return factors and an April6 boundary. Calendar birthday age; zero-horizon accumulation; consistent pension/target equations and percentage funded. Derive values from immutable observations; no migrations.
**Tech Stack:** Existing Foundation Swift core, SwiftUI, Swift Charts and XCTest.
**Spec:** docs/implementation/calculation-audit.md and user's instruction “can you fix the errors”.

## Global constraints
- Retain iOS26/watchOS26, signing identities and full event history; leave unrelated React Native edits untouched. Work on existing feature branch because native work is uncommitted; no automatic commits.
- Date identifiers and original recorded Decimal amounts remain unchanged.
- Existing aggregate cash flows retain the end-of-period approximation; disclose it. Do not invent transaction timing or change debt signs without a definition.
- State pension level/start assumptions, investable account selection and scenario table calibration are modelling choices beyond the confirmed arithmetic fixes. Keep visible assumptions explicit.
- Missing-balance handling awaits user answer; continue independent arithmetic fixes meanwhile.

## Review focus
- First record flows are excluded from since-baseline profit but retained in total-recorded-flow statistics.
- Year opening uses last observation before the year, or first ever point if no earlier baseline; first year's initial flow excluded from since-baseline year profit. Show baseline date/limitation when no boundary valuation exists.
- Geometric year linking survives zero-return intervals and year transitions; cache remains linear and exact date formats remain preserved.
- Zero horizon includes neither growth nor future deposits; invalid/past/out-of-table horizons are unavailable rather than silently clamped.
- Target-funded percentage uses100; zero target/zero income handled explicitly; pension income in target and projection uses the same basis.

### Task1: Correct portfolio arithmetic
- [x] Add failing independent expected-value tests for compounding, calendar opening baselines, opening flow exclusion, gross growth denominator and April5/6 boundaries.
- [x] Implement linear metrics and expose year baseline date for honest presentation. Preserve ordinary since-baseline return/flow/total calculations.
- [x] Update old parity tests to compare only unaffected fields; keep the frozen old calculator as historical reference. Run full core suite.

### Task2: Correct goal arithmetic and presentation
- [x] Add failing tests for leap-cycle birthday, zero/past horizons, horizon limits, target percentage and pension equation reconciliation.
- [x] Implement calendar age and explicit horizon guards, zero-year projection, consistent pension contribution, percentage funded and finite zero-target behaviour. Preserve original tables/positive whole-year accumulation amounts.
- [x] Update independent goal fixtures, labels, About/version notes and approximation/baseline explanations. Run full core suite.

### Task3: Close missing-balance decision, verify and review
- [x] Apply user's missing-balance choice if supplied, with regressions and original-source preservation. If optional answer does not arrive, state a conservative scope ruling before dependent changes.
- [x] Run populated UI/edit/reopen regression, phone/Watch physical build and same-input performance benchmark.
- [x] Independent focused review; fix material findings, rerun relevant/full checks, document outcomes and remaining model assumptions.

## Authorized additions during implementation

User requests actual-vs-projected Goals and multi-currency accounts. They chose recalculating historical projection when assumptions change, and rates captured at entry time, frozen until explicit refresh. Existing main currency is GBP; support changing reporting currency with explicit goal monetary-input conversion using a current quote.

### Task4: Historical comparison
- [x] Add shared accumulation calculation (zero/fractional/yearly horizons) and independent first/one-year historical comparison tests. Curve anchors to first actual snapshot; current contribution/style assumptions apply over its history. No saved forecast/history rewriting.
- [x] Cache comparison points with portfolio revision; native Goals chart overlays Actual/Average/Poor, latest actual-versus-average difference, and baseline/current-assumption explanation.

### Task5: Frozen FX and currency UI
- [x] Add backward-compatible account currency (GBP default), dated saved rates in GBP per foreign unit, source/date metadata, validation/replay/export support. Rates are immutable events when saved/refreshed; blanks carry prior balances/rates only in derived views.
- [x] Add snapshot conversion into reporting currency for net worth/flows; raw-currency account detail remains in account currency. Missing required rates yield unavailable valuations, never a1:1 guess. Preserve old JSON/event decoding.
- [x] Fetch a current public Bank of Canada quote once per entry/explicit refresh (cached app session), allow manual overrides, save quote only with user Save. Add explicit Fill missing rates for historical observations; preserve already saved rates. Bulk updates commit atomically without per-record replay.
- [x] Currency pickers/labels on accounts, dated entry, Settings, portfolio/Goals/history and Watch; quote provenance and refresh control visible. Reporting-currency edits convert earnings/contributions consistently.
- [x] Core regression tests for conversion, frozen/refresh behavior, missing rates, event merges, migration, export/reopen; simulator currency/edit and actual/projection UI verification. Final reviewer covers the complete combined change.

### Task6: Reported Watch Quick entry crash
- [x] Reproduce opening Quick entry with production navigation and synthetic model (missing WatchModel environment fatal error).
- [x] Move shared model injection above NavigationStack and retain a source-derived isolated Watch runtime probe.
- [x] Verify the same automatic navigation renders successfully after the fix; capture screenshot and rebuild production Watch/iPhone targets.
