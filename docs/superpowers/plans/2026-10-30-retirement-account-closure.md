# Retirement timeline and account lifecycle implementation plan

**Goal:** Continue the actual-vs-projected illustration to retirement and preserve closed accounts with dated close/reopen operations.
**Architecture:** Extend the existing first-observation/current-assumptions curve; actuals remain observed only. Store account lifecycle as dated boolean fields in the existing deterministic event projection. Closing appends a zero balance plus additive closing outflow and status in one durable transaction. Reopening resumes entry eligibility with zero carried balance.
**Execution:** Direct implementation, then one independent review, as previously selected. Existing shared feature branch; preserve all unrelated work and signing. No commits or project regeneration.

## Constraints and decisions
- iOS/watchOS26, SwiftUI, native Apple styling, eight existing currencies, saved rates.
- Default lifecycle action is today; allow dates from latest account observation/status through today. Reject earlier/future dates to avoid silently changing later balances. Preserve historical entry access; closure-day amounts are read-only while closed.
- Deleting an account that ever had an entry is prohibited. Empty accounts may still be deleted.
- Zero balance requires no outflow; signed balances use signed outflow in the existing account-unit flow convention.
- Projection retains current assumptions, samples annually plus exact retirement birthday, never fabricates future actual values; unsupported retirement settings leave history available.
- Close/reopen and financial draft saves validate captured lifecycle state, preventing stale forms/Watch delivery from reintroducing a closed balance. Duplicate acknowledged Watch commands remain idempotent.

## Tasks
- [x] 1. Tests first: retirement endpoint, no future actuals, leap birthday/fractional age, invalid/past horizon. Extend GoalHistoryComparison and Swift Charts rendering.
- [x] 2. Tests first: old archive defaults; dated closed status; close zero/outflow/preserved flows; reopen zero; roundtrip/replay; rollback; history deletion guard; stale entry rejection; currency conversion. Implement Domain/Events/Projection/Archive/EventStore.
- [x] 3. Expose lifecycle actions in Settings account editor with review confirmation, date and account-currency amount; filter new iPhone/Watch entries, retain historic read-only balances; audit labels.
- [x] 4. Run full core tests, native phone/Watch build and appropriate simulator UI checks; independent review once, fix significant findings with regression tests, document results.

## Review focus
- Concurrent close/edit, same-day close/reopen and duplicate commands.
- Old timestamp day identifiers, dated historical forms and closure-day zero preservation.
- FX unavailable at closure: preserve prior saved rates and never guess conversion.
- Delete historical or closing day, leaving status without zero observation.
- Chart optional actuals and latest-vs-retirement labels; no invented future actuals.

## Implementation and review notes
- Closed status overrides derived balances for closed intervals; late offline raw observations remain in history but cannot resurrect balances or flows while closed. Reopening continues from the lifecycle-adjusted zero balance.
- Closing status stores the exact settlement record identifier, preserving old timestamp day IDs and deterministic merge behavior across time zones. Closing settlements are protected from concurrent whole-day deletions; deletion events remain permanently auditable.
- Independent final reviewer found concurrent settlement deletion and phantom second closing outflows; both reproduced in failing tests and corrected. No deferred findings.
