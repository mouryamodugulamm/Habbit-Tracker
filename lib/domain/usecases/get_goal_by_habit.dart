import 'package:habit_tracker/domain/entities/goal.dart';
import 'package:habit_tracker/domain/repositories/goal_repository.dart';

class GetGoalByHabit {
  GetGoalByHabit(this._repository);

  final GoalRepository _repository;

  Future<Goal?> execute(String habitId) async {
    return _repository.getGoalByHabitId(habitId);
  }
}
