import 'package:flutter/material.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/presentation/screens/add_habit_screen.dart';
import 'package:habit_tracker/presentation/screens/data_privacy_screen.dart';
import 'package:habit_tracker/presentation/screens/edit_habit_screen.dart';
import 'package:habit_tracker/presentation/screens/goals_screen.dart';
import 'package:habit_tracker/presentation/screens/habit_detail_screen.dart';
import 'package:habit_tracker/presentation/screens/profile_screen.dart';

/// Central navigation helpers. Use from screens to push routes.
abstract final class AppRouter {
  AppRouter._();

  static Future<void> toAddHabit(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const AddHabitScreen()),
    );
  }

  static Future<void> toHabitDetail(BuildContext context, String habitId) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => HabitDetailScreen(habitId: habitId),
      ),
    );
  }

  static Future<void> toGoals(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const GoalsScreen()),
    );
  }

  static Future<void> toProfile(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  static Future<void> toDataPrivacy(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const DataPrivacyScreen()),
    );
  }

  static Future<void> toEditHabit(BuildContext context, Habit habit) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => EditHabitScreen(habit: habit)),
    );
  }
}
