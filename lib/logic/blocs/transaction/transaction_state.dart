part of 'transaction_bloc.dart';

class TransactionState extends Equatable {
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

  List<TransactionModel> get filtered {
    var list = allTransactions;
    if (filterCategory != null) {
      list = list.where((t) => t.category == filterCategory).toList();
    }
    if (filterType != null) {
      list = list.where((t) => t.type == filterType).toList();
    }
    return list;
  }

  double get totalIncome => allTransactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (s, t) => s + t.amount);

  double get totalExpense => allTransactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (s, t) => s + t.amount);

  double get netBalance => totalIncome - totalExpense;

  TransactionState copyWith({
    TransactionStatus? status,
    List<TransactionModel>? allTransactions,
    String? filterCategory,
    TransactionType? filterType,
    String? errorMessage,
    bool clearFilter = false,
  }) =>
      TransactionState(
        status: status ?? this.status,
        allTransactions: allTransactions ?? this.allTransactions,
        filterCategory: clearFilter ? null : (filterCategory ?? this.filterCategory),
        filterType: clearFilter ? null : (filterType ?? this.filterType),
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props =>
      [status, allTransactions, filterCategory, filterType, errorMessage];
}

enum TransactionStatus { initial, loading, loaded, error }
