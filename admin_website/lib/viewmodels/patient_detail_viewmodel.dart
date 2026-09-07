import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class PatientDetailViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  UserModel patient;

  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> videoHistory = [];
  int totalVideos = 0;
  int completedVideos = 0;
  int progressRate = 0;
  bool isAccountInfoCollapsed = false;

  PatientDetailViewModel({required this.patient}) {
    fetchPatientDetails();
  }

  void toggleAccountInfoCollapsed() {
    isAccountInfoCollapsed = !isAccountInfoCollapsed;
    notifyListeners();
  }

  void updatePatient(UserModel updated) {
    patient = updated;
    notifyListeners();
  }

  Future<void> fetchPatientDetails() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getUserById(patient.id);
      final resData = response.data;

      Map<String, dynamic> userData = {};
      if (resData is Map<String, dynamic>) {
        if (resData['data'] is Map<String, dynamic>) {
          userData = Map<String, dynamic>.from(resData['data']);
        } else if (resData['user'] is Map<String, dynamic>) {
          userData = Map<String, dynamic>.from(resData['user']);
        } else {
          userData = resData;
        }
      }

      if (userData.isNotEmpty) {
        patient = UserModel.fromJson(userData);

        // Parse assigned or watched videos
        final List<dynamic> rawVideos =
            userData['assigned_videos'] ??
            userData['assignedVideos'] ??
            userData['videos'] ??
            userData['history'] ??
            userData['watched_videos'] ??
            [];

        videoHistory = rawVideos
            .map((v) => Map<String, dynamic>.from(v as Map))
            .toList();

        // Calculate / extract statistics
        totalVideos =
            int.tryParse(
              userData['total_videos']?.toString() ??
                  userData['totalVideos']?.toString() ??
                  userData['total_watched']?.toString() ??
                  '',
            ) ??
            videoHistory.length;

        completedVideos =
            int.tryParse(
              userData['total_completed']?.toString() ??
                  userData['completed_videos']?.toString() ??
                  userData['completedCount']?.toString() ??
                  '',
            ) ??
            videoHistory
                .where(
                  (v) =>
                      v['isCompleted'] == true ||
                      v['completed'] == true ||
                      v['status'] == 'completed' ||
                      v['progress'] == 100,
                )
                .length;

        if (totalVideos > 0) {
          progressRate = ((completedVideos / totalVideos) * 100).round();
        } else if (userData['progress'] != null) {
          progressRate =
              int.tryParse(userData['progress'].toString()) ??
              (double.tryParse(userData['progress'].toString())?.round() ?? 0);
        } else {
          progressRate = 0;
        }
      }
    } catch (e) {
      debugPrint("Error fetching patient details: $e");
      errorMessage = "Failed to fetch latest details from server.";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePatient() async {
    try {
      final response = await _apiService.deleteUser(patient.id);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint("Error deleting patient: $e");
      return false;
    }
  }
}
