import 'package:dio/dio.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  String? _authToken;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://b52kcl7t-3000.inc1.devtunnels.ms/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    // Interceptor to add auth token to headers
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null && _authToken!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        return handler.next(options);
      },
    ));
    
    // Add interceptors for logging or auth if needed in the future
    _dio.interceptors.add(LogInterceptor(responseBody: true));
  }

  // --- Auth Token Management ---
  void setAuthToken(String token) {
    _authToken = token;
  }
  
  void clearAuthToken() {
    _authToken = null;
  }

  // --- Auth ---
  Future<Response> login(Map<String, dynamic> credentials) async {
    return await _dio.post('/auth/admin/login', data: credentials);
  }

  // --- Dashboard Metrics ---
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

  // --- Users Management ---
  Future<Response> createUser(Map<String, dynamic> userData) async {
    return await _dio.post('/admin/users/create', data: userData);
  }

  Future<Response> listUsers() async {
    return await _dio.get('/admin/users/list');
  }

  Future<Response> getUserById(String id) async {
    return await _dio.get('/admin/users/get/$id');
  }

  Future<Response> editUser(String id, Map<String, dynamic> updateData) async {
    // Assuming PUT or PATCH for edit, using PUT as standard
    return await _dio.put('/admin/users/edit/$id', data: updateData);
  }

  Future<Response> deleteUser(String id) async {
    return await _dio.delete('/admin/users/delete/$id');
  }
}
