import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  static const String baseUrl = 'https://7qh4z02n-3000.inc1.devtunnels.ms';

  late Dio _dio;
  String? _authToken;

  final Map<String, Uint8List> _imageCache = {};

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '$baseUrl/api',
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

  // --- 5. Video Management ---
  Future<Response> createVideo({
    required String title,
    required String category,
    required String videoUrl,
    required String language,
    String? description,
    Uint8List? thumbnailBytes,
    String? thumbnailFilename,
  }) async {
    final Map<String, dynamic> formMap = {
      'title': title,
      'category': category.toLowerCase(),
      'video_url': videoUrl,
      'language': language.toLowerCase(),
    };

    if (description != null && description.trim().isNotEmpty) {
      formMap['description'] = description.trim();
    }

    if (thumbnailBytes != null && thumbnailBytes.isNotEmpty) {
      final filename = thumbnailFilename ?? 'thumbnail.jpg';
      formMap['thumbnail'] = MultipartFile.fromBytes(
        thumbnailBytes,
        filename: filename,
      );
    }

    if (language.trim().isNotEmpty) {
      formMap['language'] = language.trim();
    }

    final formData = FormData.fromMap(formMap);

    return await _dio.post('/admin/videos/create', data: formData);
  }

  Future<Response> listVideos({
    int? page,
    int? limit,
    String? search,
    String? category,
    String? source,
  }) async {
    final Map<String, dynamic> queryParams = {};
    if (page != null) queryParams['page'] = page;
    if (limit != null) queryParams['limit'] = limit;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (category != null &&
        category.isNotEmpty &&
        category.toLowerCase() != 'all') {
      queryParams['category'] = category.toLowerCase();
    }
    if (source != null && source.isNotEmpty) queryParams['source'] = source;

    return await _dio.get(
      '/admin/videos/list',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  Future<Response> editVideo(
    String id, {
    required String title,
    required String category,
    required String videoUrl,
    String? language,
    String? description,
    Uint8List? thumbnailBytes,
    String? thumbnailFilename,
  }) async {
    final Map<String, dynamic> formMap = {
      'title': title,
      'category': category.toLowerCase(),
      'video_url': videoUrl,
    };

    if (language != null && language.trim().isNotEmpty) {
      formMap['language'] = language.trim();
    }

    if (description != null) {
      formMap['description'] = description.trim();
    }

    if (thumbnailBytes != null && thumbnailBytes.isNotEmpty) {
      final filename = thumbnailFilename ?? 'thumbnail.jpg';
      formMap['thumbnail'] = MultipartFile.fromBytes(
        thumbnailBytes,
        filename: filename,
      );
    }

    final formData = FormData.fromMap(formMap);

    try {
      return await _dio.put('/admin/videos/edit/$id', data: formData);
    } catch (e) {
      if (e is DioException &&
          (e.response?.statusCode == 404 || e.response?.statusCode == 405)) {
        try {
          return await _dio.post('/admin/videos/edit/$id', data: formData);
        } catch (_) {
          return await _dio.patch('/admin/videos/edit/$id', data: formData);
        }
      }
      rethrow;
    }
  }

  Future<Response> deleteVideo(String id) async {
    return await _dio.delete('/admin/videos/delete/$id');
  }

  // --- 6. Languages Management ---
  Future<Response> listLanguages() async {
    return await _dio.get('/admin/languages/list');
  }

  // --- Image URL Helper ---
  String getFullImageUrl(String photoPath) {
    final trimmed = photoPath.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final cleanPath = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    if (cleanPath.startsWith('uploads/')) {
      return '$baseUrl/$cleanPath';
    }
    return '$baseUrl/uploads/$cleanPath';
  }

  // --- Image Fetching Helper ---
  Future<Uint8List?> fetchImageBytes(String url) async {
    if (url.trim().isEmpty) return null;
    final fullUrl = getFullImageUrl(url);

    if (_imageCache.containsKey(fullUrl)) {
      return _imageCache[fullUrl];
    }

    try {
      final response = await _dio.get(
        fullUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data != null) {
        Uint8List? bytes;
        if (response.data is Uint8List) {
          bytes = response.data as Uint8List;
        } else if (response.data is List<int>) {
          bytes = Uint8List.fromList(response.data as List<int>);
        } else if (response.data is ByteBuffer) {
          bytes = (response.data as ByteBuffer).asUint8List();
        }
        if (bytes != null && bytes.isNotEmpty) {
          _imageCache[fullUrl] = bytes;
          return bytes;
        }
      }
    } catch (e) {
      debugPrint("Error fetching image bytes: $e");
    }

    return null;
  }
}
