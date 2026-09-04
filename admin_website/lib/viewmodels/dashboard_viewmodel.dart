import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserActivity {
  final String id;
  final String patientName;
  final String ward;
  final String lastLogin;
  final int progressPercentage;
  final int videosWatched;
  final int totalVideos;

  UserActivity({
    required this.id,
    required this.patientName,
    required this.ward,
    required this.lastLogin,
    required this.progressPercentage,
    required this.videosWatched,
    required this.totalVideos,
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      patientName: json['patientName']?.toString() ??
          json['name']?.toString() ??
          json['username']?.toString() ??
          'Patient',
      ward: json['ward']?.toString() ?? 'General Ward',
      lastLogin: json['lastLogin']?.toString() ??
          json['createdAt']?.toString() ??
          'Recently',
      progressPercentage: (json['progressPercentage'] is num)
          ? (json['progressPercentage'] as num).toInt()
          : 0,
      videosWatched: (json['videosWatched'] is num)
          ? (json['videosWatched'] as num).toInt()
          : 0,
      totalVideos: (json['totalVideos'] is num)
          ? (json['totalVideos'] as num).toInt()
          : 0,
    );
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
          totalLogins = d['totalLogins'] ?? d['count'] ?? d['total'] ?? 0;
        } else if (d is num) {
          totalLogins = d.toInt();
        }
      }

      // 2. Avg Videos
      final avgData = avgVideosRes.data;
      if (avgData is Map<String, dynamic>) {
        final d = avgData['data'] ?? avgData;
        if (d is Map) {
          avgVideosWatched = (d['avgVideos'] ?? d['average'] ?? 0).toDouble();
        } else if (d is num) {
          avgVideosWatched = d.toDouble();
        }
      }

      // 3. Completion Rate
      final compData = completionRes.data;
      if (compData is Map<String, dynamic>) {
        final d = compData['data'] ?? compData;
        if (d is Map) {
          completionRate = (d['completionRate'] ?? d['rate'] ?? 0).toDouble();
        } else if (d is num) {
          completionRate = d.toDouble();
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
