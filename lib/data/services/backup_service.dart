import 'dart:convert';

import 'package:habit_tracker/domain/entities/goal.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/repositories/goal_repository.dart';
import 'package:habit_tracker/domain/repositories/habit_repository.dart';

/// Backup format version for future migrations.
const int _backupVersion = 1;

/// Exports and restores habits and goals as JSON. Use for backup/restore on same or new device.
class BackupService {
  BackupService({
    required HabitRepository habitRepository,
    required GoalRepository goalRepository,
  })  : _habitRepository = habitRepository,
        _goalRepository = goalRepository;

  final HabitRepository _habitRepository;
  final GoalRepository _goalRepository;

  /// Exports all habits (with completions) and goals to a JSON string.
  Future<String> exportToJson() async {
    final habits = await _habitRepository.getHabits();
    final goals = await _goalRepository.getGoals();
    final payload = <String, dynamic>{
      'version': _backupVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'habits': habits.map(_habitToMap).toList(),
      'goals': goals.map(_goalToMap).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Map<String, dynamic> _habitToMap(Habit h) {
    return <String, dynamic>{
      'id': h.id,
      'name': h.name,
      'reminderMinutesSinceMidnight': h.reminderMinutesSinceMidnight,
      'iconIndex': h.iconIndex,
      'isArchived': h.isArchived,
      'category': h.category,
      'frequency': _frequencyToIndex(h.frequency),
      'customWeekdays': List<int>.from(h.customWeekdays),
      'targetCountPerDay': h.targetCountPerDay,
      'createdAt': h.createdAt.millisecondsSinceEpoch,
      'completions': h.completions
          .map((c) => <String, dynamic>{
                'completedAt': c.completedAt.millisecondsSinceEpoch,
                'note': c.note,
              })
          .toList(),
    };
  }

  int _frequencyToIndex(HabitFrequency f) {
    switch (f) {
      case HabitFrequency.weekdays:
        return 1;
      case HabitFrequency.custom:
        return 2;
      default:
        return 0;
    }
  }

  HabitFrequency _indexToFrequency(int i) {
    switch (i) {
      case 1:
        return HabitFrequency.weekdays;
      case 2:
        return HabitFrequency.custom;
      default:
        return HabitFrequency.daily;
    }
  }

  Map<String, dynamic> _goalToMap(Goal g) {
    return <String, dynamic>{
      'id': g.id,
      'habitId': g.habitId,
      'targetType': g.targetType == GoalTargetType.streak ? 1 : 0,
      'targetValue': g.targetValue,
      'completedAt': g.completedAt?.millisecondsSinceEpoch,
      'closedAt': g.closedAt?.millisecondsSinceEpoch,
      'createdAt': g.createdAt.millisecondsSinceEpoch,
    };
  }

  /// Restores habits and goals from a JSON string. Clears existing data first.
  /// Returns the number of habits restored; throws on invalid JSON or format.
  Future<int> restoreFromJson(String jsonString) async {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final habitsList = decoded['habits'] as List<dynamic>? ?? [];
    final goalsList = decoded['goals'] as List<dynamic>? ?? [];

    await _habitRepository.clearAll();
    await _goalRepository.clearAll();

    for (final item in habitsList) {
      final habit = _mapToHabit(item as Map<String, dynamic>);
      await _habitRepository.addHabit(habit);
    }
    for (final item in goalsList) {
      final goal = _mapToGoal(item as Map<String, dynamic>);
      await _goalRepository.addGoal(goal);
    }
    return habitsList.length;
  }

  Habit _mapToHabit(Map<String, dynamic> m) {
    final completionsList = m['completions'] as List<dynamic>? ?? [];
    final completions = completionsList.map((c) {
      final map = c as Map<String, dynamic>;
      final ms = map['completedAt'] as int;
      final note = map['note'] as String?;
      return HabitCompletion(DateTime.fromMillisecondsSinceEpoch(ms), note);
    }).toList();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      m['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
    return Habit(
      id: m['id'] as String,
      name: m['name'] as String,
      completions: completions,
      createdAt: createdAt,
      reminderMinutesSinceMidnight: m['reminderMinutesSinceMidnight'] as int?,
      iconIndex: m['iconIndex'] as int?,
      isArchived: m['isArchived'] as bool? ?? false,
      category: m['category'] as String?,
      frequency: _indexToFrequency(m['frequency'] as int? ?? 0),
      customWeekdays: (m['customWeekdays'] as List<dynamic>?)?.cast<int>() ?? const [],
      targetCountPerDay: m['targetCountPerDay'] as int?,
    );
  }

  Goal _mapToGoal(Map<String, dynamic> m) {
    return Goal(
      id: m['id'] as String,
      habitId: m['habitId'] as String,
      targetType: (m['targetType'] as int?) == 1 ? GoalTargetType.streak : GoalTargetType.totalDays,
      targetValue: m['targetValue'] as int,
      completedAt: m['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(m['completedAt'] as int)
          : null,
      closedAt: m['closedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(m['closedAt'] as int)
          : null,
      createdAt: m['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int)
          : null,
    );
  }
}
