part of 'goal_bloc.dart';

abstract class GoalEvent extends Equatable {
  const GoalEvent();
  @override
  List<Object?> get props => [];
}

class GoalStreamStarted extends GoalEvent {
  const GoalStreamStarted({required this.userId});
  final String userId;
  @override
  List<Object?> get props => [userId];
}

class GoalAdded extends GoalEvent {
  const GoalAdded({required this.goal});
  final GoalModel goal;
  @override
  List<Object?> get props => [goal];
}

class GoalDeleted extends GoalEvent {
  const GoalDeleted({required this.userId, required this.goalId});
  final String userId;
  final String goalId;
  @override
  List<Object?> get props => [userId, goalId];
}

class GoalFundsAdded extends GoalEvent {
  const GoalFundsAdded({
    required this.userId,
    required this.goalId,
    required this.amount,
  });
  final String userId;
  final String goalId;
  final double amount;
  @override
  List<Object?> get props => [userId, goalId, amount];
}

class _GoalStreamUpdated extends GoalEvent {
  const _GoalStreamUpdated({required this.goals});
  final List<GoalModel> goals;
  @override
  List<Object?> get props => [goals];
}
