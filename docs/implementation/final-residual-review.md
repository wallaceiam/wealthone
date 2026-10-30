# Final residual review — 2026-10-28

Reviewed only the two residual fixes from final-rereview.md, their regression coverage, and the requested test-directory/iPad-plist changes. No test reruns, source edits or subagents.

**Both residuals ADDRESSED. No new Critical or Important breakage identified in this scope.**

1. **Fractional ISO legacy dates — ADDRESSED.** PortfolioCalculator.date now attempts an ISO8601 formatter with `.withInternetDateTime` and `.withFractionalSeconds` before its date-only fallback. The existing nonfractional attempt remains first, which is compatible with this fix. The exact `2026-06-30T23:00:00.000Z` key now retains its timestamp/offset for London July 1 lookup instead of becoming June 30 local midnight. Regression coverage includes that key and a fixed Europe/London calendar. Watch lookup consumes this same parser.

2. **Unobserved/replaced account dependency in open dated editors — ADDRESSED.** EntryEditor freezes its displayed and saved account list together with its captured record/context, refreshing them on date selection. EditContext records current account generations, and submit checks every changed day field against that captured generation before append. New/deleted/recreated account dependencies therefore produce a visible error without saving, while unchanged unrelated account data does not block a legitimate edit. The original parents remain intact, so this does not restore the stale same-field overwrite problem. Regression coverage verifies rejection with unchanged event count, successful original-account editing, successful new-account editing after recapture, and recreated-account rejection.

The DEBUG simulator fixture directory requires a UUID environment value and otherwise uses the ordinary directory; production/non-simulator code retains the existing WealthOne path. It neither deletes nor migrates ordinary history. The iPad orientation declaration adds supported orientations only. No data-loss concern identified in those requested changes.

Evidence: final-fixes.md records explicit assertion-failing RED results for both residuals and a subsequent **28/28 passing Swift tests**. Those runs were not repeated by this reviewer. Final integrated build/simulator evidence remains owned by the coordinating agent. Signed CloudKit/KVS, paired Watch delivery and the legacy native share sheet remain documented release gates.

This closes the two outstanding issues in final-rereview.md; it is not a new full-system review or a claim of signed-device readiness.
