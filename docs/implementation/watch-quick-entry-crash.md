# Watch Quick entry navigation crash — 30 October 2026

User reported an immediate crash on opening Quick entry, before interacting with an account/amount.

Reproduced the production navigation path in an isolated watchOS27 simulator app with synthetic accounts. Root NavigationStack, WatchHomeView, QuickEntryView, WatchModel and shared payload source match production; only the test copy automatically activates the Quick entry NavigationLink. Before the fix, opening it traps:

`SwiftUICore/EnvironmentObject.swift:93: Fatal error: No ObservableObject of type WatchModel found.`

The crash stack enters `QuickEntryView.model.getter`, then its account Picker and Form construction. This is a screen environment-scoping bug, not a financial-data, input-validation or WatchConnectivity save error. The user pasted the isolated reproduction's crash report (WealthOneCrashReview, process42764), confirming the same failure.

Fix: attach `.environmentObject(model)` to NavigationStack in WealthOneWatchApp, rather than only to its initial WatchHomeView. Pushed destinations then inherit the shared model.

RED: isolated app process42764 trapped immediately with the missing-model message. GREEN: the same automatic NavigationLink transition remained running and rendered the account picker and amount field after moving injection above NavigationStack. Screenshot: calculation-corrections/watch-quick-entry-fixed.png. The reusable Tools/watch-navigation-probe.rb derives its app/root and screens directly from production sources, adding synthetic initialization and automatic navigation only in the temporary copy. Probe build passed; final production physical build checked in the correction ledger.

Native computer-use automation could not start; reproduction uses a separate temporary source-only probe and synthetic data on the disposable review simulator. Physical Watch/iPhone crash-log download attempts failed because CoreDevice could not establish its device tunnel. No real account balances, app files or watch pending commands were changed by this reproduction.
