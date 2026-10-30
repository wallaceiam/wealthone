# Whole-implementation review — 2026-10-28

## Verdict

**Changes required before acceptance.** Six Important findings below affect ordinary synchronized editing, the legacy recovery route, imported financial data, and recovery after local-storage failure. No Critical issue established. Previously reviewed core findings remain addressed; this review does not reopen unchanged core logic.

Read the actual native App, Views, Watch, Shared and Complication sources, core calculators and calculation tests, project generator/plists/entitlements, legacy export module/archive helper and tracked Settings/project diff, progress/ui reports and README against the approved design/event plan. Existing unrelated user edits were excluded. No implementation changes, subagents or suite reruns.

Evidence supplied by the coordinating agent: Swift 19 tests pass; legacy Jest 2 tests pass; Watch/Widget builds succeed; final integrated iOS build was still running after compile fixes when this review began. These are compilation/domain evidence, not exercised simulator UI or signed-device CloudKit evidence.

## Important findings

### 1. Saving a stale editor overwrites unrelated synchronized fields and resurrects deleted entities

Locations: `App/AppModel.swift:99–114,125–145,221–226`; `App/Views/PortfolioViews.swift` AccountEditorView Save/onAppear and EntryEditorView effectiveRecord/save.

AccountEditor snapshots name/provider/type when opened and sends the entire account when saved. Historical EntryEditor starts from its captured DayRecord and sends a full record. AppModel's `changed` compares these stale full objects with the *current* projection, so unrelated remote changes become intentional reversions in the new event. Because the new event parents the latest integrated heads, the reversion causally supersedes the remote change and is not flagged as concurrency.

Concrete example: historical editor opens A=10/B=20. Sync changes B to 30 and adds an inflow for B. User changes only A to 11 and saves. saveDay emits A=11, B=20, and null for the newly added inflow. Account provider edits similarly revert a synchronized name/type. If sync deletes the entity while its editor is open, these save methods silently choose `.create` with a fresh generation, resurrecting it; replacement epochs can likewise receive stale form data.

Fix: submit only explicitly touched fields (including explicit clears), capture/check original entity generation and dataset epoch, and surface deletion/replacement instead of auto-recreating an existing editor target. Separate create intent from edit intent. Add adapter regressions for remote disjoint updates, new fields, deletion and epoch replacement during an open form.

### 2. Legacy export presenter assumes a scene-based app; the legacy app has no scene lifecycle

Location: `ios/wealthone/LegacyJSONExporter.m:29–41`; compare `ios/wealthone/AppDelegate.mm`, `ios/wealthone/Info.plist`, and legacy project deployment target 12.4.

The exporter finds its presenter only through `UIApplication.connectedScenes` and foreground UIWindowScene key windows. The existing React Native app uses RCTAppDelegate's window and has no UIApplicationSceneManifest/scene delegate. Consequently the presenter discovery has no legacy window fallback, so Export can end in `export_present` rather than show the required share sheet. On supported legacy iOS 12.4, the iOS-13 scene APIs are also called without availability guards.

This blocks the staged-release JSON escape route the design explicitly requires. Use the React Native/application delegate window/presented-controller mechanism compatible with this actual app, with availability-guarded scene lookup only as appropriate. Exercise the real share sheet in the legacy app; mocked JS bridge tests cannot establish native presentation success.

### 3. Valid imported goal numbers can crash the app before the UI can report an unavailable projection

Location: `Sources/WealthOneCore/GoalProjectionCalculator.swift:38–40`; `App/Views/AnalysisViews.swift` GoalsView.projection and GoalEditorView's Int conversions.

Archive validation accepts finite Decimal goal values without bounded ranges. A valid state import with `goal: {"investmentStyle": 100000000000000000000}` therefore persists successfully. Opening Goals executes `Int(number("investmentStyle", 3))` before clamping to 0...6; this traps because the finite Double is outside Int's representable range. Huge retirementAge similarly reaches Int(years - 1) before clamping, and huge retirementAge/lifeStyle also trap in editor section titles. The later `.isFinite` chart filter never gets control.

Clamp/check finite Double ranges before integer conversion and define handling for out-of-domain imported goal settings; reject with a useful preview validation error or show an unavailable projection without trapping. Add regression coverage for finite out-of-Int-range imports, not only normal financial scenarios. Preservation of raw imported data can coexist with safe calculations.

### 4. Watch date handling disagrees with iPhone and produces wrong latest worth or a second record for today

Locations: `App/PhoneWatchBridge.swift:18–31`; `App/AppModel.swift:179–188`; compare `PortfolioCalculator.date` and EntryEditorView's parsed local-day lookup.

Watch history sorts raw date strings lexicographically. Supported imported millisecond strings do not share chronological lexical ordering with ISO/date keys. For example a 1999 millisecond record `946598400000` sorts after a new `2026-10-28` record, so Watch and its complication show the old balance as latest while iPhone correctly parses dates.

The phone's Watch-entry handler identifies today's existing record using `prefix(10) == command.day`. A supported millisecond record for today never matches; an ISO timestamp on the previous UTC date but today's local date also fails. A Watch quick entry then creates a separate today row containing only the selected account instead of updating the existing row and preserving its other totals/flows. This directly violates the quick-entry preservation requirement for migrated history.

Use one shared parsed-date/calendar-day policy for iPhone entries, Watch writes and chronological Watch snapshots. Keep the original raw identifier after locating the matching day. Cover mixed millisecond/ISO history and a London summer-time midnight boundary. Watch/phone differing calendar dates should remain an explicit rejection/review case as already implemented, not silently redate a command.

### 5. Local-load failure leaves an interactive app that silently claims saves/imports succeeded and cannot restore a backup

Locations: `App/AppModel.swift:25–34,37,194,208–218,230–231`; editor/BackupView success checks use `model.error == nil`.

If history.json cannot decode or validate, init keeps store nil and shows an alert. After the user dismisses the alert, ordinary UI remains enabled. `perform` returns immediately for nil store without setting an error. Saving an account closes its form; confirming a valid backup clears the preview and disables migration, but nothing is saved. Export produces a valid empty log because `events` returns [] when the store is unavailable. Sync and migration also cannot recover it.

Concrete sequence: truncated/corrupt history.json -> launch error -> dismiss -> Import valid full backup -> Confirm -> preview disappears, file remains corrupt, next launch fails again. This defeats the advertised recovery path and false-success protection.

Represent unavailable storage as a persistent application state. Disable normal saves/empty exports and throw/report failed operations. Provide an explicit recovery transaction that preserves/quarantines the unreadable original file, validates and durably installs a selected backup, then publishes success. Never silently overwrite the corrupt source or advertise successful restore before durable replacement.

## Compliance and quality assessment

The implementation has useful boundaries: immutable events remain authoritative; commands save before publication; full backups preserve history; state import has a visible preview and confirmation; legacy KVS reads preserve source values; CloudKit validates incoming event sets and colliding record IDs before upload/merge. Owner binding is persisted and a later observed owner mismatch pauses sync. Foreground activation, periodic passes and post-save attempts provide retry without depending on notification delivery. The transport enumerates all records and compares IDs, so no cursor-loss checkpoint dependency was introduced. Real account-change races, signed entitlements, schema setup and device sync still need the documented release validation; no independent signed-sync success is claimed here.

Watch commands retain IDs across retry, phone commit precedes acknowledgment, and duplicate committed commands do not append twice. However date integration in finding 4 breaks the intended one-account update behavior for supported legacy data. Watch amount parsing additionally uses permissive Decimal(string:) without the iPhone editor's full-string validation; align that validation when revisiting the Watch path.

The five tabs, history navigation, charts, account/day/goal editors, audit/conflict views and file import/export UI are present. Calculator tests provide concrete parity fixtures, including deliberately retained legacy formula anomalies. The native system-font substitution and unverified runtime accessibility/layout are explicitly reported; they should not be presented as full visual parity. Goal robustness in finding 3 needs resolution despite normal-case numerical parity.

Native development identity, iOS 17/watchOS 10 minimums, private container, legacy KVS entitlement and Watch App Group are explicit in configuration and README. Production cutover/schema promotion remains gated. Legacy source/history are preserved. Final build status should be recorded separately when it finishes; a successful build would not remove the behavioral findings above.

There are no AppModel/transport/Watch integration tests in the supplied suite, which is why domain convergence tests did not expose stale-editor writes or mixed-date adapter behavior. Add targeted tests around these concrete defects rather than treating the 19 core/calculation tests as end-to-end acceptance.

## Runtime addendum from coordinator

### 6. Important — unsigned simulator launch aborts before any UI/offline workflow

Location: `App/CloudEventTransport.swift:8` eagerly creates CKContainer; `App/AppModel.swift:22` constructs transport before repository loading.

The coordinator subsequently completed the integrated iOS/Watch build and launched on an iOS 17 simulator. Launch aborted with CloudKit's `process must have com.apple.developer.icloud-services entitlement` assertion at CKContainer initialization. Crash artifact: `/Users/chris/Library/Logs/DiagnosticReports/WealthOne-2026-10-28-135519.ips`. This is reported runtime evidence from the coordinator, not a launch repeated by this reviewer.

Because construction occurs before any throwable sync handling or local-store loading, the app cannot provide its offline workflow or even show the sync-unavailable message. Defer CKContainer construction until sync is requested and check the runtime entitlement/capability before calling CloudKit, allowing unsigned simulator/offline startup. A do/catch around synchronize cannot catch a framework process assertion during initialization. Verify launch and local create/save/reopen after fixing, and retain signed-device CloudKit as a separate gate.

Updated verdict: **six Important findings; changes required**. Integrated compilation has now succeeded, but the verified runtime startup failure remains blocking.
