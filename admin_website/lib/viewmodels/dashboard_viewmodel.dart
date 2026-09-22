import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
  final String progressText;

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
    this.progressText = '',
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
      parsedVideosWatched = (json['videosWatched'] is num)
          ? (json['videosWatched'] as num).toInt()
          : (int.tryParse(json['videosWatched']?.toString() ?? '') ?? 0);
      parsedTotalVideos = (json['totalVideos'] is num)
          ? (json['totalVideos'] as num).toInt()
          : (int.tryParse(json['totalVideos']?.toString() ?? '') ?? 0);
    }

    final dtParts = _formatDateTimeParts(
      json['last_login']?.toString() ??
          json['lastLogin']?.toString() ??
          json['createdAt']?.toString(),
    );

    final rawProg = json['raw_progress_percent'] ?? json['progressPercentage'];
    int parsedProgress = 0;
    if (rawProg is num) {
      parsedProgress = rawProg.toInt();
    } else if (rawProg != null) {
      parsedProgress = int.tryParse(rawProg.toString()) ?? 0;
    }

    return UserActivity(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      patientName: json['patient_name']?.toString() ??
          json['patientName']?.toString() ??
          json['name']?.toString() ??
          json['username']?.toString() ??
          'Patient',
      ward: (json['ward'] == null ||
              json['ward'].toString().trim().isEmpty ||
              json['ward'].toString().toLowerCase() == 'null' ||
              json['ward'].toString().trim().toLowerCase() == 'general ward')
          ? ''
          : json['ward'].toString(),
      lastLogin: dtParts['full'] ?? 'Recently',
      lastLoginDate: dtParts['date'] ?? '',
      lastLoginTime: dtParts['time'] ?? '',
      progressPercentage: parsedProgress,
      videosWatched: parsedVideosWatched,
      totalVideos: parsedTotalVideos,
      preWatched: json['pre_watched']?.toString() ??
          json['preWatched']?.toString() ??
          '',
      postWatched: json['post_watched']?.toString() ??
          json['postWatched']?.toString() ??
          '',
      progressText: json['progress']?.toString() ?? '',
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
      return {
        'date': dateStr,
        'time': timeStr,
        'full': "$dateStr, $timeStr",
      };
    }
    return {'date': rawDate, 'time': '', 'full': rawDate};
  }
}

class DashboardViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  int totalLogins = 0;
  int totalUsers = 0;
  double avgVideosWatched = 0.0;
  double completionRate = 0.0;
  List<UserActivity> activityLogs = [];
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
        _apiService.getTotalLogins().catchError((e) => Response(requestOptions: RequestOptions(path: ''), data: null)),
        _apiService.getAvgVideosWatched().catchError((e) => Response(requestOptions: RequestOptions(path: ''), data: null)),
        _apiService.getCompletionRate().catchError((e) => Response(requestOptions: RequestOptions(path: ''), data: null)),
        _apiService.getActivityLogs().catchError((e) => Response(requestOptions: RequestOptions(path: ''), data: null)),
        _apiService.listUsers(limit: 100).catchError((e) => Response(requestOptions: RequestOptions(path: ''), data: null)),
      ]);

      final loginsRes = results[0];
      final avgVideosRes = results[1];
      final completionRes = results[2];
      final logsRes = results[3];
      final usersRes = results[4];

      // 1. Total Logins
      final loginsData = loginsRes.data;
      if (loginsData is Map<String, dynamic>) {
        final d = loginsData['data'] ?? loginsData;
        if (d is Map) {
          final val = d['total_logins'] ??
              d['totalLogins'] ??
              d['count'] ??
              d['total'] ??
              d['logins'];
          if (val is num) {
            totalLogins = val.toInt();
          } else if (val is String) {
            totalLogins =
                int.tryParse(val) ?? (double.tryParse(val)?.toInt() ?? 0);
          }
        } else if (d is num) {
          totalLogins = d.toInt();
        } else if (d is String) {
          totalLogins =
              int.tryParse(d) ?? (double.tryParse(d)?.toInt() ?? 0);
        }
      }

      // 2. Avg Videos
      final avgData = avgVideosRes.data;
      if (avgData is Map<String, dynamic>) {
        final d = avgData['data'] ?? avgData;
        if (d is Map) {
          final val = d['avg_videos_watched'] ??
              d['avgVideosWatched'] ??
              d['avg_videos'] ??
              d['avgVideos'] ??
              d['average'] ??
              d['avg'] ??
              d['count'];
          if (val is num) {
            avgVideosWatched = val.toDouble();
          } else if (val is String) {
            avgVideosWatched = double.tryParse(val) ?? 0.0;
          }
        } else if (d is num) {
          avgVideosWatched = d.toDouble();
        } else if (d is String) {
          avgVideosWatched = double.tryParse(d) ?? 0.0;
        }
      }

      // 3. Completion Rate
      final compData = completionRes.data;
      if (compData is Map<String, dynamic>) {
        final d = compData['data'] ?? compData;
        if (d is Map) {
          final val = d['completion_rate'] ??
              d['completionRate'] ??
              d['rate'] ??
              d['completion'] ??
              d['percentage'];
          if (val is num) {
            completionRate = val.toDouble();
          } else if (val is String) {
            completionRate = double.tryParse(val) ?? 0.0;
          }
        } else if (d is num) {
          completionRate = d.toDouble();
        } else if (d is String) {
          completionRate = double.tryParse(d) ?? 0.0;
        }
      }

      // 4. Activity Logs
      final logsData = logsRes.data;
      List<dynamic> logsList = [];
      if (logsData is Map<String, dynamic>) {
        final d = logsData['data'] ?? logsData['logs'] ?? logsData;
        if (d is List) {
          logsList = d;
        } else if (d is Map && d['logs'] is List) {
          logsList = d['logs'];
        }
      } else if (logsData is List) {
        logsList = logsData;
      }

      activityLogs = logsList
          .map((json) => UserActivity.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      // 5. Total Users count from users list
      final resData = usersRes.data;
      if (resData is Map<String, dynamic>) {
        if (resData['data'] is Map && resData['data']['total'] != null) {
          totalUsers = (resData['data']['total'] as num).toInt();
        } else if (resData['total'] != null) {
          totalUsers = (resData['total'] as num).toInt();
        } else if (resData['data'] is List) {
          totalUsers = (resData['data'] as List).length;
        } else if (resData['users'] is List) {
          totalUsers = (resData['users'] as List).length;
        }
      } else if (resData is List) {
        totalUsers = resData.length;
      }
    } catch (e) {
      errorMessage = "Failed to load dashboard data.";
      debugPrint("refreshData error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
