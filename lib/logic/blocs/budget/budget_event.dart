part of 'budget_bloc.dart';

abstract class BudgetEvent extends Equatable {
  const BudgetEvent();
  @override
  List<Object?> get props => [];
}

class BudgetStreamStarted extends BudgetEvent {
  const BudgetStreamStarted({
    required this.userId,
    required this.month,
    required this.year,
  });
  final String userId;
  final int month;
  final int year;
  @override
  List<Object?> get props => [userId, month, year];
}

class BudgetAdded extends BudgetEvent {
  const BudgetAdded({required this.budget});
  final BudgetModel budget;
  @override
  List<Object?> get props => [budget];
}

class BudgetUpdated extends BudgetEvent {
  const BudgetUpdated({required this.budget});
  final BudgetModel budget;
  @override
  List<Object?> get props => [budget];
}

class BudgetDeleted extends BudgetEvent {
  const BudgetDeleted({required this.userId, required this.budgetId});
  final String userId;
  final String budgetId;
  @override
  List<Object?> get props => [userId, budgetId];
}

class BudgetSpentUpdated extends BudgetEvent {
  const BudgetSpentUpdated({required this.spentMap});
  final Map<String, double> spentMap;
  @override
  List<Object?> get props => [spentMap];
}

class _BudgetStreamUpdated extends BudgetEvent {
  const _BudgetStreamUpdated({required this.budgets});
  final List<BudgetModel> budgets;
  @override
  List<Object?> get props => [budgets];
}

class _BudgetStreamErrored extends BudgetEvent {
  const _BudgetStreamErrored();
}
