/// Pure domain entity. No Hive or framework dependencies.
/// [completedDates] are stored as [DateTime]; only the date part is meaningful for streak logic.
class Habit {
  Habit({
    required this.id,
    required this.name,
    List<DateTime>? completedDates,
    DateTime? createdAt,
    this.reminderMinutesSinceMidnight,
    this.iconIndex,
  })  : completedDates = completedDates ?? const [],
        _createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final List<DateTime> completedDates;
  final DateTime _createdAt;
  /// Optional daily reminder: minutes since midnight (0–1439). Null = no reminder.
  final int? reminderMinutesSinceMidnight;
  /// Index into app's habit icon list. Null = use default (e.g. from id hash).
  final int? iconIndex;

  /// For data-layer mapping only. Do not use in domain logic.
  DateTime get createdAt => _createdAt;

  /// Normalizes to date-only (midnight UTC) for comparison.
  static DateTime toDate(DateTime dateTime) {
    return DateTime.utc(dateTime.year, dateTime.month, dateTime.day);
  }

  /// When [clearReminder] is true, [reminderMinutesSinceMidnight] is set to null.
  Habit copyWith({
    String? id,
    String? name,
    List<DateTime>? completedDates,
    DateTime? createdAt,
    int? reminderMinutesSinceMidnight,
    bool clearReminder = false,
    int? iconIndex,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      completedDates: completedDates ?? List.from(this.completedDates),
      createdAt: createdAt ?? _createdAt,
      reminderMinutesSinceMidnight: clearReminder
          ? null
          : (reminderMinutesSinceMidnight ?? this.reminderMinutesSinceMidnight),
      iconIndex: iconIndex ?? this.iconIndex,
    );
  }

  /// True if this habit has a completion logged for today (date-only).
  bool get isCompletedToday {
    final today = Habit.toDate(DateTime.now());
    return completedDates.any((d) => Habit.toDate(d) == today);
  }

  /// Completion ratio (0.0–1.0) over the last [days] days. Domain logic for stats.
  double completionPercentageLastDays(int days) {
    if (days <= 0) return 0;
    final now = DateTime.now();
    final start = DateTime.utc(now.year, now.month, now.day).subtract(Duration(days: days));
    int completed = 0;
    for (final d in completedDates) {
      final dateOnly = Habit.toDate(d);
      if (!dateOnly.isBefore(start) && !dateOnly.isAfter(Habit.toDate(now))) completed++;
    }
    return (completed / days).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Habit &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          reminderMinutesSinceMidnight == other.reminderMinutesSinceMidnight &&
          iconIndex == other.iconIndex &&
          _listEquals(completedDates, other.completedDates);

  @override
  int get hashCode => Object.hash(id, name, completedDates.length, reminderMinutesSinceMidnight, iconIndex);

  static bool _listEquals(List<DateTime> a, List<DateTime> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (Habit.toDate(a[i]) != Habit.toDate(b[i])) return false;
    }
    return true;
  }
}
