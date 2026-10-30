# Implemented WealthOne premium interface

Actual iOS 17 simulator captures using a synthetic, isolated screenshot-test portfolio. These are rendered SwiftUI screens, not generated concept art. Karla/Montserrat typography and Feather outline symbols are the original asset binaries. The phone/iPad UI intentionally uses the approved light palette.

## Gallery

- [Onboarding, empty dashboard and labelled financial forms](contact-sheet-1.jpg)
- [Saved amount, dashboard, account detail and allocation](contact-sheet-2.jpg)
- [Goals, precise input controls, History and Settings](contact-sheet-3.jpg)
- [Backups, readable edit log, change details and About](contact-sheet-4.jpg)
- [Accessibility-size typography and form reachability](contact-sheet-5.jpg)

Original PNGs are in [screens](screens). The dashboard capture preserves the viewport after saving a snapshot, so it shows part of the chart and lower summaries; normal scrolling reveals the header/hero. A few immediately captured frames include standard navigation/scroll transition artifacts. The screenshot journey tests navigation; image inspection is recorded separately from pass/fail status.

## Chart refinements

Latest iPhone 17 / iOS 27 captures: [Home](chart-refinement-home.png) and [Goals](chart-refinement-goals.png). These use an isolated £102 portfolio. Navigation titles are explicit dark Karla text, chart metrics sit in a trailing menu, and the default duplicate chart amount is removed. Goals includes a dashed Current line and amount/percentage pairs. The latest explanatory footer wording was simplified after these captures.

## What changed

White surfaces over a soft neutral background, pale-blue actions, gentle shadows, larger spacing and readable content widths. Native tab images use the original Feather home/bar-chart/target/list/settings glyphs. Heading/body fonts scale with semantic Dynamic Type styles.

Dashboard/chart controls read real portfolio projections, include a date range selector and show single snapshots as points. Financial forms retain visible account/currency labels. Goal assumptions accept exact values and safe sliders. Unsaved forms block swipe dismissal; Cancel offers Keep Editing and Discard Changes in a native alert on both phone and tablet. Saved history leads with account/date/value descriptions; internal event identities remain available in technical disclosures.

The generated design reference is [concept v2](../wealthone-premium-dashboard-concept-v2.png). The running app does not contain that concept's mock portfolio figures. In-app changes still go through the existing event-sourced store and captured edit contexts.

## Validation boundaries

Native domain/resource tests and simulator UI scenarios are recorded in `docs/implementation/premium-ui/progress.md`. The UI checks cover save/reopen, full screen navigation, large-text reachability, exact goal inputs and draft decisions. They do not establish exhaustive VoiceOver traversal, contrast certification, physical-device touch behavior or signed cloud sync. The separately reported WatchConnectivity issue remains open.
