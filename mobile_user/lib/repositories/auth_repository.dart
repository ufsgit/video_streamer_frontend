import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../core/storage/session_manager.dart';
import '../models/user_model.dart';

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
        data: {
          'username': cleanUsername,
          'password': password,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        String? token;
        if (data.containsKey('token')) {
          token = data['token'];
        } else if (data.containsKey('accessToken')) {
          token = data['accessToken'];
        }

        if (token != null) {
          _client.setAuthToken(token);
        }

        if (data.containsKey('user') && data['user'] is Map<String, dynamic>) {
          _user = UserModel.fromJson(data['user']);
        }

        // Persist session across app restarts
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
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
  }

  @override
  Future<void> logout() async {
    _client.setAuthToken(null);
    _user = null;
    await SessionManager.clearSession();
  }
}
