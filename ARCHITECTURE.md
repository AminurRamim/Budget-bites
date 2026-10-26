# Architecture — Budget Bites

## Layers
```
lib/
  main.dart                  App entry, theme, Provider setup, lifecycle refresh
  models/                    Meal, Purchase, PurchaseRow (plain Dart, toMap/fromMap)
  data/                      DatabaseHelper (single sqflite connection) + repositories
  services/                  SettingsService (SharedPreferences), EstimatorService (smart helper)
  state/                     BudgetController (ChangeNotifier shared state)
  screens/                   Five screen roles + bottom-nav shell
  widgets/                   Reusable UI: BudgetDial, MealTile, ReceiptCard, dialogs
  utils/                     Validators, formatting, week math, insights aggregation
test/                        Unit and widget tests
```

Data flows one way: **Screen → BudgetController → Repository → DatabaseHelper → SQLite**, then the controller calls `notifyListeners()` and screens rebuild.

## Why these choices
- **Provider + one ChangeNotifier.** The weekly total must stay consistent across Home, Detail, and Insights. One shared controller is the single source of truth, so the dial updates the moment a purchase is logged, edited, or deleted.
- **setState for local UI state.** Form fields, the purchase flow step, the slider while dragging, and filter selections only matter to one screen, so they stay in that screen's State.
- **Repositories.** Screens never write SQL. This keeps queries in one place and makes the data layer easy to test or swap.
- **DatabaseHelper owns the connection.** One open handle for the app. `close()` awaits shutdown and clears the cached handle so a later call reopens cleanly.
- **Pure-Dart helper and utils.** `EstimatorService`, validators, week math, and `InsightsSummary` have no Flutter or database dependency, so they are unit-tested directly.

## Screens (five roles)
| Role | Screen | File |
| --- | --- | --- |
| Catalog / dashboard | Budget Desk | `screens/home_screen.dart` |
| Create / edit | Meal Form | `screens/meal_form_screen.dart` |
| Detail / activity | Meal Detail | `screens/meal_detail_screen.dart` |
| History / insights | Spending Insights | `screens/insights_screen.dart` |
| Settings | Settings | `screens/settings_screen.dart` |

## Database schema
```sql
CREATE TABLE meals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  location TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL,
  typical_price REAL NOT NULL CHECK (typical_price > 0 AND typical_price <= 100),
  created_at TEXT NOT NULL
);

CREATE TABLE purchases (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  meal_id INTEGER NOT NULL,
  price_paid REAL NOT NULL CHECK (price_paid >= 0 AND price_paid <= 100),
  purchased_at TEXT NOT NULL,
  note TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL CHECK (status IN ('in_progress', 'logged')),
  FOREIGN KEY (meal_id) REFERENCES meals (id) ON DELETE CASCADE
);
```
- `PRAGMA foreign_keys = ON` is set in `onConfigure`.
- **Parent-delete policy:** deleting a meal shows how many purchases go with it, asks for confirmation, then cascades.
- `price_paid = 0` is allowed only for an in-progress draft. A purchase can only become `logged` after the form validates a price above 0.

## Stateful workflow
`Start` (Buy this meal → in_progress row) → `Progress` (price/note typed, draft auto-saved after 600 ms) → `Finish` (status = logged, receipt shown) or `Cancel` (row deleted). An unfinished purchase is restored on the Detail screen and listed on the home screen after a restart.

## Integrity rule
The dial, Insights "This week" total, and receipt all read logged purchases in the same `[weekStart, weekEnd)` window, so they always agree after create, edit, delete, restart, or a week-start change.

## Lifecycle
- All `TextEditingController`s and the draft `Timer` are disposed in `dispose()`.
- Every `await` in a State is followed by a `mounted` check before using `context` or `setState`.
- On app resume, the controller refreshes (the week may have rolled over).
