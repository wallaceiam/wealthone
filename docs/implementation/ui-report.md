# Native UI and calculation implementation

Implemented the native iOS 17+ five-tab shell: Home, Breakdown, Goals, History and Settings. Views use `AppModel` commands and the immutable event store rather than writing snapshots directly.

Files:

- `native-ios/App/WealthOneApp.swift`
- `native-ios/App/Views/PortfolioViews.swift` — home, charts, account forms/detail, sparse dated entry editor and performance metrics.
- `native-ios/App/Views/AnalysisViews.swift` — asset/liability allocation, year-sectioned history and metric selection, goal controls and poor/average/goal chart.
- `native-ios/App/Views/SettingsViews.swift` — sync status, migration/import routes, preview/confirmation, full-history export, event detail, baseline inspection and retained-value conflict resolution.
- `native-ios/Sources/WealthOneCore/PortfolioCalculator.swift`
- `native-ios/Sources/WealthOneCore/GoalProjectionCalculator.swift`
- `native-ios/Sources/WealthOneCore/GoalProjectionTables.swift`
- `native-ios/Tests/WealthOneCoreTests/CalculationTests.swift`

Entry forms preserve raw historical date identifiers, empty dated rows and untouched Decimal amounts. Only edited numeric fields round to whole currency units. Clearing a field removes that value, leaving other accounts and flow categories intact. Goal saves send only fields the user changed, preserving imported decimals, unknown fields and the hidden pension setting. Account type IDs 0–9 and unknown imported IDs remain supported.

Calculation validation:

Executed the actual existing TypeScript goal selector body and bundled `GoalData.ts` with a fixed `Date.now()` of 2026-10-28, using Node. Recorded results for two representative scenarios and asserted all ten Swift projection output values against them:

| Scenario | Income goal / poor / average | Savings goal / poor / average |
| --- | --- | --- |
| Age 40; retirement 65; earnings 55,000; monthly 200; style 3; lifestyle 40%; worth 100,000 | 28,200 / 8,500 / 13,300 | 784,000 / 236,000 / 369,000 |
| Age 50; retirement 68; earnings 100,000; monthly 500; pension 15%; style 5; lifestyle 70%; worth 250,000 | 83,700 / 42,100 / 57,000 | 1,457,000 / 398,000 / 774,000 |

Executed the existing TypeScript `reduceCalc` body on four dates crossing New Year and April 1. Swift matches cumulative return 0.646666666666667, legacy yearly return 0.30121212121212126, total profit/loss 60, yearly profit/loss 40 and tax-year net flows 10. Tests additionally cover sparse zero values, Decimal assets, positive liability account history, and missing asset amounts.

The legacy yearly TWRR recurrence and April 1 tax-year boundary are preserved deliberately. The actual UK boundary is April 6; About explains this discrepancy. Goal tables are copied verbatim from the shipped TypeScript numeric arrays. No statistical model or financial assumptions were updated.

Verification command:

```sh
CLANG_MODULE_CACHE_PATH=/tmp/wealthone-clang SWIFTPM_MODULECACHE_OVERRIDE=/tmp/wealthone-swift swift test --package-path native-ios --scratch-path /tmp/wealthone-core-build --cache-path /tmp/wealthone-cache --disable-sandbox
```

Result: 15 tests passed, zero failures, including 5 calculation tests, 8 event-core tests and 2 legacy decoder tests. Swift files formatted using Xcode `swift-format`.

UI verification limitations:

The owning agent performs the integrated Xcode simulator build after project generation. This report does not claim simulator interaction, real-device iCloud sync, signed migration, Watch interaction, iPad layout, large Dynamic Type or VoiceOver runtime verification. The implementation uses native semantic controls, adaptive Forms/Lists/NavigationStacks, system fonts and light/dark semantic colors. Existing custom fonts were not added; the native target uses the system font. Actual device walkthroughs remain necessary before release.
