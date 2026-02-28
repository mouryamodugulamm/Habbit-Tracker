import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/repositories/habit_repository.dart';

/// Use case: toggle completion for a habit on a given date.
/// Same-day duplicates are ignored (one entry per day); toggling removes if already present.
class ToggleHabitCompletion {
  ToggleHabitCompletion(this._repository);

  final HabitRepository _repository;

  Future<Habit?> execute(String habitId, DateTime date) async {
    final habit = await _repository.getHabitById(habitId);
    if (habit == null) return null;

    final targetDate = Habit.toDate(date);
    final normalizedDates = habit.completedDates.map(Habit.toDate).toList();
    final set = normalizedDates.toSet();

    if (set.contains(targetDate)) {
      set.remove(targetDate);
    } else {
      set.add(targetDate);
    }

    final newDates = set.toList()..sort();
    final updated = habit.copyWith(
      completedDates: newDates.map((d) => DateTime.utc(d.year, d.month, d.day)).toList(),
    );
    await _repository.updateHabit(updated);
    return updated;
  }
}
