import 'package:hive_flutter/hive_flutter.dart';

import 'package:habit_tracker/core/errors/exceptions.dart';
import 'package:habit_tracker/data/models/habit_model.dart';

/// Local persistence for habits using the Hive "habits" box.
/// The box must be opened (e.g. in main) before any method is called.
class HabitLocalDataSource {
  HabitLocalDataSource({required String habitsBoxName})
      : _habitsBoxName = habitsBoxName;

  final String _habitsBoxName;

  Box<HabitModel> get _box => Hive.box<HabitModel>(_habitsBoxName);

  /// Returns all stored habits. Empty list if none.
  Future<List<HabitModel>> getAll() async {
    try {
      final box = _box;
      return box.values.toList();
    } catch (e) {
      throw StorageException('Failed to get habits', e);
    }
  }

  /// Returns the habit with [id], or null if not found.
  Future<HabitModel?> getById(String id) async {
    try {
      return _box.get(id);
    } catch (e) {
      throw StorageException('Failed to get habit by id', e);
    }
  }

  /// Stores [habit] using [habit.modelId] as key (habits box keyed by id).
  Future<void> put(HabitModel habit) async {
    try {
      await _box.put(habit.modelId, habit);
    } catch (e) {
      throw StorageException('Failed to save habit', e);
    }
  }

  /// Removes the habit with [id]. No-op if key does not exist.
  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw StorageException('Failed to delete habit', e);
    }
  }

  /// Removes all habits from the box.
  Future<void> clearAll() async {
    try {
      await _box.clear();
    } catch (e) {
      throw StorageException('Failed to clear habits', e);
    }
  }
}
