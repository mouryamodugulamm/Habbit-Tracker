import 'package:hive/hive.dart';

import 'package:habit_tracker/domain/entities/habit.dart';

part 'habit_model.g.dart';

/// Data-layer model for Hive persistence. Extends [Habit] and adds serialization.
/// Use [toEntity] for domain and [fromEntity] for storage.
@HiveType(typeId: 0)
class HabitModel extends Habit {
  @HiveField(0)
  final String modelId;

  @HiveField(1)
  final String modelName;

  @HiveField(2)
  final List<int> completedDatesMs;

  @HiveField(3)
  final int createdAtMs;

  @HiveField(4)
  @override
  // ignore: overridden_fields
  final int? reminderMinutesSinceMidnight;

  @HiveField(5)
  @override
  // ignore: overridden_fields
  final int? iconIndex;

  @HiveField(6)
  @override
  // ignore: overridden_fields
  final bool isArchived;

  @HiveField(7)
  @override
  // ignore: overridden_fields
  final String? category;

  @HiveField(8)
  final int frequencyIndex;

  @override
  @HiveField(9)
  final List<int> customWeekdays;

  @HiveField(10)
  final List<String>? completionNotes;

  @HiveField(11)
  final int? targetCountPerDay;

  HabitModel({
    required this.modelId,
    required this.modelName,
    List<int>? completedDatesMs,
    int? createdAtMs,
    this.reminderMinutesSinceMidnight,
    this.iconIndex,
    this.isArchived = false,
    this.category,
    this.frequencyIndex = 0,
    List<int>? customWeekdays,
    List<String>? completionNotes,
    this.targetCountPerDay,
  })  : completedDatesMs = completedDatesMs ?? [],
        createdAtMs = createdAtMs ?? DateTime.now().millisecondsSinceEpoch,
        customWeekdays = customWeekdays ?? [],
        completionNotes = _normalizeNotes(completionNotes, completedDatesMs ?? []),
        super(
          id: modelId,
          name: modelName,
          completions: _buildCompletions(
            completedDatesMs ?? [],
            _normalizeNotes(completionNotes, completedDatesMs ?? []),
          ),
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            createdAtMs ?? DateTime.now().millisecondsSinceEpoch,
          ),
          reminderMinutesSinceMidnight: reminderMinutesSinceMidnight,
          iconIndex: iconIndex,
          isArchived: isArchived,
          category: category,
          frequency: _frequencyFromIndex(frequencyIndex),
          customWeekdays: customWeekdays ?? [],
          targetCountPerDay: targetCountPerDay,
        );

  static List<String> _normalizeNotes(List<String>? notes, List<int> msList) {
    if (notes == null || notes.length != msList.length) {
      return List.filled(msList.length, '');
    }
    return List.from(notes);
  }

  static List<HabitCompletion> _buildCompletions(List<int> msList, List<String> notes) {
    final n = notes.length;
    return [
      for (int i = 0; i < msList.length; i++)
        HabitCompletion(
          DateTime.fromMillisecondsSinceEpoch(msList[i]),
          i < n && notes[i].isNotEmpty ? notes[i] : null,
        ),
    ];
  }

  static HabitFrequency _frequencyFromIndex(int i) {
    switch (i) {
      case 1:
        return HabitFrequency.weekdays;
      case 2:
        return HabitFrequency.custom;
      default:
        return HabitFrequency.daily;
    }
  }

  static int _indexFromFrequency(HabitFrequency f) {
    switch (f) {
      case HabitFrequency.weekdays:
        return 1;
      case HabitFrequency.custom:
        return 2;
      default:
        return 0;
    }
  }

  /// Maps from domain entity to model for storage.
  factory HabitModel.fromEntity(Habit habit) {
    return HabitModel(
      modelId: habit.id,
      modelName: habit.name,
      completedDatesMs: habit.completions
          .map((c) => c.completedAt.millisecondsSinceEpoch)
          .toList(),
      createdAtMs: habit.createdAt.millisecondsSinceEpoch,
      reminderMinutesSinceMidnight: habit.reminderMinutesSinceMidnight,
      iconIndex: habit.iconIndex,
      isArchived: habit.isArchived,
      category: habit.category,
      frequencyIndex: _indexFromFrequency(habit.frequency),
      customWeekdays: List.from(habit.customWeekdays),
      completionNotes: habit.completions.map((c) => c.note ?? '').toList(),
      targetCountPerDay: habit.targetCountPerDay,
    );
  }

  /// Maps this model to domain entity.
  Habit toEntity() {
    final notes = completionNotes ?? _normalizeNotes(null, completedDatesMs);
    return Habit(
      id: modelId,
      name: modelName,
      completions: _buildCompletions(completedDatesMs, notes),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      reminderMinutesSinceMidnight: reminderMinutesSinceMidnight,
      iconIndex: iconIndex,
      isArchived: isArchived,
      category: category,
      frequency: _frequencyFromIndex(frequencyIndex),
      customWeekdays: List.from(customWeekdays),
      targetCountPerDay: targetCountPerDay,
    );
  }
}
