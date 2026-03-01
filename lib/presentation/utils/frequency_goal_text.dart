import 'package:habit_tracker/domain/entities/habit.dart';

/// Short description of [frequency] for use in Goal section: which days count.
String frequencyScheduleDescription(HabitFrequency frequency, List<int> customWeekdays) {
  switch (frequency) {
    case HabitFrequency.daily:
      return 'every day';
    case HabitFrequency.weekdays:
      return 'weekdays (Mon–Fri)';
    case HabitFrequency.custom:
      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final names = customWeekdays.map((w) => labels[w - 1]).toList();
      return names.length == 7 ? 'every day' : 'your chosen days (${names.join(', ')})';
  }
}
