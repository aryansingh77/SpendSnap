part of 'budget_bloc.dart';

class BudgetState extends Equatable {
  const BudgetState({
    this.status = BudgetStatus.initial,
    this.budgets = const [],
    this.spentMap = const {},
    this.errorMessage,
  });

  final BudgetStatus status;
  final List<BudgetModel> budgets;
  // Cached category→spent so Firestore refreshes don't wipe calculated values
  final Map<String, double> spentMap;
  final String? errorMessage;

  double get totalLimit =>
      budgets.fold(0.0, (s, b) => s + b.limitAmount);

  double get totalSpent =>
      budgets.fold(0.0, (s, b) => s + b.spentAmount);

  int get overBudgetCount => budgets.where((b) => b.isOverBudget).length;

  BudgetState copyWith({
    BudgetStatus? status,
    List<BudgetModel>? budgets,
    Map<String, double>? spentMap,
    String? errorMessage,
  }) =>
      BudgetState(
        status: status ?? this.status,
        budgets: budgets ?? this.budgets,
        spentMap: spentMap ?? this.spentMap,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [status, budgets, spentMap, errorMessage];
}

enum BudgetStatus { initial, loading, loaded, error }
