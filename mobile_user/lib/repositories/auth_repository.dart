import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../core/storage/session_manager.dart';
import '../models/user_model.dart';
import 'user_repository.dart';
import '../services/notification_service.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  });
  Future<bool> tryAutoLogin();
  String? get authToken;
  UserModel? get currentUser;
  Future<void> logout();
}

class AuthRepositoryImpl implements AuthRepository {
  final DioClient _client;
  UserModel? _user;

  AuthRepositoryImpl({DioClient? client}) : _client = client ?? DioClient();

  @override
  String? get authToken => _client.authToken;

  @override
  UserModel? get currentUser => _user;

  @override
  Future<bool> tryAutoLogin() async {
    final token = await SessionManager.getToken();
    if (token != null && token.isNotEmpty) {
      _client.setAuthToken(token);
      _user = await SessionManager.getUser();

      // If user profile wasn't in storage yet, fetch it from backend and save to Hive
      if (_user == null) {
        try {
          final userRepo = UserRepositoryImpl(client: _client);
          _user = await userRepo.getUserProfile();
          if (_user != null) {
            await SessionManager.saveUserToHive(_user!);
          }
        } catch (_) {}
      }
      return true;
    }
    return false;
  }

  @override
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final cleanUsername = username.trim();

    try {
      final response = await _client.dio.post(
        ApiConstants.userLoginPath,
        data: {'username': cleanUsername, 'password': password},
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        String? token;
        if (data.containsKey('token')) {
          token = data['token'];
        } else if (data.containsKey('accessToken')) {
          token = data['accessToken'];
        }

        if (token == null && data.containsKey('data') && data['data'] is Map<String, dynamic>) {
          final innerData = data['data'];
          if (innerData.containsKey('token')) {
            token = innerData['token'];
          } else if (innerData.containsKey('accessToken')) {
            token = innerData['accessToken'];
          }
        }

        if (token != null) {
          _client.setAuthToken(token);
        }

        if (data.containsKey('user') && data['user'] is Map<String, dynamic>) {
          _user = UserModel.fromJson(data['user']);
        } else if (data.containsKey('data') && data['data'] is Map<String, dynamic> && data['data'].containsKey('user')) {
          _user = UserModel.fromJson(data['data']['user']);
        }

        // If login response didn't include the full user, fetch it immediately from profile endpoint
        if (_user == null && token != null) {
          try {
            final userRepo = UserRepositoryImpl(client: _client);
            _user = await userRepo.getUserProfile();
          } catch (_) {}
        }

        // Extract language from login payload
        Map<String, dynamic>? userPayload;
        if (data['user'] is Map<String, dynamic>) {
          userPayload = data['user'];
        } else if (data['data'] is Map<String, dynamic>) {
          if (data['data']['user'] is Map<String, dynamic>) {
            userPayload = data['data']['user'];
          } else {
            userPayload = data['data'];
          }
        }

        dynamic rawLang = userPayload?['language'] ??
            data['language'] ??
            (data['data'] is Map ? data['data']['language'] : null);
        dynamic rawLangName = userPayload?['language_name'] ??
            userPayload?['languageName'] ??
            data['language_name'] ??
            data['languageName'] ??
            (data['data'] is Map ? data['data']['language_name'] : null);
        dynamic rawLangId = userPayload?['language_id'] ??
            userPayload?['languageId'] ??
            data['language_id'] ??
            data['languageId'] ??
            (data['data'] is Map ? data['data']['language_id'] : null);

        if (rawLang is Map) {
          rawLangName ??= rawLang['name'] ?? rawLang['language_name'] ?? rawLang['title'];
          rawLangId ??= rawLang['id'] ?? rawLang['language_id'];
        } else if (rawLang is String && rawLang.trim().isNotEmpty) {
          rawLangName ??= rawLang.trim();
        }

        String? resolvedLanguageName;
        if (rawLangName != null) {
          final s = rawLangName.toString().trim();
          if (s.isNotEmpty && s.toLowerCase() != 'null' && s.toLowerCase() != 'none') {
            resolvedLanguageName = s;
          }
        }

        int? resolvedLanguageId;
        if (rawLangId != null) {
          resolvedLanguageId = int.tryParse(rawLangId.toString());
        }

        // Also check if _user model extracted language
        if (resolvedLanguageName == null && _user?.languageName != null) {
          resolvedLanguageName = _user!.languageName;
        }
        if (resolvedLanguageId == null && _user?.languageId != null) {
          resolvedLanguageId = _user!.languageId;
        }

        final settingsBox = Hive.isBoxOpen(SessionManager.settingsBoxName)
            ? Hive.box(SessionManager.settingsBoxName)
            : await Hive.openBox(SessionManager.settingsBoxName);

        if (resolvedLanguageName != null) {
          await settingsBox.put('selected_language', resolvedLanguageName);
          if (resolvedLanguageId != null) {
            await settingsBox.put('selected_language_id', resolvedLanguageId);
          }
          debugPrint('[AuthRepository] Language found in login response: $resolvedLanguageName (ID: $resolvedLanguageId)');
        } else if (resolvedLanguageId != null && resolvedLanguageId != 0) {
          await settingsBox.put('selected_language_id', resolvedLanguageId);
          await settingsBox.put('selected_language', 'Language $resolvedLanguageId');
          debugPrint('[AuthRepository] Language ID found in login response: $resolvedLanguageId');
        } else {
          // If language is explicitly null or missing, remove any old language selection
          await settingsBox.delete('selected_language');
          await settingsBox.delete('selected_language_id');
          debugPrint('[AuthRepository] Language is null in login response. User will be asked to select language.');
        }

        // Persist token in SharedPreferences and user details in Hive
        if (token != null) {
          await SessionManager.saveSession(token: token, user: _user);
        }

        return {'success': true, 'data': data};
      }
      return {'success': true, 'data': data};
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic>) {
          final message =
              data['message'] ?? data['error'] ?? 'Invalid credentials';
          return {'success': false, 'message': message.toString()};
        }
      }
      if (e.type == DioExceptionType.connectionError) {
        return {
          'success': false,
          'message':
              'Connection error: Request was blocked by the browser (CORS). Please run on Windows ("flutter run -d windows") or launch Chrome with web security disabled.',
        };
      }
      return {
        'success': false,
        'message': e.response?.statusCode != null
            ? 'Login failed with status code ${e.response?.statusCode}'
            : 'Connection error (${e.type}). Please check your connection.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  @override
  Future<void> logout() async {
    _client.setAuthToken(null);
    _user = null;
    await SessionManager.clearSession();
    try {
      await NotificationService.instance.cancelDailyReminder(
        persist: false,
        syncToServer: false,
      );
    } catch (_) {}
  }
}
