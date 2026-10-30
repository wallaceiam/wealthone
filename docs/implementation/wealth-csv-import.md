# Wealth+ CSV import — 30 October 2026

Implemented in Settings → Import Wealth+ CSV, also reachable from Backups. No automatic import into any real portfolio; the supplied original CSV was only read for validation. No private CSV or balances were copied into the repository or test fixtures.

## Source validation
The supplied export parses as five account columns and 238 snapshots from 2017-07-21 through 2022-09-10. It has no duplicate dates, blank account amounts, notes or nonempty extra columns. The earlier recovered JSON copy has different account names; the validator correctly blocks importing balances until matching accounts exist. This is a check against that recovered copy, not a claim about the current device’s portfolio.

## Final behavior
- Match existing account names after case/whitespace normalization. Missing names trigger an explicit offer to create accounts. Accepting opens the existing account editor with each name prefilled; review currency, type and provider before Save. Cancel stops the creation sequence. Ambiguous names still require resolution. No accounts are created merely by parsing or reviewing a CSV.
- Account creation and balance import are separate user actions. All matching accounts must exist before a final balance preview can be accepted. If account setup is canceled, any accounts already explicitly saved remain as empty accounts and no balances are imported.
- Source balances default to each account’s currency, as explicitly selected by the user. Optional main-currency source conversion is labeled in the preview. Existing quote values/provenance stay frozen; missing rates require a current fetched reference quote and are saved on imported dates. The screen explains that current import-time quotes are approximate, not historical-rate backfills.
- Default merge fills missing balances/dates. Update existing balances is an explicit option. Other accounts, flows, goals, closures and prior events remain intact. Total/Assets/Liabilities summary columns are ignored. Strict quote/row/date/decimal validation, unsupported nonempty notes, duplicate source dates, ambiguous stored day aliases, closed periods and stale previews block the whole import.
- The event store appends the entire reviewed balance batch in one transaction. Failed writes publish nothing; repeating an identical reviewed import produces no new edits.

## Evidence
- Core tests cover quoted/CRLF/BOM/exact decimals, date ordering, blank versus zero, all account blockers, explicit account creation before import, preserving other accounts/flows/goals, optional overwrites, atomic disk failure, stale proposals, frozen FX/conversion and no-op repeats. The combined native core suite passes 115 tests.
- Real-file read-only validation uses Tools/inspect-wealth-csv.swift; outputs metadata and missing names, never balances.
- Three normal simulator journeys passed: CSV picker, populated retirement endpoint and account close/reopen/relaunch. The updated normal picker is verified separately after the final creation UI change.
- Tools/csv-creation-probe.py copies production sources to a disposable /tmp project and preselects a fixed synthetic two-account/one-date CSV. Production sources contain no fixture hook. The gated UITest accepted the creation offer, saved both prefilled account editors in sequence, explicitly confirmed the balance import and verified the dashboard’s synthetic total (34.942 seconds, PASS).
- iPhone simulator build-for-testing and native iPhone plus embedded Watch/widget unsigned device build pass. These tests do not establish physical iCloud/WatchConnectivity behavior.
- One independent CSV review, plus a focused follow-up for the user’s changed account-creation requirement, found no actionable issues. Review was static; author-run tests/builds provide runtime evidence. No deferred findings.
