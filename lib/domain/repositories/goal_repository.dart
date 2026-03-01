import 'package:habit_tracker/domain/entities/goal.dart';

abstract class GoalRepository {
  Future<void> addGoal(Goal goal);
  Future<void> deleteGoal(String id);
  Future<void> deleteGoalsForHabit(String habitId);
  Future<List<Goal>> getGoals();
  Future<Goal?> getGoalByHabitId(String habitId);
  Future<void> updateGoal(Goal goal);
  Future<void> clearAll();
}
