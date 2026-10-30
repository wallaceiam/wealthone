# Final scoped re-review — 2026-10-28

Scope: six findings in final-review.md and breakage introduced by their fixes. Read final-fixes.md and current AppModel/CloudEventTransport, form context wiring, EventStore command/recovery helpers, calculator/date helpers, phone Watch projection, shared amount parser, legacy Objective-C presenter, and adapter regression tests. No suite rerun, source edits or subagents. Reported evidence is 27 passing Swift tests and prior iPhone/iPad simulator interaction checks; final builds after the latest shared parser edit are being repeated by the coordinator.

## Verdict

**Changes still required: one residual Important issue and one new Important regression.** Five original findings are addressed; finding 4 remains incomplete for the actual fractional-second legacy export format.

| Original finding | Status | Assessment |
| --- | --- | --- |
| 1. Stale editor overwrites/resurrection | ADDRESSED | Captured fields/epoch/generation and observed causal heads prevent unrelated reversions and reject deleted/replaced targets. Same-field unseen edits remain concurrent. See new dependency regression below. |
| 2. Legacy scene-only presenter | ADDRESSED | Scene APIs are iOS-13 availability guarded, with delegate-window and application-key-window fallback for the existing non-scene app. Actual native share presentation remains a device/runtime gate. |
| 3. Extreme imported goal crash | ADDRESSED | Numeric ranges are checked before Int conversion; bounded age computation and clamped editor reads remove the reported traps while retaining raw input. Normal parity fixtures reportedly remain green. |
| 4. Watch raw date handling | NOT ADDRESSED completely | Watch now uses shared chronological calculation and raw-identifier lookup, but the shared parser drops time/offset for fractional-second ISO strings—the exact legacy export shape. |
| 5. Nil-store false success/recovery | ADDRESSED | Persistent unavailable state, throwing exports, explicit save errors, and a validate/copy-original/atomic-install/reload recovery path address the reported corrupt-file sequence. Candidate validation precedes touching the source; original bytes are retained. |
| 6. Unsigned simulator crash | ADDRESSED | CKContainer is no longer eagerly initialized; simulator sync returns before CK access and simulator migration avoids KVS. This is a simulator capability branch rather than a general runtime entitlement probe; signed-device provisioning remains a gate. |

## Residual Important: fractional ISO dates still create the wrong Watch day

Location: `Sources/WealthOneCore/PortfolioCalculator.swift:16–22` and `record(on:records:calendar:)`; `EventStore.applyQuickEntry` consumes this parser.

The parser tries default ISO8601DateFormatter, which does not enable `.withFractionalSeconds`, then falls back to the first ten characters as a local date. Legacy `createWealthOneArchive` uses JavaScript `Date.toISOString()`, which emits fractional seconds. Thus the ordinary exported key `2026-06-30T23:00:00.000Z` represents July 1 midnight in London summer time, but falls back to June 30 local midnight. A July 1 Watch entry does not find the migrated record and creates a new row with only its selected total. This remains the original preservation defect, despite unifying the lookup paths.

Add a fractional-second ISO parse attempt retaining the instant/offset before plain-date fallback. Cover that exact legacy-export key with a fixed Europe/London calendar and assert the existing raw key and unrelated totals/flows survive quick entry. Also assert chronological ordering for mixed fractional/nonfractional forms.

## New Important: captured parents omit newly visible account dependencies

Locations: `App/Views/PortfolioViews.swift:214` (live account list) and `save()` live-account loop; `EventStore.submit` passes `context.parents` to append; Projection's day eligibility requires causal observation of the current account generation.

Concrete sequence: open a dated editor and capture heads H. Sync creates account B after H. The open form uses live `model.snapshot.accounts`, so B appears and the user enters B=20. Submit accepts it because B exists in the current projection, but the new event parents only H. Projection therefore discards B=20 because the event does not causally observe B's creation. The durable event exists, the save reports success and closes the editor, yet the value is absent. Recreating an existing account while a day form remains open exposes the same generation-dependency mismatch.

Fix by making the editable account set/generations part of the captured context and rejecting a save against a newly introduced/replaced account until the form refreshes, or explicitly incorporating newly observed account-lifecycle dependencies without turning unseen same-field edits into causal overwrites. Merely parenting all current heads would reintroduce the stale-intent problem the fix was designed to avoid. Add a regression that captures a day context, adds/recreates an account, submits a value for it, and requires either a visible rejection or a value that survives projection.

## Other notes

The shared EntryAmount helper now applies strict whole-string validation and Decimal truncation toward zero without Int conversion; no new issue identified there. The recovery code's missing-source/copy failure remains visible rather than claiming success. Final simulator launch/local save/reopen and integrated build evidence should be recorded independently by the coordinator; no signed CloudKit/Watch/native legacy-export success follows from this source re-review.
