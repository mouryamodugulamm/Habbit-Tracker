import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/entities/streak_result.dart';

/// Use case: compute current and longest streak for a habit.
///
/// Rules:
/// - Same-day entries count as one (deduplicated).
/// - Dates are sorted internally.
/// - Streak resets when day gap > 1.
/// - Current streak = consecutive days ending at the most recent completion.
/// - Longest streak = maximum consecutive-day run in history.
class CalculateStreak {
  StreakResult execute(Habit habit) {
    if (habit.completedDates.isEmpty) {
      return const StreakResult(currentStreak: 0, longestStreak: 0);
    }

    final dateOnly = habit.completedDates.map(Habit.toDate).toSet().toList();
    dateOnly.sort();

    final dateSet = dateOnly.toSet();
    final sorted = dateOnly;

    int longestStreak = 1;
    int run = 1;
    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff == 1) {
        run++;
      } else {
        run = 1;
      }
      if (run > longestStreak) longestStreak = run;
    }

    int currentStreak = 0;
    if (sorted.isNotEmpty) {
      DateTime cursor = sorted.last;
      currentStreak = 1;
      DateTime prev = DateTime.utc(cursor.year, cursor.month, cursor.day)
          .subtract(const Duration(days: 1));
      prev = DateTime.utc(prev.year, prev.month, prev.day);
      while (dateSet.contains(prev)) {
        currentStreak++;
        prev = DateTime.utc(prev.year, prev.month, prev.day)
            .subtract(const Duration(days: 1));
        prev = DateTime.utc(prev.year, prev.month, prev.day);
      }
    }

    return StreakResult(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );
  }
}
