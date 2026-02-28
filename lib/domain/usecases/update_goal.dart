import 'package:habit_tracker/domain/entities/goal.dart';
import 'package:habit_tracker/domain/repositories/goal_repository.dart';

class UpdateGoal {
  UpdateGoal(this._repository);

  final GoalRepository _repository;

  Future<void> execute(Goal goal) async {
    await _repository.updateGoal(goal);
  }
}
