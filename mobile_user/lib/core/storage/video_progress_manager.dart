import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../services/api_service.dart';

class VideoProgress {
  final double totalDuration; // in seconds
  final double currentPosition; // in seconds
  final bool isCompleted;
  final dynamic videoId;
  final String? firstOpenedAt;
  final String? lastWatchedAt;
  final String? completedAt;

  const VideoProgress({
    this.totalDuration = 0.0,
    this.currentPosition = 0.0,
    this.isCompleted = false,
    this.videoId,
    this.firstOpenedAt,
    this.lastWatchedAt,
    this.completedAt,
  });

  /// Returns progress value from 0.0 to 1.0
  double get progressFraction {
    if (totalDuration <= 0) return 0.0;
    if (isCompleted || currentPosition >= totalDuration) return 1.0;
    return (currentPosition / totalDuration).clamp(0.0, 1.0);
  }

  /// Returns true when marked completed by the backend or watched to the end
  bool get isActuallyCompleted {
    if (isCompleted) return true;
    if (totalDuration > 0 && currentPosition >= (totalDuration - 1.0)) return true;
    return false;
  }

  /// Returns percentage integer (0 to 100)
  int get percentInt => (progressFraction * 100).round();

  Map<String, dynamic> toMap() {
    return {
      'totalDuration': totalDuration,
      'currentPosition': currentPosition,
      'isCompleted': isActuallyCompleted,
      'videoId': videoId,
      'firstOpenedAt': firstOpenedAt,
      'lastWatchedAt': lastWatchedAt,
      'completedAt': completedAt,
    };
  }

  factory VideoProgress.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const VideoProgress();
    final double dur = (map['totalDuration'] as num?)?.toDouble() ?? 0.0;
    final double pos = (map['currentPosition'] as num?)?.toDouble() ?? 0.0;
    final dynamic compRaw = map['isCompleted'] ?? map['is_completed'];
    final bool comp = compRaw == true ||
        compRaw == 1 ||
        compRaw == '1' ||
        compRaw == 'true' ||
        (dur > 0 && pos >= (dur - 1.0));

    return VideoProgress(
      totalDuration: dur,
      currentPosition: pos,
      isCompleted: comp,
      videoId: map['videoId'],
      firstOpenedAt: map['firstOpenedAt']?.toString() ??
          map['first_opened_at']?.toString(),
      lastWatchedAt: map['lastWatchedAt']?.toString() ??
          map['last_watched_at']?.toString(),
      completedAt: map['completedAt']?.toString() ??
          map['completed_at']?.toString(),
    );
  }
}

class VideoProgressManager {
  static const String boxName = 'video_progress';

  static Box get _box => Hive.box(boxName);

  /// Normalizes a video ID or URL into a consistent storage key.
  static String normalizeKey(String? idOrUrl) {
    if (idOrUrl == null || idOrUrl.trim().isEmpty) return 'unknown';
    final trimmed = idOrUrl.trim();
    final ytId = YoutubePlayerController.convertUrlToId(trimmed);
    if (ytId != null && ytId.isNotEmpty) {
      return ytId;
    }
    return trimmed;
  }

  /// Retrieves the saved progress for a video.
  static VideoProgress getProgress(String? idOrUrl) {
    try {
      final key = normalizeKey(idOrUrl);
      if (!Hive.isBoxOpen(boxName)) return const VideoProgress();
      final data = _box.get(key);
      if (data is Map) {
        return VideoProgress.fromMap(data);
      }
    } catch (_) {}
    return const VideoProgress();
  }

  /// Returns the current time in Indian Standard Time (IST, UTC+5:30) as an ISO-8601 string.
  static String nowInIstIso() {
    final nowUtc = DateTime.now().toUtc();
    final ist = nowUtc.add(const Duration(hours: 5, minutes: 30));
    return ist.toIso8601String();
  }

  /// Saves the total duration, current position, completion state, and tracking timestamps in Hive.
  static Future<void> saveProgress({
    required String? idOrUrl,
    required double currentPosition,
    required double totalDuration,
    bool? isCompleted,
    dynamic videoId,
    String? firstOpenedAt,
    String? lastWatchedAt,
    String? completedAt,
  }) async {
    try {
      final key = normalizeKey(idOrUrl);
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox(boxName);
      }

      final existing = getProgress(key);
      final double effectiveDur = totalDuration > 0
          ? totalDuration
          : existing.totalDuration;
      final bool completed =
          isCompleted ?? (effectiveDur > 0 && currentPosition >= effectiveDur);

      final nowIst = nowInIstIso();

      // first_opened_at: set once in IST when first started/opened, never overwritten
      final String effectiveFirstOpenedAt = firstOpenedAt ??
          existing.firstOpenedAt ??
          nowIst;

      // last_watched_at: updated whenever video progress is saved / resumed / watched in IST
      final String effectiveLastWatchedAt = lastWatchedAt ?? nowIst;

      // completed_at: set once in IST when video is completed, never overwritten once completed
      String? effectiveCompletedAt = completedAt ?? existing.completedAt;
      if (completed && (effectiveCompletedAt == null || effectiveCompletedAt.isEmpty)) {
        effectiveCompletedAt = nowIst;
      }

      final progress = VideoProgress(
        currentPosition: currentPosition,
        totalDuration: effectiveDur,
        isCompleted: completed,
        videoId: videoId ?? existing.videoId,
        firstOpenedAt: effectiveFirstOpenedAt,
        lastWatchedAt: effectiveLastWatchedAt,
        completedAt: effectiveCompletedAt,
      );

      await _box.put(key, progress.toMap());
      if (progress.videoId != null) {
        final idKey = progress.videoId.toString();
        if (idKey != key) {
          await _box.put(idKey, progress.toMap());
        }
      }
    } catch (e) {
      debugPrint('[VideoProgressManager] Error saving progress: $e');
    }
  }

  /// Saves progress data received from the backend API into Hive storage.
  static Future<void> saveFromApiData({
    required String? idOrUrl,
    required Map<String, dynamic> apiData,
    dynamic videoId,
  }) async {
    try {
      num? parseNum(dynamic val) {
        if (val == null) return null;
        if (val is num) return val;
        return num.tryParse(val.toString());
      }

      final num? posNum = parseNum(
        apiData['current_timestamp_seconds'] ??
            apiData['current_position'] ??
            apiData['currentPosition'] ??
            apiData['position'] ??
            apiData['timestamp'] ??
            apiData['progress_seconds'],
      );
      final double currentPosition = posNum?.toDouble() ?? 0.0;

      final num? durNum = parseNum(
        apiData['total_watch_time_seconds'] ??
            apiData['total_duration'] ??
            apiData['totalDuration'] ??
            apiData['duration'] ??
            apiData['duration_seconds'],
      );
      final double totalDuration = durNum?.toDouble() ?? 0.0;

      final dynamic isCompVal = apiData['is_completed'] ??
          apiData['isCompleted'] ??
          apiData['completed'];
      final String? statusVal = apiData['status']?.toString().toLowerCase();
      final bool isCompleted = isCompVal == true ||
          isCompVal == 1 ||
          isCompVal == '1' ||
          isCompVal == 'true' ||
          statusVal == 'completed' ||
          (totalDuration > 0 && currentPosition >= (totalDuration - 1.0));

      final String? firstOpenedAt = apiData['first_opened_at']?.toString() ??
          apiData['firstOpenedAt']?.toString();
      final String? lastWatchedAt = apiData['last_watched_at']?.toString() ??
          apiData['lastWatchedAt']?.toString();
      final String? completedAt = apiData['completed_at']?.toString() ??
          apiData['completedAt']?.toString();
      final dynamic effectiveVideoId =
          apiData['video_id'] ?? apiData['videoId'] ?? apiData['id'] ?? videoId;

      final String effectiveKey = (idOrUrl != null && idOrUrl.isNotEmpty)
          ? idOrUrl
          : (apiData['link'] ?? apiData['url'] ?? effectiveVideoId?.toString() ?? 'unknown');

      await saveProgress(
        idOrUrl: effectiveKey,
        currentPosition: currentPosition,
        totalDuration: totalDuration,
        isCompleted: isCompleted,
        videoId: effectiveVideoId,
        firstOpenedAt: firstOpenedAt,
        lastWatchedAt: lastWatchedAt,
        completedAt: completedAt,
      );

      debugPrint(
        '[VideoProgressManager] Saved API progress into Hive for videoId=$effectiveVideoId: '
        'pos=${currentPosition}s, dur=${totalDuration}s, completed=$isCompleted',
      );
    } catch (e) {
      debugPrint('[VideoProgressManager] Error saving API progress data to Hive: $e');
    }
  }

  /// Fetches video progress from the backend endpoint (/api/user/videos/progress/{videoId}),
  /// parses it, and stores it in Hive. Returns the saved VideoProgress object.
  static Future<VideoProgress?> fetchAndSyncProgressFromApi({
    required dynamic videoId,
    required String? idOrUrl,
  }) async {
    if (videoId == null) return null;
    try {
      final apiData = await ApiService().getVideoProgress(videoId);
      if (apiData != null && apiData.isNotEmpty) {
        await saveFromApiData(
          idOrUrl: idOrUrl,
          apiData: apiData,
          videoId: videoId,
        );
        return getProgress(idOrUrl ?? videoId.toString());
      }
    } catch (e) {
      debugPrint('[VideoProgressManager] Error fetching and syncing video progress from API: $e');
    }
    return null;
  }

  /// Returns a listenable for Hive progress changes to auto-update UI.
  static ValueListenable<Box> listenable({List<String>? keys}) {
    return _box.listenable(keys: keys);
  }
}
