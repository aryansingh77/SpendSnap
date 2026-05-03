import 'package:flutter_test/flutter_test.dart';
import 'package:spendsnap/data/models/budget_model.dart';
import 'package:spendsnap/data/models/transaction_model.dart';
import 'package:spendsnap/logic/services/spending_health_score_service.dart';

void main() {
  const service = SpendingHealthScoreService();

  TransactionModel makeIncome(double amount, {int monthOffset = 0}) =>
      TransactionModel(
        id: 'i-$amount',
        userId: 'u1',
        title: 'Salary',
        amount: amount,
        type: TransactionType.income,
        category: 'Income',
        date: DateTime.now().subtract(Duration(days: monthOffset * 30)),
      );

  TransactionModel makeExpense(double amount, String category,
          {int monthOffset = 0}) =>
      TransactionModel(
        id: 'e-$amount-$category',
        userId: 'u1',
        title: 'Expense',
        amount: amount,
        type: TransactionType.expense,
        category: category,
        date: DateTime.now().subtract(Duration(days: monthOffset * 30)),
      );

  BudgetModel makeBudget(String cat, double limit, double spent) => BudgetModel(
        id: 'b-$cat',
        userId: 'u1',
        category: cat,
        limitAmount: limit,
        month: DateTime.now().month,
        year: DateTime.now().year,
        spentAmount: spent,
      );

  group('SpendingHealthScoreService', () {
    test('returns high score for healthy finances', () {
      final current = [
        makeIncome(100000),
        makeExpense(15000, 'Food & Dining'),
        makeExpense(10000, 'Transport'),
        makeExpense(5000, 'Entertainment'),
        makeExpense(5000, 'Health'),
      ];
      final last = [
        makeIncome(100000),
        makeExpense(40000, 'Food & Dining'),
      ];
      final budgets = [
        makeBudget('Food & Dining', 20000, 15000),
        makeBudget('Transport', 12000, 10000),
      ];

      final result = service.compute(
        currentMonthTransactions: current,
        lastMonthTransactions: last,
        budgets: budgets,
      );

      expect(result.total, greaterThanOrEqualTo(70));
      expect(result.budgetScore, greaterThan(0));
      expect(result.savingsScore, greaterThan(0));
      expect(result.trendScore, greaterThan(0));
    });

    test('penalises over-budget spending', () {
      final current = [makeIncome(50000), makeExpense(30000, 'Food & Dining')];
      final budgets = [makeBudget('Food & Dining', 10000, 30000)];

      final result = service.compute(
        currentMonthTransactions: current,
        lastMonthTransactions: [],
        budgets: budgets,
      );

      expect(result.budgetScore, lessThan(20));
    });

    test('returns 0 savings score when spending exceeds income', () {
      final current = [
        makeIncome(20000),
        makeExpense(25000, 'Shopping'),
      ];

      final result = service.compute(
        currentMonthTransactions: current,
        lastMonthTransactions: [],
        budgets: [],
      );

      expect(result.savingsScore, equals(0));
    });

    test('rewards spending reduction vs last month', () {
      final current = [makeExpense(10000, 'Food & Dining')];
      final last = [makeExpense(20000, 'Food & Dining')];

      final result = service.compute(
        currentMonthTransactions: current,
        lastMonthTransactions: last,
        budgets: [],
      );

      expect(result.trendScore, greaterThanOrEqualTo(14));
    });

    test('penalises single-category dominance in diversity score', () {
      final current = [makeExpense(50000, 'Shopping')];

      final result = service.compute(
        currentMonthTransactions: current,
        lastMonthTransactions: [],
        budgets: [],
      );

      expect(result.diversityScore, lessThanOrEqualTo(4));
    });

    test('generates insight containing over-budget category name', () {
      final current = [makeIncome(50000), makeExpense(30000, 'Food & Dining')];
      final budgets = [makeBudget('Food & Dining', 10000, 30000)];

      final result = service.compute(
        currentMonthTransactions: current,
        lastMonthTransactions: [],
        budgets: budgets,
      );

      expect(result.insights, isNotEmpty);
      expect(result.insights.any((i) => i.contains('Food & Dining')), isTrue);
    });

    test('total score is always clamped between 0 and 100', () {
      final result = service.compute(
        currentMonthTransactions: [],
        lastMonthTransactions: [],
        budgets: [],
      );
      expect(result.total, inInclusiveRange(0, 100));
    });
  });
}
