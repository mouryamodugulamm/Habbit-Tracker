import 'package:habit_tracker/domain/repositories/goal_repository.dart';

class DeleteGoalsForHabit {
  DeleteGoalsForHabit(this._repository);

  final GoalRepository _repository;

  Future<void> execute(String habitId) async {
    await _repository.deleteGoalsForHabit(habitId);
  }
}
