import 'dart:developer';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../models/user_model.dart';

abstract class UserRepository {
  Future<UserModel?> getUserProfile();
  Future<bool> updateUserLanguage({
    required int languageId,
    required String languageName,
  });
  Future<bool> saveUserReminder({
    required int userId,
    required String reminderTime,
    required int isEnabled,
  });
  Future<Map<String, dynamic>?> getUserReminder(int userId);
  Future<dynamic> getUserNotifications();
}

class UserRepositoryImpl implements UserRepository {
  final DioClient _client;

  UserRepositoryImpl({DioClient? client}) : _client = client ?? DioClient();

  @override
  Future<UserModel?> getUserProfile() async {
    try {
      final response = await _client.dio.get(ApiConstants.userProfilePath);
      if (response.statusCode == 200) {
        final body = response.data;
        if (body is Map<String, dynamic> && body['success'] == true) {
          final data = body['data'];
          if (data is Map<String, dynamic>) {
            return UserModel.fromJson(data);
          }
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<bool> updateUserLanguage({
    required int languageId,
    required String languageName,
  }) async {
    try {
      final response = await _client.dio.put(
        ApiConstants.userProfileLanguagePath,
        data: {'language_id': languageId, 'language_name': languageName},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  @override
  Future<bool> saveUserReminder({
    required int userId,
    required String reminderTime,
    required int isEnabled,
  }) async {
    final Map<String, dynamic> payload = {
      'user_id': userId,
      'reminder_time': reminderTime,
      'is_enabled': isEnabled,
    };

    log(
      'DEBUG: Setting user reminder via /api/user/reminder/$userId: $payload',
    );

    // 1. Primary endpoint: /api/user/reminder/:userId (POST)
    try {
      final response = await _client.dio.post(
        ApiConstants.userReminderPath(userId),
        data: payload,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        log(
          'DEBUG: Reminder set successfully via POST /api/user/reminder/$userId: ${response.data}',
        );
        return true;
      }
    } catch (e) {
      log('DEBUG: POST /api/user/reminder/$userId attempt error: $e');
    }

    // 2. Primary endpoint: /api/user/reminder/:userId (PUT)
    try {
      final putResponse = await _client.dio.put(
        ApiConstants.userReminderPath(userId),
        data: payload,
      );
      if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
        log(
          'DEBUG: Reminder set successfully via PUT /api/user/reminder/$userId: ${putResponse.data}',
        );
        return true;
      }
    } catch (e) {
      log('DEBUG: PUT /api/user/reminder/$userId attempt error: $e');
    }

    // 3. Fallback endpoint: /api/user/reminder/save
    try {
      final fallbackResponse = await _client.dio.post(
        ApiConstants.userReminderSavePath,
        data: payload,
      );
      if (fallbackResponse.statusCode == 200 ||
          fallbackResponse.statusCode == 201) {
        log(
          'DEBUG: Reminder set successfully via /api/user/reminder/save: ${fallbackResponse.data}',
        );
        return true;
      }
    } catch (e) {
      log('DEBUG: Fallback /api/user/reminder/save attempt error: $e');
    }

    return false;
  }

  @override
  Future<Map<String, dynamic>?> getUserReminder(int userId) async {
    try {
      final response = await _client.dio.get(
        ApiConstants.userReminderPath(userId),
      );
      if (response.statusCode == 200) {
        final body = response.data;
        if (body is Map<String, dynamic> && body['success'] == true) {
          final data = body['data'];
          if (data is Map<String, dynamic>) {
            return data;
          }
        }
      }
    } catch (e) {
      log('DEBUG: Error fetching user reminder: $e');
    }
    return null;
  }

  @override
  Future<dynamic> getUserNotifications() async {
    final List<String> candidateUrls = [
      '${ApiConstants.baseUrl}${ApiConstants.userNotificationsPath}',
      if (ApiConstants.baseUrl != 'https://7qh4z02n-3000.inc1.devtunnels.ms')
        'https://7qh4z02n-3000.inc1.devtunnels.ms/api/user/notifications',
    ];

    for (final url in candidateUrls) {
      try {
        print('🚀 [API] Calling /api/user/notifications at: $url');
        final response = await _client.dio
            .get(
              url,
              options: Options(
                sendTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 4),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  'X-Tunnel-Skip-Anti-Abuse': 'true',
                  'bypass-tunnel-reminder': 'true',
                  'X-Tunnel-Bypass': 'true',
                },
              ),
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200 && response.data != null) {
          print(
            '✅ [API] /api/user/notifications response from $url: ${response.data}',
          );
          return response.data;
        }
      } catch (e) {
        print('⚠️ [API] Failed calling /api/user/notifications at $url: $e');
      }
    }

    return null;
  }
}
