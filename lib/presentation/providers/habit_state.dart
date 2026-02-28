import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/domain/entities/habit.dart';

/// Presentation state for the habits list. Business logic lives in use cases.
final class HabitState {
  const HabitState({required this.habits});

  /// Loading / data / error for the list of habits. Updates after load and mutations.
  final AsyncValue<List<Habit>> habits;

  /// Initial state before first load.
  static HabitState get initial => HabitState(habits: const AsyncValue.loading());

  HabitState copyWith({AsyncValue<List<Habit>>? habits}) {
    return HabitState(habits: habits ?? this.habits);
  }
}
