# Retirement timeline and account lifecycle — 30 October 2026

Implemented directly on the existing native feature branch. No commits, signing changes, project regeneration, pruning, automatic changes to real portfolios, or React Native changes.

## Behavior
- Actual vs projected retains the first-observation anchor and current contribution/investment assumptions. Average/Poor curves sample annually through the exact retirement anniversary; actual values stop at the last observation. The latest-entry marker and retirement totals distinguish the two dates. Unsupported/past horizons retain recorded history.
- Settings account editor closes/reopens an account on a reviewed date from its latest observation/status through today. Closing appends zero balance, additive remaining-balance outflow in account units, saved FX provenance and status atomically. Reopening preserves zero until another balance is entered. Zero/negative balances retain their signed convention.
- Closed accounts remain in historical views and Settings → Closed accounts. They disappear from editable iPhone/Watch entry choices for closed periods. Historical entries before closure remain editable; recorded closure-day amounts are read-only. Account deletion is prohibited once any historical entry exists. Closure records cannot be deleted.
- Late offline values remain auditable but do not restore a closed balance or flows during closed intervals. Exact settlement record IDs are retained to protect legacy timestamp IDs from concurrent deletion without timezone-dependent projection rules.

## Verification and review
- Initial lifecycle/future-actual tests failed before implementation. Final lifecycle core suite reached 107 passing tests before CSV work; combined suite now covers these cases too.
- Independent review found concurrent whole-day deletion removing a settlement, and re-closing from a suppressed offline balance causing phantom profit. Both reproduced RED and passed GREEN. Settlement preservation and lifecycle-adjusted closing balance now cover them. No deferred findings.
- Simulator close → hidden entry → retirement endpoint → reopen → relaunch journey passed. Populated synthetic 344-date chart/endpoint passed. Screenshot in retirement-account-closure/retirement-timeline.png contains synthetic data only.
- Phone and embedded Watch/widget simulator and unsigned device builds passed. Physical iCloud/WatchConnectivity are not established by these tests. Rebuild all native devices before using new lifecycle event fields.
