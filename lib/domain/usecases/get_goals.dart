import 'package:habit_tracker/domain/entities/goal.dart';
import 'package:habit_tracker/domain/repositories/goal_repository.dart';

class GetGoals {
  GetGoals(this._repository);

  final GoalRepository _repository;

  Future<List<Goal>> execute() async {
    return _repository.getGoals();
  }
}
