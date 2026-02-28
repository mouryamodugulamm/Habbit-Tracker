import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/repositories/habit_repository.dart';

/// Use case: update an existing habit (name, reminder, etc.). Preserves id and completedDates.
class UpdateHabit {
  UpdateHabit(this._repository);

  final HabitRepository _repository;

  Future<void> execute(Habit habit) async {
    await _repository.updateHabit(habit);
  }
}
