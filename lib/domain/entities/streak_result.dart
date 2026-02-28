/// Result of streak calculation: current run and longest run.
class StreakResult {
  const StreakResult({
    required this.currentStreak,
    required this.longestStreak,
  });

  final int currentStreak;
  final int longestStreak;
}
