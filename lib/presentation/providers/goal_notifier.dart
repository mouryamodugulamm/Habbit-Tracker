import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/domain/entities/goal.dart';
import 'package:habit_tracker/domain/usecases/add_goal.dart';
import 'package:habit_tracker/domain/usecases/delete_goals_for_habit.dart';
import 'package:habit_tracker/domain/usecases/get_goals.dart';
import 'package:habit_tracker/domain/usecases/update_goal.dart';

/// Holds goals list and exposes load/add/update/delete. Goals are loaded separately from habits.
class GoalNotifier extends StateNotifier<AsyncValue<List<Goal>>> {
  GoalNotifier({
    required GetGoals getGoals,
    required AddGoal addGoal,
    required UpdateGoal updateGoal,
    required DeleteGoalsForHabit deleteGoalsForHabit,
  })  : _getGoals = getGoals,
        _addGoal = addGoal,
        _updateGoal = updateGoal,
        _deleteGoalsForHabit = deleteGoalsForHabit,
        super(const AsyncValue.loading());

  final GetGoals _getGoals;
  final AddGoal _addGoal;
  final UpdateGoal _updateGoal;
  final DeleteGoalsForHabit _deleteGoalsForHabit;

  Future<void> loadGoals() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _getGoals.execute());
  }

  Future<void> addGoal(Goal goal) async {
    await _addGoal.execute(goal);
    unawaited(loadGoals()); // refresh list in background so save returns immediately
  }

  Future<void> updateGoal(Goal goal) async {
    await _updateGoal.execute(goal);
    unawaited(loadGoals());
  }

  Future<void> deleteGoalsForHabit(String habitId) async {
    await _deleteGoalsForHabit.execute(habitId);
    unawaited(loadGoals());
  }

  Future<void> markGoalCompleted(Goal goal) async {
    await _updateGoal.execute(goal.copyWith(completedAt: DateTime.now()));
    unawaited(loadGoals());
  }

  Future<void> markGoalClosed(Goal goal) async {
    await _updateGoal.execute(goal.copyWith(closedAt: DateTime.now()));
    unawaited(loadGoals());
  }
}
