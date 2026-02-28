/// Goal tied to a habit: user aims to reach [targetValue] of [targetType] (e.g. 30 total days or 7-day streak).
/// When achieved or abandoned, [completedAt] or [closedAt] is set.
class Goal {
  Goal({
    required this.id,
    required this.habitId,
    required this.targetType,
    required this.targetValue,
    this.completedAt,
    this.closedAt,
    DateTime? createdAt,
  }) : _createdAt = createdAt ?? DateTime.now();

  final String id;
  final String habitId;
  final GoalTargetType targetType;
  final int targetValue;
  final DateTime? completedAt;
  final DateTime? closedAt;
  final DateTime _createdAt;

  DateTime get createdAt => _createdAt;

  bool get isCompleted => completedAt != null;
  bool get isClosed => closedAt != null;
  bool get isActive => !isCompleted && !isClosed;

  Goal copyWith({
    String? id,
    String? habitId,
    GoalTargetType? targetType,
    int? targetValue,
    DateTime? completedAt,
    DateTime? closedAt,
    bool clearCompleted = false,
    bool clearClosed = false,
    DateTime? createdAt,
  }) {
    return Goal(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      targetType: targetType ?? this.targetType,
      targetValue: targetValue ?? this.targetValue,
      completedAt: clearCompleted ? null : (completedAt ?? this.completedAt),
      closedAt: clearClosed ? null : (closedAt ?? this.closedAt),
      createdAt: createdAt ?? _createdAt,
    );
  }
}

enum GoalTargetType {
  totalDays,
  streak,
}
