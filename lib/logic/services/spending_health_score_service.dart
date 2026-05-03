import '../../data/models/budget_model.dart';
import '../../data/models/transaction_model.dart';

/// Computes a Spending Health Score (0–100) from four rule-based dimensions.
///
/// Dimensions and max points:
///   BudgetAdherence  — 40 pts : how well user stays within set budgets
///   SavingsRate      — 30 pts : (income − expenses) / income
///   SpendingTrend    — 20 pts : month-over-month expense direction
///   CategoryDiversity — 10 pts : entropy of spend across categories
///
/// This is intentionally rule-based (not ML) so it remains explainable
/// and testable without external model calls.
class SpendingHealthScoreService {
  const SpendingHealthScoreService();

  SpendingHealthResult compute({
    required List<TransactionModel> currentMonthTransactions,
    required List<TransactionModel> lastMonthTransactions,
    required List<BudgetModel> budgets,
  }) {
    final budgetScore = _budgetAdherenceScore(budgets);
    final savingsScore = _savingsRateScore(currentMonthTransactions);
    final trendScore = _trendScore(
        currentMonthTransactions, lastMonthTransactions);
    final diversityScore = _diversityScore(currentMonthTransactions);

    final total = budgetScore + savingsScore + trendScore + diversityScore;

    return SpendingHealthResult(
      total: total.round().clamp(0, 100),
      budgetScore: budgetScore.round(),
      savingsScore: savingsScore.round(),
      trendScore: trendScore.round(),
      diversityScore: diversityScore.round(),
      insights: _buildInsights(
        budgetScore: budgetScore,
        savingsScore: savingsScore,
        trendScore: trendScore,
        diversityScore: diversityScore,
        budgets: budgets,
        transactions: currentMonthTransactions,
      ),
    );
  }

  // ── Dimension 1: Budget Adherence (0–40) ──────────────────────────────────
  // For each budget: full score if spent <= limit, decaying penalty otherwise.
  double _budgetAdherenceScore(List<BudgetModel> budgets) {
    if (budgets.isEmpty) return 20; // neutral when no budgets set
    double score = 0;
    for (final b in budgets) {
      if (b.limitAmount <= 0) continue;
      final ratio = b.spentAmount / b.limitAmount;
      if (ratio <= 1.0) {
        score += 40 / budgets.length;
      } else {
        // Every 10% over budget removes 5 points (per budget slot)
        final overage = (ratio - 1.0) * 10;
        final penalty = (overage * 5).clamp(0.0, 40 / budgets.length);
        score += (40 / budgets.length - penalty).clamp(0.0, 40.0);
      }
    }
    return score.clamp(0.0, 40.0);
  }

  // ── Dimension 2: Savings Rate (0–30) ──────────────────────────────────────
  // Target: save at least 20% of income (30/20 rule).
  double _savingsRateScore(List<TransactionModel> txns) {
    final income = txns
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final expense = txns
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);

    if (income <= 0) return 15; // neutral
    final savingsRate = (income - expense) / income;

    if (savingsRate >= 0.3) return 30.0;          // >= 30% saved: perfect
    if (savingsRate >= 0.2) return 22.0;          // >= 20% saved: good
    if (savingsRate >= 0.1) return 14.0;          // >= 10%: fair
    if (savingsRate >= 0) return 6.0;             // positive but low
    return 0.0;                                    // spending more than earning
  }

  // ── Dimension 3: Spending Trend (0–20) ────────────────────────────────────
  // Rewards month-over-month expense reduction.
  double _trendScore(
      List<TransactionModel> current, List<TransactionModel> last) {
    final curExpense = current
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    final lastExpense = last
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);

    if (lastExpense <= 0) return 10; // neutral for new users
    final change = (lastExpense - curExpense) / lastExpense;

    if (change >= 0.1) return 20.0;   // 10%+ reduction: excellent
    if (change >= 0) return 14.0;     // any reduction: good
    if (change >= -0.1) return 8.0;   // up to 10% increase: fair
    return 2.0;                        // >10% increase: poor
  }

  // ── Dimension 4: Category Diversity (0–10) ────────────────────────────────
  // Penalises over-concentration: if >60% of spend is in one category, score drops.
  double _diversityScore(List<TransactionModel> txns) {
    final expenses = txns.where((t) => t.type == TransactionType.expense);
    final total = expenses.fold(0.0, (s, t) => s + t.amount);
    if (total <= 0) return 5; // neutral

    final byCategory = <String, double>{};
    for (final t in expenses) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
    }

    final maxShare =
        byCategory.values.reduce((a, b) => a > b ? a : b) / total;

    if (maxShare <= 0.40) return 10.0;  // well spread
    if (maxShare <= 0.55) return 7.0;
    if (maxShare <= 0.70) return 4.0;
    return 1.0;                          // one category dominates
  }

  // ── Insight generator ─────────────────────────────────────────────────────
  List<String> _buildInsights({
    required double budgetScore,
    required double savingsScore,
    required double trendScore,
    required double diversityScore,
    required List<BudgetModel> budgets,
    required List<TransactionModel> transactions,
  }) {
    final insights = <String>[];

    final overBudget = budgets.where((b) => b.isOverBudget).toList();
    if (overBudget.isNotEmpty) {
      insights.add(
          'You exceeded your ${overBudget.first.category} budget this month.');
    }
    if (savingsScore < 14) {
      insights.add('Try to save at least 20% of your monthly income.');
    }
    if (trendScore >= 20) {
      insights.add('Great job — your spending is down from last month!');
    } else if (trendScore <= 4) {
      insights.add('Your spending increased significantly this month.');
    }
    if (diversityScore <= 4) {
      insights.add('Most of your spending is concentrated in one category.');
    }
    if (budgetScore >= 36 && savingsScore >= 22 && trendScore >= 14) {
      insights.add('Excellent financial discipline this month!');
    }
    return insights;
  }
}

class SpendingHealthResult {
  const SpendingHealthResult({
    required this.total,
    required this.budgetScore,
    required this.savingsScore,
    required this.trendScore,
    required this.diversityScore,
    required this.insights,
  });

  final int total;
  final int budgetScore;
  final int savingsScore;
  final int trendScore;
  final int diversityScore;
  final List<String> insights;
}
