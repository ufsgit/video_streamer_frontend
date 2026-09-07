class ApiConstants {
  static const String baseUrl = 'https://7qh4z02n-3000.inc1.devtunnels.ms';

  ///'https://7qh4z02n-3000.inc1.devtunnels.ms'; - "riju"

  /// 'https://b52kcl7t-3000.inc1.devtunnels.ms'; - "sw"

  // Relative API Paths (for Dio)
  static const String userLoginPath = '/api/auth/user/login';
  static const String userProfilePath = '/api/v1/user/profile';
  static const String continueWatchingPath = '/api/v1/videos/continue-watching';
  static const String completedVideosPath = '/api/v1/videos/completed';
  static const String preOpVideosPath = '/api/v1/library/pre-op';
  static const String postOpVideosPath = '/api/v1/library/post-op';
  static const String searchVideosPath = '/api/v1/videos/search';

  // Full URL endpoints
  static const String userLogin = '$baseUrl$userLoginPath';
  static const String userProfile = '$baseUrl$userProfilePath';
  static const String continueWatching = '$baseUrl$continueWatchingPath';
  static const String completedVideos = '$baseUrl$completedVideosPath';
  static const String preOpVideos = '$baseUrl$preOpVideosPath';
  static const String postOpVideos = '$baseUrl$postOpVideosPath';
  static const String searchVideos = '$baseUrl$searchVideosPath';
}
