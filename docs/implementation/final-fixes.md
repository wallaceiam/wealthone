# Final integration fixes — 2026-10-28

Read all six Important findings in `final-review.md`. This wave changes the native implementation and the legacy export bridge; it preserves the React Native source and unrelated TypeScript edits. No commit was created.

## Findings addressed

1. **Stale editors.** `EventStore.editContext` captures the entity generation, dataset epoch, form baseline fields and observed integrated heads. `submit` checks lifecycle before saving, filters against the form baseline, skips unchanged submissions, and parents only observed heads. Account, dated-entry and goal editors capture this context when opened. Day editing uses a captured record and emits explicit null only for fields present in that baseline; synchronized newly added flows and other fields survive. Deleted/replaced targets fail visibly instead of becoming creates. Simultaneous changes to the same field remain concurrent and reviewable. Goal editors retain their touched-field filtering. `CoreError` now supplies its actual message through `LocalizedError`.

2. **Legacy share presenter.** Scene lookup is availability guarded for iOS 13+. The existing application delegate window and application key windows provide fallbacks for the actual non-scene React Native app, including iOS 12.4. The existing presented-controller traversal and iPad popover configuration remain.

3. **Imported goal extremes.** The calculator checks finite ranges before integer conversion/table indexing. Unsupported imported retirement age/style/lifestyle and other numeric settings produce unavailable results without changing the imported data. Birth-date age calculation bounds extreme intervals. Goal editor slider reads clamp before integer titles and slider binding; clamping display does not rewrite untouched imported fields. Existing numeric parity fixtures remain green.

4. **Watch integration.** Snapshot history now comes from `PortfolioCalculator.netWorth`, using the phone's parsed chronological ordering. Shared core local-day lookup parses raw millisecond/ISO identifiers and retains the matched identifier. `applyQuickEntry` changes only the requested total, commits before publication/acknowledgment, validates account/day, and retains command-ID idempotency across repository restart and midnight. Reuse of an ID with different content is rejected. Watch input uses the phone's full-string numeric syntax and whole-pound truncation toward zero through the same `EntryAmount.parse` helper used on iPhone (positive/negative/huge decimal regression covered). Removed the misleading discard operation because an already delivered command cannot reliably be recalled. The default date-key calendar is Gregorian in the current timezone, matching the phone/Watch helper.

5. **Unreadable storage.** `storageUnavailable` persists independently of dismissible alerts. Home provides an explicit restore route; export is disabled and throws if invoked, and nil-store saves produce errors rather than success. Backup confirmation in this state is an explicit restore transaction: validate a candidate store, preserve the original as `history-unreadable-<UUID>.json`, atomically install the candidate, reload it, then publish success and enable normal operations. Invalid candidates leave the original unchanged. A preservation/install/load failure remains visible and retains unavailable state.

6. **Unsigned simulator startup.** Removed eager `CKContainer` construction. The compile-time simulator branch returns sync-unavailable before any CloudKit container access; the simulator migration path similarly avoids direct ubiquitous KVS access. Signed devices retain CloudKit and legacy KVS behavior. Offline local loading/editing does not require CloudKit initialization.

Also corrected the newly touched legacy Settings selector argument to describe the root `{portfolio, goal}` state shape rather than the portfolio-only `IState` interface.

## Regression evidence

RED: new adapter tests first failed compilation because `editContext`, `submit`, parsed day lookup and recovery APIs did not exist. The added extreme-goal import test then reproduced the original runtime trap: `Fatal error: Double value cannot be converted to Int because the result would be greater than Int.max` (xctest exited with signal 5). The later Watch adapter test first failed because `applyQuickEntry` was absent. The shared amount parser regression first failed because `EntryAmount` did not exist, then passed against the production Shared source compiled by iPhone and Watch.

GREEN: 27 Swift tests passed, including eight new adapter regressions: stale disjoint/new-field preservation plus same-field concurrency; deletion/replacement rejection; millisecond/offset local-day matching and chronological history; finite huge goal import; preserved unreadable file on successful restore; untouched unreadable file on invalid restore; durable migrated Watch update/restart/retry/date rejection; strict production input syntax and signed decimal truncation without Int overflow. Existing 19 domain/calculation/migration tests remain green, including normal goal parity.

Exact successful command:

```sh
CLANG_MODULE_CACHE_PATH=/tmp/wealthone-clang-cache SWIFTPM_MODULECACHE_OVERRIDE=/tmp/wealthone-module-cache swift test --disable-sandbox --package-path native-ios --scratch-path /tmp/wealthone-core-build
```

SwiftPM warns that user cache directories are unavailable in the workspace sandbox; compilation and all 27 tests pass using temporary build/module paths. Initial invocations without these settings failed in manifest module-cache/nested sandbox setup before tests.

Legacy archive regression command:

```sh
npm test -- --runInBand --watchman=false src/Redux/__tests__/WealthOneArchive.test.ts
```

Both tests passed. The first invocation with Watchman enabled failed because it attempted to write its LaunchAgents plist outside the writable workspace; disabling Watchman uses Jest's filesystem crawler.

## Remaining validation limits

The package tests exercise real core command and repository paths used by adapters, not SwiftUI automation or a signed CloudKit environment. The coordinating agent owns the final integrated iOS/Watch build and unsigned simulator launch/local save/reopen checks; this report does not assert their outcome. Real legacy share-sheet presentation on iOS 12.4/non-scene React Native and signed-device CloudKit/KVS/two-device account-change behavior remain release validation gates. The Objective-C fallback is source-reviewed, not established by the mocked JS archive suite.

## Scoped rereview follow-up

The final scoped rereview found two residual integration edges, now addressed:

- EntryEditor captures its editable account list alongside the record/context on opening and each selected date change. Sync-added accounts do not appear halfway through a form. Core `EditContext` also captures account generations; `submit` rejects a changed day field whose account was unobserved, deleted or replaced. This prevents falsely successful writes that projection would otherwise discard without parenting unseen remote events. Reopening captures the new account lifecycle and accepts the entry normally.
- Parsed dates now attempt ISO8601 fractional seconds before date-only fallback. Typical JavaScript `toISOString()` output such as `2026-06-30T23:00:00.000Z` maps to July 1 in London summer time and retains its raw record identifier.

RED: the new stale-account regression failed with “XCTAssertThrowsError failed: did not throw an error” and event count 3 instead of 2; replaced accounts also did not throw. The fractional local-midnight assertion returned nil instead of the original raw identifier. GREEN: same full Swift command above now passes **28/28 tests**, including nine new adapter regressions. AppModel initialization was left to the coordinator's isolated UI-test fixture change. Only EntryEditor, core context/date handling, regressions and this report changed during this follow-up.
