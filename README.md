# Budget Bites

An offline Flutter app that helps students plan campus meals, log what they actually paid, and see how each choice affects a weekly food budget. All data stays on the device (SQLite + SharedPreferences). No cloud services.

**Team:** [Aminur] 
**Kanban evidence:** `Kanban_Contribution_Evidence.pdf` (repository root)

## Target user
A full-time student on a fixed weekly food budget who eats on or near campus.

## Team roles
| Member | Responsibilities |
| --- | --- |
| Aminur Ramim | SQLite layer, repositories, delete policy, data tests |
| [Aminur Ramim] | Budget Desk (home + dial), Meal Form, validation, navigation |
| [Aminur RAmim] | Meal Detail, purchase workflow, smart helper, AI_FEATURE.md |
| [Aminur Ramim] | Insights filter/aggregate, Settings, README, two-device testing |

## Features
- **Budget Desk (home):** animated budget dial (spent vs. remaining this week), meal catalog, search, swipe-to-delete with confirmation, resume banner for unfinished purchases.
- **Meal Form:** create and edit meals with validated name, location, category, and typical price.
- **Meal Detail:** Buy → enter price → Finish & log, or Cancel. Unfinished purchases survive an app restart. Spending receipt after each purchase. Edit or delete past purchases.
- **Smart helper — Meal Cost Estimator:** suggests a price from your last 3 purchases (baseline: typical price), explains why, and lets you Apply or choose Not now.
- **Spending Insights:** filter by This week / 30 days / All time and by category; shows total, average, count, and most-bought meal.
- **Settings:** weekly budget slider ($20–$200), week start day, currency symbol, dark mode, reset settings.

## Setup
Requirements: Flutter stable (3.22 or newer), Android Studio or VS Code, an Android emulator or device.

```bash
git clone https://github.com/AminurRamim/budget-bites.git
cd budget-bites
flutter pub get
flutter run
```

Run tests:
```bash
flutter test
```

Build the release APK:
```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

## How to use
1. Open **Budget Desk** to see how much of this week's budget is left. Three sample meals are preloaded.
2. Tap **Add meal** to save a meal you buy often.
3. Tap a meal, then **Buy this meal**. Type what you paid (or tap **Apply** on the suggestion) and tap **Finish & log**.
4. Check **Insights** to see spending by date range and category.
5. Set your weekly budget in **Settings**.

## Tech & data
- Packages: `sqflite`, `path`, `shared_preferences`, `provider`, `intl`.
- SQLite tables: `meals` (1) → `purchases` (many), foreign key with `ON DELETE CASCADE`. See [ARCHITECTURE.md](ARCHITECTURE.md).
- SharedPreferences keys: `weekly_budget`, `week_start_day`, `currency_symbol`, `dark_mode`, `last_category_filter`.
- No remote backend, cloud storage, authentication, or cloud AI.

## Known issues / future work
- The estimator overestimates after a single unusual purchase (documented in AI_FEATURE.md).
- No data export yet (possible bonus: CSV/JSON export).
- Only tested on Android.

## Documentation
- [ARCHITECTURE.md](ARCHITECTURE.md)
- [AI_FEATURE.md](AI_FEATURE.md)
- [AI_Usage_Log.md](AI_Usage_Log.md)

