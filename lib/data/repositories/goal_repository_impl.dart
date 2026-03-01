import 'package:habit_tracker/data/datasources/goal_local_datasource.dart';
import 'package:habit_tracker/data/models/goal_model.dart';
import 'package:habit_tracker/domain/entities/goal.dart';
import 'package:habit_tracker/domain/repositories/goal_repository.dart';

class GoalRepositoryImpl implements GoalRepository {
  GoalRepositoryImpl(this._dataSource);

  final GoalLocalDataSource _dataSource;

  @override
  Future<void> addGoal(Goal goal) async {
    final model = GoalModel.fromEntity(goal);
    await _dataSource.put(model);
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _dataSource.delete(id);
  }

  @override
  Future<void> deleteGoalsForHabit(String habitId) async {
    await _dataSource.deleteByHabitId(habitId);
  }

  @override
  Future<List<Goal>> getGoals() async {
    final models = await _dataSource.getAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Goal?> getGoalByHabitId(String habitId) async {
    final model = await _dataSource.getByHabitId(habitId);
    return model?.toEntity();
  }

  @override
  Future<void> updateGoal(Goal goal) async {
    final model = GoalModel.fromEntity(goal);
    await _dataSource.put(model);
  }

  @override
  Future<void> clearAll() async {
    await _dataSource.clearAll();
  }
}
