# WealthOne native Apple design

## Approval and intent

The user approved the blue single-hue light/dark iPhone previews and matching Watch/icon board, then chose direct implementation with an independent final review. This supersedes the earlier requirement to retain Karla, Montserrat and Feather in the native UI. Preserve the React Native source and its existing edits.

Use Apple Music navigation and Stocks financial hierarchy: system typography, SF Symbols, flat content, compact controls and native Liquid Glass above the content layer. No neomorphic cards, permanent light-only appearance, or custom opaque navigation backgrounds.

## Platforms and appearance

- iOS/iPadOS minimum 26.0. Watch app and complication minimum watchOS 26.0 for the corresponding native controls. The Foundation-only core remains platform-independent.
- Respect the system light/dark appearance. Watch uses its native black-background presentation; it has no separate light mode.
- One chromatic blue family: primary system blue, darker/middle/lighter blue chart tones; neutral semantic foregrounds/backgrounds. Destructive/error affordances may retain native semantic colours for comprehension.
- Native tab bars, toolbars, menus, segmented controls and sheets supply glass automatically. Do not simulate it with bitmap assets or put glass behind charts. Respect Reduce Transparency, Reduce Motion and Dynamic Type through native components.

## Screens

Home: large native WealthOne title; net worth and snapshot date, existing change with an accurate period; compact trailing metric menu; line chart with subtle area tint; native period selector; flat Assets/Liabilities summary; compact account rows and accessible add-entry/account actions. No duplicate amount until deliberate chart selection. Empty, migration and storage-error states remain actionable.

Breakdown: native title and account/type segmented control, blue tonal donut, directly labelled account amounts and percentages, liabilities below. Preserve positive-assets-only calculation and empty/negative handling. Use text as well as tones to distinguish entries.

Goals: native title/Edit action, Savings/Annual income selector, blue tonal bars, full-width dashed Current rule with contrast-adaptive label. Group percentages under amounts. Preserve exact inputs, full-precision display estimates, legacy formula semantics, unavailable states, safe sliders and draft protection. The Current line uses net worth in Savings and annual earnings in Income; never mix units.

History, Settings, backups, edit log, conflicts and all editors adopt system typography, adaptive colours and native list/form surfaces. Preserve every existing action, field label, technical disclosure and saved-history pathway. Retain guarded dirty-sheet dismissal and explicit Cancel decisions.

Watch: glance with net worth, previous-snapshot change, history sparkline, update timestamp, Quick entry and Recent history links. Quick entry keeps account picker, today's account total, durable pending/retry state, and Save on iPhone acknowledgment semantics. Empty/disconnected state must remain visible. History shows phone snapshots, not invented market data. Complications use family-appropriate total/update-time layouts, including always-on/tinted contexts. Existing WatchConnectivity receive issue is not assumed fixed by styling.

## Icons

Keep the recognizable existing rising-chart motif. Produce crisp code-native/vector-based artwork, not extracted AI mockup pixels. iPhone light icon: pale field and sapphire line; dark icon: dark blue field and pale line. Watch: blue field and pale line with the main motif safe inside circular cropping. Supply unmasked square resources to the asset catalog; system applies platform masks. No letters, labels, currency or Apple logo. Add the currently missing Watch icon catalog and build setting. Keep old icon files/history available.

## Approaches and implementation decisions

The user selected full Apple styling over keeping custom legacy fonts/icons, then blue tones over grayscale. Prefer native navigation/glass and existing Swift Charts over a custom visual framework. Mockup figures are illustrative; production displays only real projections. Mockup chevrons do not create new destinations. WatchOS 26 is an implementation decision matching the selected phone generation; cost is dropping older Watches from this native replacement.

## Validation

Run domain/shared regressions, phone UI scenarios in light/dark and accessibility sizes, iPad reachability, and Watch/complication builds. Inspect actual captures, including no-data and pending states. Preserve same IDs/entitlements, legacy migration, cloud transport, local storage and financial formulas. Do not publish, change signing identities or claim live cloud/Watch sync verified. Changes remain reviewable in the existing feature branch.
