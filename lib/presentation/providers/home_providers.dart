import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/presentation/providers/habit_providers.dart';

/// Filter for home habit list: all, completed today, not done today, or archived.
enum HomeFilter {
  all,
  completedToday,
  notDone,
  archived,
}

/// Sort order for home habit list.
enum HomeSort {
  name,
  streak,
  needsAttention,
}

final homeFilterProvider = StateProvider<HomeFilter>((ref) => HomeFilter.all);
final homeSortProvider = StateProvider<HomeSort>((ref) => HomeSort.name);

/// Selected category for filter. Null = all (show sections by category).
final homeCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// Selected date for "today" view. Progress and filter/sort use this date; tap to change.
final homeSelectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Filtered and sorted habits for the home list. Excludes no one; widget should
/// further exclude [pendingDeleteId] if any. Depends on streaks when sort is [HomeSort.streak].
/// Filter/sort use [homeSelectedDateProvider] for "completed today" / "not done" / "needs attention".
final homeVisibleHabitsProvider = Provider<List<Habit>>((ref) {
  final habitsValue = ref.watch(habitsListProvider);
  final filter = ref.watch(homeFilterProvider);
  final sort = ref.watch(homeSortProvider);
  final selectedDate = ref.watch(homeSelectedDateProvider);
  final categoryFilter = ref.watch(homeCategoryFilterProvider);

  final habits = habitsValue.valueOrNull ?? [];
  if (habits.isEmpty) return [];

  // Watch all streaks so sort-by-streak updates when completion toggles
  for (final h in habits) {
    ref.watch(streakForHabitProvider(h.id));
  }

  var list = List<Habit>.from(habits);

  if (categoryFilter != null && categoryFilter.isNotEmpty) {
    list = list.where((h) => h.category == categoryFilter).toList();
  }

  switch (filter) {
    case HomeFilter.all:
      list = list.where((h) => !h.isArchived).toList();
      break;
    case HomeFilter.completedToday:
      list = list.where((h) => !h.isArchived && h.isCompletedOn(selectedDate)).toList();
      break;
    case HomeFilter.notDone:
      list = list.where((h) => !h.isArchived && !h.isCompletedOn(selectedDate)).toList();
      break;
    case HomeFilter.archived:
      list = list.where((h) => h.isArchived).toList();
      break;
  }

  switch (sort) {
    case HomeSort.name:
      list.sort((a, b) => a.name.compareTo(b.name));
      break;
    case HomeSort.streak:
      list.sort((a, b) {
        final sa = ref.read(streakForHabitProvider(a.id))?.currentStreak ?? 0;
        final sb = ref.read(streakForHabitProvider(b.id))?.currentStreak ?? 0;
        return sb.compareTo(sa);
      });
      break;
    case HomeSort.needsAttention:
      list.sort((a, b) {
        final ac = a.isCompletedOn(selectedDate) ? 1 : 0;
        final bc = b.isCompletedOn(selectedDate) ? 1 : 0;
        return ac.compareTo(bc);
      });
      break;
  }

  return list;
});
