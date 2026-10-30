# Independent premium UI review

Reviewed 28 October 2026 against the approved premium UI spec, implementation plan, implementation report and earlier HIG review. Reviewed actual current source rather than a committed diff because the native migration is uncommitted. No implementation files changed and no full tests rerun.

## Important findings

### 1. Returning birth date to its original value saves a different date

**Location:** `native-ios/App/Views/AnalysisViews.swift:263–267`, save at `326–327`.

**Trigger:** Open Edit goal with birth date A; change to B; change back to A; Save. The second change returns early because `birth == initialBirth`, leaving `fields["birthDate"]` and `fields["currentAge"]` set to B and its age, and both keys remain touched. Save sends those stale fields. The displayed date and age therefore disagree with what gets persisted, altering retirement projections unexpectedly.

Update the draft on every user date change, including reversion; restore the original stored representations/remove those touched keys when reverting so imported representations remain intact. Add a regression covering A → B → A → Save and reopen.

### 2. Exact-field validation remains stale when a dependent range changes

**Location:** `native-ios/App/Views/AnalysisViews.swift:239–249`, contribution range `286–291`, Save `329`.

**Trigger (blocked valid save):** Set earnings to 12,000, enter contribution 2,000 (invalid against the 1,000 upper bound), then change earnings to 36,000. The contribution now lies within the displayed 0–3,000 range, but remains in `invalidFields`; Save stays disabled until the user edits that field again. The invalid setter also left its previous value in `fields`.

**Trigger (invalid accepted save):** Set earnings to 36,000, enter contribution 2,000, then reduce earnings to 12,000. No contribution setter runs, so Save accepts 2,000 despite the new 1,000 maximum. Changing birth date similarly changes the retirement-age minimum without revalidating edited retirement text.

Derive/recompute validation from current draft text and current dependencies, including before Save. Preserve untouched imported values; do not silently clamp them to UI ranges. Add regressions in both dependency-change directions.

## Inspection results and limits

- All seven copied font binaries match the original React Native assets byte-for-byte (SHA-256 comparison). Every mapped Feather code point matches installed `react-native-vector-icons/glyphmaps/Feather.json`. Folder resource copying and `UIAppFonts` paths agree; app root configures custom navigation and light appearance. Installed-app font validation remains the parent agent's test evidence.
- Shared pale surfaces/cards and maximum readable widths implement the requested direction. SwiftUI custom text fonts use semantic scaling. Large text, small-screen account rows and chart controls still require the ongoing screenshot/runtime checks; source inspection alone cannot certify clipping or VoiceOver traversal.
- Chart filtering ends at the last snapshot, selection resolves to a visible point, and Home change captions describe the previous snapshot. Return and profit/loss remain cumulative calculator values within a filtered time window, rather than rebased period performance; clearer cumulative wording/date-span text would improve interpretation.
- Audit before-values use causal ancestors, and raw identifiers are in disclosures. Conflict choices preserve the existing resolution call and alternatives. Account/day editors retain captured contexts; goal saves are restricted to touched keys, subject to findings above.
- Draft bridge blocks dirty sheet dismissal and provides attempted-dismiss confirmation. Its delegate installation is asynchronous and traverses presentation ancestors; runtime swipe, cancel, keep-editing, discard and clean reopen checks remain necessary. No additional proven lifecycle defect was established from inspection.
- Invalid goal projections currently show “Unavailable” without a specific recovery instruction; this falls short of the plan's explicit invalid-projection explanation requirement. Add concise guidance to review goal inputs, ideally identifying the invalid assumption while preserving imported data.
- No Critical findings. Two Important behavior findings should be resolved before calling the redesign complete. Watch connectivity, event-core architecture and CloudKit were excluded as requested.
