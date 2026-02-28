import 'package:hive/hive.dart';

import 'package:habit_tracker/domain/entities/goal.dart';

part 'goal_model.g.dart';

@HiveType(typeId: 1)
class GoalModel extends HiveObject {
  @HiveField(0)
  final String modelId;

  @HiveField(1)
  final String habitId;

  @HiveField(2)
  final int targetTypeIndex;

  @HiveField(3)
  final int targetValue;

  @HiveField(4)
  final int? completedAtMs;

  @HiveField(5)
  final int? closedAtMs;

  @HiveField(6)
  final int createdAtMs;

  GoalModel({
    required this.modelId,
    required this.habitId,
    required this.targetTypeIndex,
    required this.targetValue,
    this.completedAtMs,
    this.closedAtMs,
    int? createdAtMs,
  }) : createdAtMs = createdAtMs ?? DateTime.now().millisecondsSinceEpoch;

  static GoalTargetType _typeFromIndex(int i) {
    switch (i) {
      case 1:
        return GoalTargetType.streak;
      default:
        return GoalTargetType.totalDays;
    }
  }

  static int _indexFromType(GoalTargetType t) {
    switch (t) {
      case GoalTargetType.streak:
        return 1;
      default:
        return 0;
    }
  }

  factory GoalModel.fromEntity(Goal goal) {
    return GoalModel(
      modelId: goal.id,
      habitId: goal.habitId,
      targetTypeIndex: _indexFromType(goal.targetType),
      targetValue: goal.targetValue,
      completedAtMs: goal.completedAt?.millisecondsSinceEpoch,
      closedAtMs: goal.closedAt?.millisecondsSinceEpoch,
      createdAtMs: goal.createdAt.millisecondsSinceEpoch,
    );
  }

  Goal toEntity() {
    return Goal(
      id: modelId,
      habitId: habitId,
      targetType: _typeFromIndex(targetTypeIndex),
      targetValue: targetValue,
      completedAt: completedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(completedAtMs!)
          : null,
      closedAt: closedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(closedAtMs!)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
    );
  }
}
