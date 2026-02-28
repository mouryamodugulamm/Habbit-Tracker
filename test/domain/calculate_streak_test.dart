import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/usecases/calculate_streak.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CalculateStreak calculateStreak;

  setUp(() {
    calculateStreak = CalculateStreak();
  });

  test('empty completedDates returns 0/0', () {
    final habit = Habit(id: '1', name: 'Run', completedDates: []);
    final result = calculateStreak.execute(habit);
    expect(result.currentStreak, 0);
    expect(result.longestStreak, 0);
  });

  test('single day gives current 1 longest 1', () {
    final habit = Habit(
      id: '1',
      name: 'Run',
      completedDates: [DateTime.utc(2025, 2, 1)],
    );
    final result = calculateStreak.execute(habit);
    expect(result.currentStreak, 1);
    expect(result.longestStreak, 1);
  });

  test('consecutive 3 days gives current 3 longest 3', () {
    final habit = Habit(
      id: '1',
      name: 'Run',
      completedDates: [
        DateTime.utc(2025, 2, 1),
        DateTime.utc(2025, 2, 2),
        DateTime.utc(2025, 2, 3),
      ],
    );
    final result = calculateStreak.execute(habit);
    expect(result.currentStreak, 3);
    expect(result.longestStreak, 3);
  });

  test('gap resets current streak; longest is preserved', () {
    final habit = Habit(
      id: '1',
      name: 'Run',
      completedDates: [
        DateTime.utc(2025, 2, 1),
        DateTime.utc(2025, 2, 2),
        DateTime.utc(2025, 2, 3),
        DateTime.utc(2025, 2, 5),
        DateTime.utc(2025, 2, 6),
      ],
    );
    final result = calculateStreak.execute(habit);
    expect(result.currentStreak, 2);
    expect(result.longestStreak, 3);
  });

  test('same day duplicates count as one', () {
    final habit = Habit(
      id: '1',
      name: 'Run',
      completedDates: [
        DateTime.utc(2025, 2, 1, 8, 0),
        DateTime.utc(2025, 2, 1, 20, 0),
      ],
    );
    final result = calculateStreak.execute(habit);
    expect(result.currentStreak, 1);
    expect(result.longestStreak, 1);
  });
}
