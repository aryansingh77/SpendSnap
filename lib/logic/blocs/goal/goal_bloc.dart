import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/repositories/goal_repository.dart';

part 'goal_event.dart';
part 'goal_state.dart';

class GoalBloc extends Bloc<GoalEvent, GoalState> {
  GoalBloc({required GoalRepository repository})
      : _repo = repository,
        super(const GoalState()) {
    on<GoalStreamStarted>(_onStarted);
    on<_GoalStreamUpdated>(_onUpdated);
    on<GoalAdded>(_onAdded);
    on<GoalUpdated>(_onGoalUpdated);
    on<GoalDeleted>(_onDeleted);
    on<GoalFundsAdded>(_onFundsAdded);
  }

  final GoalRepository _repo;
  StreamSubscription<List<GoalModel>>? _sub;

  Future<void> _onStarted(
      GoalStreamStarted event, Emitter<GoalState> emit) async {
    emit(state.copyWith(status: GoalStatus.loading));
    await _sub?.cancel();
    _sub = _repo.watchGoals(event.userId).listen(
      (goals) => add(_GoalStreamUpdated(goals: goals)),
      onError: (_) => emit(state.copyWith(status: GoalStatus.error)),
    );
    await emit.forEach<GoalState>(Stream.empty(), onData: (s) => s);
  }

  void _onUpdated(_GoalStreamUpdated event, Emitter<GoalState> emit) {
    emit(state.copyWith(
      status: GoalStatus.loaded,
      goals: event.goals,
    ));
  }

  Future<void> _onAdded(GoalAdded event, Emitter<GoalState> emit) async {
    try {
      await _repo.addGoal(event.goal);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onGoalUpdated(GoalUpdated event, Emitter<GoalState> emit) async {
    try {
      await _repo.updateGoal(event.goal);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleted(GoalDeleted event, Emitter<GoalState> emit) async {
    try {
      await _repo.deleteGoal(event.userId, event.goalId);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onFundsAdded(
      GoalFundsAdded event, Emitter<GoalState> emit) async {
    try {
      await _repo.addFunds(event.userId, event.goalId, event.amount);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
