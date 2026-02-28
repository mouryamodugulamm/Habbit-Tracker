import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/repositories/habit_repository.dart';

/// Use case: add a new habit. Caller must provide [id] (e.g. from UUID).
class AddHabit {
  AddHabit(this._repository);

  final HabitRepository _repository;

  Future<void> execute(String id, String name, {int? reminderMinutesSinceMidnight, int? iconIndex}) async {
    final habit = Habit(
      id: id,
      name: name,
      completedDates: [],
      reminderMinutesSinceMidnight: reminderMinutesSinceMidnight,
      iconIndex: iconIndex,
    );
    await _repository.addHabit(habit);
  }
}
