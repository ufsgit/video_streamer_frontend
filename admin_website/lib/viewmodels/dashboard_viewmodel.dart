import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

String _sanitizeWard(dynamic ward) {
  if (ward == null) return '';
  final str = ward.toString().trim();
  if (str.isEmpty ||
      str.toLowerCase() == 'null' ||
      str.toLowerCase() == 'general ward') {
    return '';
  }
  return str;
}

int _parseInt(dynamic val, [int fallback = 0]) {
  if (val is num) return val.toInt();
  if (val != null) {
    final s = val.toString().replaceAll('%', '').trim();
    return int.tryParse(s) ?? (double.tryParse(s)?.toInt() ?? fallback);
  }
  return fallback;
}

double _parseDouble(dynamic val, [double fallback = 0.0]) {
  if (val is num) return val.toDouble();
  if (val != null) {
    final s = val.toString().replaceAll('%', '').trim();
    return double.tryParse(s) ?? fallback;
  }
  return fallback;
}

class UserActivity {
  final String id;
  final String patientName;
  final String ward;
  final String lastLogin;
  final String lastLoginDate;
  final String lastLoginTime;
  final int progressPercentage;
  final int videosWatched;
  final int totalVideos;
  final String preWatched;
  final String postWatched;

  UserActivity({
    required this.id,
    required this.patientName,
    required this.ward,
    required this.lastLogin,
    this.lastLoginDate = '',
    this.lastLoginTime = '',
    required this.progressPercentage,
    required this.videosWatched,
    required this.totalVideos,
    this.preWatched = '',
    this.postWatched = '',
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    int parsedVideosWatched = 0;
    int parsedTotalVideos = 0;
    final String vwStr = json['videos_watched']?.toString() ?? '';
    if (vwStr.contains('/')) {
      final parts = vwStr.split('/');
      parsedVideosWatched = int.tryParse(parts[0]) ?? 0;
      if (parts.length > 1) {
        parsedTotalVideos = int.tryParse(parts[1]) ?? 0;
      }
    } else {
      parsedVideosWatched = _parseInt(
        json['videosWatched'] ?? json['videos_watched'],
      );
      parsedTotalVideos = _parseInt(
        json['totalVideos'] ?? json['total_videos'],
      );
    }

    final dtParts = _formatDateTimeParts(
      json['last_login']?.toString() ??
          json['lastLogin']?.toString() ??
          json['createdAt']?.toString(),
    );

    final rawProg = json['raw_progress_percent'] ?? json['progressPercentage'];
    final parsedProgress = _parseInt(rawProg);

    return UserActivity(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      patientName:
          json['patient_name']?.toString() ??
          json['patientName']?.toString() ??
          json['name']?.toString() ??
          json['username']?.toString() ??
          'Patient',
      ward: _sanitizeWard(json['ward']),
      lastLogin: dtParts['full'] ?? 'Recently',
      lastLoginDate: dtParts['date'] ?? '',
      lastLoginTime: dtParts['time'] ?? '',
      progressPercentage: parsedProgress,
      videosWatched: parsedVideosWatched,
      totalVideos: parsedTotalVideos,
      preWatched:
          json['pre_watched']?.toString() ??
          json['preWatched']?.toString() ??
          '',
      postWatched:
          json['post_watched']?.toString() ??
          json['postWatched']?.toString() ??
          '',
    );
  }

  static Map<String, String> _formatDateTimeParts(String? rawDate) {
    if (rawDate == null ||
        rawDate.trim().isEmpty ||
        rawDate.trim().toLowerCase() == 'null') {
      return {'date': 'Recently', 'time': '', 'full': 'Recently'};
    }
    final parsed = DateTime.tryParse(rawDate.trim());
    if (parsed != null) {
      final local = parsed.toLocal();
      final day = local.day.toString().padLeft(2, '0');
      final month = local.month.toString().padLeft(2, '0');
      final year = local.year.toString();
      final hour = local.hour;
      final minute = local.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final hourStr = displayHour.toString().padLeft(2, '0');
      final dateStr = "$day/$month/$year";
      final timeStr = "$hourStr:$minute $period";
      return {'date': dateStr, 'time': timeStr, 'full': "$dateStr, $timeStr"};
    }
    return {'date': rawDate, 'time': '', 'full': rawDate};
  }
}

class TopWatchedVideo {
  final String id;
  final String title;
  final int watchCount;
  final String category;
  final String duration;
  final String thumbnailUrl;

  TopWatchedVideo({
    required this.id,
    required this.title,
    required this.watchCount,
    this.category = 'Pre-op',
    this.duration = '',
    this.thumbnailUrl = '',
  });

  factory TopWatchedVideo.fromJson(Map<String, dynamic> json) {
    final rawCount =
        json['watch_count'] ??
        json['watchCount'] ??
        json['views'] ??
        json['view_count'] ??
        json['total_views'] ??
        json['totalViews'] ??
        json['count'] ??
        json['watched'] ??
        json['plays'];

    return TopWatchedVideo(
      id:
          json['id']?.toString() ??
          json['video_id']?.toString() ??
          json['_id']?.toString() ??
          '',
      title:
          json['title']?.toString() ??
          json['video_title']?.toString() ??
          json['videoTitle']?.toString() ??
          json['name']?.toString() ??
          'Video',
      watchCount: _parseInt(rawCount),
      category:
          json['category']?.toString() ??
          json['category_name']?.toString() ??
          'Pre-op',
      duration: json['duration']?.toString() ?? '',
      thumbnailUrl:
          json['thumbnail_url']?.toString() ??
          json['thumbnailUrl']?.toString() ??
          json['thumbnail']?.toString() ??
          json['imageUrl']?.toString() ??
          json['image_url']?.toString() ??
          '',
    );
  }
}

class TopPatient {
  final String id;
  final String name;
  final int videosWatched;
  final String imageUrl;
  final String ward;
  final double? completionRate;

  TopPatient({
    required this.id,
    required this.name,
    required this.videosWatched,
    this.imageUrl = '',
    this.ward = '',
    this.completionRate,
  });

  factory TopPatient.fromJson(Map<String, dynamic> json) {
    int parsedWatched = 0;
    final vwStr =
        json['videos_watched']?.toString() ??
        json['videosWatched']?.toString() ??
        json['total_watched']?.toString() ??
        json['watch_count']?.toString() ??
        json['count']?.toString() ??
        json['videos']?.toString() ??
        '';

    if (vwStr.contains('/')) {
      parsedWatched = int.tryParse(vwStr.split('/')[0]) ?? 0;
    } else {
      parsedWatched = _parseInt(
        json['videos_watched'] ??
            json['videosWatched'] ??
            json['watch_count'] ??
            json['count'] ??
            vwStr,
      );
    }

    double? parsedRate;
    final rawRate =
        json['completion_rate'] ??
        json['completionRate'] ??
        json['progress_percent'] ??
        json['progressPercentage'] ??
        json['progress'] ??
        json['rate'];
    if (rawRate != null) {
      final s = rawRate.toString().replaceAll('%', '').trim();
      parsedRate = double.tryParse(s);
    }

    return TopPatient(
      id:
          json['id']?.toString() ??
          json['user_id']?.toString() ??
          json['patient_id']?.toString() ??
          json['_id']?.toString() ??
          '',
      name:
          json['name']?.toString() ??
          json['patient_name']?.toString() ??
          json['patientName']?.toString() ??
          json['username']?.toString() ??
          'Patient',
      videosWatched: parsedWatched,
      imageUrl:
          json['image_url']?.toString() ??
          json['imageUrl']?.toString() ??
          json['profile_image']?.toString() ??
          json['avatar']?.toString() ??
          '',
      ward: _sanitizeWard(json['ward']),
      completionRate: parsedRate,
    );
  }
}

class DashboardViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  int totalLogins = 0;
  int get totalUsers => totalLogins;
  double avgVideosWatched = 0.0;
  double completionRate = 0.0;
  List<UserActivity> activityLogs = [];
  List<TopWatchedVideo> topWatchedVideos = [];
  List<TopPatient> topPatients = [];
  bool isLoading = false;
  String? errorMessage;

  DashboardViewModel() {
    refreshData();
  }

  Future<void> refreshData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getTotalLogins().catchError(
          (e) => Response(requestOptions: RequestOptions(path: ''), data: null),
        ),
        _apiService.getAvgVideosWatched().catchError(
          (e) => Response(requestOptions: RequestOptions(path: ''), data: null),
        ),
        _apiService.getCompletionRate().catchError(
          (e) => Response(requestOptions: RequestOptions(path: ''), data: null),
        ),
        _apiService.getActivityLogs().catchError(
          (e) => Response(requestOptions: RequestOptions(path: ''), data: null),
        ),
        _apiService.getTopWatchedVideos().catchError(
          (e) => Response(requestOptions: RequestOptions(path: ''), data: null),
        ),
        _apiService.getTopPatients().catchError(
          (e) => Response(requestOptions: RequestOptions(path: ''), data: null),
        ),
      ]);

      // 1. Total Logins (from /admin/dashboard/total-logins)
      totalLogins = _extractMetricInt(results[0].data, [
        'total_logins',
        'totalLogins',
        'count',
        'total',
        'logins',
      ]);

      // 2. Avg Videos
      avgVideosWatched = _extractMetricDouble(results[1].data, [
        'avg_videos_watched',
        'avgVideosWatched',
        'avg_videos',
        'avgVideos',
        'average',
        'avg',
        'count',
      ]);

      // 3. Completion Rate
      completionRate = _extractMetricDouble(results[2].data, [
        'completion_rate',
        'completionRate',
        'rate',
        'completion',
        'percentage',
      ]);

      // 4. Activity Logs
      final logsList = _extractList(results[3].data, ['logs']);
      activityLogs = logsList
          .map((json) => UserActivity.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      // 5. Top Watched Videos
      final topList = _extractList(results[4].data, ['videos', 'top_videos']);
      topWatchedVideos = topList
          .map(
            (json) => TopWatchedVideo.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();

      // 6. Top Patients
      final patientsList = _extractList(results[5].data, [
        'patients',
        'top_patients',
        'topPatients',
        'users',
      ]);
      topPatients = patientsList
          .map((json) => TopPatient.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      errorMessage = "Failed to load dashboard data.";
      debugPrint("refreshData error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  static int _extractMetricInt(dynamic data, List<String> candidateKeys) {
    if (data == null) return 0;
    if (data is num) return data.toInt();
    if (data is String) return int.tryParse(data) ?? 0;
    if (data is Map) {
      final inner = data['data'] ?? data;
      if (inner is num) return inner.toInt();
      if (inner is String) return int.tryParse(inner) ?? 0;
      if (inner is Map) {
        for (final key in candidateKeys) {
          if (inner[key] != null) return _parseInt(inner[key]);
        }
      }
    }
    return 0;
  }

  static double _extractMetricDouble(dynamic data, List<String> candidateKeys) {
    if (data == null) return 0.0;
    if (data is num) return data.toDouble();
    if (data is String) return double.tryParse(data) ?? 0.0;
    if (data is Map) {
      final inner = data['data'] ?? data;
      if (inner is num) return inner.toDouble();
      if (inner is String) return double.tryParse(inner) ?? 0.0;
      if (inner is Map) {
        for (final key in candidateKeys) {
          if (inner[key] != null) return _parseDouble(inner[key]);
        }
      }
    }
    return 0.0;
  }

  static List<dynamic> _extractList(
    dynamic data, [
    List<String> candidateKeys = const [],
  ]) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map) {
      final inner = data['data'];
      if (inner is List) return inner;
      for (final key in candidateKeys) {
        if (data[key] is List) return data[key] as List;
      }
      if (inner is Map) {
        for (final key in candidateKeys) {
          if (inner[key] is List) return inner[key] as List;
        }
      }
    }
    return [];
  }
}
