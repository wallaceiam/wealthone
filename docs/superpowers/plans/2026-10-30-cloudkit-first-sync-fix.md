# CloudKit first-sync fix

User reports both signed devices show “Did not find record type: WealthEvent”; iPad cannot receive the phone’s local history. Root cause: CloudEventTransport queries the record type before uploading the first event, preventing initial development schema creation. Watch uses separate phone transport. Both connected devices have the same saved iCloud owner; phone history was copied read-only to private /tmp for preservation, not modified. iPad has no persisted event history yet.

- [x] RED regression for fresh empty-zone download then initial upload; pagination in causal-independent order; collisions/network failures before upload; deletions/deduplication; repeated cursor protection.
- [x] Replace type-specific CKQuery enumeration with custom-zone change enumeration from nil token on every sync, retaining all immutable history validation, owner binding and uploads. Core sync coordinator receives opaque cursor bytes and typed events; Apple-specific API stays in App. Clear migration offer after receiving native history.
- [x] Distinct native build2 (same app/team/container identities), full tests, unsigned/signed phone+Watch builds, independent review of sync safety.
- [x] Install signed update on paired iPhone/iPad preserving containers, then launch phone first and verify actual cloud delivery by metadata/event-ID comparison where device access permits. Do not report device convergence without evidence.

Keep existing account/CSV/goal work and unrelated RN edits. No commits, cloud resets, history pruning or automatic re-import. Settings → Import Wealth+ CSV is below accounts in Data; latest build includes explicit missing-account creation flow. Device UI and schema environment verification may need user input.


Live verification complete: signed build2 installed on both devices; same249events/12accounts/365datedentries,0buffered, decoded histories/projections identical, originalphoneevents preserved. No cloud resets/reimports. User subsequently requested Home/Breakdown closed-account hiding and Addentry provider grouping; build3 includes these, with123coretests passing and the combined provider/closed-account/reopening UI check passing. See docs/implementation/cloud-first-sync-fix.md for private-data-safe evidence.

Completion: build2.0(3) installed on both; post-update saved histories identical (249events/12accounts/365dates), originaldata preserved;123coretests and combined UIjourneyPASS. Finalauto-launch refused because bothdeviceslocked; user opens appafterunlock. No source/task work remains; no commits or cloud resets performed.
