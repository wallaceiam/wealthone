# Independent Apple styling review

Fresh read-only review by a separate agent after direct implementation. No Critical findings.

## Important findings

1. Breakdown chart inferred its colour domain from positive groups, while list dots indexed all groups. Zero/negative groups could misidentify sectors. Use an explicit shared category domain.
2. Watch and complication persisted balances displayed only update time. Older cached data looked current. Show date/age for older data, a compact date in circular accessories and full accessible timestamps.

## Minor follow-up

Watch change comparison still appears with zero/one history point. Hide comparison until a predecessor exists. This was not a material acceptance blocker.

## Strengths

Inspected actual light/dark captures showed readable titles, adaptive surfaces and contrasting Current annotations. Native typography, SF Symbols, glass controls, platform floors, icon catalogs and Watch motif insets matched the approved direction. Pending entries remained pending until successful acknowledgment.

## Boundaries considered

- Live WatchConnectivity/cloud/migration/cross-device saves: not certified by styling fixtures or this review. Existing issue remains open; signed-device validation required.
- Populated accessibility layouts combining long names, negative and very large balances: not certified by empty-state large-text tests. Normal financial screens remain scrollable; exhaustive combinations remain a validation limitation.
- Complication clipping/tinted/always-on and masked icon runtime appearance: no complete runtime evidence at review time. Builds/catalog and crop inspection provide partial validation only.
- Remaining Watch entry/history/pending runtime presentation was still being captured at review time; final capture results are recorded by the implementer separately.

## Resolution

Both Important findings corrected: explicit shared category-to-colour mapping for allocation, and tested date-aware labels plus full accessible timestamps on Watch/accessories. The zero/negative case was reproduced visually before correction and inspected afterward. Three timestamp regressions failed first for the missing helper, then passed. Full suite43/43 and targeted final phone checks passed; unsigned physical iPhone/Watch/complication build succeeded. See apple-native-progress.md for detailed evidence. No second review dispatched: direct-execution workflow uses regression verification for this fix pass.
