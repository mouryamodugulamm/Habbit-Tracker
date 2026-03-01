import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/repositories/habit_repository.dart';

/// Use case: toggle completion for a habit on a given date.
/// If there is at least one completion on that day, removes the most recent. Otherwise adds one with current time.
/// Optional [note] is used when adding (e.g. from detail screen).
Future<Habit?> toggleHabitCompletion(
  HabitRepository repository,
  String habitId,
  DateTime date, {
  String? note,
}) async {
  final habit = await repository.getHabitById(habitId);
  if (habit == null) return null;

  final targetDate = Habit.toDate(date);
  final completions = List<HabitCompletion>.from(habit.completions);

  final onDay = completions.where((c) => Habit.toDate(c.completedAt) == targetDate).toList();
  if (onDay.isNotEmpty) {
    final toRemove = onDay.last;
    completions.remove(toRemove);
  } else {
    completions.add(HabitCompletion(DateTime.now(), note));
    completions.sort((a, b) => a.completedAt.compareTo(b.completedAt));
  }

  final updated = habit.copyWith(completions: completions);
  await repository.updateHabit(updated);
  return updated;
}

/// Use case: add a completion for a habit (multiple per day, capped at target per day). Optional [note].
/// Does not add if today already has [effectiveTargetPerDay] completions.
Future<Habit?> addHabitCompletion(
  HabitRepository repository,
  String habitId, {
  String? note,
}) async {
  final habit = await repository.getHabitById(habitId);
  if (habit == null) return null;
  final countToday = habit.completedCountOn(DateTime.now());
  if (countToday >= habit.effectiveTargetPerDay) return habit;
  final completions = List<HabitCompletion>.from(habit.completions)
    ..add(HabitCompletion(DateTime.now(), note))
    ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
  final updated = habit.copyWith(completions: completions);
  await repository.updateHabit(updated);
  return updated;
}

/// Use case class for dependency injection.
class ToggleHabitCompletion {
  ToggleHabitCompletion(this._repository);
  final HabitRepository _repository;

  Future<Habit?> execute(String habitId, DateTime date, {String? note}) async {
    return toggleHabitCompletion(_repository, habitId, date, note: note);
  }
}

/// Use case: add a completion (always adds; for multiple per day / notes).
class AddHabitCompletion {
  AddHabitCompletion(this._repository);
  final HabitRepository _repository;

  Future<Habit?> execute(String habitId, {String? note}) async {
    return addHabitCompletion(_repository, habitId, note: note);
  }
}
