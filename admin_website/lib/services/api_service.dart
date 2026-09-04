import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  String? _authToken;

  final Map<String, Uint8List> _imageCache = {};

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://b52kcl7t-3000.inc1.devtunnels.ms/api',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'bypass-tunnel-reminder': 'true',
          'X-Tunnel-Bypass': 'true',
        },
      ),
    );

    // Initialize token from storage if available
    _initTokenFromStorage();

    // Interceptor to add auth token to headers
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_authToken == null || _authToken!.isEmpty) {
            try {
              final prefs = await SharedPreferences.getInstance();
              _authToken = prefs.getString('auth_token');
            } catch (_) {
              // Fallback to in-memory token if plugin channel is not registered yet
            }
          }
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
      ),
    );

    // Logging interceptor for debugging
    _dio.interceptors.add(LogInterceptor(responseBody: true));
  }

  Future<void> _initTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
    } catch (_) {}
  }

  // --- Auth Token Management ---
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (_) {}
  }

  Future<void> clearAuthToken() async {
    _authToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (_) {}
  }

  String? get authToken => _authToken;

  // --- 1. System Health Check ---
  Future<Response> healthCheck() async {
    return await _dio.get('/health');
  }

  // --- 2. Authentication ---
  Future<Response> login(Map<String, dynamic> credentials) async {
    return await _dio.post('/auth/admin/login', data: credentials);
  }

  Future<Response> userLogin(Map<String, dynamic> credentials) async {
    return await _dio.post('/auth/user/login', data: credentials);
  }

  // --- 3. Admin Dashboard Statistics ---
  Future<Response> getTotalLogins() async {
    return await _dio.get('/admin/dashboard/total-logins');
  }

  Future<Response> getAvgVideosWatched() async {
    return await _dio.get('/admin/dashboard/avg-videos');
  }

  Future<Response> getCompletionRate() async {
    return await _dio.get('/admin/dashboard/completion-rate');
  }

  Future<Response> getActivityLogs() async {
    return await _dio.get('/admin/dashboard/activity-logs');
  }

  // --- 4. Admin User Management ---
  Future<Response> listUsers({
    int? page,
    int? limit,
    String? search,
    String? dateFrom,
    String? dateTo,
  }) async {
    final Map<String, dynamic> queryParams = {};
    if (page != null) {
      queryParams['page'] = page;
    }
    if (limit != null) {
      queryParams['limit'] = limit;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (dateFrom != null && dateFrom.isNotEmpty) {
      queryParams['dateFrom'] = dateFrom;
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      queryParams['dateTo'] = dateTo;
    }

    return await _dio.get(
      '/admin/users/list',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  Future<Response> getUserById(String id) async {
    try {
      return await _dio.get('/admin/users/get/$id');
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return await _dio.get('/api/admin/users/get/$id');
      }
      rethrow;
    }
  }

  Future<Response> createUser(dynamic userData) async {
    return await _dio.post('/admin/users/create', data: userData);
  }

  Future<Response> editUser(String id, dynamic updateData) async {
    return await _dio.put('/admin/users/edit/$id', data: updateData);
  }

  Future<Response> deleteUser(String id) async {
    return await _dio.delete('/admin/users/delete/$id');
  }

  // --- Image Fetching Helper (with bypass headers & caching) ---
  Future<Uint8List?> fetchImageBytes(String url) async {
    if (url.trim().isEmpty) return null;
    String fullUrl = url.trim();
    if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
      if (fullUrl.startsWith('/')) {
        fullUrl = 'https://b52kcl7t-3000.inc1.devtunnels.ms$fullUrl';
      } else {
        fullUrl = 'https://b52kcl7t-3000.inc1.devtunnels.ms/$fullUrl';
      }
    }

    if (_imageCache.containsKey(fullUrl)) {
      return _imageCache[fullUrl];
    }

    try {
      final response = await _dio.get<List<int>>(
        fullUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'bypass-tunnel-reminder': 'true',
            'X-Tunnel-Bypass': 'true',
          },
        ),
      );
      if (response.data != null && response.data!.isNotEmpty) {
        final bytes = Uint8List.fromList(response.data!);
        _imageCache[fullUrl] = bytes;
        return bytes;
      }
    } catch (e) {
      debugPrint("Error fetching image bytes: $e");
    }
    return null;
  }
}
