import 'package:flutter_test/flutter_test.dart';
import 'package:spendsnap/data/models/transaction_model.dart';
import 'package:spendsnap/logic/services/budget_recommendation_service.dart';

void main() {
  const service = BudgetRecommendationService();

  TransactionModel makeExpense(double amount, String category,
          {int daysAgo = 10}) =>
      TransactionModel(
        id: 'e-$amount-$category',
        userId: 'u1',
        title: 'Expense',
        amount: amount,
        type: TransactionType.expense,
        category: category,
        date: DateTime.now().subtract(Duration(days: daysAgo)),
      );

  group('BudgetRecommendationService', () {
    test('returns empty list when income is zero', () {
      final recs = service.recommend(
        monthlyIncome: 0,
        lastThreeMonthsTransactions: [],
      );
      expect(recs, isEmpty);
    });

    test('returns recommendations for all standard categories', () {
      final recs = service.recommend(
        monthlyIncome: 60000,
        lastThreeMonthsTransactions: [],
      );
      expect(recs.length, greaterThanOrEqualTo(6));
    });

    test('suggested amounts are multiples of 500', () {
      final recs = service.recommend(
        monthlyIncome: 80000,
        lastThreeMonthsTransactions: [],
      );
      for (final r in recs) {
        expect(r.suggestedAmount % 500, equals(0));
      }
    });

    test('flags isOverspending when historical avg exceeds suggested by >20%', () {
      final txns = [
        // 3 months of heavy food spending: avg 25000/month
        makeExpense(25000, 'Food & Dining', daysAgo: 5),
        makeExpense(25000, 'Food & Dining', daysAgo: 35),
        makeExpense(25000, 'Food & Dining', daysAgo: 65),
      ];

      final recs = service.recommend(
        monthlyIncome: 60000,
        lastThreeMonthsTransactions: txns,
      );

      final foodRec = recs.firstWhere((r) => r.category == 'Food & Dining');
      // ideal = 60000 * 0.15 = 9000; historical avg = 25000 — clearly over
      expect(foodRec.isOverspending, isTrue);
    });

    test('classifies needs and wants correctly', () {
      final recs = service.recommend(
        monthlyIncome: 50000,
        lastThreeMonthsTransactions: [],
      );

      final needs = recs.where((r) => r.type == BudgetType.need).toList();
      final wants = recs.where((r) => r.type == BudgetType.want).toList();

      expect(needs.map((r) => r.category),
          containsAll(['Food & Dining', 'Transport', 'Health', 'Bills & Utilities']));
      expect(wants.map((r) => r.category),
          containsAll(['Shopping', 'Entertainment']));
    });

    test('suggested amounts scale proportionally with income', () {
      final recs30k = service.recommend(
        monthlyIncome: 30000,
        lastThreeMonthsTransactions: [],
      );
      final recs60k = service.recommend(
        monthlyIncome: 60000,
        lastThreeMonthsTransactions: [],
      );

      final food30 = recs30k.firstWhere((r) => r.category == 'Food & Dining');
      final food60 = recs60k.firstWhere((r) => r.category == 'Food & Dining');

      expect(food60.suggestedAmount, greaterThan(food30.suggestedAmount));
    });
  });
}
