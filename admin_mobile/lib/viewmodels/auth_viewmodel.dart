import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/error_utils.dart';

class AuthViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool isLoading = false;
  String? errorMessage;
  bool obscurePassword = true;

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login({
        'username': username.trim(),
        'password': password.trim(),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        String? token;
        if (data is Map<String, dynamic>) {
          token = data['token']?.toString() ??
              data['accessToken']?.toString() ??
              data['jwt']?.toString() ??
              data['authToken']?.toString() ??
              (data['data'] is Map
                  ? (data['data']['token'] ?? data['data']['accessToken'])?.toString()
                  : null) ??
              (data['admin'] is Map
                  ? (data['admin']['token'] ?? data['admin']['accessToken'])?.toString()
                  : null);
        }
        if (token != null && token.isNotEmpty) {
          await _apiService.setAuthToken(token);
        }
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        errorMessage = ErrorUtils.format(response.data, fallback: 'Invalid credentials. Please try again.');
        isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      errorMessage = ErrorUtils.format(e, fallback: 'Server error. Please try again.');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.clearAuthToken();
    notifyListeners();
  }
}

