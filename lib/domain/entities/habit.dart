/// Frequency of the habit: which days count for streak and "today".
enum HabitFrequency {
  /// Every day counts.
  daily,
  /// Monday–Friday only.
  weekdays,
  /// Only [customWeekdays] (1 = Monday … 7 = Sunday).
  custom,
}

/// A single completion entry: time and optional note. Supports multiple completions per day.
class HabitCompletion {
  const HabitCompletion(this.completedAt, [this.note]);

  final DateTime completedAt;
  final String? note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitCompletion &&
          runtimeType == other.runtimeType &&
          completedAt == other.completedAt &&
          note == other.note;

  @override
  int get hashCode => Object.hash(completedAt, note);
}

/// Pure domain entity. No Hive or framework dependencies.
/// Completions hold time and optional note; [completedDates] is derived for streak/calendar.
class Habit {
  Habit({
    required this.id,
    required this.name,
    List<DateTime>? completedDates,
    List<HabitCompletion>? completions,
    DateTime? createdAt,
    this.reminderMinutesSinceMidnight,
    this.iconIndex,
    this.isArchived = false,
    this.category,
    this.frequency = HabitFrequency.daily,
    List<int>? customWeekdays,
    this.targetCountPerDay,
  })  : _completions = completions ?? _datesToCompletions(completedDates ?? const []),
        _createdAt = createdAt ?? DateTime.now(),
        customWeekdays = customWeekdays ?? const [];

  static List<HabitCompletion> _datesToCompletions(List<DateTime> dates) {
    return dates.map((d) => HabitCompletion(DateTime.utc(d.year, d.month, d.day))).toList();
  }

  final String id;
  final String name;

  /// Completion entries (time + optional note). Source of truth; [completedDates] is derived.
  List<HabitCompletion> get completions => _completions ?? const [];
  final List<HabitCompletion>? _completions;

  /// Derived list of completion times for streak/calendar. Prefer [completions] when time/note needed.
  List<DateTime> get completedDates => completions.map((c) => c.completedAt).toList();

  final DateTime _createdAt;

  /// Optional daily reminder: minutes since midnight (0–1439). Null = no reminder.
  final int? reminderMinutesSinceMidnight;

  /// Index into app's habit icon list. Null = use default (e.g. from id hash).
  final int? iconIndex;

  /// When true, habit is hidden from main list and can be restored from archived view.
  final bool isArchived;

  /// Optional category for filtering (e.g. "Health", "Work").
  final String? category;

  /// Which days count for streak and "today". [customWeekdays] used when frequency is [HabitFrequency.custom] (1 = Mon … 7 = Sun).
  final HabitFrequency frequency;
  final List<int> customWeekdays;

  /// Target completions per day (e.g. 3 for "Drink 3 glasses of water"). Null or 1 = once per day.
  final int? targetCountPerDay;

  /// Effective target per day: 1 if [targetCountPerDay] is null or < 1.
  int get effectiveTargetPerDay => (targetCountPerDay == null || targetCountPerDay! < 1) ? 1 : targetCountPerDay!;

  /// True if [date] is a scheduled day for this habit (counts for streak / today).
  bool isScheduledOn(DateTime date) {
    final weekday = date.weekday; // 1 = Mon, 7 = Sun
    switch (frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.weekdays:
        return weekday >= 1 && weekday <= 5;
      case HabitFrequency.custom:
        return customWeekdays.contains(weekday);
    }
  }

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
    List<HabitCompletion>? completions,
    DateTime? createdAt,
    int? reminderMinutesSinceMidnight,
    bool clearReminder = false,
    int? iconIndex,
    bool? isArchived,
    String? category,
    bool clearCategory = false,
    HabitFrequency? frequency,
    List<int>? customWeekdays,
    int? targetCountPerDay,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      completedDates: completedDates,
      completions: completions ?? (completedDates != null ? _datesToCompletions(completedDates) : List.from(this.completions)),
      createdAt: createdAt ?? _createdAt,
      reminderMinutesSinceMidnight: clearReminder
          ? null
          : (reminderMinutesSinceMidnight ?? this.reminderMinutesSinceMidnight),
      iconIndex: iconIndex ?? this.iconIndex,
      isArchived: isArchived ?? this.isArchived,
      category: clearCategory ? null : (category ?? this.category),
      frequency: frequency ?? this.frequency,
      customWeekdays: customWeekdays ?? List.from(this.customWeekdays),
      targetCountPerDay: targetCountPerDay ?? this.targetCountPerDay,
    );
  }

  /// True if this habit has a completion logged for today (date-only).
  bool get isCompletedToday => isCompletedOn(DateTime.now());

  /// True if this habit is "done" for [date]: on scheduled days, has at least [effectiveTargetPerDay] completions (or any completion when target is 1).
  bool isCompletedOn(DateTime date) {
    if (!isScheduledOn(date)) return false;
    final count = completedCountOn(date);
    return count >= effectiveTargetPerDay;
  }

  /// Number of completions on [date] (for habits with target per day). Only scheduled days count.
  int completedCountOn(DateTime date) {
    if (!isScheduledOn(date)) return 0;
    final target = Habit.toDate(date);
    return completions.where((c) => Habit.toDate(c.completedAt) == target).length;
  }

  /// Number of distinct days where the habit was fully completed (reps met). For goals: count 1 per day, not per rep.
  int get completedDaysCount {
    final dates = completions.map((c) => Habit.toDate(c.completedAt)).toSet();
    return dates.where((d) => isCompletedOn(d)).length;
  }

  /// Completion ratio (0.0–1.0) over the last [days] days, counting only scheduled days.
  /// Uses micro-completions: each day contributes min(completedCount, target) / target (so 2/3 on a day counts as 2/3).
  double completionPercentageLastDays(int days) {
    if (days <= 0) return 0;
    final now = DateTime.now();
    final target = effectiveTargetPerDay;
    double ratioSum = 0;
    int scheduledCount = 0;
    for (int i = 0; i < days; i++) {
      final d = DateTime.utc(now.year, now.month, now.day).subtract(Duration(days: i));
      if (isScheduledOn(d)) {
        scheduledCount++;
        final count = completedCountOn(d);
        ratioSum += (count >= target ? 1.0 : count / target);
      }
    }
    if (scheduledCount == 0) return 0;
    return (ratioSum / scheduledCount).clamp(0.0, 1.0);
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
          isArchived == other.isArchived &&
          category == other.category &&
          frequency == other.frequency &&
          targetCountPerDay == other.targetCountPerDay &&
          _listEqualsInt(customWeekdays, other.customWeekdays) &&
          _listEqualsCompletion(completions, other.completions);

  @override
  int get hashCode => Object.hash(
        id,
        name,
        completions.length,
        reminderMinutesSinceMidnight,
        iconIndex,
        isArchived,
        category,
        frequency,
        targetCountPerDay,
        Object.hashAll(customWeekdays),
      );

  static bool _listEqualsInt(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _listEqualsCompletion(List<HabitCompletion> a, List<HabitCompletion> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
