part of 'transaction_bloc.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();
  @override
  List<Object?> get props => [];
}

class TransactionStreamStarted extends TransactionEvent {
  const TransactionStreamStarted({required this.userId});
  final String userId;
  @override
  List<Object?> get props => [userId];
}

class TransactionAdded extends TransactionEvent {
  const TransactionAdded({required this.transaction});
  final TransactionModel transaction;
  @override
  List<Object?> get props => [transaction];
}

class TransactionUpdated extends TransactionEvent {
  const TransactionUpdated({required this.transaction});
  final TransactionModel transaction;
  @override
  List<Object?> get props => [transaction];
}

class TransactionDeleted extends TransactionEvent {
  const TransactionDeleted({required this.userId, required this.transactionId});
  final String userId;
  final String transactionId;
  @override
  List<Object?> get props => [userId, transactionId];
}

class TransactionFilterChanged extends TransactionEvent {
  const TransactionFilterChanged({this.category, this.type});
  final String? category;
  final TransactionType? type;
  @override
  List<Object?> get props => [category, type];
}

class _TransactionStreamUpdated extends TransactionEvent {
  const _TransactionStreamUpdated({required this.transactions});
  final List<TransactionModel> transactions;
  @override
  List<Object?> get props => [transactions];
}

class _TransactionStreamErrored extends TransactionEvent {
  const _TransactionStreamErrored();
}
