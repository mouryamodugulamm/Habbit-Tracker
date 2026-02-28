// Basic Flutter widget test for the Habit Tracker app.
// Overrides habit repository so tests do not use real Hive.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/main.dart';
import 'package:habit_tracker/presentation/providers/habit_providers.dart';
import 'package:habit_tracker/presentation/providers/settings_provider.dart';
import 'fakes/fake_habit_repository.dart';
import 'fakes/fake_settings_service.dart';

void main() {
  testWidgets('App loads and shows home with app bar title', (WidgetTester tester) async {
    final fakeRepo = FakeHabitRepository();
    final fakeSettings = createFakeSettingsService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitRepositoryProvider.overrideWithValue(fakeRepo),
          settingsServiceProvider.overrideWithValue(fakeSettings),
        ],
        child: const HabitTrackerApp(),
      ),
    );

    expect(find.text('habbit app'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
