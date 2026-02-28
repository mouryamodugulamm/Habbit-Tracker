import 'package:hive_flutter/hive_flutter.dart';

import 'package:habit_tracker/core/errors/exceptions.dart';
import 'package:habit_tracker/data/models/goal_model.dart';

class GoalLocalDataSource {
  GoalLocalDataSource({required String goalsBoxName}) : _goalsBoxName = goalsBoxName;

  final String _goalsBoxName;

  Future<void> _ensureBoxOpen() async {
    if (!Hive.isBoxOpen(_goalsBoxName)) {
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(GoalModelAdapter());
      }
      await Hive.openBox<GoalModel>(_goalsBoxName);
    }
  }

  Box<GoalModel> get _box => Hive.box<GoalModel>(_goalsBoxName);

  Future<List<GoalModel>> getAll() async {
    await _ensureBoxOpen();
    try {
      return _box.values.toList();
    } catch (e) {
      throw StorageException('Failed to get goals', e);
    }
  }

  Future<GoalModel?> getById(String id) async {
    await _ensureBoxOpen();
    try {
      return _box.get(id);
    } catch (e) {
      throw StorageException('Failed to get goal by id', e);
    }
  }

  Future<GoalModel?> getByHabitId(String habitId) async {
    await _ensureBoxOpen();
    try {
      for (final g in _box.values) {
        if (g.habitId == habitId) return g;
      }
      return null;
    } catch (e) {
      throw StorageException('Failed to get goal by habitId', e);
    }
  }

  Future<void> put(GoalModel goal) async {
    await _ensureBoxOpen();
    try {
      await _box.put(goal.modelId, goal);
    } catch (e) {
      throw StorageException('Failed to save goal', e);
    }
  }

  Future<void> delete(String id) async {
    await _ensureBoxOpen();
    try {
      await _box.delete(id);
    } catch (e) {
      throw StorageException('Failed to delete goal', e);
    }
  }

  Future<void> deleteByHabitId(String habitId) async {
    await _ensureBoxOpen();
    try {
      final toRemove = <String>[];
      for (final e in _box.keys) {
        final g = _box.get(e);
        if (g != null && g.habitId == habitId) toRemove.add(g.modelId);
      }
      for (final id in toRemove) {
        await _box.delete(id);
      }
    } catch (e) {
      throw StorageException('Failed to delete goals for habit', e);
    }
  }
}
