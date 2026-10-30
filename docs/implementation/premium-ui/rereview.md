# Premium UI scoped rereview — round 1

Reviewed 28 October 2026. Scope: the two original Important findings and the related stepped-slider fix. Inspected the appended implementation report, production `GoalDraft.swift`, all seven `GoalDraftTests`, and actual `GoalEditorView` wiring. No tests rerun, no implementation changes, no additional agents.

## Verdict

- **Birth A → B → A: ADDRESSED.** `GoalDraft.setBirth` removes both birthDate and currentAge edits when the displayed date returns to its original day. It leaves `original` untouched, preserving its exact representation or missing keys. The editor invokes this on every date change, and Save uses `draft.changes`. Tests cover string/Decimal/absent originals and EventStore save/reopen alongside another changed field.
- **Dependent numeric validation: ADDRESSED.** Typed values remain in `draft.text`. `invalidKeys` evaluates them against current earnings and current age each time; Save repeats that validation via throwing `changes`. The editor's disabled state and field messages consume the same current validation. Earnings increases can therefore make a previously invalid contribution valid, and earnings decreases or age increases invalidate previously accepted edited values. Untouched imported inputs remain outside the change payload.
- **Stepped-slider crash: ADDRESSED in inspected code.** Nonzero ranges use `min(preferredStep, span)`; all actual callers supply positive preferred steps. Zero-span ranges produce no Slider. The editor's thumb binding clamps its displayed value against the same current range without changing stored text. Earnings zero produces contribution range 0...0; edited nonzero contributions fail validation. The test exercises earnings deletion/retyping and retirement ranges at ages 75 and 90.

No new Important or Critical issue identified in these fixes. The seven regression tests directly cover the reported failure paths and preservation requirements; their passing result is reported by the implementation agent, not independently rerun here. App compilation and iPhone/iPad runtime checks, including the formerly crashing exact-input journey, remain the parent agent's verification gate.

## Final scoped draft-protection rereview

Inspected only the current shared `DraftProtection` in `WealthTheme.swift` after the iPad decision-button fix. The simplification is sound: dirty sheets retain `interactiveDismissDisabled(true)`, dirty navigation hides the ordinary back action and provides Cancel, and Cancel opens a native alert with explicit Keep Editing and Discard Changes buttons. Keep Editing has no draft mutation; only the destructive action invokes the supplied discard closure. Clean forms retain ordinary dismissal. Removing the custom presentation delegate eliminates its lifecycle/ownership uncertainty.

The behavior is now **blocked dirty swipe, then Cancel for the explicit decision**; a swipe does not itself open the alert. This remains a data-loss guard, but earlier implementation-report wording promising an attempted-swipe confirmation must be updated. No Important/Critical issue found in this scoped change. Parent-reported prior iPhone checks passed; updated targeted iPhone/iPad checks remain underway and were not rerun by this reviewer.
