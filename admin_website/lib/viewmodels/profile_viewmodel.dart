import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../core/error_utils.dart';

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
        _errorMessage = 'Server error. Please try again.';
      }
    } catch (e) {
      _errorMessage = ErrorUtils.format(e, fallback: 'Server error. Please try again.');
      if (kDebugMode) {
        print('Error fetching profile: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
