# SpendSnap — Viva Preparation Summary

---

## 🎯 **1-Minute Pitch**

**SpendSnap** is a personal finance management app built in Flutter that helps users:
- Track income and expenses with smart categorization
- Set budgets and monitor spending against limits
- Set savings goals with deadline tracking
- Get AI-driven spending insights via a custom health score (0–100)
- Receive budget recommendations using a blended 50/30/20 algorithm

**Why Custom?** The health score uses 4 dimensions (budget adherence, savings rate, spending trend, category diversity) with custom weights derived from personal finance principles — not template code.

---

## 📱 **Tech Stack**

| Layer | Tech |
|---|---|
| **UI Framework** | Flutter (Dart) |
| **State Management** | BLoC (Business Logic Component) |
| **Backend** | Firebase (Auth + Cloud Firestore) |
| **Navigation** | GoRouter (deep linking support) |
| **Charts** | fl_chart |
| **Animations** | flutter_animate, CustomPainter |

---

## 🏗️ **Architecture Overview (Clean Layers)**

```
PRESENTATION LAYER (UI)
    ↓
BUSINESS LOGIC LAYER (Bloc)
    ↓
DATA LAYER (Repositories)
    ↓
EXTERNAL (Firebase)
```

### **Key Separation:**
- **UI** — Screens only call `BlocBuilder` and `.add(events)` — never touches Firebase
- **Bloc** — Orchestrates state, listens to repositories, emits states
- **Repository** — Abstracts data source (Firestore, local cache)
- **Firebase** — Auth, Firestore CRUD, security rules

---

## 📂 **Folder Structure**

```
lib/
├── core/
│   ├── theme/              # AppColors, AppTypography (13 text styles)
│   ├── constants/          # Category enum, allocation rules
│   ├── utils/              # CurrencyFormatter, Validators
│   └── widgets/            # 7+ custom reusable components
│       ├── SnapCard.dart
│       ├── GlowButton.dart
│       ├── CategoryBadge.dart
│       ├── AmountDisplay.dart
│       ├── HealthScoreDial.dart (⭐ CustomPainter — animated arc)
│       ├── EmptyState.dart
│       └── SnapTextField.dart
│
├── data/
│   ├── models/             # TransactionModel, BudgetModel, GoalModel
│   └── repositories/       # AuthRepository, TransactionRepository, etc.
│
├── logic/
│   ├── blocs/              # 4 domain blocs
│   │   ├── auth_bloc/
│   │   ├── transaction_bloc/
│   │   ├── budget_bloc/
│   │   └── goal_bloc/
│   └── services/           # 2 custom business logic services
│       ├── spending_health_score_service.dart (⭐)
│       └── budget_recommendation_service.dart (⭐)
│
└── ui/
    └── screens/
        ├── auth/
        ├── dashboard/
        ├── transactions/
        ├── budgets/
        ├── goals/
        ├── insights/
        └── profile/
```

---

## 🔑 **Core Features Explained**

### **1. Authentication (AuthBloc)**
```dart
// Flow: Email → FirebaseAuth → User created in Firestore
events: LoginRequested, SignupRequested, LogoutRequested
states: Initial, Loading, Authenticated, Failure
```
✅ Uses Firebase Email/Password auth  
✅ Forgot password via Firebase reset link  
✅ UserProfileModel stores uid, email, monthlyIncome

---

### **2. Transaction Tracking (TransactionBloc)**
```dart
// Model:
TransactionModel {
  id, userId, title, amount, 
  type (income/expense), category, date,
  isRecurring, recurringInterval
}

// CRUD Operations:
- TransactionAdded → Firestore create
- TransactionUpdated → Firestore update
- TransactionDeleted → Firestore delete (swipe-to-delete UI)
- TransactionsFetched → Real-time listener
- TransactionFilterChanged → Client-side filter (no DB hit)
```
✅ Real-time sync via Firestore stream  
✅ Client-side filtering by category + type (using Sentinel/unset pattern)  
✅ Search by title (on-device)  
✅ Swipe-to-delete with confirm dialog  
✅ Custom notes displayed dynamically (collection-if syntax)
✅ **Bank Sync Simulator**: Fetches real JSON from HTTP API and auto-categorizes expenses

---

### **3. Budget Management (BudgetBloc)**
```dart
// Model:
BudgetModel {
  id, userId, category, limitAmount, 
  spentAmount (derived), month, year
}

// Key Logic:
- User sets budget for each category
- spentAmount = SUM(transactions where category matches && date in month)
- Progress bar shows: spentAmount / limitAmount
- Color: Green (safe) → Orange (90%) → Red (>100%)
```
✅ Real-time spent amount calculation  
✅ Monthly budget cycle  
✅ Animated progress bars  
✅ One-tap smart suggestions

---

### **4. Savings Goals (GoalBloc)**
```dart
// Model:
GoalModel {
  id, userId, title, targetAmount, 
  currentAmount, deadline, createdAt
}

// Flow:
- User creates goal + deadline
- Adds money incrementally via goal transactions
- Progress shown as: currentAmount / targetAmount
- Days remaining calculated
```
✅ Multiple concurrent goals  
✅ Deadline countdown  
✅ Incremental funding UI

---

### **5. Insights Dashboard**
```dart
// Visualizations:
1. Pie Chart — Spending by category
2. Line Chart — 6-month trend (expense MoM change)
3. Health Score Dial — Custom animated arc (0–100)

// Data shown:
- Total income / expense / net balance
- Savings rate %
- Health score with category-specific insights
```
✅ Real-time chart updates  
✅ Responsive on different screen sizes

---

## ⭐ **Custom Logic Systems (Key for Viva!)**

### **System 1: SpendingHealthScore** 📊
**File:** `logic/services/spending_health_score_service.dart`

**Purpose:** Give users a holistic spending health metric (0–100)

**Algorithm:**
```
Score = (BudgetAdherence × 0.4) + (SavingsRate × 0.3) 
        + (SpendingTrend × 0.2) + (CategoryDiversity × 0.1)

1. Budget Adherence (40 pts max)
   - Per category: If under limit → 40pts
   - If over: decay by (overage% / 10)
   - Average across all budgets

2. Savings Rate (30 pts max)
   - ≥30% → 30pts
   - ≥20% → 22pts
   - ≥10% → 14pts
   - <0% (net loss) → 0pts

3. Spending Trend (20 pts max)
   - Current month vs last month
   - Reduced ≥10% → 20pts (good!)
   - Increased >10% → 2pts (caution)

4. Category Diversity (10 pts max)
   - If one category >70% of spend → 1pt
   - If balanced across 5+ → 10pts
```

**Output:**
- Score number (e.g., 72/100)
- Color-coded status (Red < 40, Amber 40–70, Green >70)
- Category-specific insights (e.g., "Food exceeds budget by 50%")

**Why Not Copy-Paste?**
- Custom dimensions adapted to Indian spending patterns
- Weights based on personal finance research, not tutorials
- Tested with 7 unit tests covering edge cases

---

### **System 2: BudgetRecommendationEngine** 💡
**File:** `logic/services/budget_recommendation_service.dart`

**Purpose:** Suggest optimal category budgets using income + historical data

**Algorithm:**
```
1. Get user's monthlyIncome from profile
2. Compute ideal 50/30/20 split:
   - 50% → Needs (Housing, Transport, Groceries, etc.)
   - 30% → Wants (Entertainment, Dining out, Shopping, etc.)
   - 20% → Savings

3. Get historical spend per category (last 3 months avg)
   - Example: avg(Food & Dining) = ₹15,000/month

4. Blend historical + ideal:
   suggested = (historical × 0.6) + (ideal × 0.4)
   - Weights: 60% respect user's habits, 40% nudge toward ideal

5. Round to nearest ₹500 for UX clarity

6. Flag if historical_avg > suggested × 1.2
   → "Consider reducing Food budget"
```

**Example:**
```
Monthly Income: ₹1,00,000
Ideal Needs: ₹50,000

Historical Food avg: ₹18,000
Ideal Food (needs category): ₹12,000
Suggested: (18,000 × 0.6) + (12,000 × 0.4) = ₹15,200 → ₹15,000
```

**Why Not Copy-Paste?**
- Custom 60/40 blend (not standard 50/30/20)
- Accounts for user's spending history
- Tested with 6 unit tests (income scaling, overspending flags)

---

### **System 3: Bank Sync Auto-Categorization (DoD compliance)** 🏦
**File:** `logic/services/bank_sync_service.dart`

**Purpose:** Emulates connecting to a real bank API to import transactions automatically without manual entry.

**Algorithm:**
```
1. Fetch dynamic JSON from an HTTP endpoint (dummyjson.com/products) to simulate bank data.
2. Filter the fetch for "expenses".
3. Map generic items into domain-specific SpendSnap categories:
   - Uses a keyword dictionary (e.g. food = "groceries, meal, apple, chicken", self care = "beauty, perfume")
   - Reverts to 'Miscellaneous' if no dictionary match is found.
4. Convert successfully parsed entries directly into TransactionModel items and save them to Firestore.
```

**Why Not Copy-Paste?**
- Provides actual HTTP network handling (dart:convert, http package) bypassing hardcoded data.
- Handles UI loading dialogs safely against deeply nested shell navigators (`rootNavigator: true`).
- Incorporates error handling for internet drops ("Failed to sync bank data").

---

### **System 4: Smart Notification Engine (Stateful Unread Tracking)** 🔔
**File:** `ui/screens/dashboard/dashboard_screen.dart` (`_NotificationBell`)

**Purpose:** Provide intelligent unread badging without unnecessary Firestore writes. It only shows the unread counter for *new* limit breaches or goal completions.

**Algorithm:**
```
1. Derive current alert keys dynamically from active Bloc states:
   - "budget_over_${category}_${month}_${year}"
   - "goal_done_${goalId}"
2. Compare active keys against `static final Set<String> _seenAlerts`.
3. If actve keys exist that are not in `seenAlerts`, display the yellow badge with the calculated unread count.
4. On tap, add all current keys to `_seenAlerts` via `setState`, dismissing the unread badge automatically while popping open a dynamic bottom modal sheet.
```

**Why Not Copy-Paste?**
- Completely local state tracking reduces expensive database document updates (no "isRead" boolean on Firebase).
- Key combination strategy ensures the notification safely re-triggers the next month when limits reset.

---

## 🔄 **State Management Deep Dive (Bloc)**

### **Example: Adding a Transaction**

```
User (UI)
  ↓
TransactionsScreen.add() 
  → BlocBuilder listens to TransactionState
  ↓
TransactionBloc receives: TransactionAdded(model)
  ├─ Emit: TransactionStatus.loading
  ├─ Repository.addTransaction(model)
  │  ├─ Firestore.collection('transactions').add(model.toJson())
  │  └─ Returns model with firestore-generated ID
  ├─ Emit: TransactionStatus.loaded + updated list
  ├─ Trigger: BudgetBloc.add(BudgetSpentUpdated)
  │  (because a new transaction affects budget spent totals)
  └─ Return to previous screen
```

**Key Design:**
- Blocs communicate via events (not shared state)
- No circular dependencies
- Each Bloc owns one domain (Single Responsibility)
- Tests mock repositories → easy to test Bloc logic

---

## 🔐 **Firebase Integration**

### **Authentication**
```dart
FirebaseAuth.instance
  .createUserWithEmailAndPassword(email, password)
  → Creates user + generates UID
  → Store user profile in Firestore at /users/{uid}/

FirebaseAuth.instance
  .signInWithEmailAndPassword(email, password)
  → Validates credentials
  → Stores session locally
```

### **Firestore Structure**
```
users/{uid}
  ├── email: String
  ├── name: String
  ├── monthlyIncome: double
  ├── currency: String (default: INR)
  └── timestamps
  
users/{uid}/transactions/{txnId}
  ├── title, amount, type, category, date, isRecurring
  
users/{uid}/budgets/{budgetId}
  ├── category, limitAmount, month, year
  
users/{uid}/goals/{goalId}
  ├── title, targetAmount, currentAmount, deadline
```

### **Security Rules**
```
match /users/{userId}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```
✅ User can only access their own data

### **Offline Handling**
- ✅ SharedPreferences caches user profile
- ✅ Firestore offline persistence enabled (local DB copy)
- ✅ Graceful empty state if no data
- ✅ Auto-sync when connection restored

---

## 🎨 **Custom UI Components**

| Component | Purpose | Custom Feature |
|---|---|---|
| **HealthScoreDial** | Display 0–100 score | CustomPainter — animated arc from 0° to 180° |
| **SnapCard** | Branded card wrapper | Mint + Violet theme with custom padding |
| **GlowButton** | CTA button | Loading spinner state during async ops |
| **AmountDisplay** | Format currency ± | Shows ₹ before, color-coded green (income) / red (expense) |
| **CategoryBadge** | Show category label | Dynamic color per category (Food=Orange, etc.) |
| **EmptyState** | No data fallback | Consistent icon + message + CTA across all screens |

---

## ✅ **Testing Coverage (26 Tests)**

### **Unit Tests (13 tests)**
```dart
test/widget_test.dart

Tests for:
- AmountDisplay: Format +/- amounts correctly
- CategoryBadge: Render color + label
- GlowButton: Show loading state
- EmptyState: Display when list empty
- HealthScoreDial: Arc renders at correct angle
```

### **Service Logic Tests (13 tests)**
```dart
test/spending_health_score_test.dart (7 tests)
- Score calculation with all dimensions
- Edge case: negative savings (score = 0)
- Edge case: single category >70%
- Insight string generation

test/budget_recommendation_test.dart (6 tests)
- Historical + ideal blend
- Rounding to nearest ₹500
- Income scaling (what if monthly income changes?)
- Overspending flags
```

---

## 🎬 **User Flow Example: Adding an Expense**

```
1. User taps FAB on Transactions screen
   → Navigate to /add-transaction

2. Add Transaction Screen:
   - Form fields: title, amount, category, date, notes
   - Form validation (amount > 0, title not empty)
   - Select category from dropdown
   - Submit → TransactionBloc.add(TransactionAdded(model))

3. TransactionBloc processes:
   - Emit: loading
   - Call: TransactionRepository.addTransaction()
     ├─ Firestore.collection('users/{uid}/transactions').add(model)
     └─ Return created model with ID
   - Update local list
   - Emit: loaded with new list
   - Trigger: BudgetBloc.add(BudgetSpentUpdated)
     (so budget progress bars refresh)

4. UI response:
   - Snackbar: "Transaction added ✓"
   - Pop back to Transactions screen
   - Charts auto-update (real-time stream)
```

---

## 📊 **Dashboard Flow: Health Score Calculation**

```
1. User opens Insights screen
2. InsightsScreen BlocBuilder listens to TransactionBloc + BudgetBloc
3. On widget build:
   - Fetch all transactions for current month
   - Fetch all budgets
   - Call: SpendingHealthScoreService.calculate()
     ├─ Compute percentage under budget per category
     ├─ Compute savings rate (income - expense) / income
     ├─ Compute trend (current month vs last month)
     ├─ Compute diversity (std dev of category spend)
     └─ Weighted sum → final score
   - Generate insights strings
   - Return: score + insights

4. UI renders:
   - HealthScoreDial with AnimationController
     └─ Arc animates from 0° to (score/100 * 180°) over 2 seconds
   - Text: "Your spending health: 72/100 · Good"
   - Category-specific insights below
```

---

## 🚀 **Deployment Steps**

```bash
# 1. Build APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk

# 2. Configure app icon + splash (already done in project)
# Check: android/app/build.gradle.kts + iOS Runner

# 3. Firebase configuration (already in firebase_options.dart)
# Auto-generated via: flutterfire configure
```

---

## 🎯 **Key Points to Highlight in Viva**

### **Originality:**
1. ✅ Custom health score (4 dimensions, custom weights)
2. ✅ Budget recommendation engine (60/40 historical + ideal blend)
3. ✅ Bank sync simulated HTTP integration + AI-like auto-categorization
4. ✅ Custom HealthScoreDial widget (animated CustomPainter arc)
5. ✅ Theme system (electric mint + violet, 8 semantic colors)

### **Architecture:**
1. ✅ Clean layer separation (UI → Bloc → Repository → Firebase)
2. ✅ No circular dependencies
3. ✅ Each Bloc owns one domain
4. ✅ Tests mock repositories

### **Firebase Integration:**
1. ✅ Auth + Firestore + Security rules
2. ✅ User-scoped data access
3. ✅ Real-time sync via streams
4. ✅ Offline persistence

### **State Management:**
1. ✅ BLoC for all domain state
2. ✅ Events flow through blocs
3. ✅ No setState misuse
4. ✅ Predictable state transitions

### **Edge Cases Handled:**
1. ✅ Empty states (no transactions, budgets, etc.)
2. ✅ Invalid input (form validation)
3. ✅ No internet (graceful fallback + caching)
4. ✅ Concurrent goals/budgets

---

## 💡 **Common Viva Questions & Answers**

**Q: Why use Bloc instead of Provider?**  
A: BLoC provides better separation of concerns and predictable event flow. Each Bloc owns one domain, and tests can mock a repository by providing a test-specific Bloc.

**Q: How does the health score differ from copying tutorials?**  
A: We designed 4 custom dimensions with custom weights based on personal finance principles. The savings rate threshold (30/20/10) is research-based. Tests verify it handles edge cases like negative savings.

**Q: How does the bank sync feature work?**  
A: It makes a real HTTP network request to a dummy API, extracting product entries. A dictionary-based algorithm scans the titles and maps them to our app's predefined categories (like Food & Dining or Personal Care). It then pushes these models immediately to Firestore, completing an end-to-end simulated flow.

**Q: How do you handle resetting the transaction filters?**  
A: Dart's copyWith method drops null parameters. I used a private sentinel object (`_unset`) in the `TransactionState.copyWith` so it knows the difference between "do not update this filter" versus "clear this filter explicitly".

**Q: How do budgets stay in sync with transactions?**  
A: When a transaction is added, `TransactionBloc` emits an event that triggers `BudgetBloc.add(BudgetSpentUpdated)`. Budget's `spentAmount` is derived (not stored) by summing matching transactions.

**Q: How is offline data handled?**  
A: Firestore offline persistence is enabled in `main.dart`. SharedPreferences caches user profile. When offline, users see stale data gracefully; when online, Firestore auto-syncs.

**Q: Why does the recommendation engine use 60/40 blend?**  
A: Standard 50/30/20 assumes generic spending. We respect user's habits (60%) while nudging toward ideal (40%) to avoid jarring recommendations.

**Q: What's the HealthScoreDial CustomPainter doing?**  
A: Draws a half-arc (180° sweep) colored by score level. `AnimationController` drives the arc from 0° to target over 2 seconds on initial render.

---

## 📝 **To Remember**

- **4 Blocs** = auth, transaction, budget, goal (each independent)
- **2 Custom Services** = health score, budget recommendation (pure Dart logic)
- **7+ Custom Widgets** = reusable, theme-consistent, responsive
- **26 Tests** = unit + widget, covering happy path + edge cases
- **Firebase Security** = user-scoped access via security rules
- **Real-time Sync** = Firestore streams + BudgetSpentUpdated event flow
- **Offline Handling** = Firestore persistence + SharedPreferences cache

---

**You're ready! 🎯**
