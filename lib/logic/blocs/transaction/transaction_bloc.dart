import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';

part 'transaction_event.dart';
part 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  TransactionBloc({required TransactionRepository repository})
      : _repo = repository,
        super(const TransactionState()) {
    on<TransactionStreamStarted>(_onStarted);
    on<_TransactionStreamUpdated>(_onUpdated);
    on<TransactionAdded>(_onAdded);
    on<TransactionUpdated>(_onUpdated2);
    on<TransactionDeleted>(_onDeleted);
    on<TransactionFilterChanged>(_onFilterChanged);
  }

  final TransactionRepository _repo;
  StreamSubscription<List<TransactionModel>>? _sub;

  Future<void> _onStarted(
      TransactionStreamStarted event, Emitter<TransactionState> emit) async {
    emit(state.copyWith(status: TransactionStatus.loading));
    await _sub?.cancel();
    _sub = _repo.watchTransactions(event.userId).listen(
      (txns) => add(_TransactionStreamUpdated(transactions: txns)),
      onError: (_) => emit(state.copyWith(status: TransactionStatus.error)),
    );
    await emit.forEach<TransactionState>(
      Stream.empty(),
      onData: (s) => s,
    );
  }

  void _onUpdated(
      _TransactionStreamUpdated event, Emitter<TransactionState> emit) {
    emit(state.copyWith(
      status: TransactionStatus.loaded,
      allTransactions: event.transactions,
    ));
  }

  Future<void> _onAdded(
      TransactionAdded event, Emitter<TransactionState> emit) async {
    try {
      await _repo.addTransaction(event.transaction);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdated2(
      TransactionUpdated event, Emitter<TransactionState> emit) async {
    try {
      await _repo.updateTransaction(event.transaction);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleted(
      TransactionDeleted event, Emitter<TransactionState> emit) async {
    try {
      await _repo.deleteTransaction(event.userId, event.transactionId);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void _onFilterChanged(
      TransactionFilterChanged event, Emitter<TransactionState> emit) {
    if (event.category == null && event.type == null) {
      emit(state.copyWith(clearFilter: true));
    } else {
      emit(state.copyWith(
        filterCategory: event.category,
        filterType: event.type,
      ));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
