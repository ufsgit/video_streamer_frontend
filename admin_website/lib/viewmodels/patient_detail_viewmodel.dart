import 'package:dio/dio.dart';
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

  String selectedOpStage = "Pre-op";

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

  Future<void> setOpStage(String stage) async {
    selectedOpStage = stage;
    notifyListeners();
    await fetchProgress(stage);
  }

  Future<void> fetchProgress(String category) async {
    try {
      final progressRes = await _apiService.getUserProgress(
        patient.id,
        category: category,
      );
      _parseProgressData(progressRes.data);
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching user progress for category $category: $e");
    }
  }

  Future<void> fetchPatientDetails({String? category}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final activeCategory = category ?? selectedOpStage;

    try {
      final results = await Future.wait([
        _apiService.getUserById(patient.id),
        _apiService.getUserProgress(
          patient.id,
          category: activeCategory,
        ).catchError((e) {
          debugPrint("Error fetching user progress: $e");
          return Response(
            requestOptions: RequestOptions(path: ''),
            data: null,
          );
        }),
      ]);

      final userRes = results[0];
      final progressRes = results[1];
      final resData = userRes.data;

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

        // Calculate / extract statistics default
        totalVideos =
            _parseInt(
              userData['total_videos'] ??
                  userData['totalVideos'] ??
                  userData['total_assigned'] ??
                  userData['total_watched'],
            ) ??
            videoHistory.length;

        completedVideos =
            _parseInt(
              userData['total_completed'] ??
                  userData['completed_videos'] ??
                  userData['completedCount'],
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
          progressRate = _parseInt(userData['progress']) ?? 0;
        } else {
          progressRate = 0;
        }
      }

      // Parse progress data from /api/admin/users/progress/{id}
      if (progressRes.data != null) {
        _parseProgressData(progressRes.data);
      }
    } catch (e, stackTrace) {
      debugPrint("Error fetching patient details: $e\n$stackTrace");
      errorMessage = "Failed to fetch latest details from server.";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _parseProgressData(dynamic rawData) {
    if (rawData == null) return;
    Map<String, dynamic> progressData = {};
    if (rawData is Map) {
      if (rawData['data'] is Map) {
        progressData = Map<String, dynamic>.from(rawData['data'] as Map);
        if (progressData['progress'] is Map) {
          progressData = Map<String, dynamic>.from(
            progressData['progress'] as Map,
          );
        } else if (progressData['overview'] is Map) {
          progressData = Map<String, dynamic>.from(
            progressData['overview'] as Map,
          );
        } else if (progressData['stats'] is Map) {
          progressData = Map<String, dynamic>.from(
            progressData['stats'] as Map,
          );
        } else if (progressData['engagement'] is Map) {
          progressData = Map<String, dynamic>.from(
            progressData['engagement'] as Map,
          );
        }
      } else if (rawData['progress'] is Map) {
        progressData = Map<String, dynamic>.from(rawData['progress'] as Map);
      } else if (rawData['engagement'] is Map) {
        progressData = Map<String, dynamic>.from(rawData['engagement'] as Map);
      } else if (rawData['stats'] is Map) {
        progressData = Map<String, dynamic>.from(rawData['stats'] as Map);
      } else if (rawData['overview'] is Map) {
        progressData = Map<String, dynamic>.from(rawData['overview'] as Map);
      } else {
        progressData = Map<String, dynamic>.from(rawData);
      }
    }

    if (progressData.isNotEmpty) {
      final parsedTotal = _parseInt(
        progressData['totalAssigned'] ??
            progressData['total_assigned'] ??
            progressData['totalVideos'] ??
            progressData['total_videos'] ??
            progressData['assignedVideos'] ??
            progressData['assigned_videos'] ??
            progressData['assigned'] ??
            progressData['total'] ??
            progressData['count'] ??
            progressData['total_count'],
      );
      if (parsedTotal != null) {
        totalVideos = parsedTotal;
      }

      final parsedCompleted = _parseInt(
        progressData['totalCompleted'] ??
            progressData['total_completed'] ??
            progressData['completedVideos'] ??
            progressData['completed_videos'] ??
            progressData['completedCount'] ??
            progressData['completed_count'] ??
            progressData['completed'] ??
            progressData['watchedVideos'] ??
            progressData['watched_videos'] ??
            progressData['videosWatched'] ??
            progressData['videos_watched'] ??
            progressData['total_watched'] ??
            progressData['watched'],
      );
      if (parsedCompleted != null) {
        completedVideos = parsedCompleted;
      }

      final parsedProgress = _parseInt(
        progressData['progressRate'] ??
            progressData['progress_rate'] ??
            progressData['overallProgress'] ??
            progressData['overall_progress'] ??
            progressData['completionRate'] ??
            progressData['completion_rate'] ??
            progressData['progressPercentage'] ??
            progressData['progress_percentage'] ??
            progressData['progress'] ??
            progressData['rate'] ??
            progressData['percentage'],
      );
      if (parsedProgress != null) {
        progressRate = parsedProgress;
      } else if (totalVideos > 0) {
        progressRate = ((completedVideos / totalVideos) * 100).round();
      }

      // Fallback populate videoHistory if empty or if stage-specific videos returned
      final dynamic rawHist =
          progressData['video_history'] ??
          progressData['videoHistory'] ??
          progressData['videos'] ??
          progressData['history'] ??
          progressData['assigned_videos'] ??
          progressData['assignedVideos'];
      if (rawHist is List && rawHist.isNotEmpty) {
        videoHistory = rawHist
            .whereType<Map>()
            .map((v) => Map<String, dynamic>.from(v))
            .toList();
      }
    }
  }

  int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toInt();
    if (val is String) {
      final cleaned = val.replaceAll('%', '').trim();
      return int.tryParse(cleaned) ?? (double.tryParse(cleaned)?.round());
    }
    return null;
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
