import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:habit_tracker/core/constants/app_constants.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules and cancels daily habit reminders. Requires [initialize] to be called once (e.g. from main).
class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const String _channelId = 'habit_reminders';
  static const String _channelName = 'Habit reminders';

  /// Initialize timezone data, set local timezone, and the plugin. Call once before [scheduleDailyReminder].
  static Future<FlutterLocalNotificationsPlugin> initialize() async {
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      developer.log('Timezone fallback to UTC', name: 'NotificationService', error: e);
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    final plugin = FlutterLocalNotificationsPlugin();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
    );
    const initSettings = InitializationSettings(android: android, iOS: ios);
    await plugin.initialize(initSettings);

    if (Platform.isAndroid) {
      await plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Daily reminders for habits',
          importance: Importance.defaultImportance,
        ),
      );
    }

    return plugin;
  }

  /// Request notification permission (Android 13+, iOS). Call after [initialize].
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final result = await android?.requestNotificationsPermission();
      return result == true;
    }
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final result = await ios?.requestPermissions(alert: true);
      return result == true;
    }
    return true;
  }

  static int _notificationId(String habitId) {
    return habitId.hashCode.abs() % AppConstants.notificationIdMax;
  }

  /// Schedules a daily reminder at [minutesSinceMidnight] (0–1439). Replaces any existing reminder for this habit.
  Future<void> scheduleDailyReminder(
    String habitId,
    String habitName,
    int minutesSinceMidnight,
  ) async {
    final id = _notificationId(habitId);
    final hour = minutesSinceMidnight ~/ 60;
    final minute = minutesSinceMidnight % 60;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Daily reminders for habits',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      id,
      'Habit reminder',
      habitName,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancels the daily reminder for [habitId]. No-op if none scheduled.
  Future<void> cancelReminder(String habitId) async {
    final id = _notificationId(habitId);
    await _plugin.cancel(id);
  }
}
