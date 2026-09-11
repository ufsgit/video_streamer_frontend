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
      if (resData is Map) {
        if (resData['data'] is Map) {
          userData = Map<String, dynamic>.from(resData['data'] as Map);
        } else if (resData['user'] is Map) {
          userData = Map<String, dynamic>.from(resData['user'] as Map);
        } else {
          userData = Map<String, dynamic>.from(resData);
        }
      }

      if (userData.isNotEmpty) {
        patient = UserModel.fromJson(userData);

        // Parse assigned or watched videos safely
        final dynamic rawVideosData =
            userData['assigned_videos'] ??
            userData['assignedVideos'] ??
            userData['videos'] ??
            userData['history'] ??
            userData['watched_videos'];

        if (rawVideosData is List) {
          videoHistory = rawVideosData
              .whereType<Map>()
              .map((v) => Map<String, dynamic>.from(v))
              .toList();
        } else {
          videoHistory = [];
        }

        // Calculate / extract statistics
        totalVideos =
            int.tryParse(
              userData['total_videos']?.toString() ??
                  userData['totalVideos']?.toString() ??
                  userData['total_assigned']?.toString() ??
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
    } catch (e, stackTrace) {
      debugPrint("Error fetching patient details: $e\n$stackTrace");
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
