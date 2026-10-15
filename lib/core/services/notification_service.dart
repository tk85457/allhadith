import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Production Daily Hadith Notification Service
/// Fires daily at:
/// 1. 12:00 PM (Midday Hadith of the Day)
/// 2. 06:00 PM (Evening Sunnah Reminder)
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int _middayNotificationId = 101;
  static const int _eveningNotificationId = 102;

  static const String _channelId = 'hadith_daily_reminders';
  static const String _channelName = 'Daily Hadith Reminders';
  static const String _channelDescription =
      'Receive blessed daily Hadith reminders at 12:00 PM and 6:00 PM';

  static bool _initialized = false;

  /// Initialize notifications on app start
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('Notification clicked: ${details.payload}');
        },
      );

      // Create Android Notification Channel with high importance
      final AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
      );

      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(channel);
        // Request runtime permission for Android 13+ (API 33+)
        await androidImplementation.requestNotificationsPermission();
      }

      // Schedule both daily notifications
      await scheduleDailyReminders();
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Schedule both 12:00 PM and 06:00 PM daily repeating notifications
  static Future<void> scheduleDailyReminders() async {
    try {
      // 1. Midday 12:00 PM Notification
      await _scheduleDailyAtTime(
        id: _middayNotificationId,
        hour: 12,
        minute: 0,
        title: '📖 Hadith of the Day (1 min read)',
        body:
            '“The best among you are those with the best character.” Take a 60-second break & read today’s blessed Hadith.',
      );

      // 2. Evening 06:00 PM Notification
      await _scheduleDailyAtTime(
        id: _eveningNotificationId,
        hour: 18,
        minute: 0,
        title: '🌙 Evening Sunnah Reminder',
        body:
            'Prophet Muhammad (ﷺ) said: “Convey from me even if it is one ayah.” Start your evening with a noble Hadith.',
      );
    } catch (e) {
      debugPrint('Schedule reminders error: $e');
    }
  }

  static Future<void> _scheduleDailyAtTime({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
