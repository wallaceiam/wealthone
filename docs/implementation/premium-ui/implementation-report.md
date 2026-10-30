# Premium native UI implementation

Implemented the approved light spacious direction across all iPhone/iPad views. The production UI uses the supplied BrandFont and FeatherIcon APIs, with real portfolio values and no decorative profile control.

## Files

- `native-ios/App/Views/WealthTheme.swift`: neutral/pale-blue palette, white cards, shallow shadows, centered readable-width layouts, shared branded typography and draft dismissal protection.
- `native-ios/App/Views/PortfolioViews.swift`: five original Feather tab images; spacious dashboard, actual dates and previous-snapshot changes, assets/liabilities summaries, working 1M/3M/6M/1Y/All chart ranges, date selection, zero/one-point states, account detail summary, persistent financial labels and explicit account category.
- `native-ios/App/Views/AnalysisViews.swift`: allocation context/percentages and empty explanation, period/unit labels in History, exact numeric retirement-age/earnings/contribution inputs alongside existing sliders, locally visible numeric errors, protected goal drafts.
- `native-ios/App/Views/SettingsViews.swift`: matching grouped surfaces, sync progress, real backup importer/exporter and completion state, explicit replacement/merge wording, goal-settings preview, human-readable edit/conflict/baseline values, causal before/after values and collapsed technical details, About version/build.

## Behavior and integration

Account/day/goal editors retain their original captured EditContext and captured account/record semantics. Unedited imported Decimal values never pass through display formatting on save. Goal saves include touched fields only; exact text uses EntryAmount.parse and preserves Decimal values. Changing a date after entering amounts requires a separate discard confirmation.

Dirty Cancel/back actions show Keep Editing and Discard Changes. Dirty sheet swipes are blocked by native interactiveDismissDisabled, preserving the form and entered values. Use Cancel for the explicit draft decision. Unchanged forms can dismiss normally.

Charts use the selected range ending at the latest recorded snapshot; summary change explicitly compares the last two recorded snapshots, independent of the chart range. Selection shows the nearest visible snapshot value and date. Currency and percent axes are explicit. Audit before-values are derived from the event's causal ancestry, avoiding mislabeling concurrent changes as earlier values. Archived account names are recovered from historical account events/baselines. Raw technical IDs remain inspectable.

## Validation and remaining gates

Source review covered original save, validation, deletion, import/export and conflict-resolution calls. Integration build, UI journeys, screenshots, Dynamic Type, swipe/back behavior and root-level errors are being verified by the parent implementation agent. No domain, storage, cloud, Watch, project configuration or AppModel files were edited by this view implementation.

VoiceOver traversal, physical-device sheet gestures and increased-contrast validation still require explicit runtime review. No support destination was invented because none exists in the supplied product configuration. Watch work remains outside this implementation.

## Review round 1 fixes

Added the production `GoalDraft` helper in `Sources/WealthOneCore/GoalDraft.swift` and seven regressions in `Tests/WealthOneCoreTests/GoalDraftTests.swift`. The editor now derives validation from current exact text and current age/earnings on every render and again before Save. Invalid text stays visible; no stale accepted value can be saved. Untouched imported fields remain excluded from the change payload, including values beyond editor ranges. Exact edited goal amounts preserve fractions with a strict Decimal parser; the dated-entry whole-pound parser remains unchanged.

Birth A → B → A removes both birthDate/currentAge edits, preserving the original stored representation or absence. Tests cover representation restoration, save/reopen through EventStore, dependent contribution validation in both earnings directions, retirement validation when age changes/reverts, zero earnings with only zero contribution allowed, and untouched imported precision.

The actual exact-input UI crash was traced to the monthly contribution stepped Slider: deleting earnings produced a range with span 1 while step remained 50. The iOS 17 SwiftUI framework binary contains the assertion `max stride must be positive`; floor(span / step) reached zero. Slider constraints now use step no larger than the available span, clamp only the displayed slider thumb, and omit the slider when the span is zero (including age 75 retirement ranges). Exact typed/stored values are never clamped. Contribution bounds now permit only zero when earnings are zero. A regression exercises deleting/retyping earnings, invalid intermediate strings and collapsed ranges.

`swift test --package-path native-ios --filter GoalDraftTests`: **7 passed, 0 failures**, 28 October 2026 16:07 UTC. The app's original failing UI test will be rerun by the parent agent; no Xcode jobs were launched by this worker.

Also clarified cumulative chart performance/date spans and added an actionable Review goal inputs explanation for unavailable projections. `Package.swift` and existing calculators remain unchanged.


## Runtime round 2 simplification

The parent’s serial iPhone runtime checks passed exact-goal save/reopen and dirty Cancel protection. A sheet swipe safely retained the draft but did not present the UIKit delegate’s intended dialog. Removed that delegate bridge and its UIKit dependency; draft protection now uses native `interactiveDismissDisabled` plus the existing explicit Cancel / Keep Editing / Discard Changes flow. No claim is made that a blocked swipe shows a prompt. The parent is verifying the simpler no-data-loss behavior in the gesture test.


## iPad explicit draft choices

The parent’s iPad runtime pass exposed platform behavior: `confirmationDialog` renders as a popover and omits its cancel-role action, hiding Keep Editing. Changed the shared draft decision to a native alert, which displays both Keep Editing (cancel) and Discard Changes (destructive) on iPhone and iPad. Native blocked sheet swipes remain unchanged. Existing failing draft-decision tests cover the behavior; the parent is rerunning the two affected cases on both devices.
