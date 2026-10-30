# Calculation audit — 29 October 2026

Scope: native portfolio metrics, account metrics, cash-flow handling, retirement projections and their displayed labels. The performance work deliberately retained React Native results; existing parity tests establish compatibility, not financial correctness. This audit tests independent financial identities and calendar examples.

No production formulas, imported data or event history were changed by this audit. Synthetic reproductions are in `native-ios/Tools/audit-calculations.swift`; the normal test suite is not modified to assert financial correctness of known legacy bugs.

## Confirmed formula/calendar defects

### 1. Year return does not compound correctly (high priority)

`PortfolioCalculator.swift:125` updates the yearly fold as `1 + product * return`, rather than `product * (1 + return)`. A zero-return interval resets prior gains. Four same-year balances £100 → £110 → £110 → £121 with no cash flows produce overall return 21%, but Year return 10%. Both should be 21% for this fixture.

Fix: geometrically link all valid interval return factors for the reporting year. Separately establish the reporting baseline at the year boundary (see item 3). [GIPS handbook, provision 2.A.24](https://www.gipsstandards.org/standards/gips-standards-for-firms/gips-standards-handbook-for-firms/) supports geometric linking; this reference does not certify the app as GIPS compliant.

### 2. Year growth percentage divides by cash flows (high priority)

`PortfolioCalculator.swift:111` divides the balance change by the first same-year point's `taxYearNetflows`. This is neither the opening balance nor a return denominator. With the same no-flow £100 → £121 example, Year growth is £21 but Year growth % is 0% instead of 21%.

Fix: define gross balance growth as `(ending - opening) / opening`; show unavailable when there is no meaningful denominator, and keep this distinct from cash-flow-adjusted return.

### 3. Year growth/profit uses inconsistent opening balances (high priority)

`PortfolioCalculator.swift:101-102,119-120` uses zero until a same-year point has already been appended, then uses that first point. No-flow balances 31 Dec £100, 1 Jan £110, 1 Feb £121 produce:

| Metric | Actual | Expected using last year-end balance |
|---|---:|---:|
| 1 Jan year growth | £110 | £10 |
| 1 Jan year profit | £110 | £10 |
| 1 Feb year growth | £11 | £21 |
| 1 Feb year profit | £11 | £21 |

Fix: use one explicit opening value for the year, normally the last observation before the year starts, and subtract subsequent external flows for profit. If snapshots straddle the boundary without a year-end valuation, disclose that the result measures from the available observation; an exact calendar-year allocation cannot be inferred. For the first ever observation, establish a baseline rather than treating the entire balance as growth.

### 4. Opening cash flow is counted twice in lifetime profit (high priority, conditional on nonzero initial flow)

`PortfolioCalculator.swift:112,117` includes the first record's flows in cumulative flows, then subtracts those along with the first balance. Opening £100 with a £100 deposit recorded on that first observation, followed by unchanged £100, gives profit −£100 instead of £0 **since the first snapshot**. First record itself shows £0, causing an inconsistent jump.

Fix: keep total recorded flows as a separate statistic if desired, but calculate since-baseline profit using only flows after that baseline. Different inception reporting would require an explicit pre-deposit opening balance. Private archive metadata check found no nonzero initial flows, so this particular trigger does not affect that archive's current opening record.

### 5. UK tax-year boundary is five days early (medium priority)

`PortfolioCalculator.swift:100` resets at 1 April. With £10 inflows on 31 March, 1 April, 5 April and 6 April, current tax-year totals are £10 on 1 April, £20 on 5 April, £30 on 6 April; expected totals are £20, £30 and £10 respectively. The [UK tax year runs 6 April to 5 April](https://www.gov.uk/income-tax-rates). Use month/day comparisons with an explicit reporting calendar/timezone.

### 6. Zero/past retirement horizon projects an extra year (high priority)

`GoalProjectionCalculator.swift:60,67,75-77` clamps zero and negative years to table row zero, which represents one year. Synthetic age 40, retirement 40, current capital £100,000 and no contributions produces average capital £103,489.50 instead of £100,000. With £200/month contributions it produces £105,973.25 despite there being no future accumulation period.

Fix: zero horizon returns current capital with no future contributions. Past retirement needs an explicit already-retired policy or unavailable result. Fractional years are currently truncated; horizons over the 80-year table limit silently reuse the last row. Define supported horizons rather than silently substituting a different period.

### 7. Age uses an elapsed-duration shortcut (medium priority)

`GoalProjectionCalculator.swift:32-35` converts elapsed seconds to a date relative to 1970, then uses its year. It is not a birthday calculation. Birth 28 October 1971, as-of 27 October 2025, produces 54 instead of 53. Different leap-year cycles cause the discrepancy; this changes selected accumulation rows and earnings growth.

Fix: calendar birthday/year components with a chosen civil date/timezone policy, including an explicit leap-day birthday convention and rejection of future/invalid birth dates.

### 8. Pension-inclusive savings target and income do not reconcile (medium priority)

`GoalProjectionCalculator.swift:73` discounts the pension income by 1.01 when finding required capital, but `:81-82` adds the undiscounted pension when deriving income. Same-point target and income therefore use different pension amounts. In the synthetic age40/retire68, earnings£55,000, pension15%, lifestyle40% fixture, capital exactly meeting the unrounded savings target generates annual income £29,176.33 against an unrounded income target £29,068.40, a £107.93 discrepancy.

Fix: use the same retirement-year pension basis on both sides; if a one-year offset is intentional, model and label that timing explicitly.

## Model and presentation decisions

### Goal percentage is not percentage funded

`GoalProjectionCalculator.swift:85-100` multiplies projected/target by `lifeStyle`, rather than 100. At a 40% lifestyle setting, exact target funding shows 40%, not 100%. The current UI explicitly says the number is lifestyle adjusted, so the arithmetic represents a different metric rather than a hidden multiplication error. However, calling it progress towards the target is misleading, particularly for savings. Recommendation: show funding ratio `projected / target * 100`, and show lifestyle/replacement-income percentage separately. Treat zero targets explicitly; current fallback100 is a convention, not measured funding. Income percentage can also be nonfinite for zero earnings/lifestyle.

### Recorded interval flows do not support an exact TWR without timing information

The interval return `(ending - netflow) / opening - 1` treats flows as end-of-period. It is valid under that convention, not universally. Example: £100 opening, £100 deposit at the start, both earning10%, £220 ending: current result20%, actual holding-period return10%. An identical ending balance and flow total could arise from different timing/performance paths, so aggregate snapshot fields cannot recover the true return.

Recommendation: agree and disclose an end-of-period approximation for existing aggregate data, or add dated external cash flows/valuations for exact subperiod linking. Do not silently replace it with another timing assumption. [GIPS handbook](https://www.gipsstandards.org/standards/gips-standards-for-firms/gips-standards-handbook-for-firms/) discusses valuations at flows and weighted-flow approximations. Flow treatment for debts needs user confirmation: the current portfolio sums debt inflows/outflows in the same sign as assets while subtracting debt balances.

### Missing totals become zero; partial Watch records can change the apparent portfolio

`PortfolioCalculator.swift:73` substitutes zero for any absent balance. The UI labels blanks as no recorded value. A Watch entry on a new day creates a record for only the selected account; other accounts have no totals that day and contribute zero. Two accounts worth£100 and£200 followed by an update of only the first to£110 produce a portfolio of£110, not a complete valuation of£310. A missing observation is not evidence of a zero balance.

Recommendation: choose either carrying forward last known balances with their valuation dates, or marking partial portfolio valuations/returns unavailable. Explicit recorded zero must remain zero, and balances before an account's first observation must not be invented. The recovered archive has 4 of344 records missing at least one of the seven current account totals; that metadata alone does not establish whether those blanks represent account inception, closure, or missing observations.

### Goal capital and pension assumptions need modernization

- `GoalsView.currentNetWorth` passes all net worth into the accumulation model, including property if present. A home is not automatically investable retirement capital. Prefer an explicit selection of retirement assets, with liabilities treated deliberately. The reviewed recovered archive currently has no liability accounts; that does not establish which assets are investable.
- Fixed £8,500 state pension and age68 are legacy assumptions. The full new State Pension is £241.30/week in2026/27, but actual entitlement depends on the individual's National Insurance record: [DWP explanation](https://www.gov.uk/government/publications/your-new-state-pension-explained/your-state-pension-explained). A personalised forecast is preferable to assuming full entitlement.
- Retiring before68 sets state pension to zero for the entire retirement rather than starting it later. Retiring later than68 includes it from the start. Retirement date and State Pension start date must be separate. Statutory State Pension age depends on birth date: [government timetable](https://www.gov.uk/government/publications/state-pension-age-timetable/state-pension-age-timetable).
- Zero inflation, 1% real earnings growth, longevity96 and static scenario tables are assumptions, not validated forecasts. The tables match the legacy data but have no financial calibration/provenance established in this audit. Poor/Average amounts should remain described as illustrative.
- Targets are rounded to£100/£1,000 while scenario amounts retain full precision. Use unrounded values internally and a consistent display precision to avoid apparent mismatches.
- Dated amount entry on both phone and Watch deliberately truncates fractions to whole pounds (`Shared/WatchPayload.swift:43-50`). Imported decimals are preserved until edited. This can explain differences after typing pence; changing the input policy should be explicit.
- Monetary storage is Decimal but metrics sum/compute in Double. Small binary precision artifacts are possible; these do not explain the large demonstrated discrepancies. Keep money arithmetic in Decimal where practical and use floating point for ratios/projections with intentional display rounding.

## Checks that passed

Synthetic assets£1,000 less debt£300 = net worth£700; no-flow lifetime compounding£100→£110→£110→£121 =21%; no-flow lifetime profit£21; end-of-period deposit£20 with£100→£120 gives0% return and£0 profit. These validate those cases, not every possible cash-flow, zero/negative opening balance or debt convention. Undefined percentage denominators currently fall back to0 rather than unavailable, which should be part of the return display policy.

## Reproduction and next steps

Compile a temporary copy of `native-ios/Tools/audit-calculations.swift` named `main.swift` alongside `native-ios/Sources/WealthOneCore/*.swift`, then run it. It prints synthetic actual/expected comparisons. An optional archive path prints only record/account/missing-total metadata. It is an audit probe and exits successfully after reporting mismatches; it is not a replacement for regression assertions.

Recommended implementation order:
1. Agree metric definitions: since-baseline vs inception, year opening policy, goal funding ratio, flow timing and missing balances.
2. Add independent expected-value regressions; update legacy parity fixtures only for intentionally corrected formulas. Preserve the frozen old calculator as a migration/reference artifact rather than treating it as the correctness oracle.
3. Correct yearly compounding, growth denominator, baseline accounting, UK boundary, birthday age and zero-horizon behavior; reconcile pension equations. Keep formulas linear and cached.
4. Address missing values/Watch partial records and define debt/zero/negative-base return availability without inventing historical cash-flow timing.
5. Make retirement assets/pension inputs explicit and provide a personalised assumption model.

Recalculate derived read models from original immutable records; no rewriting/importing of source events is needed for formula corrections. Add a calculation-version note so historical inputs stay replayable while users can understand why displayed results changed. Run the full core suite plus populated UI/edit/reopen and performance checks after implementation.
