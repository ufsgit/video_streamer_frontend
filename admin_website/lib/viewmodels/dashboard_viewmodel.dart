import 'package:flutter/material.dart';

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
}

class DashboardViewModel extends ChangeNotifier {
  // Mock Data for Dashboard
  int totalLogins = 1248;
  double avgVideosWatched = 3.4;
  double completionRate = 78.2;

  List<UserActivity> activityLogs = [
    UserActivity(
      id: "JD",
      patientName: "John_Doe88",
      ward: "Cardiology Ward",
      lastLogin: "10 mins ago",
      progressPercentage: 75,
      videosWatched: 15,
      totalVideos: 20,
    ),
    UserActivity(
      id: "AS",
      patientName: "A.Smith_99",
      ward: "Orthopedics",
      lastLogin: "1 hr ago",
      progressPercentage: 20,
      videosWatched: 4,
      totalVideos: 20,
    ),
    UserActivity(
      id: "MR",
      patientName: "MariaR_PT",
      ward: "Physical Therapy",
      lastLogin: "3 hrs ago",
      progressPercentage: 100,
      videosWatched: 20,
      totalVideos: 20,
    ),
  ];

  // Logic to fetch new data would go here
  void refreshData() {
    // In a real app, make an API call here
    notifyListeners();
  }
}
