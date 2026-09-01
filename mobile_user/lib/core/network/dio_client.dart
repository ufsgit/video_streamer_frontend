import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late final Dio dio;
  String? _authToken;

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Tunnel-Skip-Anti-Abuse': 'true',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
      ),
    );
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;
}
