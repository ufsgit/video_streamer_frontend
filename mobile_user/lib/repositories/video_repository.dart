import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../models/video_model.dart';

abstract class VideoRepository {
  Future<VideoModel?> getContinueWatchingVideo();
  Future<List<VideoModel>> getCompletedVideos();
  Future<List<VideoModel>> getPreOpLibraryVideos();
  Future<List<VideoModel>> getPostOpLibraryVideos();
  Future<List<VideoModel>> searchVideos(String query);
}

class VideoRepositoryImpl implements VideoRepository {
  final DioClient _client;

  VideoRepositoryImpl({DioClient? client}) : _client = client ?? DioClient();

  @override
  Future<VideoModel?> getContinueWatchingVideo() async {
    try {
      final response = await _client.dio.get(ApiConstants.continueWatchingPath);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['video'] != null) {
          return VideoModel.fromJson(data['video']);
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<VideoModel>> getCompletedVideos() async {
    try {
      final response = await _client.dio.get(ApiConstants.completedVideosPath);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((json) => VideoModel.fromJson(json)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<List<VideoModel>> getPreOpLibraryVideos() async {
    try {
      final response = await _client.dio.get(ApiConstants.preOpVideosPath);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((json) => VideoModel.fromJson(json)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<List<VideoModel>> getPostOpLibraryVideos() async {
    try {
      final response = await _client.dio.get(ApiConstants.postOpVideosPath);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((json) => VideoModel.fromJson(json)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<List<VideoModel>> searchVideos(String query) async {
    try {
      final response = await _client.dio.get(
        ApiConstants.searchVideosPath,
        queryParameters: {'q': query},
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((json) => VideoModel.fromJson(json)).toList();
        }
      }
    } catch (_) {}
    return [];
  }
}
