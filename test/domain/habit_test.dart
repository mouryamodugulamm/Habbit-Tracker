import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Habit.toDate', () {
    test('strips time to midnight UTC', () {
      final d = DateTime.utc(2025, 2, 15, 14, 30, 0);
      expect(Habit.toDate(d), DateTime.utc(2025, 2, 15));
    });

    test('same calendar day equals', () {
      expect(
        Habit.toDate(DateTime.utc(2025, 2, 15, 0, 0)),
        Habit.toDate(DateTime.utc(2025, 2, 15, 23, 59)),
      );
    });
  });

  group('Habit.copyWith', () {
    test('updates only provided fields', () {
      final h = Habit(
        id: '1',
        name: 'Run',
        completedDates: [DateTime.utc(2025, 2, 1)],
        reminderMinutesSinceMidnight: 480,
      );
      final h2 = h.copyWith(name: 'Jog');
      expect(h2.id, '1');
      expect(h2.name, 'Jog');
      expect(h2.reminderMinutesSinceMidnight, 480);
    });

    test('clearReminder sets reminder to null', () {
      final h = Habit(
        id: '1',
        name: 'Run',
        reminderMinutesSinceMidnight: 480,
      );
      final h2 = h.copyWith(clearReminder: true);
      expect(h2.reminderMinutesSinceMidnight, isNull);
    });

    test('without clearReminder keeps existing reminder', () {
      final h = Habit(
        id: '1',
        name: 'Run',
        reminderMinutesSinceMidnight: 480,
      );
      final h2 = h.copyWith(name: 'Jog');
      expect(h2.reminderMinutesSinceMidnight, 480);
    });
  });

  group('Habit equality', () {
    test('same id name dates reminder are equal', () {
      final a = Habit(
        id: '1',
        name: 'Run',
        completedDates: [DateTime.utc(2025, 2, 1)],
        reminderMinutesSinceMidnight: 480,
      );
      final b = Habit(
        id: '1',
        name: 'Run',
        completedDates: [DateTime.utc(2025, 2, 1)],
        reminderMinutesSinceMidnight: 480,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different reminder breaks equality', () {
      final a = Habit(id: '1', name: 'Run', reminderMinutesSinceMidnight: 480);
      final b = Habit(id: '1', name: 'Run', reminderMinutesSinceMidnight: 540);
      expect(a, isNot(equals(b)));
    });
  });

  group('Habit.isCompletedToday', () {
    test('true when today is in completedDates', () {
      final now = DateTime.now();
      final today = DateTime.utc(now.year, now.month, now.day);
      final h = Habit(id: '1', name: 'Run', completedDates: [today]);
      expect(h.isCompletedToday, isTrue);
    });

    test('false when no completion today', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final h = Habit(
        id: '1',
        name: 'Run',
        completedDates: [Habit.toDate(yesterday)],
      );
      expect(h.isCompletedToday, isFalse);
    });
  });

  group('Habit.completionPercentageLastDays', () {
    test('zero for days <= 0', () {
      final h = Habit(id: '1', name: 'Run', completedDates: [DateTime.utc(2025, 2, 1)]);
      expect(h.completionPercentageLastDays(0), 0);
      expect(h.completionPercentageLastDays(-1), 0);
    });

    test('ratio within window', () {
      final now = DateTime.now();
      final today = Habit.toDate(now);
      final h = Habit(id: '1', name: 'Run', completedDates: [today]);
      expect(h.completionPercentageLastDays(1), 1.0);
      expect(h.completionPercentageLastDays(10), 0.1);
    });
  });
}
