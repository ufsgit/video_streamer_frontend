import '../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/video_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/video_repository.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String baseUrl = ApiConstants.baseUrl;

  final AuthRepository authRepository = AuthRepositoryImpl();
  final VideoRepository videoRepository = VideoRepositoryImpl();
  final UserRepository userRepository = UserRepositoryImpl();

  String? get authToken => authRepository.authToken;
  UserModel? get currentUser => authRepository.currentUser;

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) =>
      authRepository.login(username: username, password: password);

  Future<UserModel?> getUserProfile() =>
      userRepository.getUserProfile();

  Future<VideoModel?> getContinueWatchingVideo() =>
      videoRepository.getContinueWatchingVideo();

  Future<List<VideoModel>> getCompletedVideos() =>
      videoRepository.getCompletedVideos();

  Future<List<VideoModel>> getPreOpLibraryVideos() =>
      videoRepository.getPreOpLibraryVideos();

  Future<List<VideoModel>> getPostOpLibraryVideos() =>
      videoRepository.getPostOpLibraryVideos();

  Future<List<VideoModel>> searchVideos(String query) =>
      videoRepository.searchVideos(query);
}
