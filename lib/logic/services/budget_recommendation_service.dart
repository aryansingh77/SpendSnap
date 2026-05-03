import '../../data/models/transaction_model.dart';

/// Generates per-category budget recommendations using an adapted 50/30/20 rule,
/// calibrated against the user's actual 3-month historical spending patterns.
///
/// Algorithm:
///   1. Compute average monthly spend per category over last 3 months.
///   2. Apply 50/30/20 allocation to income → Needs / Wants / Savings.
///   3. Blend historical average with ideal allocation (60% history, 40% ideal)
///      so recommendations feel personal rather than textbook.
///   4. Flag categories where current spend exceeds recommended by > 20%.
class BudgetRecommendationService {
  const BudgetRecommendationService();

  static const _needsCategories = {
    'Food & Dining', 'Transport', 'Health', 'Bills & Utilities'
  };
  static const _wantsCategories = {
    'Shopping', 'Entertainment', 'Other'
  };

  static const Map<String, double> _idealSplit = {
    'Food & Dining': 0.15,
    'Transport': 0.10,
    'Health': 0.05,
    'Bills & Utilities': 0.15,
    'Shopping': 0.08,
    'Entertainment': 0.07,
    'Other': 0.10,
  };

  List<BudgetRecommendation> recommend({
    required double monthlyIncome,
    required List<TransactionModel> lastThreeMonthsTransactions,
  }) {
    if (monthlyIncome <= 0) return [];

    // Step 1: historical average per category
    final historicalAvg = _computeHistoricalAverage(lastThreeMonthsTransactions);

    // Step 2: 50/30/20 ideal amounts
    final idealAmounts = _computeIdealAmounts(monthlyIncome);

    // Step 3: blend (60% history, 40% ideal)
    final recommendations = <BudgetRecommendation>[];
    final categories = <String>{
      ..._needsCategories,
      ..._wantsCategories,
    };

    for (final cat in categories) {
      final historical = historicalAvg[cat] ?? (idealAmounts[cat]! * 0.8);
      final ideal = idealAmounts[cat]!;
      final blended = (historical * 0.6) + (ideal * 0.4);

      // Round to nearest 500 for cleaner UX
      final rounded = (blended / 500).round() * 500.0;
      final suggested = rounded < 500 ? 500.0 : rounded;

      // Step 4: flag overspending
      final currentAvg = historicalAvg[cat] ?? 0;
      final isOverspending = currentAvg > suggested * 1.2;

      recommendations.add(BudgetRecommendation(
        category: cat,
        suggestedAmount: suggested,
        historicalAverage: currentAvg,
        type: _needsCategories.contains(cat)
            ? BudgetType.need
            : BudgetType.want,
        isOverspending: isOverspending,
        overspendPercent: currentAvg > 0 && suggested > 0
            ? ((currentAvg - suggested) / suggested * 100).clamp(-100.0, 500.0)
            : 0,
      ));
    }

    recommendations.sort((a, b) =>
        b.overspendPercent.compareTo(a.overspendPercent));

    return recommendations;
  }

  Map<String, double> _computeHistoricalAverage(
      List<TransactionModel> transactions) {
    final monthlyTotals = <String, Map<int, double>>{};
    for (final t in transactions) {
      if (t.type != TransactionType.expense) continue;
      final monthKey = t.date.year * 12 + t.date.month;
      monthlyTotals[t.category] ??= {};
      monthlyTotals[t.category]![monthKey] =
          (monthlyTotals[t.category]![monthKey] ?? 0) + t.amount;
    }

    final averages = <String, double>{};
    for (final entry in monthlyTotals.entries) {
      final months = entry.value.values;
      averages[entry.key] = months.reduce((a, b) => a + b) / months.length;
    }
    return averages;
  }

  Map<String, double> _computeIdealAmounts(double income) {
    return _idealSplit.map((cat, pct) => MapEntry(cat, income * pct));
  }
}

enum BudgetType { need, want }

class BudgetRecommendation {
  const BudgetRecommendation({
    required this.category,
    required this.suggestedAmount,
    required this.historicalAverage,
    required this.type,
    required this.isOverspending,
    required this.overspendPercent,
  });

  final String category;
  final double suggestedAmount;
  final double historicalAverage;
  final BudgetType type;
  final bool isOverspending;
  final double overspendPercent;
}
