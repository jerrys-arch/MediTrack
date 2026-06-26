import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  debugPrint('Background notification tapped: ${response.payload}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    try {
      final dynamic timezoneResponse =
          await FlutterTimezone.getLocalTimezone();
      String locationId = (timezoneResponse is String)
          ? timezoneResponse
          : timezoneResponse.name.toString();
      tz.setLocalLocation(tz.getLocation(locationId));
      debugPrint('✅ Timezone set to: $locationId');
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Africa/Addis_Ababa'));
    }

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
      await androidImpl.requestExactAlarmsPermission();
    }
  }

  // ── Schedule a daily medication reminder ──────────────────────────────────

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'med_reminders_v5',
          'Medication Reminders',
          channelDescription: 'Daily medication reminders',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          ongoing: false,
          autoCancel: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    debugPrint('⏰ Daily reminder scheduled for $hour:$minute (id: $id)');
  }

  // ── Schedule a weekly medication reminder ─────────────────────────────────
  // dayOfWeek: 0=Monday ... 6=Sunday (matches Django's day_of_week field)

  Future<void> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek,
    required int hour,
    required int minute,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfWeekday(dayOfWeek, hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'med_reminders_v5',
          'Medication Reminders',
          channelDescription: 'Weekly medication reminders',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          ongoing: false,
          autoCancel: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
    debugPrint(
        '⏰ Weekly reminder scheduled for day $dayOfWeek at $hour:$minute (id: $id)');
  }

  // ── Schedule a one-time missed dose alert to the caregiver ────────────────

  Future<void> scheduleMissedDoseAlert({
    required int id,
    required String patientName,
    required String medicationName,
    required int hour,
    required int minute,
    int graceMinutes = 60,
  }) async {
    final fireTime = _nextInstanceOfTime(hour, minute)
        .add(Duration(minutes: graceMinutes));

    await _notifications.zonedSchedule(
      id + 100000,
      '⚠️ Missed dose — $patientName',
      '$patientName has not confirmed taking $medicationName',
      fireTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'missed_dose_alerts',
          'Missed Dose Alerts',
          channelDescription: 'Alerts when a patient misses a dose',
          importance: Importance.max,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
          autoCancel: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    debugPrint(
        '🔔 Missed dose alert scheduled for $graceMinutes min after $hour:$minute');
  }

  // ── Show an immediate notification ────────────────────────────────────────

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'dose_confirmed',
          'Dose Confirmations',
          channelDescription: 'Confirms when a patient takes their medication',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          autoCancel: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // ── Cancel a specific notification ────────────────────────────────────────

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    await _notifications.cancel(id + 100000);
  }

  // ── Cancel all notifications ───────────────────────────────────────────────

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  // dayOfWeek: 0=Monday ... 6=Sunday. Dart's TZDateTime.weekday is 1=Monday..7=Sunday
  tz.TZDateTime _nextInstanceOfWeekday(int dayOfWeek, int hour, int minute) {
    tz.TZDateTime scheduled = _nextInstanceOfTime(hour, minute);
    // Convert our 0-6 (Mon-Sun) to Dart's 1-7 (Mon-Sun)
    final targetWeekday = dayOfWeek + 1;
    while (scheduled.weekday != targetWeekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}