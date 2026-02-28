import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:habit_tracker/core/core.dart';
import 'package:habit_tracker/data/models/goal_model.dart';
import 'package:habit_tracker/data/models/habit_model.dart';
import 'package:habit_tracker/data/services/notification_service.dart';
import 'package:habit_tracker/data/services/settings_service.dart';
import 'package:habit_tracker/presentation/providers/habit_providers.dart';
import 'package:habit_tracker/presentation/providers/settings_provider.dart';
import 'package:habit_tracker/presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final settingsService = SettingsService(prefs);

  await _initHive();

  final notificationService = await _initNotifications();
  final overrides = [
    settingsServiceProvider.overrideWithValue(settingsService),
    if (notificationService != null)
      notificationServiceProvider.overrideWithValue(notificationService),
  ];

  runApp(
    ProviderScope(
      overrides: overrides,
      child: const HabitTrackerApp(),
    ),
  );
}

Future<void> _initHive() async {
  await Hive.initFlutter();
  _registerHiveAdapters();
  await Hive.openBox<HabitModel>(AppConstants.habitsBoxName);
  await Hive.openBox<GoalModel>(AppConstants.goalsBoxName);
}

void _registerHiveAdapters() {
  Hive.registerAdapter(HabitModelAdapter());
  Hive.registerAdapter(GoalModelAdapter());
}

/// Initializes flutter_local_notifications and timezone. Requests permission. Returns [NotificationService] or null on failure.
Future<NotificationService?> _initNotifications() async {
  try {
    final plugin = await NotificationService.initialize();
    final service = NotificationService(plugin);
    await service.requestPermission();
    return service;
  } catch (e, stack) {
    assert(() {
      // ignore: avoid_print
      print('NotificationService init failed: $e\n$stack');
      return true;
    }());
    return null;
  }
}

class HabitTrackerApp extends ConsumerWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      home: const HomeScreen(),
    );
  }
}
