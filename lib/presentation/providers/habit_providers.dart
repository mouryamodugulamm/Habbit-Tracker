import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/constants/app_constants.dart';
import 'package:habit_tracker/data/datasources/habit_local_datasource.dart';
import 'package:habit_tracker/data/repositories/habit_repository_impl.dart';
import 'package:habit_tracker/data/services/notification_service.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/entities/streak_result.dart';
import 'package:habit_tracker/domain/repositories/habit_repository.dart';
import 'package:habit_tracker/domain/usecases/add_habit.dart';
import 'package:habit_tracker/domain/usecases/calculate_streak.dart';
import 'package:habit_tracker/domain/usecases/delete_habit.dart';
import 'package:habit_tracker/domain/usecases/delete_goals_for_habit.dart';
import 'package:habit_tracker/domain/usecases/get_habits.dart';
import 'package:habit_tracker/domain/usecases/toggle_habit_completion.dart';
import 'package:habit_tracker/domain/usecases/update_habit.dart';
import 'package:habit_tracker/presentation/providers/goal_providers.dart';
import 'package:habit_tracker/presentation/providers/habit_notifier.dart';
import 'package:habit_tracker/presentation/providers/habit_state.dart';

// ---------------------------------------------------------------------------
// Data & domain (wired here; business logic stays in domain)
// ---------------------------------------------------------------------------

final _habitLocalDataSourceProvider = Provider<HabitLocalDataSource>((ref) {
  return HabitLocalDataSource(habitsBoxName: AppConstants.habitsBoxName);
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepositoryImpl(ref.watch(_habitLocalDataSourceProvider));
});

final _getHabitsUseCaseProvider = Provider<GetHabits>((ref) {
  return GetHabits(ref.watch(habitRepositoryProvider));
});

final _addHabitUseCaseProvider = Provider<AddHabit>((ref) {
  return AddHabit(ref.watch(habitRepositoryProvider));
});

final _deleteHabitUseCaseProvider = Provider<DeleteHabit>((ref) {
  return DeleteHabit(ref.watch(habitRepositoryProvider));
});

final _deleteGoalsForHabitUseCaseProvider = Provider<DeleteGoalsForHabit>((
  ref,
) {
  return DeleteGoalsForHabit(ref.watch(goalRepositoryProvider));
});

final _toggleHabitCompletionUseCaseProvider = Provider<ToggleHabitCompletion>((
  ref,
) {
  return ToggleHabitCompletion(ref.watch(habitRepositoryProvider));
});

final _addHabitCompletionUseCaseProvider = Provider<AddHabitCompletion>((ref) {
  return AddHabitCompletion(ref.watch(habitRepositoryProvider));
});

final _updateHabitUseCaseProvider = Provider<UpdateHabit>((ref) {
  return UpdateHabit(ref.watch(habitRepositoryProvider));
});

final _calculateStreakUseCaseProvider = Provider<CalculateStreak>((ref) {
  return CalculateStreak();
});

/// Injected from main after notification init. Null until overridden.
final notificationServiceProvider = Provider<NotificationService?>(
  (ref) => null,
);

// ---------------------------------------------------------------------------
// Presentation state
// ---------------------------------------------------------------------------

final habitNotifierProvider = StateNotifierProvider<HabitNotifier, HabitState>((
  ref,
) {
  return HabitNotifier(
    getHabits: ref.watch(_getHabitsUseCaseProvider),
    addHabit: ref.watch(_addHabitUseCaseProvider),
    deleteHabit: ref.watch(_deleteHabitUseCaseProvider),
    deleteGoalsForHabit: ref.watch(_deleteGoalsForHabitUseCaseProvider),
    updateHabit: ref.watch(_updateHabitUseCaseProvider),
    toggleCompletion: ref.watch(_toggleHabitCompletionUseCaseProvider),
    addCompletion: ref.watch(_addHabitCompletionUseCaseProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
});

/// Current habits list (loading / data / error). Watch this to rebuild UI.
final habitsListProvider = Provider<AsyncValue<List<Habit>>>((ref) {
  return ref.watch(habitNotifierProvider).habits;
});

/// Streak for a habit. Updates automatically when habits list changes.
final streakForHabitProvider = Provider.family<StreakResult?, String>((
  ref,
  habitId,
) {
  final habitsValue = ref.watch(habitsListProvider);
  return habitsValue.when(
    data: (habits) {
      final habit = habits.where((h) => h.id == habitId).firstOrNull;
      if (habit == null) return null;
      return ref.read(_calculateStreakUseCaseProvider).execute(habit);
    },
    loading: () => null,
    error: (error, stackTrace) => null,
  );
});
