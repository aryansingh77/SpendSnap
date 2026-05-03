part of 'goal_bloc.dart';

class GoalState extends Equatable {
  const GoalState({
    this.status = GoalStatus.initial,
    this.goals = const [],
    this.errorMessage,
  });

  final GoalStatus status;
  final List<GoalModel> goals;
  final String? errorMessage;

  List<GoalModel> get active => goals.where((g) => !g.isCompleted).toList();
  List<GoalModel> get completed => goals.where((g) => g.isCompleted).toList();

  double get totalSaved => goals.fold(0.0, (s, g) => s + g.currentAmount);
  double get totalTarget => goals.fold(0.0, (s, g) => s + g.targetAmount);

  GoalState copyWith({
    GoalStatus? status,
    List<GoalModel>? goals,
    String? errorMessage,
  }) =>
      GoalState(
        status: status ?? this.status,
        goals: goals ?? this.goals,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [status, goals, errorMessage];
}

enum GoalStatus { initial, loading, loaded, error }
