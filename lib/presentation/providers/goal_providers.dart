import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/constants/app_constants.dart';
import 'package:habit_tracker/data/datasources/goal_local_datasource.dart';
import 'package:habit_tracker/data/repositories/goal_repository_impl.dart';
import 'package:habit_tracker/domain/entities/goal.dart';
import 'package:habit_tracker/domain/repositories/goal_repository.dart';
import 'package:habit_tracker/domain/usecases/add_goal.dart';
import 'package:habit_tracker/domain/usecases/delete_goals_for_habit.dart';
import 'package:habit_tracker/domain/usecases/get_goals.dart';
import 'package:habit_tracker/domain/usecases/update_goal.dart';
import 'package:habit_tracker/presentation/providers/goal_notifier.dart';

final _goalLocalDataSourceProvider = Provider<GoalLocalDataSource>((ref) {
  return GoalLocalDataSource(goalsBoxName: AppConstants.goalsBoxName);
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepositoryImpl(ref.watch(_goalLocalDataSourceProvider));
});

final _getGoalsUseCaseProvider = Provider<GetGoals>((ref) {
  return GetGoals(ref.watch(goalRepositoryProvider));
});

final _addGoalUseCaseProvider = Provider<AddGoal>((ref) {
  return AddGoal(ref.watch(goalRepositoryProvider));
});

final _updateGoalUseCaseProvider = Provider<UpdateGoal>((ref) {
  return UpdateGoal(ref.watch(goalRepositoryProvider));
});

final _deleteGoalsForHabitUseCaseProvider = Provider<DeleteGoalsForHabit>((ref) {
  return DeleteGoalsForHabit(ref.watch(goalRepositoryProvider));
});

final goalNotifierProvider =
    StateNotifierProvider<GoalNotifier, AsyncValue<List<Goal>>>((ref) {
  return GoalNotifier(
    getGoals: ref.watch(_getGoalsUseCaseProvider),
    addGoal: ref.watch(_addGoalUseCaseProvider),
    updateGoal: ref.watch(_updateGoalUseCaseProvider),
    deleteGoalsForHabit: ref.watch(_deleteGoalsForHabitUseCaseProvider),
  );
});

/// All goals (loading / data / error). Call [GoalNotifier.loadGoals] on app start.
final goalsListProvider = Provider<AsyncValue<List<Goal>>>((ref) {
  return ref.watch(goalNotifierProvider);
});

/// Active goals only (not completed, not closed). For the Goals section UI.
final activeGoalsListProvider = Provider<AsyncValue<List<Goal>>>((ref) {
  return ref.watch(goalsListProvider).whenData(
        (list) => list.where((g) => g.isActive).toList(),
      );
});

/// Goal for a habit, if any. Updates when goals list changes.
final goalForHabitProvider = Provider.family<Goal?, String>((ref, habitId) {
  final goalsValue = ref.watch(goalsListProvider);
  return goalsValue.when(
    data: (goals) => goals.where((g) => g.habitId == habitId).firstOrNull,
    loading: () => null,
    error: (_, _) => null,
  );
});