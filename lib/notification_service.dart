import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initializeNotifications() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Make sure this icon exists or use default

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'dhikr_channel',
        'Dhikr Notifications',
        channelDescription: 'Daily reminders for Dhikr',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: true, // Use default soft sound
      ),
      iOS: DarwinNotificationDetails(
        presentSound: true, // Use default soft sound
      ),
      linux: LinuxNotificationDetails(),
    );
  }

  Future<void> scheduleMorningDhikr() async {
    await _scheduleDailyNotification(
      id: 1,
      title: 'أذكار الصباح',
      body: 'ابدأ يومك بذكر الله 🌅',
      hour: 7,
      minute: 0,
    );
  }

  Future<void> scheduleEveningDhikr() async {
    await _scheduleDailyNotification(
      id: 2,
      title: 'أذكار المساء',
      body: 'لا تنسَ أذكار المساء 🌙',
      hour: 18,
      minute: 0, // 6:00 PM
    );
  }

  Future<void> scheduleNightDhikr() async {
    await _scheduleDailyNotification(
      id: 3,
      title: 'أذكار النوم',
      body: 'اختم يومك بذكر الله 😴',
      hour: 22,
      minute: 30, // 10:30 PM
    );
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    // zonedSchedule is not implemented on Linux, only on Android, iOS and macOS.
    if (Platform.isLinux) {
      debugPrint('Scheduling notifications is not supported on Linux.');
      return;
    }
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(hour, minute),
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Error scheduling notification $id: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelAllDhikrNotifications() async {
    await _notificationsPlugin.cancel(1);
    await _notificationsPlugin.cancel(2);
    await _notificationsPlugin.cancel(3);
  }

  Future<void> rescheduleAllDhikrNotifications() async {
    await cancelAllDhikrNotifications();
    await scheduleMorningDhikr();
    await scheduleEveningDhikr();
    await scheduleNightDhikr();
  }

  Future<void> showTestNotification() async {
    try {
      await _notificationsPlugin.show(
        999, // Unique ID for test notification
        'اختبار الإشعارات',
        'الإشعارات تعمل بنجاح 🌙',
        _notificationDetails(),
      );
    } catch (e) {
      debugPrint('Error showing test notification: $e');
    }
  }
}
