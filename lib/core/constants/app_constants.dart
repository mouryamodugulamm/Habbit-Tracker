/// App-wide constants. Add storage keys, default values, and feature flags here.
abstract final class AppConstants {
  AppConstants._();

  static const String appTitle = 'habbit app';

  /// Hive box names (register in main.dart when boxes are used).
  static const String habitsBoxName = 'habits';
  static const String completionsBoxName = 'completions';
  static const String settingsBoxName = 'settings';
  static const String goalsBoxName = 'goals';

  /// Default window (days) for completion percentage in detail screen.
  static const int completionPercentageDays = 30;

  /// Max habit name length (validation and storage).
  static const int maxHabitNameLength = 100;

  /// Max notification id (positive 31-bit) for mapping habit id to notification id.
  static const int notificationIdMax = 0x7FFFFFFF;
}
