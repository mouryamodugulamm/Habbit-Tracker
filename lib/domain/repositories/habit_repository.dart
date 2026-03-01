import 'package:habit_tracker/domain/entities/habit.dart';

/// Abstract contract for habit persistence. Implemented in the data layer.
abstract class HabitRepository {
  Future<void> addHabit(Habit habit);
  Future<void> deleteHabit(String id);
  Future<List<Habit>> getHabits();
  Future<Habit?> getHabitById(String id);
  Future<void> updateHabit(Habit habit);
  Future<void> clearAll();
}
