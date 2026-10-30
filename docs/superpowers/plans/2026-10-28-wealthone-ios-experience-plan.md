# WealthOne Native iOS Experience Implementation Plan

> **Updated architecture:** The approved [event-sourcing plan](./2026-10-28-wealthone-event-sourcing-plan.md) supersedes mutable SwiftData persistence, state-only native backup, and store interfaces below. These earlier plans retain legacy behavior and screen requirements; implement through immutable events and local projections.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the existing WealthOne iPhone/iPad experience in native SwiftUI while preserving portfolio, calculation, and history behavior.

**Architecture:** SwiftUI screens consume the `PortfolioStore` and versioned domain values defined in the data/migration plan. Financial calculations live in pure domain services and are compared against the existing TypeScript selectors and goal calculator before the views depend on them.

**Tech Stack:** Swift 6, SwiftUI, Swift Charts, SwiftData through `PortfolioStore`, iOS 17+.

**Spec:** [2026-10-28-wealthone-native-ios-design.md](../specs/2026-10-28-wealthone-native-ios-design.md)

## Global Constraints

- The native app will target iOS 17 or later so it can use SwiftData.
- Preserve every valid dated record, including sparse values, and existing goal inputs.
- Home, Breakdown, Goals, History, account editing, historical-entry editing, and Settings provide feature parity with the existing iOS app.
- Keep the current WealthOne color/font identity where it works, while using native iOS interaction patterns.
- Do not modify the legacy React Native screens except for an explicitly assigned transition fix.

## Review Focus

- Asset/liability classification and unknown account type IDs must produce stable totals; check Home and Breakdown with mixed account examples.
- Empty portfolios and missing per-account values must render as valid empty/zero states rather than crashes.
- Net worth changes and netflows must respect the same date ordering and same-day rules as the old selectors.
- Goal projections must use the existing GBP assumptions, scenario arrays, retirement-age boundaries, and rounding rules.
- Editing/deleting a historical entry must preserve other dates and correctly refresh Home, Breakdown, History, and Goals.

---

### Task 1: Port portfolio and goal calculations into domain services

**Files:**
- Create: `native-ios/WealthOne/Domain/PortfolioCalculator.swift`
- Create: `native-ios/WealthOne/Domain/GoalProjectionCalculator.swift`
- Create: `native-ios/WealthOne/Domain/GoalProjectionTables.swift`

**Interfaces:**
- `PortfolioCalculator.netWorth(accounts:days:entries:) -> [NetWorthPoint]` returns date, assets, liabilities, total, inflows, outflows, netflows, change amount/percent, raw and annualized TWRR, yearly growth amount/percent, total/yearly/tax-year netflows, and total/yearly profit/loss amounts/percentages, ordered ascending.
- `PortfolioCalculator.accountHistory(accountID:accounts:days:entries:) -> [AccountHistoryPoint]` returns date, total, inflow/outflow/netflows, change amount/percent, raw and annualized TWRR, yearly growth amount/percent, total/yearly/tax-year netflows, and total/yearly profit/loss amounts/percentages used by AccountStats.
- All `NetWorthPoint` and `AccountHistoryPoint` fields are immutable `Date` or `Double` properties, named to match the legacy selector output: `date`, `assets`, `liabilities`, `total`, `inflows`, `outflows`, `netflows`, `changeAmount`, `changePercent`, `twrrRaw`, `twrrPercent`, `yearlyTwrrPercent`, `yearlyGrowth`, `yearlyGrowthPercent`, `totalNetflows`, `yearlyNetflows`, `taxYearNetflows`, `totalPL`, `totalPLPercent`, `yearlyPL`, and `yearlyPLPercent` (omit inapplicable asset/flow fields from `AccountHistoryPoint`).
- `GoalProjectionCalculator.calculate(settings:currentNetWorth:asOf:) -> GoalProjection` returns the same projected savings/income poor/average values as the existing selector.
- `NetWorthPoint` and `AccountHistoryPoint` are immutable value types defined in `PortfolioCalculator.swift`; `GoalProjection` contains `projectedIncomeGoal`, `projectedIncomePoor`, `projectedIncomePoorPercentage`, `projectedIncomeAverage`, `projectedIncomeAveragePercentage`, `projectedSavingsGoal`, `projectedSavingsPoor`, `projectedSavingsPoorPercentage`, `projectedSavingsAverage`, and `projectedSavingsAveragePercentage`, all as `Double`.
- Port current GBP defaults and table values from `src/Redux/Selectors/NetWorthSelector.ts`, `src/Redux/Selectors/GoalResultSelector.ts`, and `src/Redux/Data/GoalData.ts` without silently correcting existing formula behavior.

- [ ] Implement the portfolio calculation using every `PortfolioDay`, including days with no values, and local calendar-day grouping matching `justDate`, `toUtc`, and `sameDay`; the legacy `sameTaxYear` implementation currently changes on April 1 (its month condition includes all of April); preserve this existing behavior for parity and document the discrepancy with the actual U.K. April 6 boundary.
- [ ] Port all goal tables and formulas, including current-age derivation from birth date, life expectancy 96, current assumptions, and rounding.
- [ ] Preserve the old goal editor ranges exactly: retirement age current age–75 (step 1), earnings 0–150000 (step 500), monthly contributions 0–earnings/12 (step 50), investment style 0–6, lifestyle 0–100; birth-date edits recompute current age. Pension remains preserved but is not presented as an editable control because the existing screen hides it.
- [ ] Manually compare a fixed set of dated portfolio and goal input values against results calculated by the existing TypeScript app; record matching outputs and known existing edge behavior.

### Task 2: Build Home, account management, and entry editing

**Files:**
- Create: `native-ios/WealthOne/Views/Home/HomeView.swift`
- Create: `native-ios/WealthOne/Views/Home/AccountRow.swift`
- Create: `native-ios/WealthOne/Views/Home/NetWorthChart.swift`
- Create: `native-ios/WealthOne/Views/Accounts/AccountEditorView.swift`
- Create: `native-ios/WealthOne/Views/Entries/EntryEditorView.swift`
- Create: `native-ios/WealthOne/Views/Accounts/AccountDetailView.swift`
- Modify: `native-ios/WealthOne/RootTabView.swift`

**Interfaces:**
- Views consume `PortfolioStore` and `PortfolioCalculator`; mutations call `saveAccount`, `setEntryValue`, `deleteAccount`, and `deleteEntry` from the data plan.
- Account types preserve the IDs 0–9 and names in `src/Models/AccountTypes.ts`.
- Entry editor creates one snapshot date and edits totals/inflows/outflows by account without changing unrelated dates.
- User-entered amounts retain the legacy whole-currency-unit behavior; migration and JSON import preserve existing decimal amounts until a user edits them.
- `GoalEditorView` preserves the existing control ranges: retirement age from current age to 75 in steps of 1, earnings 0–150000 in steps of 500, monthly contributions 0–earnings/12 in steps of 50, investment style 0–6, and lifestyle 0–100. Birth-date changes recalculate current age. Pension remains stored and projected but has no visible legacy editor control.

- [ ] Create the five-tab root navigation in existing order: Home, Breakdown, Goals, History, Settings.
- [ ] Build Home account sections, current net worth, account growth/net worth chart, and add-entry route.
- [ ] Build add/edit/delete account forms with name, provider, asset/liability kind, and compatible type picker.
- [ ] Build dated entry editor with date selection, Total/Inflows/Outflows modes, existing-value loading, save, and delete confirmation.
- [ ] Preserve date rows when all values are blank; changing/removing one value must leave other account values and flow categories for that day intact.
- [ ] Manually verify empty and populated Home, account add/edit/delete, dated entry create/edit/delete, and preservation of other date entries.

### Task 3: Build Breakdown and History

**Files:**
- Create: `native-ios/WealthOne/Views/Breakdown/BreakdownView.swift`
- Create: `native-ios/WealthOne/Views/Breakdown/AllocationChart.swift`
- Create: `native-ios/WealthOne/Views/History/HistoryView.swift`
- Create: `native-ios/WealthOne/Views/History/HistoryRow.swift`
- Modify: `native-ios/WealthOne/RootTabView.swift`

**Interfaces:**
- Breakdown consumes account values from `PortfolioStore` and latest valid totals.
- History consumes `NetWorthPoint` and navigates to `EntryEditorView` for the selected day.

- [ ] Show asset allocation by type and by account, and liabilities by account, using the latest available totals.
- [ ] Show year-sectioned history and the Total, +/- amount, percent, and Netflows selectors; order newest dates first within each year.
- [ ] Manually verify asset/liability grouping, empty states, yearly section boundaries, all four metrics, and opening/editing a historical date.

### Task 4: Build Goals, Settings, and About

**Files:**
- Create: `native-ios/WealthOne/Views/Goals/GoalsView.swift`
- Create: `native-ios/WealthOne/Views/Goals/GoalEditorView.swift`
- Create: `native-ios/WealthOne/Views/Goals/GoalProjectionChart.swift`
- Create: `native-ios/WealthOne/Views/Settings/SettingsView.swift`
- Create: `native-ios/WealthOne/Views/Settings/AboutView.swift`
- Modify: `native-ios/WealthOne/RootTabView.swift`

**Interfaces:**
- Goals read/write the single `GoalSettings` record and display `GoalProjection` values.
- Settings opens account management and the archive import/export flows from the data plan.

- [ ] Build Savings/Income modes, retirement goal, poor/average scenarios, and chart. Match the existing editor: birth date, age, retirement age, earnings, contributions, investment style, and lifestyle are editable; pension is retained and used in projections but has no editor control.
- [ ] Build Settings account groups, CloudKit sync/backup status, JSON import/export entry points, and About.
- [ ] Manually verify goal inputs persist after relaunch and projection output agrees with the existing TypeScript calculations for representative scenarios.

### Task 5: Visual and end-to-end parity pass

**Files:**
- Modify: `native-ios/WealthOne/Resources/Assets.xcassets/`
- Modify: `native-ios/WealthOne/Resources/Fonts/`
- Modify: affected SwiftUI views only.

- [ ] Reuse available WealthOne app icon and fonts only where licensed assets are already present; document any font omitted from the native target.
- [ ] Manually walk the main journeys: empty install, migrated portfolio, edit current value, inspect breakdown, inspect historical entry, update goal inputs, import/export JSON, and return to Home.
- [ ] Confirm layout on iPhone and iPad sizes, Dynamic Type, VoiceOver labels for amount fields, and dark mode behavior.
