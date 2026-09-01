import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepositoryImpl();

  bool _isLoading = false;
  bool _isCheckingSession = true;
  String? _errorMessage;
  UserModel? _currentUser;
  bool _obscurePassword = true;

  bool get isLoading => _isLoading;
  bool get isCheckingSession => _isCheckingSession;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser ?? _authRepository.currentUser;
  bool get obscurePassword => _obscurePassword;
  bool get isAuthenticated => _authRepository.authToken != null;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> checkSession() async {
    _isCheckingSession = true;
    notifyListeners();

    final hasSession = await _authRepository.tryAutoLogin();
    if (hasSession) {
      _currentUser = _authRepository.currentUser;
    }

    _isCheckingSession = false;
    notifyListeners();
    return hasSession;
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    final cleanUsername = username.trim();
    if (cleanUsername.isEmpty || password.isEmpty) {
      _errorMessage = 'Please enter both username and password';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.login(
      username: cleanUsername,
      password: password,
    );

    _isLoading = false;

    if (result['success'] == true) {
      _currentUser = _authRepository.currentUser;
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? 'Login failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}
