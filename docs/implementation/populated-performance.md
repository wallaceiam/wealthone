# Populated performance ledger

User confirmed every category slow: launch, tabs, scrolling, saving/sync. Direct implementation follows existing chosen workflow; no extra design/permission gate for a reproduced performance bug.

Baseline debug CLI (same imported shape, no balances printed): decode0.2336s; portfolio calculation0.5323s; seven calculations3.6429s; date sort0.3027s; baseline replay1.0986s; unchanged merge/replay0.7449s. These are local Mac CPU timings, not claims about the physical iPhone.

Root causes verified in source: per-body repeated portfolio getters, full recalculation per History year, date parsing inside sort comparators, repeated Breakdown sorting per row/color, quadratic metric scans, per-entity full projection scans, unchanged merges replaying/persisting and republishing. Preserve calculator semantics and event history; optimize access/indexing rather than replace formulas.


Implemented:
- Batch-owned date formatters and a single date parse per record; no formatter state shared across actors. Linear running products/year state preserve the old floating-point arithmetic order, including the unusual yearly return recurrence.
- Indexed projection version keys and final fields by entity. Causality, generations, removals, conflicts and winner selection remain unchanged.
- Empty/exact-duplicate merges validate collisions but skip replay/commit. Clock-only updates remain durable and commit before in-memory state changes.
- Immutable PortfolioReadModel holds the snapshot, chronological records, latest record, portfolio/account histories, grouped years and account/type allocations. AppModel caches by snapshot and calendar context; screens and Watch share those results.
- Chart window, nearest selection, scale and allocation colors are computed outside per-mark/per-row closures. Local calendar refresh runs before network synchronization so offline devices can invalidate their cache.

Representative after timings, same debug CLI/Mac/input: decode0.1093s; one portfolio calculation0.0502s; seven uncached calculations0.3220s; replay0.2239s; unchanged merge rounded0.0000s. Preparing the complete shared read model including all seven account histories takes0.0576s, and seven unchanged cache checks0.0001s. The standalone old comparator-sort benchmark still costs0.3081s; production screen ordering no longer uses that comparator.

Validation:
- 67 core tests passed, including a frozen reference calculator with exact equality for every metric over synthetic sparse/negative/zero balances and multiple year boundaries, mixed date formats/local-day lookup, cache reuse/edit/calendar invalidation, duplicate merge collision/write guards and remote clock advancement.
- Private verification compared every point/metric for all344 dates in the recovered portfolio and all seven account histories against the previous implementation: exact matches. No private fixtures/balances were added to the repository.
- Simulator build-for-testing and unsigned physical iPhone/embedded Watch build passed.
- Both ChartRefinementTests passed: compact controls/goal estimates and the populated344-record journey (separate runs after fixing an XCTest range-control query). The populated test exercised All-range chart dragging, all five tabs/scrolling, save/cache invalidation and process relaunch; updated synthetic total persisted. Saved screenshot inspected.
- Independent focused review identified offline calendar refresh; fixed by moving local refresh before the network await.

The synthetic populated UI test is ChartRefinementTests.testPopulatedPortfolioNavigationAndEdit. It skips unless its runner receives WEALTHONE_PERF_TEST_STORE (a UUID). Seed that UUID's isolated simulator Application Support/WealthOneUITests/<UUID>/history.json with Tools/seed-performance-fixture.swift, compiled as main.swift alongside core sources. The tool only creates a new file (withoutOverwriting), never overwrites one. The test exercises all tabs, scrolling, All chart range, editing the most recent synthetic record and reopening. Its elapsed journey includes XCTest input/idle overhead; it is a functional regression rather than an FPS or device-speed claim.

Physical-device interaction speed and iCloud/Watch network latency still need confirmation on the user's hardware. Cloud transport behavior and signing identities were not changed. Full immutable history is retained; no pruning or destructive data migration.
