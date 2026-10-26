# AI_FEATURE.md — Meal Cost Estimator

## What it is
A **rule-based** local smart helper. It is not a trained model and uses no cloud service. It suggests what a meal will cost before the student logs a purchase.

- **Code:** `lib/services/estimator_service.dart`
- **Shown in:** Meal Detail screen, "Suggested estimate (not guaranteed)" card
- **Tests:** `test/estimator_test.dart`

## Decision it supports
"Can I afford this meal right now?" The card shows the estimate, the reason, and whether it fits the remaining weekly budget.

## Inputs
- The meal's `typical_price` (from SQLite `meals`)
- Its most recent logged `price_paid` values, newest first (from SQLite `purchases`)

## Method
1. Drop invalid prices (≤ 0, > 100, NaN, infinite).
2. Take the 3 most recent valid prices.
3. If none remain, use the baseline. Otherwise return their average, rounded to cents.

## Baseline
The meal's typical price, unchanged. The helper is only useful if it beats this.

## Explanation shown to the user
- "Average of your last 3 purchases"
- "Based on 1 purchase"
- "Using your typical price — not enough history yet"

## User control
- **Apply** fills the price field (and starts the purchase if needed).
- **Not now** hides the suggestion.
- The user can always type a different price. Nothing is saved until they tap **Finish & log**.

## Evaluation (five case types)
| Case | Input history | Typical price | Baseline | Helper | Actual (demo) | Baseline error | Helper error |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Normal | $7, $8, $10 | $8.00 | $8.00 | $8.33 | $9.00 | $1.00 | $0.67 |
| No data | none | $9.50 | $9.50 | $9.50 | $9.50 | $0.00 | $0.00 |
| Invalid | $0, -$3, NaN | $6.00 | $6.00 | $6.00 | $6.50 | $0.50 | $0.50 |
| Boundary | $9.00 (one purchase) | $8.00 | $8.00 | $9.00 | $9.25 | $1.25 | $0.25 |
| Outlier (counterexample) | $8, $8, $25 | $8.00 | $8.00 | $13.67 | $8.00 | $0.00 | $5.67 |

Metric: absolute error in dollars against the next real price. The "Actual (demo)" column is a small demonstration sample we chose, not proof of accuracy.

**Result:** the helper beat the baseline in 2 of 5 cases, tied in 2, and lost badly in the outlier case.

## Counterexample and limitation
One unusual purchase (a $25 group order) pulls the average to $13.67 when the student normally pays $8. The helper overestimates.

**Why we kept it:** the reason text tells the user exactly which purchases were averaged, and **Not now** or typing a price corrects it immediately.

**Revision considered:** use the median of the last 3 instead of the mean. That fixes this case ($8.00) but reacts more slowly when prices genuinely rise. [Team: record whether you adopted it.]

## Critical-thinking decisions
- Rules instead of ML: there are only a few purchases per meal, too little to train anything honestly.
- Only 3 purchases: recent prices reflect current menu prices; older ones go stale.
- Labeled "not guaranteed": it is an estimate, not a fact.
- No data leaves the device.

## Pathway
Undergraduate: baseline plus five case types, documented above.
