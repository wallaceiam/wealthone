# Independent iCloud recovery review

Read-only focused review by an independent agent; no Critical findings. One Important and one Minor finding.

## Findings and resolution

Important: `LegacyRecoverySession.start()` replaced the remembered identity before comparing accounts. A direct A→B retry before Apple's callback could classify A's cached data under B. Resolution: retain last-known nonnil identity across retries/unavailable states, require a fresh value notification after a mismatch, and recheck revision/identity after decoding. Direct A→B, A→nil→B and reentrant invalidation regressions failed before correction and pass afterward.

Minor: a quota callback could overwrite an account-change diagnostic after refresh invalidated the session. The same generation guard now preserves the account-change state; regression failed first and then passed.

Reviewer inspected backup-before-replacement ordering, atomic backup writing, retained event history, frozen candidate exports, simulator exclusion, and helper scheme/source membership/identifiers. No other concrete Important/Critical findings.

Final verification:58 native package tests passed; final native recovery-availability/save-reopen UI checks2/2 passed; helper unsigned device build succeeded. Physical signing and real iCloud retrieval remain unverified.

Declined to certify: Apple provisioning/entitlement authorization, actual remote availability/download, and file-exporter dismissal on physical hardware. These are explicit user-device validation boundaries, not evidence that data is missing or present. No second reviewer dispatched after the fix pass; new regressions and green suites are the corrective evidence.
