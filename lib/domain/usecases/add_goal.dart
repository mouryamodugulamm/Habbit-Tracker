import 'package:habit_tracker/domain/entities/goal.dart';
import 'package:habit_tracker/domain/repositories/goal_repository.dart';

class AddGoal {
  AddGoal(this._repository);

  final GoalRepository _repository;

  Future<void> execute(Goal goal) async {
    await _repository.addGoal(goal);
  }
}
