import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/data/services/notification_service.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/usecases/add_habit.dart';
import 'package:habit_tracker/domain/usecases/delete_habit.dart';
import 'package:habit_tracker/domain/usecases/delete_goals_for_habit.dart';
import 'package:habit_tracker/domain/usecases/get_habits.dart';
import 'package:habit_tracker/domain/usecases/toggle_habit_completion.dart';
import 'package:habit_tracker/domain/usecases/update_habit.dart';
import 'package:habit_tracker/presentation/providers/habit_state.dart';

/// Coordinates habit operations via use cases and updates [HabitState].
/// Schedules/cancels notifications when [notificationService] is set.
/// Deletes goals for the habit when the habit is deleted.
class HabitNotifier extends StateNotifier<HabitState> {
  HabitNotifier({
    required GetHabits getHabits,
    required AddHabit addHabit,
    required DeleteHabit deleteHabit,
    required DeleteGoalsForHabit deleteGoalsForHabit,
    required UpdateHabit updateHabit,
    required ToggleHabitCompletion toggleCompletion,
    NotificationService? notificationService,
  })  : _getHabits = getHabits,
        _addHabit = addHabit,
        _deleteHabit = deleteHabit,
        _deleteGoalsForHabit = deleteGoalsForHabit,
        _updateHabit = updateHabit,
        _toggleCompletion = toggleCompletion,
        _notificationService = notificationService,
        super(HabitState.initial);

  final GetHabits _getHabits;
  final AddHabit _addHabit;
  final DeleteHabit _deleteHabit;
  final DeleteGoalsForHabit _deleteGoalsForHabit;
  final UpdateHabit _updateHabit;
  final ToggleHabitCompletion _toggleCompletion;
  final NotificationService? _notificationService;

  /// Loads habits from storage. When [skipReschedule] is true, skips re-scheduling reminders (e.g. after toggle).
  Future<void> loadHabits({bool skipReschedule = false}) async {
    state = state.copyWith(habits: const AsyncValue.loading());
    state = state.copyWith(
      habits: await AsyncValue.guard(() => _getHabits.execute()),
    );
    if (!skipReschedule) await _rescheduleRemindersIfNeeded();
  }

  Future<void> _rescheduleRemindersIfNeeded() async {
    final service = _notificationService;
    if (service == null) return;
    final habits = state.habits.valueOrNull;
    if (habits == null) return;
    for (final habit in habits) {
      final minutes = habit.reminderMinutesSinceMidnight;
      if (minutes != null) {
        await service.scheduleDailyReminder(habit.id, habit.name, minutes);
      }
    }
  }

  /// Adds a new habit. [id] must be unique (e.g. UUID). [reminderMinutesSinceMidnight] 0–1439 schedules a daily reminder.
  /// When [skipReload] is true, does not refresh the list (caller should call [loadHabits] after e.g. popping a route).
  Future<void> addHabit(
    String id,
    String name, {
    bool skipReload = false,
    int? reminderMinutesSinceMidnight,
    int? iconIndex,
  }) async {
    await _addHabit.execute(id, name, reminderMinutesSinceMidnight: reminderMinutesSinceMidnight, iconIndex: iconIndex);
    final notificationService = _notificationService;
    if (reminderMinutesSinceMidnight != null && notificationService != null) {
      await notificationService.scheduleDailyReminder(id, name, reminderMinutesSinceMidnight);
    }
    if (!skipReload) await loadHabits();
  }

  /// Deletes a habit by id. Cancels its reminder, deletes its goals, and reloads habits.
  Future<void> deleteHabit(String id) async {
    await _deleteHabit.execute(id);
    await _deleteGoalsForHabit.execute(id);
    await _notificationService?.cancelReminder(id);
    await loadHabits();
  }

  /// Updates an existing habit. Reschedules or cancels reminder if changed.
  Future<void> updateHabit(Habit habit) async {
    await _updateHabit.execute(habit);
    final service = _notificationService;
    if (service != null) {
      await service.cancelReminder(habit.id);
      final minutes = habit.reminderMinutesSinceMidnight;
      if (minutes != null) {
        await service.scheduleDailyReminder(habit.id, habit.name, minutes);
      }
    }
    await loadHabits();
  }

  /// Toggles completion for [habitId] on [date]. Reloads list without re-scheduling all reminders.
  Future<void> toggleCompletion(String habitId, DateTime date) async {
    await _toggleCompletion.execute(habitId, date);
    await loadHabits(skipReschedule: true);
  }
}
