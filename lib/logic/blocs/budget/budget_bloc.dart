import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/repositories/budget_repository.dart';

part 'budget_event.dart';
part 'budget_state.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  BudgetBloc({required BudgetRepository repository})
      : _repo = repository,
        super(const BudgetState()) {
    on<BudgetStreamStarted>(_onStarted);
    on<_BudgetStreamUpdated>(_onUpdated);
    on<_BudgetStreamErrored>(_onStreamError);
    on<BudgetAdded>(_onAdded);
    on<BudgetDeleted>(_onDeleted);
    on<BudgetSpentUpdated>(_onSpentUpdated);
  }

  final BudgetRepository _repo;
  StreamSubscription<List<BudgetModel>>? _sub;

  Future<void> _onStarted(
      BudgetStreamStarted event, Emitter<BudgetState> emit) async {
    emit(state.copyWith(status: BudgetStatus.loading));
    await _sub?.cancel();
    _sub = _repo
        .watchBudgetsForMonth(event.userId, event.month, event.year)
        .listen(
          (b) => add(_BudgetStreamUpdated(budgets: b)),
          onError: (_) => add(const _BudgetStreamErrored()),
        );
    await emit.forEach<BudgetState>(Stream.empty(), onData: (s) => s);
  }

  void _onStreamError(
      _BudgetStreamErrored event, Emitter<BudgetState> emit) {
    emit(state.copyWith(status: BudgetStatus.error));
  }

  void _onUpdated(_BudgetStreamUpdated event, Emitter<BudgetState> emit) {
    // Re-apply cached spentMap so a Firestore refresh doesn't reset spending to 0
    final budgets = event.budgets.map((b) {
      return b.withSpent(state.spentMap[b.category] ?? 0.0);
    }).toList();
    emit(state.copyWith(status: BudgetStatus.loaded, budgets: budgets));
  }

  Future<void> _onAdded(BudgetAdded event, Emitter<BudgetState> emit) async {
    try {
      await _repo.addBudget(event.budget);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleted(
      BudgetDeleted event, Emitter<BudgetState> emit) async {
    try {
      await _repo.deleteBudget(event.userId, event.budgetId);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void _onSpentUpdated(
      BudgetSpentUpdated event, Emitter<BudgetState> emit) {
    final updated = state.budgets.map((b) {
      return b.withSpent(event.spentMap[b.category] ?? 0.0);
    }).toList();
    emit(state.copyWith(budgets: updated, spentMap: event.spentMap));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
