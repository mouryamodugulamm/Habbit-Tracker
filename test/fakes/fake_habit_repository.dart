import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/repositories/habit_repository.dart';

/// Fake repository for tests. No Hive; returns empty list and no-ops mutations.
class FakeHabitRepository implements HabitRepository {
  @override
  Future<void> addHabit(Habit habit) async {}

  @override
  Future<void> deleteHabit(String id) async {}

  @override
  Future<List<Habit>> getHabits() async => [];

  @override
  Future<Habit?> getHabitById(String id) async => null;

  @override
  Future<void> updateHabit(Habit habit) async {}
}
