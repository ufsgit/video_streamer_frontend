import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  UserModel? _user;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getAdminProfile();
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] != null) {
          _user = UserModel.fromJson(data['data']);
        } else if (data is Map<String, dynamic>) {
          _user = UserModel.fromJson(data);
        }
      } else {
        _errorMessage = 'Failed to load profile';
      }
    } catch (e) {
      if (e is DioException) {
        _errorMessage = e.response?.data?['message']?.toString() ?? 'Network error occurred';
      } else {
        _errorMessage = 'An unexpected error occurred';
      }
      if (kDebugMode) {
        print('Error fetching profile: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
