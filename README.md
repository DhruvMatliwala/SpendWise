# SpendWise

**Offline-First Smart Expense & Budget Analytics Manager** built with Flutter, Material Design 3, SQLite (`sqflite`), interactive `fl_chart` visualizations, live multi-currency REST exchange rates, and CSV statement export.

---

## Features

- **Offline-First SQLite Persistence (`sqflite`)**
  - Full CRUD for expenses (`id`, `title`, `amount`, `currency`, `convertedAmountInBase`, `category`, `date`, `notes`) and a dedicated `budgets` table storing monthly per-category limits.
  - Instant search by title or notes, category chip filters, and month navigation.
  - Swipe-to-delete with an immediate **Undo** snackbar.

- **Interactive Analytics Dashboard (`fl_chart`)**
  - **Category Breakdown Pie Chart** with touch-to-expand slices, live center total readout, percentage shares, and color-coded legend.
  - **6-Month Spending Trend Bar Graph** with interactive touch tooltips and formatted axis labels.
  - **Summary KPI Cards**: Monthly Total, Daily Average, Top Category, and Transaction Count.

- **Live Multi-Currency Conversion (`http` + `SharedPreferences`)**
  - Select your preferred base currency (`INR ₹` default, `USD $`, `EUR €`, `GBP £`, `AED د.إ`, `JPY ¥`) and log expenses in any supported currency.
  - Fetches live rates from `https://open.er-api.com/v6/latest/{base}` with automatic `SharedPreferences` caching, a **Last updated** timestamp, and deterministic offline fallback.
  - Automatically recalculates stored expense totals when switching base currencies.

- **Budget Thresholds & 80% / 100% Alerts**
  - Set monthly limits per category (`Food`, `Travel`, `Bills`, `Shopping`, `Health`, `Entertainment`, `Other`).
  - Color-coded progress indicators: **Green** (`< 80%`), **Amber Warning** (`80%–99%`), **Red Exceeded** (`>= 100%`).
  - Triggers immediate alert snackbars and an inline warning banner when spending crosses 80% or 100% of a category limit.

- **1-Tap CSV Statement Export (`path_provider` + `share_plus`)**
  - Exports filtered or monthly transactions (`Date, Title, Category, Original Amount, Currency, Converted Amount, Notes`) to an RFC-4180 `.csv` file and opens the native share sheet.

- **Responsive Material 3 Fintech UI**
  - Dark Slate / Indigo fintech theme with an instant Light Mode toggle.
  - Adaptive 4-tab layout switching smoothly between `NavigationBar` on mobile and `NavigationRail` on tablet/desktop viewports.

---

## Architecture

```text
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart      # Spacing, radii, breakpoints, categories, currencies
│   └── theme/
│       └── app_theme.dart          # Material 3 dark/light themes & semantic colors
├── db/
│   └── database_helper.dart        # Singleton SQLite helper (expenses + budgets tables)
├── models/
│   ├── category_budget.dart        # Budget model, utilization snapshot & threshold detector
│   ├── currency_rate.dart          # Live/cached FX rate table & currency conversion
│   └── expense.dart                # Immutable Expense domain/SQLite/JSON model
├── providers/
│   ├── budget_provider.dart        # Monthly category limits & alert checks
│   ├── currency_provider.dart      # Base currency, FX refresh & offline cache state
│   ├── expense_provider.dart       # Expense CRUD, search/filter & analytics aggregations
│   └── theme_provider.dart         # Persisted Dark Slate / Light Mode state
├── screens/
│   ├── analytics_screen.dart       # KPI grid, pie chart & 6-month bar chart
│   ├── app_shell.dart              # Responsive NavigationBar / NavigationRail shell
│   ├── budgets_screen.dart         # Monthly category budget cards & limit editor
│   ├── home_screen.dart            # Ledger, search, category chips, alerts & CSV export
│   └── settings_screen.dart        # Base currency, live FX status, theme & export
├── services/
│   ├── csv_export_service.dart     # RFC-4180 CSV generator & share sheet integration
│   └── currency_service.dart       # Exchange rate REST API client & SharedPreferences cache
├── widgets/
│   ├── add_edit_expense_sheet.dart # Modal form with live currency preview & alert trigger
│   ├── budget_progress_card.dart   # Color-coded progress card & status badge
│   ├── category_filter_chips.dart  # Horizontal category filter chips
│   ├── category_pie_chart.dart     # Touch-interactive fl_chart PieChart
│   ├── empty_state_view.dart       # Reusable empty & retryable error states
│   ├── expense_card.dart           # Swipeable transaction row card
│   ├── kpi_summary_grid.dart       # Responsive 2x2 / 4x1 KPI cards
│   └── monthly_bar_chart.dart      # Touch-interactive 6-month fl_chart BarChart
└── main.dart                       # MultiProvider setup & MaterialApp entrypoint
```

---

## Tech Stack

| Layer | Technology |
| --- | --- |
| **Framework** | Flutter & Dart (Material Design 3) |
| **State Management** | `provider` (`ChangeNotifier`) |
| **Offline Database** | SQLite via `sqflite` & `path` |
| **Key-Value Cache** | `shared_preferences` |
| **Charts** | `fl_chart` |
| **Networking** | `http` REST API (`open.er-api.com`) |
| **Export & Formatting** | `path_provider`, `share_plus`, `intl` |
| **CI/CD** | GitHub Actions (`flutter analyze`, `flutter test`, release APK) |

---

## Cloud Build & APK Artifact

Every push to `main` automatically runs [`.github/workflows/build.yml`](.github/workflows/build.yml):
1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`
4. `flutter build apk --release`
5. Uploads `spendwise-release-apk` (`app-release.apk`) as a downloadable workflow artifact under the **Actions** tab.

---

## Local Setup

```bash
git clone https://github.com/DhruvMatliwala/SpendWise.git
cd SpendWise
flutter pub get
flutter analyze
flutter test
flutter run
```
