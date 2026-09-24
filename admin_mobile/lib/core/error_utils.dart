import 'package:dio/dio.dart';

class ErrorUtils {
  /// Transforms any raw error/exception into a simple, professional,
  /// user-friendly string (e.g. "Server error. Please try again.").
  static String format(dynamic error, {String fallback = "Server error. Please try again."}) {
    if (error == null) return fallback;

    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;

      // 401 / 403: Authentication issues
      if (statusCode == 401 || statusCode == 403) {
        return "Invalid credentials. Please try again.";
      }

      // 404: Not found
      if (statusCode == 404) {
        return "The requested item was not found.";
      }

      // Check for structured backend error message
      if (data is Map) {
        final msg = data['message'] ?? data['error'] ?? data['msg'];
        if (msg != null && msg.toString().trim().isNotEmpty) {
          final clean = _sanitize(msg.toString().trim());
          if (clean != null) return clean;
        }
      }

      // Timeouts
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return "Connection timed out. Please try again.";
      }

      if (error.type == DioExceptionType.connectionError) {
        return "Unable to connect to server. Please try again.";
      }

      // Server error responses (500, 502, 503, 504)
      if (statusCode != null && statusCode >= 500) {
        return "Server error. Please try again.";
      }

      // 400 Bad Request / 422 Unprocessable Entity
      if (statusCode == 400 || statusCode == 422) {
        return "Please check your input and try again.";
      }
    }

    if (error is String) {
      final clean = _sanitize(error);
      if (clean != null) return clean;
    }

    return fallback;
  }

  /// Sanitizes raw error strings to avoid showing stacktraces, HTML, or verbose logs
  static String? _sanitize(String raw) {
    final lower = raw.toLowerCase();

    // If it's a stack trace or HTML or DioException dump, reject it
    if (lower.contains("<html") ||
        lower.contains("<!doctype") ||
        lower.contains("exception") ||
        lower.contains("stack trace") ||
        lower.contains("dioexception") ||
        lower.contains("status code") ||
        lower.contains("failed host lookup") ||
        lower.contains("connection refused") ||
        raw.length > 90) {
      return null;
    }

    // Capitalize first letter and ensure ending punctuation
    String clean = raw.trim();
    if (clean.isNotEmpty) {
      clean = clean[0].toUpperCase() + clean.substring(1);
      if (!clean.endsWith('.') && !clean.endsWith('!') && !clean.endsWith('?')) {
        clean = "$clean.";
      }
    }
    return clean;
  }
}
