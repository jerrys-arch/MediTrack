import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

// ── CRITICAL: This callback runs in a separate isolate when the app is killed.
// The @pragma annotation tells the Dart compiler NOT to tree-shake this function.
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
      // ── This is the key fix: register the background handler
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Request permissions on Android 13+
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
          audioAttributesUsage: AudioAttributesUsage.alarm,
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

  // ── Schedule a one-time missed dose alert to the caregiver ────────────────
  // Called after scheduling a patient dose — fires once after graceMinutes

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
      // Use a different ID range for alerts (add 100000 to avoid collision)
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
  // Used to confirm to the caregiver that patient just took a dose

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
    // Also cancel the missed dose alert if it exists
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
}