import 'package:habit_tracker/domain/repositories/habit_repository.dart';

/// Use case: delete a habit by id.
class DeleteHabit {
  DeleteHabit(this._repository);

  final HabitRepository _repository;

  Future<void> execute(String habitId) async {
    await _repository.deleteHabit(habitId);
  }
}
