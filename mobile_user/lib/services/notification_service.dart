import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive/hive.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../core/storage/session_manager.dart';
import 'api_service.dart';

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
          timeZoneName = (rawZone.name ?? rawZone.id ?? rawZone.title ?? '')
              .toString()
              .trim();
        } catch (_) {
          timeZoneName = rawZone.toString().trim();
        }
      }

      // Normalization for common aliases
      if (timeZoneName.contains('Calcutta') ||
          timeZoneName == 'IST' ||
          timeZoneName.contains('India')) {
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

      final tz.TZDateTime scheduledDate = tz.TZDateTime.now(
        tz.local,
      ).add(Duration(seconds: seconds));

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
      debugPrint(
        'Test reminder scheduled for $seconds seconds from now ($scheduledDate)',
      );
    } catch (e) {
      debugPrint('Error scheduling test reminder: $e');
    }
  }

  Future<String> scheduleDailyReminder({
    required int hour,
    required int minute,
    String? title,
    String? body,
    bool persist = true,
    bool syncToServer = true,
    int? userId,
  }) async {
    // Save to Hive settings box if required
    if (persist) {
      final box = Hive.box('settings');
      await box.put('reminder_enabled', true);
      await box.put('reminder_time_set', true);
      await box.put('reminder_hour', hour);
      await box.put('reminder_minute', minute);
    }

    if (syncToServer && persist) {
      // Fire-and-forget sync to server so local alarm scheduling is instantaneous
      syncReminderToServer(
        hour: hour,
        minute: minute,
        isEnabled: true,
        userId: userId,
      );
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
      await cancelDailyReminder(persist: false, syncToServer: false);

      final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      final difference = scheduledDate.difference(now);
      final isToday =
          scheduledDate.day == now.day &&
          scheduledDate.month == now.month &&
          scheduledDate.year == now.year;
      final timeStr =
          '${(hour % 12 == 0 ? 12 : hour % 12).toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} ${hour >= 12 ? 'PM' : 'AM'}';

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

      final String notifTitle =
          title ??
          (Hive.box('settings').get('reminder_title') as String?) ??
          'Daily Video Reminder';
      final String notifBody =
          body ??
          (Hive.box('settings').get('reminder_message') as String?) ??
          'Reminder to watch your videos';

      try {
        await _notificationsPlugin.zonedSchedule(
          dailyReminderId,
          notifTitle,
          notifBody,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        debugPrint(
          'Daily reminder scheduled for $scheduledDate (Summary: $scheduledSummary)',
        );
        return scheduledSummary;
      } catch (e) {
        debugPrint('exactAllowWhileIdle mode failed ($e), trying inexact...');
        await _notificationsPlugin.zonedSchedule(
          dailyReminderId,
          notifTitle,
          notifBody,
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

  Future<void> cancelDailyReminder({
    bool persist = true,
    bool syncToServer = true,
    int? userId,
  }) async {
    if (persist) {
      final box = Hive.box('settings');
      await box.put('reminder_enabled', false);
    }
    if (syncToServer && persist) {
      final time = getReminderTime();
      syncReminderToServer(
        hour: time.hour,
        minute: time.minute,
        isEnabled: false,
        userId: userId,
      );
    }
    try {
      await _notificationsPlugin.cancel(dailyReminderId);
      debugPrint('Daily reminder cancelled');
    } catch (e) {
      debugPrint('Error cancelling reminder: $e');
    }
  }

  String? _lastSyncPayloadKey;
  DateTime? _lastSyncTimestamp;

  /// Syncs reminder settings with the backend API
  Future<bool> syncReminderToServer({
    required int hour,
    required int minute,
    required bool isEnabled,
    DayPeriod? period,
    int? userId,
  }) async {
    try {
      int? effectiveUserId = userId;
      if (effectiveUserId == null) {
        final currentUser = ApiService().currentUser;
        if (currentUser != null && currentUser.id > 0) {
          effectiveUserId = currentUser.id;
        } else {
          // Check Hive directly
          effectiveUserId = SessionManager.getUserId();
          if (effectiveUserId == null || effectiveUserId <= 0) {
            final user = await SessionManager.getUser();
            if (user != null && user.id > 0) {
              effectiveUserId = user.id;
            }
          }
        }
      }

      if (effectiveUserId == null || effectiveUserId <= 0) {
        debugPrint(
          'NotificationService: Cannot sync reminder - no valid user ID',
        );
        return false;
      }

      // Convert to 24-hour format (00:00:00 to 23:59:00)
      int hour24 = hour;
      if (period != null) {
        if (period == DayPeriod.am) {
          hour24 = (hour == 12) ? 0 : (hour % 12);
        } else {
          hour24 = (hour == 12) ? 12 : (hour % 12) + 12;
        }
      }

      // Prevent duplicate rapid calls with identical payload
      final String payloadKey = '$effectiveUserId-$hour24:$minute-$isEnabled';
      final DateTime now = DateTime.now();
      if (_lastSyncPayloadKey == payloadKey &&
          _lastSyncTimestamp != null &&
          now.difference(_lastSyncTimestamp!).inMilliseconds < 1500) {
        debugPrint(
          'NotificationService: Skipping duplicate reminder sync to server ($payloadKey)',
        );
        return true;
      }
      _lastSyncPayloadKey = payloadKey;
      _lastSyncTimestamp = now;

      final String reminderTimeStr =
          '${hour24.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';

      final success = await ApiService().saveUserReminder(
        userId: effectiveUserId,
        reminderTime: reminderTimeStr,
        isEnabled: isEnabled ? 1 : 0,
      );

      debugPrint(
        'NotificationService: Reminder synced to server (User: $effectiveUserId, Time: $reminderTimeStr, Enabled: ${isEnabled ? 1 : 0}, Success: $success)',
      );
      return success;
    } catch (e) {
      debugPrint('NotificationService: Error syncing reminder to server: $e');
      return false;
    }
  }

  /// Explicitly called immediately after login to ensure /api/user/notifications is called.
  /// If no notification is set by the user, uses the response from this API.
  Future<void> onUserLoggedIn({int? userId}) async {
    print(
      '🔔 [NotificationService] onUserLoggedIn: Triggered after login. Calling /api/user/notifications...',
    );

    // 1. ALWAYS call /api/user/notifications after login
    dynamic notifData;
    try {
      notifData = await ApiService().getUserNotifications();
      print(
        '🔔 [NotificationService] /api/user/notifications response: $notifData',
      );
    } catch (e) {
      print(
        '🔔 [NotificationService] Error calling /api/user/notifications: $e',
      );
    }

    // 2. Check if user already has an individual reminder set on server or locally
    final box = Hive.box('settings');
    final bool hasCustomFlag =
        box.get('user_custom_reminder_set', defaultValue: false) as bool;

    int? effectiveUserId =
        userId ?? SessionManager.getUserId() ?? ApiService().currentUser?.id;
    Map<String, dynamic>? userReminderData;
    if (effectiveUserId != null && effectiveUserId > 0) {
      try {
        userReminderData = await ApiService().getUserReminder(effectiveUserId);
      } catch (e) {
        print('🔔 [NotificationService] Error checking user reminder: $e');
      }
    }

    final bool hasServerReminder =
        userReminderData != null &&
        userReminderData['reminder_time'] != null &&
        userReminderData['reminder_time'].toString().trim().isNotEmpty;

    if (hasServerReminder) {
      print(
        '🔔 [NotificationService] User has individual reminder on server. Applying it.',
      );
      await _applyServerReminderData(userReminderData);
      return;
    }

    if (hasCustomFlag) {
      print(
        '🔔 [NotificationService] User has previously chosen a custom reminder locally. Keeping it.',
      );
      return;
    }

    // 3. If no notification is set by the user, use the response from /api/user/notifications
    if (notifData != null) {
      print(
        '🔔 [NotificationService] No notification is set. Using response from /api/user/notifications to set reminder...',
      );
      await _applyBroadcastNotificationData(notifData);
    } else {
      print(
        '🔔 [NotificationService] /api/user/notifications returned no data.',
      );
    }
  }

  Future<void> _applyServerReminderData(Map<String, dynamic> data) async {
    final String reminderTimeStr = data['reminder_time'].toString();
    final dynamic rawEnabled = data['is_enabled'];
    final bool isEnabled =
        rawEnabled == 1 || rawEnabled == '1' || rawEnabled == true;

    final parts = reminderTimeStr.split(':');
    if (parts.length >= 2) {
      final int hour = int.tryParse(parts[0]) ?? 20;
      final int minute = int.tryParse(parts[1]) ?? 0;

      final box = Hive.box('settings');
      await box.put('reminder_time_set', true);
      await box.put('reminder_enabled', isEnabled);
      await box.put('reminder_hour', hour);
      await box.put('reminder_minute', minute);

      if (isEnabled) {
        await scheduleDailyReminder(
          hour: hour,
          minute: minute,
          persist: false,
          syncToServer: false,
        );
      } else {
        await cancelDailyReminder(persist: false, syncToServer: false);
      }
    }
  }

  /// Fetches saved reminder from server and applies to local configuration.
  /// If no individual user reminder is set, automatically falls back to
  /// the broadcast / default notification from /api/user/notifications.
  Future<bool> fetchAndApplyServerReminder({int? userId}) async {
    await onUserLoggedIn(userId: userId);
    return isTimeSet;
  }

  Future<bool> _applyBroadcastNotificationData(dynamic data) =>
      fetchAndApplyBroadcastNotification(data);

  /// Fetches system / broadcast notification from /api/user/notifications
  /// and applies its schedule_time and message if no notification is set.
  Future<bool> fetchAndApplyBroadcastNotification([
    dynamic optionalData,
  ]) async {
    try {
      final dynamic responseData =
          optionalData ?? await ApiService().getUserNotifications();
      if (responseData == null) {
        debugPrint(
          'NotificationService: /api/user/notifications returned null',
        );
        return false;
      }

      Map<String, dynamic>? notifMap;

      if (responseData is Map<String, dynamic>) {
        if (responseData['data'] is List &&
            (responseData['data'] as List).isNotEmpty) {
          final list = responseData['data'] as List;
          final activeItem = list.firstWhere(
            (item) =>
                item is Map &&
                (item['is_active'] == 1 || item['is_active'] == true),
            orElse: () => list.last,
          );
          if (activeItem is Map<String, dynamic>) {
            notifMap = activeItem;
          } else if (activeItem is Map) {
            notifMap = Map<String, dynamic>.from(activeItem);
          }
        } else if (responseData['data'] is Map<String, dynamic>) {
          notifMap = responseData['data'] as Map<String, dynamic>;
        } else if (responseData['data'] is Map) {
          notifMap = Map<String, dynamic>.from(responseData['data'] as Map);
        } else if (responseData['notifications'] is List &&
            (responseData['notifications'] as List).isNotEmpty) {
          final list = responseData['notifications'] as List;
          final activeItem = list.firstWhere(
            (item) =>
                item is Map &&
                (item['is_active'] == 1 || item['is_active'] == true),
            orElse: () => list.last,
          );
          if (activeItem is Map) {
            notifMap = Map<String, dynamic>.from(activeItem);
          }
        } else if (responseData.containsKey('schedule_time') ||
            responseData.containsKey('reminder_time')) {
          notifMap = responseData;
        }
      } else if (responseData is List && responseData.isNotEmpty) {
        final activeItem = responseData.firstWhere(
          (item) =>
              item is Map &&
              (item['is_active'] == 1 || item['is_active'] == true),
          orElse: () => responseData.last,
        );
        if (activeItem is Map) {
          notifMap = Map<String, dynamic>.from(activeItem);
        }
      }

      if (notifMap == null) {
        debugPrint(
          'NotificationService: No valid notification found in /api/user/notifications response',
        );
        return false;
      }

      final dynamic rawTime =
          notifMap['schedule_time'] ??
          notifMap['scheduleTime'] ??
          notifMap['reminder_time'] ??
          notifMap['time'];

      if (rawTime == null || rawTime.toString().trim().isEmpty) {
        debugPrint(
          'NotificationService: Broadcast notification has no schedule_time',
        );
        return false;
      }

      final String timeStr = rawTime.toString().trim();
      final TimeOfDay? parsedTime = _parseTimeString(timeStr);
      if (parsedTime == null) {
        debugPrint(
          'NotificationService: Could not parse time string "$timeStr"',
        );
        return false;
      }

      final String title =
          notifMap['title']?.toString().trim().isNotEmpty == true
          ? notifMap['title'].toString().trim()
          : 'Daily Video Reminder';
      final String message =
          notifMap['message']?.toString().trim().isNotEmpty == true
          ? notifMap['message'].toString().trim()
          : (notifMap['body']?.toString().trim().isNotEmpty == true
                ? notifMap['body'].toString().trim()
                : 'Reminder to watch your daily assigned videos.');

      final box = Hive.box('settings');
      await box.put('reminder_time_set', true);
      await box.put('reminder_enabled', true);
      await box.put('reminder_hour', parsedTime.hour);
      await box.put('reminder_minute', parsedTime.minute);
      await box.put('reminder_title', title);
      await box.put('reminder_message', message);

      await scheduleDailyReminder(
        hour: parsedTime.hour,
        minute: parsedTime.minute,
        title: title,
        body: message,
        persist: false,
        syncToServer: false,
      );

      debugPrint(
        'NotificationService: Applied broadcast notification from /api/user/notifications (Time: $timeStr -> ${parsedTime.hour}:${parsedTime.minute}, Title: "$title")',
      );
      return true;
    } catch (e) {
      debugPrint(
        'NotificationService: Error applying broadcast notification: $e',
      );
      return false;
    }
  }

  /// Parses multiple time formats such as "18:00:00", "18:00", "6:00 PM"
  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      final clean = timeStr.trim();
      if (clean.contains(':')) {
        final parts = clean.split(':');
        int hour = int.tryParse(parts[0].trim()) ?? 0;
        int minute = 0;
        if (parts.length >= 2) {
          final minPart = parts[1].trim().split(' ')[0];
          minute = int.tryParse(minPart) ?? 0;
        }
        if (clean.toUpperCase().contains('PM') && hour < 12) {
          hour += 12;
        } else if (clean.toUpperCase().contains('AM') && hour == 12) {
          hour = 0;
        }
        return TimeOfDay(hour: hour % 24, minute: minute % 60);
      }
    } catch (_) {}
    return null;
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
