class AppConstants {
  AppConstants._();

  static const String appName = 'SpendSnap';
  static const String currency = '₹';
  static const String currencyCode = 'INR';

  static const List<String> expenseCategories = [
    'Food & Dining',
    'Transport',
    'Shopping',
    'Entertainment',
    'Health',
    'Bills & Utilities',
    'Other',
  ];

  static const List<String> allCategories = [
    'Income',
    'Food & Dining',
    'Transport',
    'Shopping',
    'Entertainment',
    'Health',
    'Bills & Utilities',
    'Savings',
    'Other',
  ];

  static const List<String> recurringIntervals = [
    'Daily',
    'Weekly',
    'Monthly',
  ];

  // 50/30/20 allocation percentages per category
  static const Map<String, double> budgetAllocationGuide = {
    'Food & Dining': 0.15,
    'Transport': 0.10,
    'Shopping': 0.10,
    'Entertainment': 0.05,
    'Health': 0.05,
    'Bills & Utilities': 0.15,
    'Other': 0.10,
    // 0.30 implicit savings
  };

  static const int maxTransactionTitleLength = 50;
  static const int maxBudgetNameLength = 30;
  static const int maxGoalNameLength = 40;
}
