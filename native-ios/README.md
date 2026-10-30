# Native WealthOne

Native SwiftUI iPhone/iPad replacement and focused Watch companion. Minimum iOS/iPadOS 26 and watchOS 26. React Native and Android source remain preserved; Android is retired from the replacement release scope.

## Open and run

Open `WealthOne.xcodeproj`, select **WealthOne**, and choose an iPhone/iPad simulator. The app uses development identity `ca.mymojo.wealthone.native` so it can coexist with the legacy app. No Metro or npm installation is needed for the native app.

The project is checked in. If adding source files, regenerate from the repository root with the existing vendored xcodeproj gem:

```sh
GEM_HOME="$PWD/vendor/bundle/ruby/2.6.0" ruby native-ios/Tools/generate-project.rb
```

Build both platforms together without an explicit `-sdk` override (a global iOS SDK override also incorrectly compiles Watch targets as iOS):

```sh
xcodebuild -project native-ios/WealthOne.xcodeproj -scheme WealthOne \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/wealthone-ios-build CODE_SIGNING_ALLOWED=NO build
swift test --package-path native-ios --scratch-path /tmp/wealthone-core-build
```

## Data architecture

The `WealthOneCore` Swift package has no UI or CloudKit dependencies. Saved commands append versioned immutable events; deterministic projections derive portfolio/account/day/goal views. Values use Decimal. Events carry causal parents, a Lamport counter, installation ID, immutable event ID and a display-only timestamp. Independent field edits merge; independent differing edits to one field use the canonical maximum `(counter, actor, event ID)` and remain available in conflict review. Corrections/resolution append events.

A local `Application Support/WealthOne/history.json` envelope stores installation identity, logical clock and full log in one atomic file replacement. A failed save does not publish changed memory. Editors retain their opening history context and submit only changes based on that context, so background sync cannot silently revert other fields or resurrect a deleted item. An unreadable local store blocks normal saves/empty exports; explicit backup recovery preserves a separate copy of the unreadable file before installing a validated replacement. Backups have `version: 2` and contain the complete event log; importing them merges immutable IDs. State-only legacy/v1 imports create a replacement dataset epoch, retaining earlier events in history. Deletion tombstones entity generations; explicit recreation cannot recover values by accident. Concurrent creation of one calendar day merges independently edited fields.

Only immutable event envelopes synchronize to the private CloudKit `WealthOneEvents` record zone as `WealthEvent` records with `payload` assets. Projections stay local. Sync runs after saved edits, on app activation, periodically while active and through Settings. It enumerates all events through custom-zone changes from a nil initial token rather than a type-specific query, so a fresh development database can upload its first event before a WealthEvent schema exists. It paginates and validates all downloaded events before uploading; this is suitable for the initial personal-use app, with log-growth benchmarking still required. Sync state is derived by comparing immutable local/remote IDs on each pass. Retry retains local data. A persisted iCloud owner binding pauses sync after an account switch to prevent uploading one account's history into another.

The Watch receives a small snapshot from the phone. Quick entry queues a durable command ID using WatchConnectivity, updates one account total for today, and only reports saved after the phone commits the event. An entry arriving on a later day is rejected for review instead of silently changing its date. The complication shows the last phone snapshot timestamp; refresh timing is controlled by watchOS.

## Signing and iCloud setup — device validation required

The code builds unsigned for simulators. Simulator builds intentionally skip live CloudKit and legacy KVS access, allowing offline and JSON workflows without iCloud entitlements. Signed physical-device builds use the real services. Real iCloud behavior needs an Apple Developer configuration and signed-device validation:

1. Register the development app/Watch/extension identifiers with signing team `2LG9PUJ57N`:
   - iPhone/iPad: `ca.mymojo.wealthone.native`
   - Watch: `ca.mymojo.wealthone.native.watchkitapp`
   - Complication: `ca.mymojo.wealthone.native.watchkitapp.networthwidget`
   Use the same enrolled developer team on all three targets. If Xcode reports an identifier unavailable, check that team first. Apple must confirm registration availability; an unsigned local build cannot. The former complication suffix `.complication` was rejected during device signing and replaced with `.networthwidget`. Keep the generator and project consistent when adjusting an identifier. Do not rename the phone/iCloud/App Group identities as a workaround for an extension-only error.
2. Create and authorize private container `iCloud.ca.mymojo.wealthone.native`; enable CloudKit and remote notifications. Use the same container in beta and final native production identities.
3. Initialize the development `WealthEvent` schema (record `payload` is an Asset) and verify zone query permissions/indexes. Promote the schema only after signed beta sync/recovery checks.
4. Authorize the legacy KVS entitlement `$(TeamIdentifierPrefix)ca.mymojo.wealthone` on the side-by-side native build. A differing app bundle ID by itself does not grant access. Confirm provisioning supports this legacy store identifier.
5. Register/authorize Watch App Group `group.ca.mymojo.wealthone.native.watch` for the Watch app and complication. Verify complication snapshots and offline/duplicate command delivery on a paired device.
6. Verify iPhone/iPad sync with the same Apple ID, offline edits, switch/reconnect, deletion/recreation, conflicting same-value edits, corrupted backup rejection, full-log backup round trip and migration source precedence.

CloudKit is not a guaranteed immediate backup. Keep an exported full-history file. App removal/device loss before upload can lose unsynchronized local events.

## Recover old iCloud data without React Native

In the native app on a signed physical iPhone/iPad, open **Settings → Recover previous iCloud data** (also available from onboarding). Use the same Apple Account as the old app. Keep the screen open: it subscribes before requesting sync and continues observing after the 45-second waiting message. “No data has arrived yet” is not confirmation of deletion. Recovery is separate from the new CloudKit event sync.

Review the recovered copies, account names and latest dated balances. **Export recovered JSON** saves a validated baseline readable by native Backups. **Export original iCloud data** preserves the three original stored strings for further recovery support, even if decoding fails; that raw support file is not the normal import format. Searching/exporting never changes legacy iCloud values or the native portfolio.

If the native build is denied access or cannot use the legacy entitlement, select Xcode scheme **WealthOneRecovery**, choose your physical iPhone, and Run. The helper uses original bundle ID `ca.mymojo.wealthone` and KVS-only entitlement `$(TeamIdentifierPrefix)ca.mymojo.wealthone`, team `2LG9PUJ57N`; it has no Watch or CloudKit dependency. It only discovers, previews and exports; it has no import callback or native event-store instance. This intentionally installs under the old app identity, so it can replace the old app binary if one is installed. The user reported the old app is absent. If Apple rejects this identifier, use the original owning developer team; do not rename the helper to an unrelated identifier, which would not grant access to the old store.

From the helper, export recovered JSON to Files. Return to the native **WealthOne → Settings → Backups → Import backup**, review, and confirm. Or use **Review import into WealthOne** when recovery works directly in the native app. Direct recovery import saves the latest full native history first in `Application Support/WealthOne/RecoveryBackups/`, aborts if backup fails, then appends a baseline replacement event without pruning old edits. Existing goals are retained when the recovered copy contains none. Unreadable native storage must use the existing Backups restore path, which preserves the corrupt original.

Physical signing must authorize the entitlement and original app identity; local builds cannot establish account ownership or prove remote data still exists. Simulator recovery deliberately reports unsupported and never accesses real KVS. Never treat a successful unsigned build or fixture test as successful cloud recovery.

## Migration and cutover

Ship the legacy JSON file Export action before retiring its release. The current native app reads logical keys in order: `persist:wealthone_data`, `wealthone`, `backup`, with the library's `@com.manicakes.iCloudStorage/` prefix. Redux slices use JSON-stringified LZ-string UTF-16; the decoder is verified against a fixture produced by the installed JS library. Legacy keys are never changed. Import accounts, sparse dated totals/flows, Decimal amounts and goal inputs as a baseline; older edits absent from the old app cannot be recreated.

Keep both apps installed during native beta. Exercise direct migration and the real JSON fallback before the native update replaces the old app. Save an export outside the app. After migration, feature parity, signed sync and Watch checks are accepted, change final native identity to `ca.mymojo.wealthone`, retain team `2LG9PUJ57N`, and update the companion identifiers/Info plists/App Groups/provisioning together. Do not rename the CloudKit container or legacy KVS store at cutover. Preserve the legacy source and Git history.

## Known behavior and boundaries

- Calculation version 2 corrects legacy yearly compounding, opening-profit/year baselines, growth denominator, April6 UK tax boundary, birthday age, zero-horizon projections and goal funding ratios. Derived totals carry forward missing balances (explicit zero remains zero); stored records/events remain unchanged. Returns retain the disclosed end-of-interval cash-flow approximation. See docs/implementation/calculation-audit.md and calculation-corrections-progress.md.
- Legacy date strings and baseline values remain in the event log. New dated entries use explicit local `yyyy-MM-dd` keys. Importing multiple representations of one calendar day needs review; the core preserves the original identifiers.
- Replay currently rebuilds ancestor sets and projections from the complete log. Large-log performance, interrupted-save/power-loss behavior and concurrent process writers need further verification before general distribution.
- CloudKit owner changes intentionally pause sync. The first version provides export for moving history; automatic cross-account transfer is outside scope.
- Permanent means normal commands never prune events. It does not imply tamper-proof storage or recovery after all copies and backups are lost.
- Native code is not yet approved for production replacement merely because compilation and domain tests pass.

## Native Apple interface

The approved 29 October direction uses system Dynamic Type typography, SF Symbols, native Liquid Glass navigation and controls, and a single blue family for charts/actions. Phone/iPad follow system light/dark appearance; Watch uses native black surfaces. Home and financial analysis content use flat layouts and compact rows. Chart selection, metric/range controls, grouped goal estimates and the Current reference line continue to use actual portfolio projections.

Legacy Karla/Montserrat/Feather source resources are retained for history but no longer registered or bundled in the native app. Legacy icon artwork is preserved in App/Resources/LegacyAppIcons. Current phone light/dark and Watch icons are deterministic vector-derived PNGs, generated from the repository root with `swift native-ios/Tools/generate-icons.swift`. Asset catalogs supply single-size platform variants; the system applies masks and appearance treatment. This is raster-catalog packaging, not a manually authored Icon Composer layered file.

Watch Quick entry remains an account-specific total submitted to the iPhone. Pending/retry status is durable and success still requires the phone acknowledgment. Visual changes do not fix or establish paired-device WatchConnectivity delivery. iCloud and migration still require signed-device verification.

Approved mockups and actual implementation captures are recorded in docs/design/apple-native; current evidence and limitations are in docs/implementation/apple-native-progress.md.


## Currencies and Goals history

Accounts can use GBP, CAD, USD, EUR, AUD, NZD, CHF or JPY. Existing accounts/archives default to GBP. Choose an account's currency in its editor; input balances and flows in that currency. Portfolio totals, breakdown, historical values, Goals and Watch summaries use the main currency from Settings → Currencies; account detail remains in native account units.

Each dated entry saves GBP-per-unit reference rates and each rate's publication date/source. The app fetches a current Bank of Canada daily quote on entry when needed; values stay frozen until explicitly refreshed and saved. Manual positive rates are supported. Fetching sends no balances to the rate provider. Settings can fill historical missing rates using the selected current quote without overwriting existing rates, or explicitly refresh all saved rates with confirmation. These are approximate entry-time rates, not backfilled historical market prices. Missing required rates show unavailable values rather than assuming parity. New quote edits append to the permanent log. Changing the main currency converts monetary goal inputs using the selected quote; historical conversions may require filling missing rates. Older native builds should be updated on all devices before using currency fields.

Goals includes Actual vs projected wealth from the first recorded snapshot through retirement age. Actuals stop at the latest observed snapshot; annual Average/Poor samples continue to the retirement birthday with separate endpoint totals. Average/Poor paths recalculate from current monthly contribution and investment-style assumptions; the comparison is illustrative, includes actual contributions/FX effects, and is not a saved historical forecast. Calculation corrections do not rewrite original entries/events.

Watch Quick entry's shared model is provided above NavigationStack so pushed screens inherit it. The simulator regression probe is generated with Tools/watch-navigation-probe.rb; use a disposable Watch simulator. It copies production sources into a separate temporary app with synthetic data, automatically opens Quick entry and does not modify the regular app store.


## Account closure and Wealth+ CSV

Close or reopen an account from its Settings editor. Closing preserves its historical data, saves a zero balance and adds its remaining account-unit balance to that date’s outflow. Closed accounts are listed in Settings → Closed accounts, and disappear from entries during closed periods. Historical accounts cannot be deleted. Closure settlements are permanent, including when an offline whole-day deletion merges later. Reopening starts from zero until a balance is recorded.

Settings → Import Wealth+ CSV (also in Backups) accepts the Wealth+ Date/Total/Assets/Liabilities/account-columns/Note format. Missing accounts trigger an offer to create them: review each prefilled account’s name, currency and type and explicitly Save, or cancel. Balances cannot import until every source column has an unambiguous existing account. Account creation and balance import are separate explicit actions. Source amounts default to each account’s own currency, as requested; optional main-currency source conversion is labeled. Preview defaults to preserving existing balances; Update existing balances explicitly replaces only matching account totals. Other accounts, flows, goals, lifecycle and saved FX stay intact. Missing rates require a fetched current quote and are fixed on imported dates, including older dates; these are not historical market-rate lookups. Duplicate/ambiguous dates, malformed numbers/quotes, nonempty unsupported notes, closed periods and stale previews block the entire import. Imports append one atomic batch and never replace the portfolio.

Tools/inspect-wealth-csv.swift performs read-only metadata validation without printing balances. Tools/csv-creation-probe.py stages a disposable copy with a fixed synthetic two-account CSV preselected; production sources have no fixture hook. The gated UITest exercises creation consent, sequential editors and final balance import. Do not use private exports in probes or committed fixtures.


Entry forms group eligible accounts by provider, naturally sorting account names inside each provider. Blank providers appear under Other accounts; set a provider in the account editor to move an account into a named group. Home and Breakdown hide closed accounts without removing their historical balances or Settings entries. Signed build2 fixed fresh CloudKit synchronization; build3 includes these display refinements. Live phone/iPad history convergence is recorded in docs/implementation/cloud-first-sync-fix.md.
