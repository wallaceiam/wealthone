# CloudKit first sync and physical-device convergence — 30 October 2026

## Confirmed failure
Both signed devices reported “Did not find record type: WealthEvent”. CloudEventTransport queried that type before uploading the first record, preventing initial development-schema setup. The Watch uses phone snapshots and did not establish that iCloud worked. Both saved Cloud ownership bindings matched. The pre-update phone had two immutable events and seven accounts/344 dated observations; iPad had no saved native history file. Private diagnostic copies are under a protected /tmp directory, outside the repo; no balances are logged.

## Fix
Use `CKDatabase.recordZoneChanges` on the existing custom zone, starting from a nil token each sync. This enumerates existing zone records without a query or index on a record type that does not yet exist. Opaque securely coded tokens page through the zone; per-record errors and fetch failures propagate. Core `EventSynchronization` assembles the remote immutable events, validates local/remote union and collisions before uploading unknown IDs, detects repeated tokens, and can restore server-deleted immutable events from retained local history. No history pruning, cloud reset or account/container/team identity change.

Clear the migration offer after native event history arrives. Native build2 identified the fix and included the CSV importer; build3 adds the requested closed-account visibility and provider-grouped entry display. Only build-version values in the existing project were updated, with no project UUID regeneration.

## Evidence
- Five first-sync/pagination/collision/failure/deletion/dedup/repeated-token tests began RED and passed GREEN. Core suite at sync-only stage120PASS; combined suite after subsequent UI-related core helpers123PASS.
- Signed iPhone+embeddedWatch/widget build succeeded with existing development identity/profile. Provisioning authorized both physical devices. Installed build2 in place on both without uninstalling or replacing their stores. Launched phone first, then iPad.
- User subsequently imported CSV/closed accounts while devices synced. Intermediate snapshots correctly showed partial progress; full convergence was verified afterward using actual read-only device copies and the production Core projection.
- Final captured phone and iPad each: **249 events,12accounts,365dated entries,0buffered**, **identical logical event histories and identical projected snapshots**. All pre-update phone events were preserved, comparing decoded Event values rather than raw JSON bytes (new optional defaults re-encode snapshots).
- `Tools/compare-device-history.swift` outputs only counts/equality booleans; no financial values or event/account IDs. No real device history was committed.
- One independent focused review found no actionable issue. Review was static; live bootstrap/convergence evidence above was collected separately afterward.

## Apple references
- [Zone changes and nil initial token](https://developer.apple.com/documentation/cloudkit/ckdatabase/recordzonechanges(inzonewith:since:desiredkeys:resultslimit:))
- [Development schema creation and initial records](https://developer.apple.com/documentation/cloudkit/designing-and-creating-a-cloudkit-database)

## Follow-up display requests
Home lists only open accounts. Breakdown asset groups/types and liabilities exclude closed accounts, while historical net-worth/account series and Settings closure/reopening remain intact. Add/Edit entry uses provider sections, natural account-name sorting and an Other accounts section for blank providers. Groups use the captured eligible accounts and never mutate provider metadata. These display changes are packaged as build3. Combined core suite123PASS; the simulator journey specifically asserted the provider header and closed-account absence on Home/Breakdown, then reopened and verified entry/relaunch (70.912 seconds, PASS). Signed and simulator builds succeeded; in-place installation followed.

### Final completion
Build **2.0 (3)** installed successfully in place on both physical devices. Read-only post-update comparison again confirmed249events/12accounts/365datedentries/0buffered and identical decoded histories/projections; all original events retained. Final core run123tests/0failures. The provider-header/Home+Breakdown hiding/close-reopen/relaunch simulator journey passed. Both physical devices had locked by the final launch attempt, so build3 could not be opened automatically; user must unlock and open WealthOne to see the updated interface. Earlier build2 live CloudKit bootstrap and convergence were already verified, and build3 retains that fix unchanged.
