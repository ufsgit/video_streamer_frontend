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
      id: json['id'] ?? '',
      patientName: json['patientName'] ?? '',
      ward: json['ward'] ?? '',
      lastLogin: json['lastLogin'] ?? '',
      progressPercentage: json['progressPercentage'] ?? 0,
      videosWatched: json['videosWatched'] ?? 0,
      totalVideos: json['totalVideos'] ?? 0,
    );
  }
}

class DashboardViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  int totalLogins = 0;
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
      final loginsRes = await _apiService.getTotalLogins();
      final avgVideosRes = await _apiService.getAvgVideosWatched();
      final completionRes = await _apiService.getCompletionRate();
      final logsRes = await _apiService.getActivityLogs();

      totalLogins = loginsRes.data['totalLogins'] ?? 0;
      avgVideosWatched = (avgVideosRes.data['avgVideos'] ?? 0).toDouble();
      completionRate = (completionRes.data['completionRate'] ?? 0).toDouble();
      
      final logs = List<Map<String, dynamic>>.from(logsRes.data['logs'] ?? []);
      activityLogs = logs.map((json) => UserActivity.fromJson(json)).toList();
    } catch (e) {
      errorMessage = "Failed to load dashboard data. (Using fallback data for preview)";
      // Fallback data for preview purposes if API is unreachable
      _loadFallbackData();
      print(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _loadFallbackData() {
    totalLogins = 1248;
    avgVideosWatched = 3.4;
    completionRate = 78.2;
    activityLogs = [
      UserActivity(id: "JD", patientName: "John_Doe88", ward: "Cardiology Ward", lastLogin: "10 mins ago", progressPercentage: 75, videosWatched: 15, totalVideos: 20),
      UserActivity(id: "AS", patientName: "A.Smith_99", ward: "Orthopedics", lastLogin: "1 hr ago", progressPercentage: 20, videosWatched: 4, totalVideos: 20),
      UserActivity(id: "MR", patientName: "MariaR_PT", ward: "Physical Therapy", lastLogin: "3 hrs ago", progressPercentage: 100, videosWatched: 20, totalVideos: 20),
    ];
  }
}
