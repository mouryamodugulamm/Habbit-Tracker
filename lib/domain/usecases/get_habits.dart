import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/repositories/habit_repository.dart';

/// Use case: get all habits.
class GetHabits {
  GetHabits(this._repository);

  final HabitRepository _repository;

  Future<List<Habit>> execute() async {
    return _repository.getHabits();
  }
}
