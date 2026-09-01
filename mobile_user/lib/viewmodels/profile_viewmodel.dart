import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  final UserRepository _userRepository;
  final AuthRepository _authRepository;

  ProfileViewModel({
    UserRepository? userRepository,
    AuthRepository? authRepository,
  })  : _userRepository = userRepository ?? UserRepositoryImpl(),
        _authRepository = authRepository ?? AuthRepositoryImpl();

  bool _isLoading = false;
  UserModel? _user;

  bool get isLoading => _isLoading;
  UserModel? get user => _user;

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    _user = await _userRepository.getUserProfile();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    notifyListeners();
  }
}
