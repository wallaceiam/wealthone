# Wealth+ CSV import implementation plan

**Goal:** Import the supplied Wealth+ dated-balance export into existing accounts only, with a reviewable, atomic merge.
**Architecture:** Pure Swift CSV parser and immutable import plan in WealthOneCore; native Settings → Backups file picker and preview; EventStore appends all dated changes in one commit. Never create accounts automatically or replace the portfolio. Missing accounts may be explicitly created in the existing account editor before the import.
**Execution:** Continue direct implementation and one independent final review. Preserve existing feature branch, unrelated edits, signing and all history. No commits or automatic import into the user's actual store.

## Requirements and decisions
- Recognize Date, Total, Assets, Liabilities, account columns, Note and empty trailing columns in the supplied format. Do not import summary totals as accounts. Strict UTF-8/quoted CSV parsing, dates and decimal validation. Blank balances mean unrecorded; zero remains zero. Nonempty notes are blocked until supported rather than silently discarded.
- Account names must match existing accounts after whitespace/case normalization. Missing or ambiguous names block the entire balance import. On the user’s latest instruction, missing names trigger an offer to create accounts; the existing account editor reviews each name/currency/type, Save explicitly creates it, and the balance import still requires a separate final review. Cancel leaves balances unimported.
- Review source count/range, matched accounts, new dates, new balances, overlapping differences and unchanged values. Default keeps existing balances; an explicit option may update matching account balances. Other accounts, flows, goal settings, status and existing FX stay intact.
- Currency interpretation is explicit in the preview: native account units or main-currency units. No currency information exists in the source. New missing rates require an explicitly fetched reference quote, fixed with imported dates; preserve already saved rates. Main-currency source amounts convert to account units using the saved/fetched quote.
- Closed account periods, multiple stored identifiers for a date, duplicate dates/headers, invalid values and stale previews reject the entire operation. Identical repeated imports append nothing. Storage failure publishes nothing.
- Preserve original private CSV outside the repo. Tests use synthetic data; log only metadata when validating the real file.

## Tasks
- [x] 1. Parser/matching/merge/currency tests first, then WealthCSVImport.swift and EventStore import command.
- [x] 2. Native picker/preview, existing-account blockers, overlap/currency choices and fetch-rates action; verify isolated simulator import and reopening workflow.
- [x] 3. Full core suite, actual-file read-only validation without balance output, iPhone+Watch builds; one independent review and regression fixes.

## Review focus
- Same-day aliases/duplicate CSV dates; preserve flows and unrelated fields.
- Missing/ambiguous accounts and closure transitions; no partial import.
- Mixed currencies, saved quote provenance and explicit source units.
- Stale previews and atomic disk failure.
- Malformed quoted CSV, byte encoding, header/row widths and decimals.


## Final verification
User clarified missing accounts should trigger an offer to create; implemented as explicitly reviewed sequential account editors before separate balance import. User selected account-native source units. Combined core suite115PASS; supplied file read-only metadata validationPASS; normal simulator picker/retirement/close-reopen journeysPASS; synthetic two-account creation/import UI probePASS; final phone+embeddedWatch buildsPASS. Independent review and focused creation-flow follow-up found no actionable issues. See docs/implementation/wealth-csv-import.md and retirement-account-closure.md for evidence and limits. No commits or actual portfolio import performed.
