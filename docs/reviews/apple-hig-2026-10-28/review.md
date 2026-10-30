# WealthOne — Apple Human Interface Guidelines review

Reviewed 28 October 2026. Scope: native iPhone/iPad screens, first-launch/recovery states, Watch companion and complication. This is a design review, not Apple certification or an App Store approval prediction. No production UI changes were made during this review.

## Evidence and limits

- Reviewed all SwiftUI view files and relevant presentation/error paths.
- Ran `HIGReviewTests.testScreenInventory` on iPhone 15 Pro / iOS 17: passed, 20 screenshots retained using a separate UUID-named test portfolio. The sample name/provider/balance are synthetic.
- Inspected all four contact sheets: [onboarding and forms](contact-sheet-1.jpg), [portfolio and breakdown](contact-sheet-2.jpg), [goals/history/settings](contact-sheet-3.jpg), [backup and edit history](contact-sheet-4.jpg). Original captures are in `screens/`. Captures 07 and 13 contain navigation/scroll transition artifacts; don't treat those artifacts as stable layout defects.
- iPad, large accessibility text, VoiceOver traversal, increased contrast, dark mode, landscape and Watch families were source-reviewed for risks but not visually audited in this pass. Earlier save/reopen tests on iPad are functional evidence, not a design/accessibility audit.
- Import preview, unreadable-storage recovery, populated conflicts, baseline detail and Watch screens were inspected in source; the screenshot journey did not exercise those states. A passing capture test establishes navigation and capture, not HIG compliance.
- Current HIG pages include newer OS designs. Recommendations below preserve iOS 17 compatibility; a newer adaptable tab bar is not a prerequisite.

## Priorities

P1: resolve before accepting the native design. P2: improve usability and complete visual/accessibility validation before distribution. These ratings describe this app's user impact; they are not Apple severity ratings.

### P1 — Persistent labels disappear from financial forms

`App/Views/PortfolioViews.swift:124` and `:217`; `Watch/WealthOneWatchApp.swift:50`.

Confirmed in screenshots 04 and 06: after entry, the account/provider fields show only their values; the amount field shows `125000` without the account name or a visible currency unit. VoiceOver labels do not replace visible labels. With several accounts this makes editing the wrong value easy.

Recommendation: retain account name and currency alongside a trailing amount field; retain separate Name/Provider labels. Keep number formatting and validation consistent with displayed currency. Clarify the existing whole-pound truncation behavior before silently changing typed decimal input. Apple supports persistent labels and numeric formatting in [Text fields](https://developer.apple.com/design/human-interface-guidelines/text-fields).

### P1 — Edits can be discarded without protection

Account/day/goal editors have Cancel actions and dismissible sheets but no dirty-state dismissal protection (`PortfolioViews.swift:143`, `:229`; `AnalysisViews.swift` GoalEditorView).

Recommendation: when values have changed, offer Keep Editing and Discard Changes on Cancel/swipe/back as appropriate. Leave unchanged forms easy to dismiss. A permanent saved-edit log cannot recover an unsaved draft. This applies Apple's [Modality](https://developer.apple.com/design/human-interface-guidelines/modality) guidance on preventing loss when closing a task.

### P1 — A one-snapshot chart appears empty

`PortfolioViews.swift:35`: only a `LineMark` is used. Account detail capture 08 has a dated value but shows axes without a visible data point. Empty Home also reserves a large blank chart area.

Recommendation: add an identifiable point for a single snapshot, an explanatory state for no snapshots, a visible date/range and a readable selected value for longer histories. Format money and percent axes explicitly. Use [Charting data](https://developer.apple.com/design/human-interface-guidelines/charting-data) to guide context and comprehension; audit Swift Charts' automatic accessibility instead of assuming a chart-level label proves accessibility.

### P1 — Precise financial assumptions have slider-only input

`AnalysisViews.swift` GoalEditorView: annual earnings, monthly contributions and retirement age require sliders over broad ranges. Exact earnings/contribution entry is difficult, especially with motor accessibility needs.

Recommendation: supplement financial sliders with labelled numeric input; use a stepper or picker for retirement age. Keep existing accepted ranges/calculation behavior unless deliberately changing the product. Apple explicitly suggests text fields/steppers for broad slider ranges in [Sliders](https://developer.apple.com/design/human-interface-guidelines/sliders).

### P1 — Edit history and conflict decisions expose storage identifiers

`SettingsViews.swift:94`, `:135`, `:148` and ConflictReviewView. Captures 17–18 lead with UUIDs, raw field names such as `totals:<UUID>`, generation/epoch and parent identities. Populated conflicts use the same identifier-based entity titles. This makes it hard to recognize the account and decide which value to keep.

Recommendation: lead with account name, formatted snapshot date, Total/Deposit/Withdrawal label, currency, and before/after or competing values. Identify the currently displayed winner. Put event IDs, generations and causal links in an optional technical disclosure. Preserve historical names/context for deleted accounts. This is an app-specific application of [Layout](https://developer.apple.com/design/human-interface-guidelines/layout)'s emphasis on information hierarchy.

### P1 — Complication needs family-specific and privacy-aware presentation

`Complication/NetWorthComplication.swift:25` uses the same vertical stack for rectangular, circular and inline families. Inline has one line; a two-line balance/time layout cannot communicate the same hierarchy there. Large balances are reduced to half-size. The balance is not marked privacy-sensitive.

Recommendation: switch on widget family; use one short inline value, a compact circular representation, and balance plus freshness in rectangular. Mark sensitive amounts appropriately and consider a discreet display option. Use useful representative placeholders. Validate tinted/Always-On appearances and privacy redaction on hardware. See [Complications](https://developer.apple.com/design/human-interface-guidelines/complications) and [Widgets](https://developer.apple.com/design/human-interface-guidelines/widgets).

## Screen-by-screen disposition

| Screen / state | What works | Recommended change / disposition |
| --- | --- | --- |
| Root navigation | Five labelled native tabs, SF Symbols and separate navigation stacks. | Keep this structure. On iPad evaluate readable content widths and whether a sidebar adds value; its absence alone is not a violation. P2. |
| Migration / first launch | Explains alternatives and supplies retry/import/start actions. | Replace empty portfolio chart with onboarding focus; make migration progress distinct from no data. Validate waiting-for-iCloud and retry states. P2. |
| Storage unavailable | Recovery action is available and editing is blocked. | Keep a persistent recovery explanation; explain preserved originals in user terms rather than an inaccessible application-support path. Source-only. P2. |
| Home, empty | Clear title and add-account action. | Replace blank chart and empty section headings with a concise first-account action. P1 chart issue. |
| Home, populated | Net worth is prominent; account names/providers and balances are grouped. | Add an “As of” date; distinguish an unrecorded account value from an actual £0 where meaningful. P2. |
| Add/edit account | Native form, Save/Cancel, compatible type picker, destructive confirmation. | Persistent labels; use an explicit Asset/Liability picker instead of an ambiguous “Asset” switch; protect drafts. P1. |
| Add/edit dated entry | Date picker and Total/Inflows/Outflows modes match the task. | Persistent name/currency labels; formatted historical dates instead of raw strings; numeric keyboard and field-local errors; protect drafts. P1. |
| Account detail | Native drill-down and performance values are available. | Single-point chart fix; lead with current balance/date and group detailed return/flow metrics into readable sections. Explain TWRR and period boundaries. P1/P2. |
| Breakdown | Familiar allocation chart, adjacent value rows and account/type switch. | Provide no-data/no-positive-assets state; include percentages and total/date context. Ensure labels/legend remain readable with many accounts. P2. |
| Goals | Scenario bars have a numeric alternative; Savings/Income mode is explicit. | Explain the denominator/meaning of “scenario percentage.” Existing formulas are lifestyle-scaled, so don't simply relabel these as percent-of-goal. Explain unavailable results with a useful edit action. P2. |
| Goal editor | Fields are grouped and current age is derived. | Exact numeric entry alongside sliders; show units and ranges; protect drafts. Avoid silently rewriting imported assumptions. P1. |
| History | Year groups, readable dates, metric selection and drill-down. | Label change period and percent units; avoid color-only sign indication; verify four segmented choices at accessibility sizes. P2. |
| Settings | Native grouped sections; sync, account and data routes are discoverable. | Use a progress indicator/disabled retry while syncing, readable error recovery and a friendlier label such as “Review conflicting changes.” P2. |
| Backups / export | Native document exporter/importer; complete history is explained. | Prefer “Export backup” and “Import backup”; JSON can be secondary format information. Give completion feedback. P2. |
| Import confirmation | Preview counts and replacement explanation precede confirmation. | Name the action “Replace Portfolio” for state replacement versus “Merge History”; make replacement visually distinct and show goal-settings presence. Source-only. P2. |
| Permanent edit log | Saved changes and timestamps are retained and inspectable. | Use recognizable account/date summaries and values; keep IDs secondary. P1. |
| Change details | Full event content can be inspected. | Put financial change/context first; collapse technical identity and parents. P1. |
| Imported baseline details | Source values can be inspected, including empty rows. | Format dates/currencies and resolve account names consistently; distinguish import time from snapshot dates. Source-only. P2. |
| Conflict review, empty | Native empty state is clear. | Small copy improvement: explain no action is needed. No major issue confirmed. |
| Conflict review, populated | Each alternative can be retained through an explicit action. | Human names/units, current winner and context; explain that choosing saves a new change. Source-only. P1. |
| About | Readable native groups; privacy and calculation boundaries disclosed. | Add app version/build and a support route; describe behavior without leading with “native” implementation terminology. P2. |
| Watch net worth glance | Short hierarchy and freshness timestamp; no complex chart controls. | Label the change and comparison date, shorten long timestamp text, and represent stale/empty states distinctly. Source-only. P2. |
| Watch recent history | Simple vertical list suits the device. | Format parsed dates for the wearer rather than raw string prefixes; keep balance readability at larger text sizes. Source-only. P2. |
| Watch quick entry | One account/one total and an explicit phone-save action keep scope narrow. | Persistent labels, prefill known value where appropriate, numeric-friendly entry, and actionable pending/rejected states. Text input is justified for an arbitrary amount but should be minimized. Source-only. P1 labels/P2 workflow. |
| Watch complication | Shows useful balance and freshness data. | Per-family layouts, compact values, useful placeholder and sensitive-data treatment. Source-only. P1. |

## Accessibility and adaptive-layout checks still required

The system Form/List/NavigationStack primitives provide useful defaults. Swift Charts also provides automatic accessibility; absence of a custom accessibility descriptor is not by itself a proven defect. No contrast ratio or touch-target failure is claimed without measurement.

Before acceptance, use Accessibility Inspector and VoiceOver on charts, financial rows, amount editing, sliders, validation errors and conflict choices. Exercise accessibility text sizes, long names/providers, negative and million-pound balances, keyboard focus, Reduce Motion, dark/increased-contrast appearances and iPad resizing. Fixed chart heights and multi-option segmented controls are specific risks to inspect, not confirmed failures from this light/default-text capture. See [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility).

## Suggested change order

1. Persistent financial field labels and safe draft dismissal.
2. Clear zero/one/many-snapshot chart states and precise goal entry.
3. Human-readable audit/conflict screens.
4. Watch family/privacy layouts and quick-entry feedback.
5. Empty states, date/unit copy and adaptive/accessibility validation.

The existing tab/navigation structure can remain. These changes can use iOS 17-compatible SwiftUI components.
