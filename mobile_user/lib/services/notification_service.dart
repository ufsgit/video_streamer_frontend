import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive/hive.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int dailyReminderId = 1001;
  static const String channelId = 'video_reminders_alarm_channel_v3';
  static const String channelName = 'Daily Video Reminders';
  static const String channelDescription =
      'Notifications reminding you to watch your daily assigned videos.';

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize timezone database
      tz.initializeTimeZones();
      try {
        final dynamic rawZone = await FlutterTimezone.getLocalTimezone();
        String timeZoneName = '';
        if (rawZone is String) {
          timeZoneName = rawZone;
        } else {
          try {
            timeZoneName = (rawZone.name ?? rawZone.id ?? rawZone.title ?? '').toString();
          } catch (_) {
            timeZoneName = rawZone.toString();
          }
        }
        timeZoneName = timeZoneName.trim();
        if (timeZoneName.contains('Calcutta')) {
          timeZoneName = 'Asia/Kolkata';
        }
        try {
          if (timeZoneName.isNotEmpty) {
            tz.setLocalLocation(tz.getLocation(timeZoneName));
          }
        } catch (_) {
          tz.setLocalLocation(tz.getLocation('UTC'));
        }
      } catch (e) {
        debugPrint('Timezone location setup note: $e');
      }

      // 2. Initialization settings for Android & iOS
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // 3. Create high-importance Android notification channel with sound & vibration
      if (!kIsWeb && Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );
        await androidImplementation?.createNotificationChannel(channel);
      }

      _isInitialized = true;

      // 4. If reminder is already enabled in settings, ensure it is scheduled
      if (isReminderEnabled) {
        final time = getReminderTime();
        await scheduleDailyReminder(hour: time.hour, minute: time.minute, persist: false);
      }
    } catch (e) {
      debugPrint('NotificationService initialize error: $e');
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    try {
      if (Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final bool? androidGranted =
            await androidImplementation?.requestNotificationsPermission();
        await androidImplementation?.requestExactAlarmsPermission();
        return androidGranted ?? true;
      } else if (Platform.isIOS) {
        final iosImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        final bool? iosGranted = await iosImplementation?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return iosGranted ?? false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    return true;
  }

  /// Sends an immediate test notification to verify sound and display
  Future<void> showTestNotification() async {
    if (kIsWeb) return;
    try {
      await initialize();
      await requestPermissions();

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _notificationsPlugin.show(
        999,
        'Daily Video Reminder 🎬',
        'Time to watch your assigned video for today!',
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    bool persist = true,
  }) async {
    // Save to Hive settings box if required
    if (persist) {
      final box = Hive.box('settings');
      await box.put('reminder_enabled', true);
      await box.put('reminder_time_set', true);
      await box.put('reminder_hour', hour);
      await box.put('reminder_minute', minute);
    }

    if (kIsWeb) {
      debugPrint('Local notifications/alarms are not supported on Web browsers.');
      return;
    }

    try {
      await initialize();
      await requestPermissions();
      await cancelDailyReminder(persist: false);

      final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        showWhen: true,
        styleInformation: BigTextStyleInformation(''),
      );

      const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        dailyReminderId,
        'Time to Watch Your Videos 🎬',
        'Stay consistent on your health journey! Check out your assigned videos today.',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('Daily reminder scheduled for $hour:${minute.toString().padLeft(2, '0')} (scheduled epoch: ${scheduledDate.millisecondsSinceEpoch})');
    } catch (e) {
      debugPrint('Error scheduling exact alarm, falling back to inexact: $e');
      try {
        final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
        const AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        );

        const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const NotificationDetails notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: darwinDetails,
        );

        await _notificationsPlugin.zonedSchedule(
          dailyReminderId,
          'Time to Watch Your Videos 🎬',
          'Stay consistent on your health journey! Check out your assigned videos today.',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (inner) {
        debugPrint('Failed to schedule daily reminder: $inner');
      }
    }
  }

  Future<void> cancelDailyReminder({bool persist = true}) async {
    if (persist) {
      final box = Hive.box('settings');
      await box.put('reminder_enabled', false);
    }
    try {
      await _notificationsPlugin.cancel(dailyReminderId);
      debugPrint('Daily reminder cancelled');
    } catch (e) {
      debugPrint('Error cancelling reminder: $e');
    }
  }

  /// Calculates the next local instance of the requested hour:minute accurately
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final DateTime now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);

    // If the scheduled time has already passed today, schedule for tomorrow
    if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return tz.TZDateTime.from(scheduled, tz.local);
  }

  // --- Storage Helper Getters & Setters ---

  bool get isReminderEnabled {
    final box = Hive.box('settings');
    return box.get('reminder_enabled', defaultValue: false) as bool;
  }

  bool get isTimeSet {
    final box = Hive.box('settings');
    return box.get('reminder_time_set', defaultValue: false) as bool;
  }

  TimeOfDay getReminderTime() {
    final box = Hive.box('settings');
    final int hour = box.get('reminder_hour', defaultValue: 20) as int;
    final int minute = box.get('reminder_minute', defaultValue: 0) as int;
    return TimeOfDay(hour: hour, minute: minute);
  }

  bool get hasPromptedInitialReminder {
    final box = Hive.box('settings');
    return box.get('reminder_first_prompt_shown', defaultValue: false) as bool;
  }

  Future<void> markInitialReminderPrompted() async {
    final box = Hive.box('settings');
    await box.put('reminder_first_prompt_shown', true);
  }

  Future<void> markTimeAsSet() async {
    final box = Hive.box('settings');
    await box.put('reminder_time_set', true);
  }
}
