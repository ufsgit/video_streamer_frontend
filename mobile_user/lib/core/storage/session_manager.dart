import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';

class SessionManager {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';
  static const String settingsBoxName = 'settings';

  /// Save token in SharedPreferences and all user values in Hive until logout
  static Future<void> saveSession({
    required String token,
    UserModel? user,
  }) async {
    // 1. Save token in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);

    // Also keep backup in prefs
    if (user != null) {
      await prefs.setString(_keyUser, jsonEncode(user.toJson()));
      // 2. Save user and required values in Hive
      await saveUserToHive(user);
    }
  }

  /// Saves or updates all user profile values in Hive until logout
  static Future<void> saveUserToHive(UserModel user) async {
    try {
      final box = Hive.isBoxOpen(settingsBoxName)
          ? Hive.box(settingsBoxName)
          : await Hive.openBox(settingsBoxName);

      await box.put('user_id', user.id);
      await box.put('user_name', user.name);
      if (user.email != null) await box.put('user_email', user.email);
      await box.put('user_profile', jsonEncode(user.toJson()));
      if (user.doctorName != null) {
        await box.put('user_doctor_name', user.doctorName);
      }
      if (user.phoneNumber != null) {
        await box.put('user_phone_number', user.phoneNumber);
      }
      if (user.sex != null) await box.put('user_sex', user.sex);
      if (user.age != null) await box.put('user_age', user.age);
      if (user.dateOfBirth != null) {
        await box.put('user_dob', user.dateOfBirth);
      }
      await box.put('user_streak', user.currentStreak);
      await box.put('user_total_video_done', user.totalVideoDone);
      await box.put('user_total_time', user.totalTimeOnPlatformSeconds);
      if (user.languages != null && user.languages!.isNotEmpty) {
        await box.put('user_languages', user.languages);
      }
      if (user.languageName != null &&
          user.languageName!.trim().isNotEmpty &&
          user.languageName!.toLowerCase() != 'null' &&
          user.languageName!.toLowerCase() != 'none') {
        await box.put('selected_language', user.languageName);
        if (user.languageId != null) {
          await box.put('selected_language_id', user.languageId);
        }
      }
    } catch (_) {}
  }

  /// Get token from SharedPreferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Get current user ID directly from Hive
  static int? getUserId() {
    try {
      if (Hive.isBoxOpen(settingsBoxName)) {
        final box = Hive.box(settingsBoxName);
        final dynamic rawId = box.get('user_id');
        if (rawId is int && rawId > 0) return rawId;
        if (rawId != null) {
          final parsed = int.tryParse(rawId.toString());
          if (parsed != null && parsed > 0) return parsed;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Get UserModel restored from Hive (or fallback from SharedPreferences)
  static Future<UserModel?> getUser() async {
    // 1. Try reading from Hive first
    try {
      if (Hive.isBoxOpen(settingsBoxName)) {
        final box = Hive.box(settingsBoxName);
        final profileData = box.get('user_profile');
        if (profileData != null) {
          final map = profileData is Map
              ? Map<String, dynamic>.from(profileData)
              : jsonDecode(profileData.toString());
          if (map is Map<String, dynamic>) {
            return UserModel.fromJson(map);
          }
        }
        final userId = getUserId();
        if (userId != null && userId > 0) {
          return UserModel(
            id: userId,
            name: box.get('user_name', defaultValue: '')?.toString() ?? '',
            email: box.get('user_email')?.toString(),
            doctorName: box.get('user_doctor_name')?.toString(),
            phoneNumber: box.get('user_phone_number')?.toString(),
            sex: box.get('user_sex')?.toString(),
            age: box.get('user_age') as int?,
            dateOfBirth: box.get('user_dob')?.toString(),
            currentStreak: (box.get('user_streak') as int?) ?? 0,
            totalVideoDone: (box.get('user_total_video_done') as int?) ?? 0,
            totalTimeOnPlatformSeconds:
                (box.get('user_total_time') as int?) ?? 0,
            languages: (box.get('user_languages') is List)
                ? List<String>.from(box.get('user_languages'))
                : null,
          );
        }
      }
    } catch (_) {}

    // 2. Fallback to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_keyUser);
    if (userJson != null) {
      try {
        final map = jsonDecode(userJson);
        if (map is Map<String, dynamic>) {
          final user = UserModel.fromJson(map);
          // Sync to Hive for next reads
          await saveUserToHive(user);
          return user;
        }
      } catch (_) {}
    }
    return null;
  }

  /// Clear token in SharedPreferences and user values in Hive on logout
  static Future<void> clearSession() async {
    // 1. Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // 2. Clear all user settings and values in Hive
    try {
      if (Hive.isBoxOpen(settingsBoxName)) {
        await Hive.box(settingsBoxName).clear();
      }
    } catch (_) {}

    // 3. Clear cached video progress in Hive
    try {
      if (Hive.isBoxOpen('video_progress')) {
        await Hive.box('video_progress').clear();
      }
    } catch (_) {}
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
