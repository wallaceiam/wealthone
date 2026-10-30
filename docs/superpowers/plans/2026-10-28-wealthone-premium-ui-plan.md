# WealthOne Premium Native UI Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development or superpowers:executing-plans. User explicitly approved implementation with “do it”; continue through verification without another design handoff.

**Goal:** Apply the approved spacious white/gray/pastel-blue interface to every native iPhone/iPad screen using existing Karla, Montserrat and Feather assets.

**Architecture:** Shared SwiftUI brand assets, adaptive surface/card components and chart styling consume the existing event-sourced AppModel. Domain calculations and persistence remain behind their existing interfaces. Implement functional HIG corrections alongside presentation, preserving causal edit contexts and user data.

**Tech Stack:** Swift 6, SwiftUI/Charts, bundled Karla/Montserrat/Feather, iOS17+.

**Spec:** ../specs/2026-10-28-wealthone-premium-ui-design.md

## Global Constraints

- Reuse existing font binaries and exact Feather tab glyphs; no React Native runtime dependency.
- Soft light palette, shallow shadows, generous spacing, strong legibility; real layouts scroll/adapt rather than forcing9:16.
- Read actual projections; chart/caption periods must agree and never contain mock balances.
- Preserve event validation, stale editor contexts, account-generation checks, migration and backup behavior.
- iPad readable widths, Dynamic Type, VoiceOver labels and reduced-motion-compatible presentation.
- Preserve existing user diffs and keep current feature branch. No signing/publishing or production cutover.
- The unresolved WatchConnectivity issue remains separately tracked; this task does not claim to resolve it.

## Review Focus

- Custom fonts/glyphs must load in installed app; check names/resources/Info.plist and rendered output.
- Charts with zero/one/many snapshots and negative/large balances must remain meaningful.
- Cancelling a dirty form must protect drafts; saving unchanged values must retain imported decimals and causal context.
- Filtered history/chart controls must communicate actual dates and units; invalid projections must explain recovery.
- Large text and iPad widths must not make primary actions or financial labels disappear.

### Task 1: Brand assets and native resource integration

**Files:** `native-ios/App/BrandAssets.swift`, `App/Resources/Fonts/`, `App/Info.plist`, `Tools/generate-project.rb`, `App/WealthOneApp.swift`.

**Interfaces:** `BrandFont.heading(_:relativeTo:) -> Font`, `BrandFont.body(_:relativeTo:weight:) -> Font`; `FeatherIcon(name:size:) -> View`. Register/check actual PostScript names, preserve semantic Dynamic Type scaling and hide decorative glyphs from VoiceOver. Toolbar/navigation titles use Karla and body controls Montserrat where native APIs permit.

- [x] Copy existing regular/bold Karla, regular/medium/semibold/bold Montserrat and Feather assets. Read CoreText metadata to verify names.
- [x] Wire fonts as bundle resources and UIAppFonts; supply native reusable glyph mapping for existing tabs/actions.
- [x] Verify installed-app fonts and glyphs in UI captures and device/simulator builds.

### Task 2: Shared visual system and all native screens

**Files:** `App/Views/PortfolioViews.swift`, `AnalysisViews.swift`, `SettingsViews.swift`, new shared theme/dashboard/audit/form files as needed; `UITests/`.

- [x] Add white/neutral adaptive backgrounds, spacious rounded surfaces and pale-blue controls, readable brand typography and Feather symbols.
- [x] Dashboard uses real net worth/change/date, functional range selector, visible single-point/empty charts, asset/liability cards, Add snapshot and readable account rows. Keep stable test accessibility identifiers.
- [x] Apply shared styling to account/day/goal forms, Breakdown, History, Settings, backup/import/recovery and About; add persistent labels and units, exact numeric goal entry, and dirty-dismiss confirmation on every editing route.
- [x] Humanize event/baseline/conflict views with names/dates/formatted amounts and hide storage IDs behind technical disclosures. Keep source alternatives and event histories intact.
- [x] Capture screen journey in isolated test portfolio, including large text; verify draft preservation, save/reopen and core suite.

### Task 3: Review, screenshots and delivery

- [x] Independent review against approved design and HIG findings; fix significant issues with meaningful regressions.
- [x] Run native package tests, iPhone/iPad UI checks and unsigned native build. Inspect representative screenshots at default and accessibility text sizes.
- [x] Save actual rendered screenshots/report and document any remaining device-only gates. Keep changes reviewable without committing unrelated user edits.

## Outcome

Implemented across native iPhone/iPad screens with original brand fonts/icons. Native package suite36/36 passed; six UI scenarios were verified on each device across serial/corrective runs. The final two affected draft scenarios passed on both iPhone and iPad after switching to an explicit native alert. See `docs/implementation/premium-ui/progress.md` and `docs/design/implemented-premium/README.md`. VoiceOver traversal, physical-device gestures and signed cloud/Watch behavior remain separate validation boundaries.
