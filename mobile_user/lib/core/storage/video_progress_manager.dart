import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

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

  /// Returns true ONLY when the current position equals or exceeds the total duration, or explicitly completed
  bool get isActuallyCompleted {
    if (totalDuration > 0 && currentPosition >= totalDuration) return true;
    return isCompleted;
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
    final bool comp = map['isCompleted'] == true && (dur <= 0 || pos >= dur);

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
    } catch (_) {}
  }

  /// Returns a listenable for Hive progress changes to auto-update UI.
  static ValueListenable<Box> listenable({List<String>? keys}) {
    return _box.listenable(keys: keys);
  }
}
