# Core scoped re-review — round 1

Reviewed current Events.swift, Projection.swift, Archive.swift, ReviewRegressionTests.swift, existing CoreTests.swift, and the appended correction/evidence section in core-report.md against the three findings in core-review.md. No source/test changes, test executions, commits, or subagents. This is a scoped correction review, not a new full-system audit.

## Verdict

**All three original findings ADDRESSED.** No new Critical or Important breakage established within the requested correction scope. The reported full-suite evidence is 19 passing tests at 13:46:10 UTC, with preceding targeted failing runs documented by the implementer; these runs were not independently repeated.

1. **Concurrent initial day creation — ADDRESSED.** Projection groups initial day creation aliases into a common lifecycle and normalizes their fields before computing causal maxima. This works for both shared and distinct caller generation identifiers, and descendants on the formerly losing branch remain eligible. Removal of an observed alias tombstones its lifecycle; recreation observing the removal forms a successor. Regression coverage checks disjoint fields, same-field conflict metadata, losing-branch descendants, reversed ordering/duplicates, removal, recreation and delayed old edits. The original two-device counterexample is handled by the actual implementation.

2. **Account/date validation inconsistency — ADDRESSED.** Shared operation validation requires nonblank creation names, rejects blank name updates, checks integral supported account types, and checks historical day syntax on replay/archive paths. Creation classification defaults are coherent. Partial account edits are checked against their causal view, preserving partial provider/name updates while rejecting invalid kind/type combinations. Snapshot classification derives from the winning type when independent changes disagree, and subsequent edit validation uses the same normalization. This is an explicit cross-field consistency policy, with raw saved versions retained for audit; it should remain documented because the derived snapshot kind can differ from the raw isAsset field winner. Current-state parsing now rejects malformed/fractional supplied types and nonboolean kinds. Regression tests cover the reported invalid operations and a concurrent-classification follow-up edit.

3. **Goal omission/NaN — ADDRESSED.** Supplied goal and input containers must be objects; unsupported nested values throw instead of disappearing. Supported bool/null values survive. Archive.validate now invokes common value validation for baseline goals, closing the replacement NaN bypass. Tests cover direct archive import, LegacyReduxDecoder's raw-state integration, baseline validation and replacement rejection, plus supported bool/null preservation. Existing compressed-slice integration still feeds the same Archive.snapshot validator.

## Minor test-maintenance observation

`CoreTests.testDurabilityArchiveAndLifecycle` still attempts an account creation with empty fields against the throwing commit closure. New name validation now rejects this command before reaching commit, so that particular assertion no longer tests failed command persistence. The implementation's save-before-publish ordering is unchanged and the separate merge failure case remains meaningful, but change this fixture to a valid named account and ideally assert that commit was invoked to retain the originally intended command-failure coverage. This is a test regression, not evidence of a newly broken persistence implementation.

## Limits

The new lifecycle grouping is more involved than the original winner-only rule. The reviewed regressions establish the original initial-creation counterexample and a subsequent delete/recreate boundary; they do not exhaust every branching delete/recreate graph. No additional correctness claim is made for those graphs, large-log performance, UI, CloudKit transport, Watch, or signed-device behavior. The established history permanence and persistence sequencing were not altered by these fixes.
