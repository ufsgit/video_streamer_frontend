import 'dart:developer';

import 'package:hive/hive.dart';
import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../models/video_model.dart';

abstract class VideoRepository {
  Future<VideoModel?> getContinueWatchingVideo();
  Future<List<VideoModel>> getCompletedVideos();
  Future<List<VideoModel>> getPreOpLibraryVideos();
  Future<List<VideoModel>> getPostOpLibraryVideos();
  Future<List<VideoModel>> searchVideos(String query);
  Future<List<VideoModel>> getVideosByCategory({
    required String category,
    int? languageId,
    int page = 1,
    int limit = 10,
  });
  /// Updates video watch progress on the backend.
  /// [currentTimestampSeconds] is the user's current playback position in seconds.
  /// [totalWatchTimeSeconds] is the total full duration of the video in seconds.
  /// [isCompleted] indicates whether the video playback has completed.
  Future<bool> updateVideoProgress({
    required dynamic videoId,
    required double currentTimestampSeconds,
    required double totalWatchTimeSeconds,
    required bool isCompleted,
  });
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

  @override
  Future<List<VideoModel>> getVideosByCategory({
    required String category,
    int? languageId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      int? effectiveLanguageId = languageId;
      if (effectiveLanguageId == null) {
        final box = Hive.box('settings');
        effectiveLanguageId = box.get('selected_language_id');
      }

      final Map<String, dynamic> queryParams = {
        'category': category,
        'page': page,
        'limit': limit,
      };
      
      if (effectiveLanguageId != null) {
        queryParams['language_id'] = effectiveLanguageId;
      }

      log('DEBUG: Calling ${ApiConstants.videosListPath} with params: $queryParams');

      final response = await _client.dio.get(
        ApiConstants.videosListPath,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // The API might return { "success": true, "data": [...] }
        if (data is Map<String, dynamic> && data['data'] is List) {
          return (data['data'] as List).map((json) => VideoModel.fromJson(json)).toList();
        } else if (data is List) {
          return data.map((json) => VideoModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      log('Error fetching videos by category: $e');
    }
    return [];
  }

  @override
  Future<bool> updateVideoProgress({
    required dynamic videoId,
    required double currentTimestampSeconds,
    required double totalWatchTimeSeconds,
    required bool isCompleted,
  }) async {
    try {
      final dynamic formattedVideoId = int.tryParse(videoId.toString()) ?? videoId;
      final Map<String, dynamic> data = {
        'video_id': formattedVideoId,
        'current_timestamp_seconds': currentTimestampSeconds.round(),
        'total_watch_time_seconds': totalWatchTimeSeconds.round(),
        'is_completed': isCompleted,
      };

      log('DEBUG: Updating video progress with payload: $data');

      final response = await _client.dio.post(
        ApiConstants.videoProgressPath,
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('DEBUG: Video progress successfully updated on server: ${response.data}');
        return true;
      }
    } catch (e) {
      log('Error updating video progress on server: $e');
    }
    return false;
  }
}
