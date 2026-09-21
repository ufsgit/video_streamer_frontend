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
      await _configureTimezone();

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
              AndroidFlutterLocalNotificationsPlugin
            >();
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

      // 4. Request system permissions on real devices if not yet requested
      if (!kIsWeb) {
        await requestPermissions();
      }

      // 5. If reminder is already enabled in settings, ensure it is scheduled
      if (isReminderEnabled) {
        final time = getReminderTime();
        await scheduleDailyReminder(
          hour: time.hour,
          minute: time.minute,
          persist: false,
        );
      }
    } catch (e) {
      debugPrint('NotificationService initialize error: $e');
    }
  }

  /// Reliably configures the local timezone matching the device's clock offset
  Future<void> _configureTimezone() async {
    try {
      final dynamic rawZone = await FlutterTimezone.getLocalTimezone();
      String timeZoneName = '';
      if (rawZone is String) {
        timeZoneName = rawZone.trim();
      } else if (rawZone != null) {
        try {
          timeZoneName = (rawZone.name ?? rawZone.id ?? rawZone.title ?? '').toString().trim();
        } catch (_) {
          timeZoneName = rawZone.toString().trim();
        }
      }

      // Normalization for common aliases
      if (timeZoneName.contains('Calcutta') || timeZoneName == 'IST' || timeZoneName.contains('India')) {
        timeZoneName = 'Asia/Kolkata';
      }

      if (timeZoneName.isNotEmpty) {
        try {
          tz.setLocalLocation(tz.getLocation(timeZoneName));
          debugPrint('Timezone successfully configured as: $timeZoneName');
          return;
        } catch (e) {
          debugPrint('Timezone name "$timeZoneName" not in tz database: $e');
        }
      }

      // Fallback based on device system offset
      final deviceOffset = DateTime.now().timeZoneOffset;
      if (deviceOffset == const Duration(hours: 5, minutes: 30)) {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
        debugPrint('Timezone configured as Asia/Kolkata via offset matching');
        return;
      }

      // Search tz database for any location matching the exact offset
      for (final entry in tz.timeZoneDatabase.locations.entries) {
        final loc = entry.value;
        final nowInLoc = tz.TZDateTime.now(loc);
        if (nowInLoc.timeZoneOffset == deviceOffset) {
          tz.setLocalLocation(loc);
          debugPrint('Timezone configured as ${entry.key} via offset match');
          return;
        }
      }

      tz.setLocalLocation(tz.getLocation('UTC'));
    } catch (e) {
      debugPrint('Error configuring timezone: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    try {
      if (Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final bool? androidGranted = await androidImplementation
            ?.requestNotificationsPermission();
        await androidImplementation?.requestExactAlarmsPermission();
        return androidGranted ?? true;
      } else if (Platform.isIOS) {
        final iosImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
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
        'Daily Video Reminder',
        'Time to watch your videos',
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
  }

  /// Schedules a test reminder that fires in [seconds] from now
  Future<void> scheduleTestReminderInSeconds({int seconds = 10}) async {
    if (kIsWeb) return;
    try {
      await initialize();
      await requestPermissions();

      final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));

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

      try {
        await _notificationsPlugin.zonedSchedule(
          998,
          'Daily Video Reminder',
          'Reminder to watch your videos',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint('exactAllowWhileIdle failed: $e, falling back to inexact');
        await _notificationsPlugin.zonedSchedule(
          998,
          'Daily Video Reminder',
          'Reminder to watch your videos',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
      debugPrint('Test reminder scheduled for $seconds seconds from now ($scheduledDate)');
    } catch (e) {
      debugPrint('Error scheduling test reminder: $e');
    }
  }

  Future<String> scheduleDailyReminder({
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
      debugPrint(
        'Local notifications/alarms are not supported on Web browsers.',
      );
      return 'Web notifications not supported';
    }

    try {
      await initialize();
      await requestPermissions();
      await cancelDailyReminder(persist: false);

      final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      final difference = scheduledDate.difference(now);
      final isToday = scheduledDate.day == now.day && scheduledDate.month == now.month && scheduledDate.year == now.year;
      final timeStr = '${(hour % 12 == 0 ? 12 : hour % 12).toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} ${hour >= 12 ? 'PM' : 'AM'}';
      
      final String scheduledSummary = isToday
          ? 'Today at $timeStr (in ${difference.inHours > 0 ? '${difference.inHours}h ' : ''}${difference.inMinutes % 60}m)'
          : 'Tomorrow at $timeStr';

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

      try {
        await _notificationsPlugin.zonedSchedule(
          dailyReminderId,
          'Daily Video Reminder',
          'Reminder to watch your videos',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        debugPrint('Daily reminder scheduled for $scheduledDate (Summary: $scheduledSummary)');
        return scheduledSummary;
      } catch (e) {
        debugPrint('exactAllowWhileIdle mode failed ($e), trying inexact...');
        await _notificationsPlugin.zonedSchedule(
          dailyReminderId,
          'Daily Video Reminder',
          'Reminder to watch your videos',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        return scheduledSummary;
      }
    } catch (e) {
      debugPrint('Failed to schedule daily reminder: $e');
      return 'Failed: $e';
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
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the scheduled time has already passed today, schedule for tomorrow
    if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
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
