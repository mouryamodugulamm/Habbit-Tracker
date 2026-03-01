import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/entities/streak_result.dart';

/// Use case: compute current and longest streak for a habit.
///
/// Rules:
/// - Only scheduled days (by [Habit.frequency]) count.
/// - Same-day entries count as one (deduplicated).
/// - Streak resets when there is a gap of more than one scheduled day.
/// - Current streak = consecutive scheduled days ending at the most recent completion.
/// - Longest streak = maximum consecutive scheduled-day run in history.
class CalculateStreak {
  StreakResult execute(Habit habit) {
    final dateOnly = habit.completedDates
        .map(Habit.toDate)
        .where((d) => habit.isScheduledOn(d))
        .toSet()
        .toList();
    if (dateOnly.isEmpty) {
      return const StreakResult(currentStreak: 0, longestStreak: 0);
    }

    dateOnly.sort();
    final dateSet = dateOnly.toSet();
    final sorted = dateOnly;

    DateTime? nextScheduledDay(DateTime date) {
      DateTime d = DateTime.utc(date.year, date.month, date.day).add(const Duration(days: 1));
      for (int i = 0; i < 8; i++) {
        if (habit.isScheduledOn(d)) return DateTime.utc(d.year, d.month, d.day);
        d = d.add(const Duration(days: 1));
      }
      return null;
    }

    DateTime? prevScheduledDay(DateTime date) {
      DateTime d = DateTime.utc(date.year, date.month, date.day).subtract(const Duration(days: 1));
      for (int i = 0; i < 8; i++) {
        if (habit.isScheduledOn(d)) return DateTime.utc(d.year, d.month, d.day);
        d = d.subtract(const Duration(days: 1));
      }
      return null;
    }

    int longestStreak = 1;
    int run = 1;
    for (int i = 1; i < sorted.length; i++) {
      final nextExpected = nextScheduledDay(sorted[i - 1]);
      if (nextExpected != null && nextExpected == Habit.toDate(sorted[i])) {
        run++;
      } else {
        run = 1;
      }
      if (run > longestStreak) longestStreak = run;
    }

    int currentStreak = 0;
    if (sorted.isNotEmpty) {
      DateTime? prev = prevScheduledDay(sorted.last);
      currentStreak = 1;
      while (prev != null && dateSet.contains(prev)) {
        currentStreak++;
        prev = prevScheduledDay(prev);
      }
    }

    return StreakResult(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );
  }
}
