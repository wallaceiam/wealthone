# WealthOne premium light UI direction

## Requested visual direction

A premium native finance experience: white and soft gray light surfaces, restrained neomorphic depth, pastel corporate blue accents, minimalist wealth charts, crisp readable controls and generous spacing. The 9:16 preview is a visual reference; real iPhone/iPad screens remain adaptive and scrollable.

## User refinement

The user selected a softer, lighter direction with more room around components. Use near-white surfaces, pale powder blue, lower-contrast shadows/dividers, larger outer margins and more vertical space. Keep dark navy financial text readable. Allow account content to continue below the scroll fold rather than shrinking rows to fit everything onscreen.

## Existing brand assets — required

The user explicitly requested retaining typography and iconography from React Native. Reuse the files directly in the native targets:

- Karla headings: `src/Assets/fonts/Karla-Regular.ttf` and `Karla-Bold.ttf` (the existing h1/h2/h3 styles use the Karla family).
- Montserrat body typography: appropriate Regular/Medium/SemiBold weights from `src/Assets/fonts/` (existing base body style declares montserrat). Preserve Dynamic Type scaling with SwiftUI custom fonts relative to semantic text styles.
- Feather outline icon family: `src/Assets/fonts/Feather.ttf` and the installed glyph mapping, rendered by a small native SwiftUI component. Existing tab symbols are `home`, `bar-chart`, `target`, `list`, `settings`; actions include `plus`, `save`, `trash-2`, chevrons and `sliders`. Verify the exact individual component glyph names before mapping.
- Existing WealthOne app icon remains the brand identity asset.

Retaining these assets requires no React Native runtime. Generated image typography/icons are illustrative; the production rendering must use the actual bundled assets and verified font PostScript names, with readable sizing and accessible text labels.

## Proposed approach

Use native SwiftUI navigation and controls with a shared palette, typography, spacing, card and chart system. Apply soft shadows primarily to summary surfaces; keep interactive elements clearly identifiable and financial text high contrast. This translates the supplied visual style into native components while addressing the HIG review's readability findings. Heavy embossed decoration would compete with financial data, so the proposal uses shallow surface depth.

## Dashboard composition

1. WealthOne header and clear contextual date.
2. Prominent net worth summary with the change period stated explicitly.
3. A restrained blue chart with visible single-data-point and empty states, labelled monetary/percent values and a legible date range.
4. Asset and liability summaries.
5. Add snapshot action and account rows with persistent names, providers and right-aligned balances.
6. Existing labelled five-tab navigation.

Preview amounts and growth are illustrative, never hard-coded into the running portfolio. Change captions must match the actual period used by the calculator.

## Shared screen treatment

- White cards over a soft neutral background; pastel blue fills and stronger blue interactive text, semantic error/success indicators and system-aware typography.
- Persistent financial field labels, explicit units and readable values; exact numeric controls where sliders are insufficient.
- Human-readable account/date/value summaries in edit history and conflicts; technical identities available through disclosure.
- Clear onboarding, no-data, sync, validation and recovery states.
- Draft dismissal protection should be implemented and tested as a separate behavior task alongside the visual pass.
- iPad uses the same design language with appropriate readable widths and adaptive grouping. VoiceOver, large Dynamic Type and Reduce Motion need explicit checks.
- The Watch retains native watchOS presentation; a corresponding blue accent/glance hierarchy can follow the phone design once approved.

## Implementation sequence after visual approval

Create shared theme/components, implement the dashboard using actual projections, propagate the shared treatment through the remaining iPhone/iPad screens, then validate screenshot journeys, large text, light/dark appearance behavior and input accessibility. Map each HIG finding to a concrete change/test; do not silently change calculation semantics while improving their presentation.

## Status

Approved for implementation by the user: “do it”, following the softer/lighter spacing refinement and explicit reuse of existing fonts/icons.
