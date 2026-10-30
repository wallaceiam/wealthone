# Independent core review — 2026-10-28

Scope: all current files in `native-ios/Sources/WealthOneCore`, both test files, the approved event-ordering design, event-sourcing plan Task 1, `core-report.md`, and `native-core-api.md`. LegacyReduxDecoder integration was included. iOS UI, CloudKit transport, Watch, and signed-device behavior are excluded. No implementation files or tests were changed and no commits were created.

## Verdict

**Changes required.** No Critical issue found. Three Important issues remain, including a normal offline workflow that loses an independently saved field from the current projection without conflict metadata. The implementation is compact and its save-before-publish boundary is sound on inspection, but the existing 10-test suite is too narrow to establish the claimed field-preservation and validation guarantees.

## Important findings

### 1. Concurrent creation of the same day discards disjoint saved fields

Location: `native-ios/Sources/WealthOneCore/Projection.swift:124–136` (creation collection at 116–118).

Counterexample: two installations share a baseline containing accounts A and B and no record for today. Offline, the first creates today's day with generation `left` and `totals:A = 10`; the second creates the same date with generation `right` and `totals:B = 20`. Both are valid commands. Merging selects the canonical maximum creation, filters out the other generation, and only displays B's 20. Conflict metadata is empty. Using an identical generation string on both devices does not fix this: the eligibility check still requires the value event to descend from the selected creation event.

This violates per-logical-field resolution and preservation of unrelated values. All immutable events remain in history, but the current portfolio silently loses one user's independently saved total. The same mechanism drops subsequent edits descending only from the losing creation. A deterministic result alone does not satisfy the field-preservation requirement.

Required direction: define concurrent initial creation of the same logical day as a shared lifecycle whose disjoint fields merge, while retaining explicit deletion/recreation boundaries. Cover both distinct and identical generation identifiers, two different account fields, conflicting values on the same field, and delete/recreate after convergence.

### 2. Normal commands and full event archives bypass essential account/date validation

Locations: `native-ios/Sources/WealthOneCore/Events.swift:38–78`, `Projection.swift:162–166`; compare stricter baseline checks in `Archive.swift:21–35`.

Counterexample executed: `append(.create(.account("bad"), generation: "g", fields: ["name": .string(""), "accountType": .decimal(999.5)]))` succeeds and publishes an account with an empty name and account type 999. Decimal account types are silently truncated by projection. Empty fields can also create an unnamed account. These values would be rejected as a replacement baseline, but normal commands and version-2 archives accept them. On the merge/archive path, `.day("garbage")` also passes entity validation (only nonempty identifiers are checked), whereas local append rejects it.

This breaks Task 1's validated command/import boundary and permits durable invalid states through the public core API. Account type feeds financial classifications, so truncation/out-of-domain values are material. Validate required creation fields, nonblank names, integral supported account types and the asset/type relationship under an explicit concurrency policy; validate historical date syntax in event replay as well as state import. Do not fix this by rejecting legitimate partial updates indiscriminately.

### 3. Goal import silently drops malformed settings and baseline validation accepts NaN

Locations: `native-ios/Sources/WealthOneCore/Archive.swift:145–154` and `21–37`; `LegacyReduxDecoder.swift:14–18,33` routes through this parser.

Counterexamples executed:

- `{"accounts":[],"records":[],"goal":{"input":{"retirementAge":{"bad":42}}}}` imports successfully with an empty goal. Unsupported values are skipped, and a non-object goal is likewise treated as absent. A malformed primary Redux/KVS source can therefore be considered successful instead of triggering fallback, losing goal inputs when saved as the migration baseline.
- `Archive.validate(Snapshot(goal: ["retirementAge": .decimal(Decimal.nan)]))` succeeds. Replacement validation does not inspect goal values at all, contradicting the implementation report's statement that the core checks goal finiteness. The create/edit validation checks NaN, so this is another inconsistent entry path.

Reject malformed supplied goal structures/values, distinguish genuinely absent optional settings from malformed ones, preserve supported Value types, and apply finite-number validation to baseline goals. Add decoder-level regression coverage proving malformed primary state is rejected for the migration adapter to fall back.

## Evidence

The reported baseline suite is **10 tests passed, 0 failures** at 13:27:11 UTC in `core-report.md`; it was not rerun for this review. A temporary standalone Swift executable compiled the actual core sources and exercised only the discovered counterexamples. Command:

```sh
swiftc -module-cache-path /tmp/wealthone-review-module native-ios/Sources/WealthOneCore/*.swift /tmp/core-review-main.swift -o /tmp/core-review-check
/tmp/core-review-check
```

Observed output:

```text
Concurrent day totals: ["b": 20] conflicts: 0
Accepted account: [main.Account(id: "bad", name: "", provider: "", isAsset: true, accountType: 999)]
Accepted baseline NaN goal
Malformed goal decoded: [:]
```

## Compliance and quality assessment

- Field updates within one established generation use causal maxima followed by the approved Lamport/actor/event ordering. Ordinary divergent edits retain conflict metadata, and resolution parents all integrated heads.
- Missing causal chains are buffered. Integrated events validate parent-clock monotonicity and epoch causality. Duplicate event IDs with differing content and actor/counter reuse are rejected. Existing tests cover basic permutations, duplicates, cycles and missing parents, but not concurrent day creation or rich lifecycle graphs.
- Replacement epochs and generation tombstones prevent the tested delayed old edits from resurrecting records. Account recreation also filters historical values by account-generation causality. No independent flaw was found in these tested boundaries, subject to finding 1's concurrent-creation semantics.
- Full backup exports retain all events and versions, including buffered events. Corrections/deletion/replacement append rather than rewriting history. State-only migration correctly establishes a baseline without fabricating old edit history.
- Persistence constructs and validates a candidate projection/envelope, invokes the injected commit, and only then publishes memory. Command and merge failure atomicity is supported by existing tests. Foundation atomic file replacement does not itself establish power-loss guarantees or concurrent-writer safety; these limitations are already documented.
- LegacyReduxDecoder handles raw state and compressed Redux slices via the common archive validator. Existing tests provide a real LZ-string fixture with Unicode and decimals plus malformed compressed input. The decompressor has output/dictionary limits. The common goal-validation issue above affects direct migration too; transport-source precedence was outside this core review.
- The Foundation-only package/API separation is useful. Validation rules are spread across replay, append, and archive import and already disagree; consolidating the shared invariants would reduce future gaps. Full-log replay/ancestor-set scaling remains unbenchmarked, as reported.

Task 1 should not be considered fully accepted until the Important issues are fixed with targeted regression tests. This report makes no UI, transport, signing, or real-device claims.
