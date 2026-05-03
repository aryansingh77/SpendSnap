# SpendSnap — Code Reference Guide for Viva

Quick code snippets to explain during viva. Read these before the exam!

---

## 🔑 **Key Code Snippets**

### **1. Bloc Pattern: TransactionBloc**

**File:** `lib/logic/blocs/transaction/transaction_bloc.dart`

```dart
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository repository;
  final BudgetBloc budgetBloc;
  
  StreamSubscription? _subscription;

  TransactionBloc({required this.repository, required this.budgetBloc})
      : super(const TransactionState()) {
    
    // Event handlers
    on<TransactionsFetched>(_onTransactionsFetched);
    on<TransactionAdded>(_onTransactionAdded);
    on<TransactionFilterChanged>(_onFilterChanged);
  }

  // Fetch all transactions (streams real-time)
  Future<void> _onTransactionsFetched(
      TransactionsFetched event, Emitter<TransactionState> emit) async {
    emit(state.copyWith(status: TransactionStatus.loading));
    
    try {
      _subscription = repository.getTransactions(event.userId).listen(
        (transactions) {
          emit(state.copyWith(
            status: TransactionStatus.loaded,
            allTransactions: transactions,
          ));
        },
        onError: (e) => emit(state.copyWith(
          status: TransactionStatus.error,
          errorMessage: e.toString(),
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        status: TransactionStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // Add transaction + trigger budget update
  Future<void> _onTransactionAdded(
      TransactionAdded event, Emitter<TransactionState> emit) async {
    emit(state.copyWith(status: TransactionStatus.loading));
    
    try {
      await repository.addTransaction(event.model);
      
      // Trigger budget recalculation
      budgetBloc.add(BudgetSpentUpdated(userId: event.model.userId));
      
    } catch (e) {
      emit(state.copyWith(
        status: TransactionStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // Filter transactions (client-side)
  Future<void> _onFilterChanged(
      TransactionFilterChanged event, Emitter<TransactionState> emit) async {
    emit(state.copyWith(
      filterCategory: event.category ?? '',
      filterType: event.type,
    ));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
```

**Key Points:**
- ✅ Each event handler is isolated (`on<Event>` syntax)
- ✅ Streams are cleaned up in `close()`
- ✅ `TransactionAdded` triggers `BudgetSpentUpdated` in other bloc
- ✅ Filter happens client-side (no Firestore query)

---

### **2. State Pattern: TransactionState**

**File:** `lib/logic/blocs/transaction/transaction_state.dart`

```dart
class TransactionState extends Equatable {
  static const Object _unset = Object();

  const TransactionState({
    this.status = TransactionStatus.initial,
    this.allTransactions = const [],
    this.filterCategory,
    this.filterType,
    this.errorMessage,
  });

  final TransactionStatus status;
  final List<TransactionModel> allTransactions;
  final String? filterCategory;
  final TransactionType? filterType;
  final String? errorMessage;

  // Filtered list (computed, not stored)
  List<TransactionModel> get filtered {
    var list = allTransactions;
    if (filterCategory != null && filterCategory!.isNotEmpty) {
      list = list.where((t) => t.category == filterCategory).toList();
    }
    if (filterType != null) {
      list = list.where((t) => t.type == filterType).toList();
    }
    return list;
  }

  // Computed properties
  double get totalIncome =>
      allTransactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (s, t) => s + t.amount);

  double get totalExpense =>
      allTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (s, t) => s + t.amount);

  // IMPORTANT: copyWith with sentinel pattern
  TransactionState copyWith({
    TransactionStatus? status,
    List<TransactionModel>? allTransactions,
    Object? filterCategory = _unset, // Sentinel to distinguish null vs no-change
    Object? filterType = _unset,
    String? errorMessage,
    bool clearFilter = false,
  }) =>
      TransactionState(
        status: status ?? this.status,
        allTransactions: allTransactions ?? this.allTransactions,
        filterCategory: clearFilter
            ? null
            : identical(filterCategory, _unset)
                ? this.filterCategory
                : filterCategory as String?,
        filterType: clearFilter
            ? null
            : identical(filterType, _unset)
                ? this.filterType
                : filterType as TransactionType?,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props =>
      [status, allTransactions, filterCategory, filterType, errorMessage];
}
```

**Why Sentinel Pattern?**
```dart
// Without sentinel:
copyWith(filterCategory: null)  // Does this mean "clear" or "no change"?

// With sentinel:
copyWith(filterCategory: null)        // ❌ Stays same (filterCategory = _unset)
copyWith(filterCategory: 'Food')      // ✅ Sets to 'Food'
copyWith(clearFilter: true)           // ✅ Clears both filters
```

---

### **3. Custom Service: SpendingHealthScore**

**File:** `lib/logic/services/spending_health_score_service.dart`

```dart
class SpendingHealthScoreService {
  // Calculate 0-100 health score
  static HealthScoreData calculate({
    required List<TransactionModel> allTransactions,
    required List<BudgetModel> allBudgets,
    required double monthlyIncome,
  }) {
    // Dimension 1: Budget Adherence (40 max)
    final budgetAdherence = _calculateBudgetAdherence(allTransactions, allBudgets);

    // Dimension 2: Savings Rate (30 max)
    final savingsRate = _calculateSavingsRate(allTransactions, monthlyIncome);

    // Dimension 3: Spending Trend (20 max)
    final spendingTrend = _calculateSpendingTrend(allTransactions);

    // Dimension 4: Category Diversity (10 max)
    final categoryDiversity = _calculateCategoryDiversity(allTransactions);

    // Weighted sum
    final score = (budgetAdherence * 0.4) +
                  (savingsRate * 0.3) +
                  (spendingTrend * 0.2) +
                  (categoryDiversity * 0.1);

    // Generate insights
    final insights = _generateInsights(
      budgetAdherence, savingsRate, spendingTrend, categoryDiversity,
      allTransactions, allBudgets
    );

    return HealthScoreData(
      score: score.toInt(),
      status: score >= 70 ? 'Good' : score >= 40 ? 'Fair' : 'Needs Improvement',
      insights: insights,
    );
  }

  static double _calculateBudgetAdherence(
    List<TransactionModel> transactions,
    List<BudgetModel> budgets,
  ) {
    if (budgets.isEmpty) return 40; // No budgets = full points

    double totalPoints = 0;
    for (final budget in budgets) {
      final categoryExpense = transactions
          .where((t) => t.category == budget.category && t.isExpense)
          .fold(0.0, (sum, t) => sum + t.amount);

      final percentageOfLimit = categoryExpense / budget.limitAmount;
      
      if (percentageOfLimit <= 1.0) {
        totalPoints += 40; // Full points if under limit
      } else {
        // Decay: lose 4 pts for each 10% over
        final overage = percentageOfLimit - 1.0;
        final penalty = (overage * 10 * 4).clamp(0, 40);
        totalPoints += max(0, 40 - penalty);
      }
    }

    return totalPoints / budgets.length;
  }

  static double _calculateSavingsRate(
    List<TransactionModel> transactions,
    double monthlyIncome,
  ) {
    if (monthlyIncome <= 0) return 0;

    final totalExpense = transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final savingsRate = (monthlyIncome - totalExpense) / monthlyIncome;

    if (savingsRate >= 0.30) return 30;
    if (savingsRate >= 0.20) return 22;
    if (savingsRate >= 0.10) return 14;
    return 0; // Negative savings
  }

  static double _calculateSpendingTrend(
    List<TransactionModel> transactions,
  ) {
    final now = DateTime.now();
    
    // Current month
    final currentMonth = transactions
        .where((t) =>
            t.date.month == now.month &&
            t.date.year == now.year &&
            t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Previous month
    final previousDate = now.subtract(Duration(days: now.day));
    final previousMonth = transactions
        .where((t) =>
            t.date.month == previousDate.month &&
            t.date.year == previousDate.year &&
            t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);

    if (previousMonth == 0) return 10; // First month data

    final changePercent = (currentMonth - previousMonth) / previousMonth;

    if (changePercent <= -0.10) return 20; // Reduced spending ✓
    if (changePercent <= 0) return 10;
    if (changePercent <= 0.10) return 5;
    return 2; // Increased >10% ✗
  }

  static double _calculateCategoryDiversity(
    List<TransactionModel> transactions,
  ) {
    if (transactions.isEmpty) return 10;

    final expenses = transactions.where((t) => t.isExpense).toList();
    if (expenses.isEmpty) return 10;

    final totalExpense = expenses.fold(0.0, (sum, t) => sum + t.amount);
    
    final categoryTotals = <String, double>{};
    for (final t in expenses) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }

    final topCategoryPercent =
        (categoryTotals.values.fold(0.0, (a, b) => max(a, b))) / totalExpense;

    // If one category > 70% → bad diversity
    if (topCategoryPercent > 0.70) return 1;
    
    // If top 3 categories < 80% → good diversity
    final top3 = categoryTotals.values.toList()
      ..sort((a, b) => b.compareTo(a));
    final top3Percent = top3.take(3).fold(0.0, (a, b) => a + b) / totalExpense;
    
    if (top3Percent < 0.80) return 10;
    
    return 5; // Medium diversity
  }

  static List<String> _generateInsights(
    double budgetAdherence,
    double savingsRate,
    double spendingTrend,
    double categoryDiversity,
    List<TransactionModel> transactions,
    List<BudgetModel> budgets,
  ) {
    final insights = <String>[];

    // Budget insight
    if (budgetAdherence >= 30) {
      insights.add("✓ You're staying within your budgets!");
    } else {
      insights.add("⚠ Several budgets are over limit. Review your spending.");
    }

    // Savings insight
    if (savingsRate >= 20) {
      insights.add("✓ Great savings rate! Keep it up.");
    } else if (savingsRate >= 10) {
      insights.add("⚠ Consider saving more for emergencies.");
    }

    // Trend insight
    if (spendingTrend >= 20) {
      insights.add("✓ Your spending decreased MoM. Well done!");
    } else if (spendingTrend <= 2) {
      insights.add("⚠ Spending increased significantly. Review expenses.");
    }

    // Diversity insight
    if (categoryDiversity >= 8) {
      insights.add("✓ Your spending is well-distributed across categories.");
    } else if (categoryDiversity <= 2) {
      insights.add("⚠ Over-reliant on one category. Diversify spending.");
    }

    return insights;
  }
}
```

**Key Points:**
- ✅ Pure Dart logic (no dependencies, easy to test)
- ✅ 4 independent dimensions with custom weights
- ✅ Computed from transactions (derived, not stored)
- ✅ Generates human-readable insights

---

### **4. Repository Pattern: TransactionRepository**

**File:** `lib/data/repositories/transaction_repository.dart`

```dart
class TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of transactions (real-time sync)
  Stream<List<TransactionModel>> getTransactions(String userId) {
    return _firestore
        .collection('users/$userId/transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TransactionModel.fromJson({
              ...doc.data(),
              'id': doc.id,
            })).toList());
  }

  // Add transaction
  Future<TransactionModel> addTransaction(TransactionModel model) async {
    final docRef = await _firestore
        .collection('users/${model.userId}/transactions')
        .add(model.toJson());

    return model.copyWith(id: docRef.id);
  }

  // Update transaction
  Future<void> updateTransaction(TransactionModel model) async {
    await _firestore
        .collection('users/${model.userId}/transactions')
        .doc(model.id)
        .update(model.toJson());
  }

  // Delete transaction
  Future<void> deleteTransaction(String userId, String txnId) async {
    await _firestore
        .collection('users/$userId/transactions')
        .doc(txnId)
        .delete();
  }
}
```

**Why This Pattern?**
- ✅ Bloc doesn't touch Firebase directly
- ✅ Easy to inject mock repository in tests
- ✅ Data layer is replaceable (could use local DB instead)
- ✅ Repositories return typed models (not raw JSON)

---

### **5. Custom Widget: HealthScoreDial**

**File:** `lib/core/widgets/health_score_dial.dart`

```dart
class HealthScoreDial extends StatefulWidget {
  final int score; // 0-100
  final String status; // 'Good', 'Fair', etc.

  const HealthScoreDial({
    required this.score,
    required this.status,
  });

  @override
  State<HealthScoreDial> createState() => _HealthScoreDialState();
}

class _HealthScoreDialState extends State<HealthScoreDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Animate from 0 to score
    _animation = Tween<double>(begin: 0, end: widget.score.toDouble())
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            SizedBox(
              width: 200,
              height: 120,
              child: CustomPaint(
                painter: DialPainter(
                  score: _animation.value.toInt(),
                  maxScore: 100,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${_animation.value.toInt()}/100',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.status,
              style: TextStyle(
                fontSize: 16,
                color: _getStatusColor(widget.score),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(int score) {
    if (score >= 70) return AppColors.income;
    if (score >= 40) return AppColors.secondary;
    return AppColors.expense;
  }
}

class DialPainter extends CustomPainter {
  final int score;
  final int maxScore;

  DialPainter({required this.score, required this.maxScore});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;

    // Background arc (gray)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi, // Start at 180° (left)
      pi, // Sweep 180° (to 0° / right)
      false,
      Paint()
        ..color = Colors.grey[300]!
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );

    // Score arc (colored)
    final scoreAngle = pi * (score / maxScore); // Convert score to radians
    final color = score >= 70
        ? AppColors.income
        : score >= 40
            ? AppColors.secondary
            : AppColors.expense;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi, // Start at 180°
      scoreAngle, // Sweep by score %
      false,
      Paint()
        ..color = color
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(DialPainter oldDelegate) =>
      oldDelegate.score != score;
}
```

**Why CustomPainter?**
- ✅ Can't draw half-arc with built-in widgets
- ✅ `strokeCap: round` smooths arc endpoints
- ✅ Animated via `AnimationController` + `_animation.value`
- ✅ Color changes based on score threshold

---

### **6. Firestore Security Rules**

**File:** `firestore.rules`

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User-scoped access only
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && 
                           request.auth.uid == userId;
    }
  }
}
```

**What This Protects:**
```
✓ User A can only read/write /users/A/*
✗ User A cannot read /users/B/transactions
✗ Unauthenticated users get 403 Forbidden
✗ Cannot forge UID (must match auth token)
```

---

### **7. Form Validation Utility**

**File:** `lib/core/utils/validators.dart`

```dart
class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Amount validation
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    try {
      final amount = double.parse(value);
      if (amount <= 0) {
        return 'Amount must be greater than 0';
      }
    } catch (e) {
      return 'Enter a valid number';
    }
    return null;
  }

  // Title validation
  static String? validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Title is required';
    }
    if (value.length < 2) {
      return 'Title must be at least 2 characters';
    }
    return null;
  }
}
```

---

### **8. BudgetRecommendationService**

**File:** `lib/logic/services/budget_recommendation_service.dart`

```dart
class BudgetRecommendationService {
  static Map<String, BudgetSuggestion> suggest({
    required double monthlyIncome,
    required List<TransactionModel> transactions,
  }) {
    final suggestions = <String, BudgetSuggestion>{};

    // Calculate 50/30/20 amounts
    final needs50 = monthlyIncome * 0.50;
    final wants30 = monthlyIncome * 0.30;
    // savings20 = monthlyIncome * 0.20 (not for budget categories)

    for (final category in AppConstants.allCategories) {
      // Historical average (last 3 months)
      final historicalAvg = _getHistoricalAverage(transactions, category);

      // Ideal amount from 50/30/20
      final idealAmount = _getCategoryIdeal(category, needs50, wants30);

      // Blend: 60% historical + 40% ideal
      final suggested = (historicalAvg * 0.6) + (idealAmount * 0.4);

      // Round to nearest ₹500
      final rounded = (suggested / 500).round() * 500.0;

      // Check if overspending
      final isOverspending = historicalAvg > (rounded * 1.2);

      suggestions[category] = BudgetSuggestion(
        suggestedAmount: rounded,
        historicalAverage: historicalAvg,
        isOverspending: isOverspending,
      );
    }

    return suggestions;
  }

  static double _getHistoricalAverage(
    List<TransactionModel> transactions,
    String category,
  ) {
    final categoryTransactions = transactions
        .where((t) => t.category == category && t.isExpense)
        .toList();

    if (categoryTransactions.isEmpty) return 0;

    // Sum of last 3 months
    final now = DateTime.now();
    final threeMonthsAgo = now.subtract(const Duration(days: 90));

    final last3Months = categoryTransactions
        .where((t) => t.date.isAfter(threeMonthsAgo))
        .fold(0.0, (sum, t) => sum + t.amount);

    // Average per month
    return last3Months / 3;
  }

  static double _getCategoryIdeal(
    String category,
    double needs50,
    double wants30,
  ) {
    // Classify category as Needs or Wants
    const needsCategories = [
      'Groceries',
      'Transport',
      'Utilities',
      'Insurance',
      'Healthcare',
    ];

    if (needsCategories.contains(category)) {
      return needs50 / needsCategories.length;
    } else {
      return wants30 / 4; // Approximate count of wants categories
    }
  }
}

class BudgetSuggestion {
  final double suggestedAmount;
  final double historicalAverage;
  final bool isOverspending;

  BudgetSuggestion({
    required this.suggestedAmount,
    required this.historicalAverage,
    required this.isOverspending,
  });
}
```

---

### **5. Bank Sync Service: BankSyncService**

**File:** `lib/logic/services/bank_sync_service.dart`

```dart
class BankSyncService {
  // Sync with bank API (mock)
  static Future<List<TransactionModel>> syncWithBank(
    String userId, 
    List<BankTransaction> bankTransactions,
  ) async {
    final syncedTransactions = <TransactionModel>[];

    for (final bankTxn in bankTransactions) {
      // 1. Map bank fields to transaction model
      final txn = TransactionModel(
        userId: userId,
        amount: bankTxn.amount,
        date: bankTxn.date,
        category: _mapCategory(bankTxn.category),
        type: bankTxn.isExpense ? TransactionType.expense : TransactionType.income,
        // ...other fields
      );

      // 2. Auto-categorize based on description keywords
      txn.category = _autoCategorize(txn.description);

      syncedTransactions.add(txn);
    }

    return syncedTransactions;
  }

  static String _mapCategory(String bankCategory) {
    // Simplified mapping logic
    const categoryMap = {
      'Food & Dining': 'Food',
      'Groceries': 'Groceries',
      'Salary': 'Income',
      // ...more mappings
    };

    return categoryMap[bankCategory] ?? 'Other';
  }

  static String _autoCategorize(String description) {
    // Basic keyword matching (expandable)
    if (description.contains('Uber') || description.contains('Lyft')) {
      return 'Transport';
    }
    if (description.contains('Starbucks') || description.contains('Dunkin')) {
      return 'Food';
    }
    return 'Other';
  }
}
```

**Key Points:**
- ✅ Mock service for demo (replace with real API)
- ✅ Maps bank categories to SpendSnap categories
- ✅ Auto-categorizes transactions using simple keywords
- ✅ Easily expandable for more categories or rules

---

## 📋 **Common Viva Questions & Code Answers**

### **Q: How do you prevent data leaks in Firestore?**
**A: Security rules + auth validation**
```dart
// In firestore.rules:
match /users/{userId}/{document=**} {
  allow read, write: if request.auth.uid == userId;
}

// In Dart: Auth layer checks user before any query
final userId = FirebaseAuth.instance.currentUser?.uid;
if (userId == null) return;
```

---

### **Q: How do budgets update when transactions change?**
**A: Event-driven update via BudgetSpentUpdated**
```dart
// In TransactionBloc._onTransactionAdded:
await repository.addTransaction(event.model);
budgetBloc.add(BudgetSpentUpdated(userId: event.model.userId));

// In BudgetBloc._onBudgetSpentUpdated:
// Recalculates spentAmount by summing matching transactions
// Re-emits budgets with updated progress bars
```

---

### **Q: Why is `copyWith` using a sentinel instead of `??`?**
**A: To distinguish "clear filter" from "no change"**
```dart
// Without sentinel:
copyWith(filterCategory: null) // Does this mean "clear" or "no value"?

// With sentinel:
copyWith(filterCategory: null)    // ❌ Keeps old value
copyWith(clearFilter: true)       // ✅ Sets to null
copyWith(filterCategory: 'Food')  // ✅ Sets to 'Food'
```

---

### **Q: How are tests structured?**
**A: 3 layers - unit, widget, and integration (mock Firebase)**
```dart
// Unit test (service logic)
test('calculateScore with all budgets under limit returns 100', () {
  final score = SpendingHealthScoreService.calculate(
    allTransactions: [],
    allBudgets: [BudgetModel(..., limitAmount: 10000)],
    monthlyIncome: 100000,
  );
  expect(score.score, 40); // Only budget dimension
});

// Widget test (UI)
testWidgets('AmountDisplay shows + for income', (tester) async {
  await tester.pumpWidget(AmountDisplay(amount: 1000, isExpense: false));
  expect(find.text('+₹1000'), findsOneWidget);
});
```

---

### **Q: How does real-time sync work?**
**A: Firestore streams + BlocBuilder**
```dart
// Repository returns stream
Stream<List<TransactionModel>> getTransactions(String userId) {
  return _firestore
    .collection('users/$userId/transactions')
    .snapshots()
    .map((snap) => snap.docs.map(...).toList());
}

// Bloc listens via on<Event> listener
_subscription = repository.getTransactions(userId).listen(
  (transactions) => emit(state.copyWith(allTransactions: transactions)),
);

// UI rebuilds automatically via BlocBuilder
BlocBuilder<TransactionBloc, TransactionState>(
  builder: (ctx, state) => ListView(
    children: state.filtered.map((t) => TxnTile(t)).toList(),
  ),
)
```

---

## 🎯 **Final Takeaway**

Your project demonstrates:
1. ✅ **Clean Architecture** — Well-separated layers
2. ✅ **Custom Logic** — Health score & recommendations not template code
3. ✅ **Firebase Integration** — Auth + Firestore + security
4. ✅ **State Management** — BLoC with proper event flow
5. ✅ **Testing** — 26 tests covering edge cases
6. ✅ **UI Customization** — 7+ custom widgets + theme system
7. ✅ **Real-time Sync** — Streams + manual event triggers

**During Viva:**
- Explain the layer separation clearly
- Show how health score is calculated (not copy-paste)
- Demonstrate filter bug fix using sentinel pattern
- Explain real-time sync via streams
- Mention test coverage and edge cases
