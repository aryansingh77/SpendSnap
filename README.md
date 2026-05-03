# SpendSnap — Personal Finance Manager

A Flutter application for smart personal finance tracking with rule-based spending intelligence.

---

## Features

### Core
| Feature | Description |
|---|---|
| Authentication | Email/password login & signup via Firebase Auth |
| Transaction Tracking | Log income and expenses with categories, dates, notes |
| Budget Management | Set monthly category budgets with animated progress bars |
| Savings Goals | Set goals with deadlines, add funds incrementally |
| Insights Dashboard | Spending breakdown (pie chart), 6-month trend (line chart) |

### Extended (beyond base requirements)
| Feature | Description |
|---|---|
| Smart Notification Center | Alert system with dynamic unread badging (stateful tracking) for budget limits & goal achievements |
| Transaction Notes | Log and elegantly display custom notes on each transaction |
| Recurring Transactions | Mark transactions as Daily / Weekly / Monthly |
| Spending Health Score | Rule-based 0–100 score across 4 dimensions |
| Smart Budget Recommendations | 50/30/20 engine adapted to user's historical data |
| Bank Auto-Sync Simulation | Fetches and auto-categorizes mock statement data via HTTP API |
| Swipe-to-delete | Transactions dismissible with confirm dialog |
| Category + type filters | Filter transaction list by category and income/expense type |
| Forgot password | Firebase password reset flow |

---

## Architecture

```
lib/
├── core/
│   ├── theme/          # AppColors, AppTypography, AppTheme
│   ├── constants/      # Category lists, allocation guides
│   ├── utils/          # CurrencyFormatter, Validators
│   └── widgets/        # SnapCard, GlowButton, CategoryBadge,
│                       # AmountDisplay, SnapTextField,
│                       # HealthScoreDial (custom painter), EmptyState
├── data/
│   ├── models/         # TransactionModel, BudgetModel, GoalModel, UserProfileModel
│   └── repositories/   # AuthRepository, TransactionRepository,
│                       # BudgetRepository, GoalRepository
├── logic/
│   ├── blocs/          # AuthBloc, TransactionBloc, BudgetBloc, GoalBloc
│   └── services/       # SpendingHealthScoreService, BudgetRecommendationService
└── ui/
    └── screens/        # auth/, dashboard/, transactions/,
                        # budgets/, goals/, insights/, profile/
```

### State Management (Bloc)
- **UI layer** — Screens only emit events and read states via `BlocBuilder` / `BlocListener`
- **Business logic layer** — Each Bloc owns one domain (auth, transactions, budgets, goals)
- **Data layer** — Repositories are injected into Blocs; screens never touch Firebase directly
- No misuse of `setState` — only used for local UI-only state (e.g., password visibility toggle)

### Firestore Data Model
```
users/{uid}
  ├── profile fields (name, email, monthlyIncome, currency)
  ├── transactions/{txnId}
  ├── budgets/{budgetId}
  └── goals/{goalId}
```

---

## Custom Logic Systems

### 1. SpendingHealthScore (`logic/services/spending_health_score_service.dart`)

A rule-based 0–100 score computed from four independently weighted dimensions:

| Dimension | Max Points | Algorithm |
|---|---|---|
| Budget Adherence | 40 | Per budget: full pts if under limit; decaying penalty for each 10% over |
| Savings Rate | 30 | ≥30% saved → 30pts · ≥20% → 22pts · ≥10% → 14pts · negative → 0pts |
| Spending Trend | 20 | MoM expense reduction ≥10% → 20pts; increase >10% → 2pts |
| Category Diversity | 10 | If one category >70% of spend → 1pt; well-spread → 10pts |

Score also generates human-readable insight strings shown on the Insights screen.

### 2. BudgetRecommendationEngine (`logic/services/budget_recommendation_service.dart`)

Generates per-category budget suggestions using a **blended 50/30/20 model**:

1. Compute user's average monthly spend per category over last 3 months
2. Compute 50/30/20 ideal amounts from monthly income
3. Blend: `suggested = (historical × 0.6) + (ideal × 0.4)`
4. Round to nearest ₹500 for UX clarity
5. Flag categories where current average exceeds suggested by >20%

Shown on the Add Budget screen as a one-tap "Smart Suggestion" card.

### 3. Bank Sync Auto-Categorization (`logic/services/bank_sync_service.dart`)

Simulates a real banking API integration using a public HTTP mock API (`dummyjson.com`).
1. Fetches a list of generic expenses.
2. Uses dictionary-based matching to infer the correct category based on raw title strings.
3. Handles HTTP network errors, parses JSON, and models the user's data structures appropriately.

---

## Setup Instructions

### Prerequisites
- Flutter 3.x (`flutter --version`)
- Firebase account

### 1. Install dependencies
```bash
cd spendsnap
flutter pub get
```

### 2. Firebase Setup (required to run)
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Creates lib/firebase_options.dart automatically
flutterfire configure
```

In Firebase Console, enable:
- **Authentication** → Email/Password provider
- **Cloud Firestore** → Start in production mode

Add Firestore security rules:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 3. Run
```bash
flutter run
```

### 4. Build APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Running Tests

```bash
flutter test
```

**26 tests across 3 files — all passing**
- 7 unit tests — `SpendingHealthScoreService`
- 6 unit tests — `BudgetRecommendationService`
- 13 widget tests — `AmountDisplay`, `CategoryBadge`, `GlowButton`, `EmptyState`, `HealthScoreDial`

---

## AI Usage Disclosure

| Tool | Purpose | Manual Modifications |
|---|---|---|
| Claude (Anthropic) | Flutter widget boilerplate, Bloc scaffolding | Scoring algorithm dimensions & weights, recommendation blending ratios, all UI design decisions, Firestore schema, architecture design |

The `SpendingHealthScoreService` scoring dimensions and `BudgetRecommendationService` blending ratios were designed from personal finance principles (50/30/20 rule, savings rate benchmarks) — not copied from tutorials.

---

## Challenges Faced

1. **Bloc stream lifecycle with StatefulShellRoute** — go_router's indexed stack doesn't re-create Blocs on tab switch, requiring careful `cancel()` in each Bloc's `close()` method.
2. **Real-time budget + transaction sync** — Budgets need `spentAmount` derived from transactions. Solved by a `BudgetSpentUpdated` event dispatched whenever transactions change.
3. **Custom animated HealthScoreDial** — Drawing a half-arc that animates via `CustomPainter` required precise radian math and `strokeCap.round` offset compensation.
4. **50/30/20 adaptation** — Standard rule doesn't account for Indian expense patterns. The 60/40 historical blend softens jarring recommendations for diverse spending habits.
5. **Differentiating "Null" vs "Unchanged" in Bloc States** — Used a Sentinel object `_unset` to clear filters gracefully inside Dart's `copyWith` method.
6. **Nested Navigation with GoRouter and Bottom Sheets** — Dialogs inside shell routes frequently close the underlying tab unless `rootNavigator: true` is set explicitly.
