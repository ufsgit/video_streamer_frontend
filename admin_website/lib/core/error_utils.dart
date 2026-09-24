import 'package:dio/dio.dart';

/// Centralized utility to format errors into clean, friendly, short user-facing messages.
class ErrorUtils {
  static String format(dynamic error, {String fallback = "Server error. Please try again."}) {
    if (error == null) return fallback;

    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode != null) {
        if (statusCode == 401 || statusCode == 403) {
          final msg = _cleanMessage(_extractMessage(error.response?.data));
          return msg ?? "Invalid credentials. Please sign in again.";
        }
        if (statusCode == 404) {
          final msg = _cleanMessage(_extractMessage(error.response?.data));
          return msg ?? "Requested item not found.";
        }
        if (statusCode == 400 || statusCode == 422) {
          final msg = _cleanMessage(_extractMessage(error.response?.data));
          return msg ?? "Please check your input and try again.";
        }
        if (statusCode >= 500) {
          return "Server error. Please try again.";
        }
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return "Connection timed out. Please try again.";
      }

      if (error.type == DioExceptionType.connectionError) {
        return "Unable to connect to server.";
      }

      final msg = _cleanMessage(_extractMessage(error.response?.data));
      if (msg != null) return msg;

      return "Server error. Please try again.";
    }

    if (error is String) {
      final msg = _cleanMessage(error);
      return msg ?? fallback;
    }

    return fallback;
  }

  static String? _extractMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      final msg = data['message'] ?? data['error'] ?? data['msg'];
      if (msg != null) return msg.toString();
    }
    return null;
  }

  static String? _cleanMessage(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final lower = trimmed.toLowerCase();
    // Filter out technical, raw exceptions or HTML
    if (lower.contains("dioexception") ||
        lower.contains("socketexception") ||
        lower.contains("formatexception") ||
        lower.contains("status code") ||
        lower.contains("connection error") ||
        lower.contains("cannot reach server") ||
        lower.contains("<html") ||
        lower.contains("stack trace") ||
        trimmed.startsWith("{") ||
        trimmed.length > 90) {
      return "Server error. Please try again.";
    }

    // Capitalize first letter if needed
    if (trimmed.isNotEmpty) {
      return trimmed[0].toUpperCase() + trimmed.substring(1);
    }
    return trimmed;
  }
}
