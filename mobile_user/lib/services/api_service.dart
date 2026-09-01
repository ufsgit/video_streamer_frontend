import '../models/user_model.dart';
import '../models/video_model.dart';

/// API MENTION: ApiService contains stubs for backend API communication.
/// Since the API is not ready yet, backend integration methods are left blank.
/// Place real HTTP client requests (e.g. using `http` or `dio`) here when backend endpoints are published.
class ApiService {
  // Singleton pattern for API Service
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // API MENTION: Authentication API Endpoint: POST /api/v1/auth/login
  // Request Body: { "username": username, "password": password }
  Future<bool> login({required String username, required String password}) async {
    // API is not ready yet.
    // TODO: Connect to backend auth endpoint once available.
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  // API MENTION: Fetch User Profile API Endpoint: GET /api/v1/user/profile
  Future<UserModel?> getUserProfile() async {
    // API is not ready yet.
    // TODO: Return UserModel parsed from backend API response.
    return null;
  }

  // API MENTION: Fetch Continue Watching API Endpoint: GET /api/v1/videos/continue-watching
  Future<VideoModel?> getContinueWatchingVideo() async {
    // API is not ready yet.
    // TODO: Return active video progress from API.
    return null;
  }

  // API MENTION: Fetch Completed Videos API Endpoint: GET /api/v1/videos/completed
  Future<List<VideoModel>> getCompletedVideos() async {
    // API is not ready yet.
    // TODO: Return completed videos list from API.
    return [];
  }

  // API MENTION: Fetch Pre-Op Library Videos API Endpoint: GET /api/v1/library/pre-op
  Future<List<VideoModel>> getPreOpLibraryVideos() async {
    // API is not ready yet.
    // TODO: Return pre-op videos list from API.
    return [];
  }

  // API MENTION: Fetch Post-Op Library Videos API Endpoint: GET /api/v1/library/post-op
  Future<List<VideoModel>> getPostOpLibraryVideos() async {
    // API is not ready yet.
    // TODO: Return post-op videos list from API.
    return [];
  }

  // API MENTION: Search Videos API Endpoint: GET /api/v1/videos/search?q={query}
  Future<List<VideoModel>> searchVideos(String query) async {
    // API is not ready yet.
    // TODO: Connect to backend search endpoint.
    return [];
  }
}
