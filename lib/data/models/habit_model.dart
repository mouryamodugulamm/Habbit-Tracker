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
  final int? iconIndex;

  HabitModel({
    required this.modelId,
    required this.modelName,
    List<int>? completedDatesMs,
    int? createdAtMs,
    this.reminderMinutesSinceMidnight,
    this.iconIndex,
  })  : completedDatesMs = completedDatesMs ?? [],
        createdAtMs = createdAtMs ?? DateTime.now().millisecondsSinceEpoch,
        super(
          id: modelId,
          name: modelName,
          completedDates: (completedDatesMs ?? [])
              .map((ms) => DateTime.fromMillisecondsSinceEpoch(ms))
              .toList(),
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            createdAtMs ?? DateTime.now().millisecondsSinceEpoch,
          ),
          reminderMinutesSinceMidnight: reminderMinutesSinceMidnight,
          iconIndex: iconIndex,
        );

  /// Maps from domain entity to model for storage.
  factory HabitModel.fromEntity(Habit habit) {
    return HabitModel(
      modelId: habit.id,
      modelName: habit.name,
      completedDatesMs: habit.completedDates
          .map((d) => d.millisecondsSinceEpoch)
          .toList(),
      createdAtMs: habit.createdAt.millisecondsSinceEpoch,
      reminderMinutesSinceMidnight: habit.reminderMinutesSinceMidnight,
      iconIndex: habit.iconIndex,
    );
  }

  /// Maps this model to domain entity.
  Habit toEntity() {
    return Habit(
      id: modelId,
      name: modelName,
      completedDates: completedDatesMs
          .map((ms) => DateTime.fromMillisecondsSinceEpoch(ms))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      reminderMinutesSinceMidnight: reminderMinutesSinceMidnight,
      iconIndex: iconIndex,
    );
  }
}
