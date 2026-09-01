import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';

class SessionManager {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';

  static Future<void> saveSession({
    required String token,
    UserModel? user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    if (user != null) {
      await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_keyUser);
    if (userJson != null) {
      try {
        final map = jsonDecode(userJson);
        if (map is Map<String, dynamic>) {
          return UserModel.fromJson(map);
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
