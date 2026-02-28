import 'package:habit_tracker/data/datasources/habit_local_datasource.dart';
import 'package:habit_tracker/data/models/habit_model.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/repositories/habit_repository.dart';

/// Implementation of [HabitRepository] using the Hive "habits" box via [HabitLocalDataSource].
class HabitRepositoryImpl implements HabitRepository {
  HabitRepositoryImpl(this._dataSource);

  final HabitLocalDataSource _dataSource;

  @override
  Future<void> addHabit(Habit habit) async {
    final model = HabitModel.fromEntity(habit);
    await _dataSource.put(model);
  }

  @override
  Future<void> deleteHabit(String id) async {
    await _dataSource.delete(id);
  }

  @override
  Future<List<Habit>> getHabits() async {
    final models = await _dataSource.getAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Habit?> getHabitById(String id) async {
    final model = await _dataSource.getById(id);
    return model?.toEntity();
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    final model = HabitModel.fromEntity(habit);
    await _dataSource.put(model);
  }
}
