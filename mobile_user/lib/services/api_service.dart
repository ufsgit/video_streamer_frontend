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
  }) => authRepository.login(username: username, password: password);

  Future<UserModel?> getUserProfile() => userRepository.getUserProfile();

  Future<bool> updateUserLanguage({
    required int languageId,
    required String languageName,
  }) =>
      userRepository.updateUserLanguage(
        languageId: languageId,
        languageName: languageName,
      );

  Future<VideoModel?> getContinueWatchingVideo() =>
      videoRepository.getContinueWatchingVideo();

  Future<List<VideoModel>> getCompletedVideos() =>
      videoRepository.getCompletedVideos();

  Future<List<VideoModel>> searchVideos(String query) =>
      videoRepository.searchVideos(query);

  Future<bool> updateVideoProgress({
    required dynamic videoId,
    required double currentTimestampSeconds,
    required double totalWatchTimeSeconds,
    required bool isCompleted,
    String? firstOpenedAt,
    String? lastWatchedAt,
    String? completedAt,
  }) => videoRepository.updateVideoProgress(
    videoId: videoId,
    currentTimestampSeconds: currentTimestampSeconds,
    totalWatchTimeSeconds: totalWatchTimeSeconds,
    isCompleted: isCompleted,
    firstOpenedAt: firstOpenedAt,
    lastWatchedAt: lastWatchedAt,
    completedAt: completedAt,
  );

  Future<Map<String, dynamic>?> getVideoProgress(dynamic videoId) =>
      videoRepository.getVideoProgress(videoId);

  Future<bool> saveUserReminder({
    required int userId,
    required String reminderTime,
    required int isEnabled,
  }) =>
      userRepository.saveUserReminder(
        userId: userId,
        reminderTime: reminderTime,
        isEnabled: isEnabled,
      );

  Future<Map<String, dynamic>?> getUserReminder(int userId) =>
      userRepository.getUserReminder(userId);
}
