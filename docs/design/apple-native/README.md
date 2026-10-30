# WealthOne native Apple interface

Approved direction: system typography and SF Symbols, native Liquid Glass navigation, flat financial content, and a single blue family in light/dark appearance. Minimum iOS/iPadOS26 and watchOS26.

## Implemented screens

- [Light phone screens](implemented-light.jpg)
- [Dark phone screens](implemented-dark.jpg)
- [Watch overview, entry and history](implemented-watch.jpg)
- [Allocation with zero/negative balances](screens/final-apple-allocation-zero-negative.png)
- [Watch stale-date detail](screens/watch-stale-date-harness.png)
- [iPad accessibility Home](screens/ipad-premium-home-accessibility-text.png) and [form](screens/ipad-premium-form-accessibility-text.png)

Phone screenshots are actual iPhone17/iOS27 simulator renders using isolated synthetic test portfolios. Light/dark were selected through simulator system appearance, not app-specific overrides. Normal app data and financial formulas were not replaced by demo figures. A single snapshot is correctly shown as a point; real history produces the line/area chart. Native tab bars can float above scrolling content.

Watch overview is the actual app on a disposable Watch simulator with synthetic cached data. Entry/history/stale-date captures render the same production SwiftUI views in a separate temporary presentation harness because native UI automation failed startup. They establish visual rendering, not WatchConnectivity, successful phone saves, full interaction coverage, or WidgetKit tinted/always-on validation. The initial empty capture predates removal of redundant initial status text.

## App icons

- [iPhone light](../../../native-ios/App/Assets.xcassets/AppIcon.appiconset/WealthOne-Light.png)
- [iPhone dark](../../../native-ios/App/Assets.xcassets/AppIcon.appiconset/WealthOne-Dark.png)
- [Watch](../../../native-ios/Watch/Assets.xcassets/AppIcon.appiconset/WealthOne-Watch.png)

These are deterministic vector-derived artwork, supplied as unmasked square PNGs; platform masking and system appearance effects happen at runtime. The existing rising-chart identity is retained. The Watch motif is inset for circular masking. They are asset-catalog icons, not handcrafted layered Icon Composer files.

## Approved reference mockups

[Light](approved-light.png), [dark](approved-dark.png), [Watch/icons](approved-watch-icons.png). Generated with the built-in image_gen tool for visual approval. Prompt briefs: three Apple Music/Stocks-inspired WealthOne screens using a single sapphire-blue hue family and native typography/glass; an unchanged-layout dark companion; a Watch overview/entry/history/complication board and icons retaining the original rising-chart mark. These raster concepts are reference material; they are not shipped app assets or actual screenshots.

Validation details and independent-review resolution: [implementation ledger](../../implementation/apple-native-progress.md), [review](../../implementation/apple-native-review.md).
