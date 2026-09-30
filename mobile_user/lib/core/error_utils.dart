import 'package:dio/dio.dart';

/// Centralized utility to format errors into friendly, professional, non-technical
/// messages tailored for patients and mobile users.
class ErrorUtils {
  /// Converts any dynamic error/exception into a clean, human-readable user-facing string.
  static String format(
    dynamic error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    if (error == null) return fallback;

    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;

      // 401 / 403: Invalid credentials or session expired
      if (statusCode == 401 || statusCode == 403) {
        final serverMsg = _extractAndSanitize(data);
        if (serverMsg != null && _isMeaningfulUserMessage(serverMsg)) {
          return serverMsg;
        }
        return 'Incorrect username or password. Please try again.';
      }

      // 404: Not found
      if (statusCode == 404) {
        final serverMsg = _extractAndSanitize(data);
        if (serverMsg != null && _isMeaningfulUserMessage(serverMsg)) {
          return serverMsg;
        }
        return 'The requested information could not be found.';
      }

      // Check for user-friendly backend message on 400, 422, etc.
      if (data != null) {
        final serverMsg = _extractAndSanitize(data);
        if (serverMsg != null && _isMeaningfulUserMessage(serverMsg)) {
          return serverMsg;
        }
      }

      // 400 / 422: Bad Request / Unprocessable
      if (statusCode == 400 || statusCode == 422) {
        return 'Please check your information and try again.';
      }

      // Server error responses (500, 502, 503, 504)
      if (statusCode != null && statusCode >= 500) {
        return 'Server is temporarily unavailable. Please try again shortly.';
      }

      // Timeout errors
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Please check your internet connection and try again.';
      }

      // Connection / Network errors (including offline, DNS failure, CORS)
      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to connect. Please check your internet connection and try again.';
      }

      return fallback;
    }

    if (error is String) {
      final clean = _sanitizeString(error);
      if (clean != null && _isMeaningfulUserMessage(clean)) {
        return clean;
      }
      return fallback;
    }

    // Generic Exception/Error handling
    final errorString = error.toString();
    final clean = _sanitizeString(errorString);
    if (clean != null && _isMeaningfulUserMessage(clean)) {
      return clean;
    }

    return fallback;
  }

  /// Extracts message from JSON response payload
  static String? _extractAndSanitize(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      final msg =
          data['message'] ?? data['error'] ?? data['msg'] ?? data['detail'];
      if (msg != null) {
        return _sanitizeString(msg.toString());
      }
    }
    return null;
  }

  /// Evaluates whether a message is an acceptable, user-friendly string
  static bool _isMeaningfulUserMessage(String message) {
    final lower = message.toLowerCase();
    // Exclude technical patterns
    const technicalIndicators = [
      'exception',
      'dioerror',
      'dioexception',
      'socket',
      'formatexception',
      'platformexception',
      'typeerror',
      'handshake',
      'status code',
      'statuscode',
      'failed host lookup',
      'connection refused',
      'connection reset',
      'cors',
      'xmlhttprequest',
      'stack trace',
      'stacktrace',
      'null pointer',
      'nullpointer',
      'internal server error',
      'database error',
      'sql',
      'sequelize',
      'mongo',
      'syntaxerror',
      'undefined',
      'null is not',
      '<html',
      '<!doctype',
      'http://',
      'https://',
      'localhost',
      '127.0.0.1',
      'errno',
      'os error',
    ];

    for (final term in technicalIndicators) {
      if (lower.contains(term)) {
        return false;
      }
    }

    return message.length >= 3 && message.length <= 120;
  }

  /// Sanitizes raw string removing technical tags, leading prefixes, and JSON
  static String? _sanitizeString(String raw) {
    String trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // Remove leading 'Exception: ', 'Error: ', etc.
    if (trimmed.startsWith('Exception:')) {
      trimmed = trimmed.substring(10).trim();
    }
    if (trimmed.startsWith('Error:')) {
      trimmed = trimmed.substring(6).trim();
    }
    if (trimmed.startsWith('Failed:')) {
      trimmed = trimmed.substring(7).trim();
    }

    // If string is JSON or HTML, discard
    if (trimmed.startsWith('{') ||
        trimmed.startsWith('[') ||
        trimmed.startsWith('<')) {
      return null;
    }

    if (!_isMeaningfulUserMessage(trimmed)) {
      return null;
    }

    // Capitalize first letter
    if (trimmed.isNotEmpty) {
      trimmed = trimmed[0].toUpperCase() + trimmed.substring(1);
      // Ensure ending punctuation
      if (!trimmed.endsWith('.') &&
          !trimmed.endsWith('!') &&
          !trimmed.endsWith('?')) {
        trimmed = '$trimmed.';
      }
    }
    return trimmed;
  }
}
