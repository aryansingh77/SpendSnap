# SpendSnap — Architecture & Code Flow Diagrams

---

## 🏗️ **Layered Architecture**

```
┌─────────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                         │
│  (UI/Screens — only BlocBuilder, BlocListener, no logic)    │
│                                                              │
│  ├─ AuthScreen (login, signup, forgot password)             │
│  ├─ DashboardScreen (overview, quick actions)               │
│  ├─ TransactionsScreen (list, filter, search, add)          │
│  ├─ BudgetsScreen (category budgets, progress bars)         │
│  ├─ GoalsScreen (savings goals, progress)                   │
│  ├─ InsightsScreen (charts, health score, trends)           │
│  └─ ProfileScreen (income, settings)                        │
└────────────────────┬───────────────────────────────────────┘
                     │ (BlocEvents)
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              BUSINESS LOGIC LAYER (Bloc)                     │
│  (Manages state, orchestrates side effects)                 │
│                                                              │
│  ├─ AuthBloc                                                │
│  │   ├─ Events: LoginRequested, SignupRequested, LogoutRequested
│  │   ├─ States: Initial, Loading, Authenticated, Failure    │
│  │   └─ Output: Current user + auth status                  │
│  │                                                           │
│  ├─ TransactionBloc                                         │
│  │   ├─ Events: TransactionAdded, TransactionUpdated, etc.  │
│  │   ├─ States: Loading, Loaded(list), Error               │
│  │   └─ Output: Filtered transaction list                   │
│  │                                                           │
│  ├─ BudgetBloc                                              │
│  │   ├─ Events: BudgetAdded, BudgetSpentUpdated (from Txn)  │
│  │   ├─ States: Loading, Loaded, Error                      │
│  │   └─ Output: Budget list + spent amounts                 │
│  │                                                           │
│  └─ GoalBloc                                                │
│      ├─ Events: GoalAdded, GoalFunded                       │
│      ├─ States: Loading, Loaded, Error                      │
│      └─ Output: Goals list + progress                       │
│                                                              │
│  PUBLIC SERVICES:
│  ├─ SpendingHealthScoreService.calculate(...)
│  │  └─ Input: transactions, budgets → Output: score + insights
│  │
│  ├─ BudgetRecommendationService.suggest(...)
│  │  └─ Input: income, transactions → Output: recommended budgets
│  │
│  └─ BankSyncService.syncBankData(...)
│     └─ Input: dummyjson HTTP API → Output: auto-categorized transactions
└────────────────────┬───────────────────────────────────────┘
                     │ (Repository calls)
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              DATA LAYER (Repositories)                       │
│  (Abstract data sources, no business logic)                 │
│                                                              │
│  ├─ AuthRepository                                          │
│  │   ├─ signUp(email, password) → FirebaseAuth             │
│  │   ├─ login(email, password)                              │
│  │   └─ logout()                                            │
│  │                                                           │
│  ├─ TransactionRepository                                   │
│  │   ├─ addTransaction(model) → Firestore create           │
│  │   ├─ getTransactions() → Stream<List<TransactionModel>>  │
│  │   ├─ updateTransaction(model)                            │
│  │   └─ deleteTransaction(id)                               │
│  │                                                           │
│  ├─ BudgetRepository                                        │
│  │   ├─ addBudget(model)                                    │
│  │   ├─ getBudgets() → Firestore stream                     │
│  │   └─ deleteBudget(id)                                    │
│  │                                                           │
│  └─ GoalRepository                                          │
│      ├─ addGoal(model)                                      │
│      ├─ getGoals() → Firestore stream                       │
│      └─ updateGoal(model)                                   │
└────────────────────┬───────────────────────────────────────┘
                     │ (Firestore queries)
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              EXTERNAL SERVICES                               │
│                                                              │
│  ├─ Firebase Authentication                                │
│  │   └─ Users: email/password auth, UID generation          │
│  │                                                           │
│  ├─ Third-Party APIs (HTTP Server)
│  │  └─ Bank Sync (Simulated via dummyjson.com)
│  │
│  ├─ Cloud Firestore                                         │
│  │   └─ Structure: /users/{uid}/transactions, budgets, goals
│  │                                                           │
│  ├─ Local Cache (SharedPreferences)                         │
│  │   └─ User profile (offline fallback)                     │
│  │                                                           │
│  └─ Device Storage                                          │
│      └─ Firestore offline persistence (local DB copy)       │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 **Event Flow: Adding a Transaction**

```
┌─────────────────────────────────────────────────────────────┐
│ User enters amount, category, title on AddTransactionScreen  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
         Form validation (amount > 0, title not empty)
                     │
                     ▼ (Valid)
┌─────────────────────────────────────────────────────────────┐
│ TransactionBloc.add(TransactionAdded(model))                │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
    Emit       Repository    Stream
   loading    calls fire     events
              Firestore      (blocs)
             create()
                │
                ▼
    Firestore generates ID
    returns: TransactionModel
    with id: "abc123"
                │
                ▼
    BLoC updates local list:
    allTransactions.add(model)
                │
                ▼
    Emit: loaded(newList)
           status: success
                │
    ┌─────────┴─────────────┐
    │                       │
  BlocBuilder     BudgetBloc.add(
  rebuilds          BudgetSpentUpdated)
  UI with            → recalculates
  new list           spent amounts
                     → re-emits
                     budgets with
                     updated progress
```

---

## 📊 **Health Score Calculation Flow**

```
InsightsScreen opened
       │
       ▼
BlocBuilder listens to:
TransactionBloc (all txns)
BudgetBloc (all budgets)
       │
       ▼
Call: SpendingHealthScoreService.calculate(
  allTransactions,
  allBudgets,
  monthlyIncome
)
       │
       ├─ Dimension 1: Budget Adherence (max 40)
       │  ├─ For each budget:
       │  │   └─ % = spent / limit
       │  ├─ If % ≤ 100% → 40pts
       │  ├─ If % > 100% → decay by (% - 100) / 10
       │  └─ Average across all budgets
       │
       ├─ Dimension 2: Savings Rate (max 30)
       │  ├─ rate = (income - expense) / income
       │  ├─ If rate ≥ 30% → 30pts
       │  ├─ If rate ≥ 20% → 22pts
       │  ├─ If rate ≥ 10% → 14pts
       │  └─ If rate < 0% → 0pts
       │
       ├─ Dimension 3: Spending Trend (max 20)
       │  ├─ currentMonth = sum(expense where month=now)
       │  ├─ lastMonth = sum(expense where month=prev)
       │  ├─ If change ≤ -10% → 20pts (reduced!)
       │  ├─ If change ≤ 0% → 10pts
       │  ├─ If change > 10% → 2pts (increased)
       │  └─ Else → 5pts
       │
       └─ Dimension 4: Category Diversity (max 10)
          ├─ For each category:
          │   └─ % = category_spend / total_spend
          ├─ If one category > 70% → 1pt
          ├─ If top 3 categories < 80% → 10pts
          └─ Else → 5pts
                     │
                     ▼
       Final: score = (d1 × 0.4) + (d2 × 0.3)
                      + (d3 × 0.2) + (d4 × 0.1)
                     │
                     ▼
       Generate insights:
       ├─ "Your budget adherence is excellent!"
       ├─ "Food & Dining exceeds budget by 50%"
       ├─ "Consider reducing Transport spending"
       └─ "Your savings rate improved 15% MoM"
                     │
                     ▼
       Return: HealthScoreData(
         score: 72,
         status: 'Good',
         insights: [...]
       )
                     │
                     ▼
       BlocBuilder emits state + rebuilds UI
       HealthScoreDial animates arc:
       0° → 129.6° (72/100 × 180°)
       Over 2 seconds
```

---

## 💰 **Budget Recommendation Flow**

```
User opens AddBudgetScreen
       │
       ▼
Display: "Get a smart suggestion?" button
       │
       ▼ (User taps)
Call: BudgetRecommendationService.suggest(
  monthlyIncome: 100000,
  allTransactions: [...]  // last 3 months
)
       │
       ├─ Extract transactions from last 3 months
       │  └─ Group by category
       │
       ├─ For each category:
       │  ├─ historicalAvg = sum(thisCategory) / 3
       │  │  Example: historicalAvg(Food) = 15000/3 = 5000/month
       │  │
       │  ├─ Compute ideal from 50/30/20:
       │  │  ├─ If category in Needs:
       │  │  │   └─ ideal = monthlyIncome × 50% / # needs cats
       │  │  │      (e.g., 50000 / 5 = 10000 per cat)
       │  │  │
       │  │  └─ If category in Wants:
       │  │      └─ ideal = monthlyIncome × 30% / # want cats
       │  │         (e.g., 30000 / 4 = 7500 per cat)
       │  │
       │  ├─ Blend: suggested = (historical × 0.6) + (ideal × 0.4)
       │  │  Example:
       │  │    suggested(Food) = (5000 × 0.6) + (10000 × 0.4)
       │  │                    = 3000 + 4000 = 7000
       │  │
       │  ├─ Round to nearest 500:
       │  │  └─ 7000 → 7000 ✓ (already multiple of 500)
       │  │
       │  └─ Check if overspending flag:
       │     └─ If historical_avg > suggested × 1.2
       │        → "Consider reducing this category"
       │
       └─ Return: Map<String, SuggestionData>
          ├─ Food: {suggested: 7000, flag: false, reason: ...}
          ├─ Transport: {suggested: 8500, flag: true, reason: "..."}
          └─ ...
                      │
                      ▼
        Show as cards on AddBudgetScreen:
        ┌─ Food & Dining          ┐
        │ Suggested: ₹7,000/month  │ [SET]
        │ Your recent avg: ₹5,000  │
        └────────────────────────┘
```

---

## 🔔 **Smart Notification Flow (Unread Tracking)**

```
User looks at DashboardScreen
       │
       ▼
_NotificationBell (StatefulWidget)
       │
       ├─ Listens to BudgetBloc & GoalBloc streams
       │
       ├─ Generate Current Alert Keys:
       │    1. Budgets over 100% → 'budget_over_Food_${month}_${year}'
       │    2. Goals at 100% → 'goal_done_${goalId}'
       │
       ├─ Check against Local Static State:
       │    static final Set<String> _seenAlerts;
       │
       ├─ Calculate unread count:
       │    currentAlertKeys.where((k) => !_seenAlerts.contains(k)).length
       │
       └─ Render UI:
          ├─ If unread > 0 → Show yellow badge with dynamic number
          └─ If unread == 0 → Standard bell icon
                     │
                     ▼ (User taps bell)
                     │
                     ├─ setState(() { _seenAlerts.addAll(currentAlertKeys); })
                     │    → Instantly marks items as read (badge disappears)
                     │
                     └─ showModalBottomSheet(...)
                          → Displays active alert messages
```

---

## 🔐 **Firebase Integration Pattern**

```
┌─────────────────────────────────────────────────────────────┐
│ AUTHENTICATION FLOW                                          │
└─────────────────────────────────────────────────────────────┘

User signs up with email + password
       │
       ▼
AuthRepository.signUp(email, password)
       │
       ▼
FirebaseAuth.createUserWithEmailAndPassword()
       │
       ├─ If success:
       │  └─ Returns: FirebaseUser with UID
       │
       └─ If failure:
          └─ Returns: FirebaseAuthException
                │
                ▼
               Bloc catches + emits Failure state
                │
                ▼
               Screen shows error dialog
                (e.g., "Email already in use")


┌─────────────────────────────────────────────────────────────┐
│ FIRESTORE STRUCTURE & SECURITY                              │
└─────────────────────────────────────────────────────────────┘

/users/{uid}
  ├─ email: "user@example.com"
  ├─ name: "John"
  ├─ monthlyIncome: 100000
  ├─ currency: "INR"
  ├─ createdAt: Timestamp
  │
  ├─ /transactions/{txnId1}
  │  ├─ title: "Groceries"
  │  ├─ amount: 500
  │  ├─ type: "expense"
  │  ├─ category: "Food & Dining"
  │  ├─ date: Timestamp
  │  ├─ isRecurring: false
  │  └─ createdAt: Timestamp
  │
  ├─ /budgets/{budgetId1}
  │  ├─ category: "Food & Dining"
  │  ├─ limitAmount: 10000
  │  ├─ month: 5
  │  ├─ year: 2026
  │  └─ createdAt: Timestamp
  │
  └─ /goals/{goalId1}
     ├─ title: "Vacation Fund"
     ├─ targetAmount: 50000
     ├─ currentAmount: 15000
     ├─ deadline: Timestamp(2026-12-31)
     └─ createdAt: Timestamp

SECURITY RULES:
┌──────────────────────────────────────────┐
│ match /users/{userId}/{document=**} {    │
│   allow read, write:                     │
│     if request.auth != null &&           │
│        request.auth.uid == userId;       │
│ }                                        │
└──────────────────────────────────────────┘

What this means:
✓ Authenticated users can only read/write their own `/users/{uid}/*`
✗ Cannot access other users' data
✗ Cannot write as different UID without re-auth
```

---

## 🔄 **Real-time Sync Pattern**

```
TransactionRepository.getTransactions()
       │
       ▼
FirebaseFirestore
  .collection('users/${uid}/transactions')
  .orderBy('date', descending: true)
  .snapshots()
       │
       ├─ Returns: Stream<QuerySnapshot>
       │
       ├─ On new data:
       │  ├─ Parse snapshot → List<TransactionModel>
       │  └─ Emit to repository consumer
       │
       ├─ On delete:
       │  ├─ Snapshot reflects deletion
       │  └─ Automatically re-emitted
       │
       └─ On add:
          ├─ Snapshot includes new doc
          └─ Automatically re-emitted
                │
                ▼
       TransactionBloc listens to this stream:
       
       Stream<TransactionState> transactionStream;
       
       @override
       Future<void> close() async {
         await transactionStream.cancel(); // Clean up
         return super.close();
       }
                │
                ▼
       On each stream event:
       Bloc emits: TransactionState(
         status: loaded,
         allTransactions: parsedList
       )
                │
                ▼
       BlocBuilder listens + rebuilds UI
       with fresh data


DIAGRAM: Data flow
┌──────────────┐
│ Firestore DB │
│ (cloud)      │
└──────┬───────┘
       │ snapshots()
       │ (real-time)
       ▼
┌──────────────────────────┐
│ Repository stream        │
│ .map(snapshot→models)    │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ TransactionBloc          │
│ .add(events)             │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ TransactionState         │
│ (emitted)                │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ BlocBuilder<Bloc, State> │
│ rebuilds UI with list    │
└──────────────────────────┘
```

---

## 🧪 **Test Architecture**

```
test/
├─ spending_health_score_test.dart (7 tests)
│  ├─ calculateScore_withAllBudgetsUnderLimit_returns100()
│  ├─ calculateScore_withOneCategoryOverspending_decaysPoints()
│  ├─ calculateScore_withNegativeSavings_returns0()
│  ├─ calculateScore_withHighCategoryDiverity_getsFullPoints()
│  └─ ...
│
├─ budget_recommendation_test.dart (6 tests)
│  ├─ suggestBudgets_blendsHistoricalAndIdeal()
│  ├─ suggestBudgets_roundsToNearestFive100()
│  ├─ suggestBudgets_flagsOverspendingCategories()
│  └─ ...
│
└─ widget_test.dart (13 tests)
   ├─ AmountDisplay renders correct sign
   ├─ CategoryBadge shows right color
   ├─ GlowButton loading state
   ├─ HealthScoreDial arc animation
   └─ ...

Why this approach?
✓ Services tested in isolation (pure Dart logic)
✓ Widgets tested with fake test harness
✓ No dependency on Firebase during tests
✓ Fast: all 26 tests run in <5 seconds
✓ Deterministic: no async/networking
```

---

## 🎯 **Key Takeaways**

| Concept | Implementation |
|---|---|
| **Clean Architecture** | Strict layer separation (UI → Bloc → Repository → Firebase) |
| **State Management** | 4 domain Blocs, events flow through layers |
| **Real-time Sync** | Firestore streams + manual event triggers (BudgetSpentUpdated) |
| **Custom Logic** | 2 services with pure Dart algorithms (testable, reusable) |
| **Security** | Firestore rules enforce user-scoped access |
| **Offline** | Local cache + Firestore persistence |
| **Testing** | Unit tests for logic, widget tests for UI |
| **Original Design** | Theme system, health score dimensions, recommendation blending |
