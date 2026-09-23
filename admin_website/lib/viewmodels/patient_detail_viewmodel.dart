import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class StagePerformanceStats {
  final String stageName;
  final int totalAssigned;
  final int totalCompleted;
  final int inProgress;
  final int notStarted;
  final int progressRate; // 0 to 100%

  const StagePerformanceStats({
    required this.stageName,
    required this.totalAssigned,
    required this.totalCompleted,
    this.inProgress = 0,
    this.notStarted = 0,
    required this.progressRate,
  });

  double get completionFraction =>
      totalAssigned > 0 ? (totalCompleted / totalAssigned).clamp(0.0, 1.0) : 0.0;
}

class PatientDetailViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  UserModel patient;

  bool isLoading = false;
  bool isAccountLoading = true;
  bool isEngagementLoading = true;
  bool isComparisonLoading = true;
  bool isHistoryLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> videoHistory = [];
  int totalVideos = 0;
  int completedVideos = 0;
  int progressRate = 0;
  bool isAccountInfoCollapsed = false;

  String selectedOpStage = "Pre-op";
  String selectedHistoryCategory = "All";

  // Detailed stage performance comparison data
  StagePerformanceStats preOpStats = const StagePerformanceStats(
    stageName: "Pre-op",
    totalAssigned: 0,
    totalCompleted: 0,
    progressRate: 0,
  );

  StagePerformanceStats postOpStats = const StagePerformanceStats(
    stageName: "Post-op",
    totalAssigned: 0,
    totalCompleted: 0,
    progressRate: 0,
  );

  /// Comparative delta: Post-Op completion rate minus Pre-Op completion rate
  int get stageDeltaRate => postOpStats.progressRate - preOpStats.progressRate;

  PatientDetailViewModel({required this.patient}) {
    fetchPatientDetails();
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

  Future<void> setHistoryCategory(String category) async {
    selectedHistoryCategory = category;
    isHistoryLoading = true;
    notifyListeners();
    try {
      final res = await _apiService.getUserHistory(
        patient.id,
        category: category.toLowerCase() == 'all' ? null : category.toLowerCase(),
      );
      if (res.data != null) {
        _parseHistoryData(res.data);
      } else {
        videoHistory = [];
      }
    } catch (e) {
      debugPrint("Error fetching history for category $category: $e");
      videoHistory = [];
    } finally {
      isHistoryLoading = false;
      notifyListeners();
    }
  }

  void _parseHistoryData(dynamic hData) {
    List<dynamic> rawHistory = [];
    if (hData is List) {
      rawHistory = hData;
    } else if (hData is Map) {
      if (hData['data'] is List) {
        rawHistory = hData['data'];
      } else if (hData['history'] is List) {
        rawHistory = hData['history'];
      } else if (hData['logs'] is List) {
        rawHistory = hData['logs'];
      } else if (hData['user_history'] is List) {
        rawHistory = hData['user_history'];
      } else if (hData['videos'] is List) {
        rawHistory = hData['videos'];
      }
    }
    videoHistory = rawHistory
        .whereType<Map>()
        .map((v) => Map<String, dynamic>.from(v))
        .toList();
  }

  Future<void> fetchProgress(String category) async {
    isEngagementLoading = true;
    notifyListeners();
    try {
      final cat = category.toLowerCase() == 'all' ? null : category.toLowerCase();
      final progressRes = await _apiService.getUserProgress(
        patient.id,
        category: cat,
      );
      if (progressRes.data != null) {
        _parseProgressData(progressRes.data);
      }
    } catch (e) {
      debugPrint("Error fetching user progress for category $category: $e");
    } finally {
      isEngagementLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPatientDetails({String? category}) async {
    isAccountLoading = true;
    isEngagementLoading = true;
    isComparisonLoading = true;
    isHistoryLoading = true;
    isLoading = false;
    errorMessage = null;
    notifyListeners();

    final activeCategory = category ?? selectedOpStage;

    // 1. Fetch User Profile independently (Account Info card)
    _apiService.getUserById(patient.id).then((userRes) {
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
      }
      isAccountLoading = false;
      notifyListeners();
    }).catchError((e) {
      debugPrint("Error fetching user profile: $e");
      isAccountLoading = false;
      notifyListeners();
    });

    // 2. Fetch Active Stage Engagement Progress independently (Engagement Overview card)
    final cat = activeCategory.toLowerCase();
    _apiService.getUserProgress(
      patient.id,
      category: cat == 'all' ? null : cat,
    ).then((progressRes) {
      if (progressRes.data != null) {
        _parseProgressData(progressRes.data);
      }
      isEngagementLoading = false;
      notifyListeners();
    }).catchError((e) {
      debugPrint("Error fetching active stage progress: $e");
      isEngagementLoading = false;
      notifyListeners();
    });

    // 3. Fetch Pre-Op and Post-Op Progress in parallel for Comparison Card
    final preOpFuture = _apiService.getUserProgress(
      patient.id,
      category: 'pre-op',
    ).catchError((e) {
      debugPrint("Error fetching pre-op progress: $e");
      return Response(requestOptions: RequestOptions(path: ''), data: null);
    });

    final postOpFuture = _apiService.getUserProgress(
      patient.id,
      category: 'post-op',
    ).catchError((e) {
      debugPrint("Error fetching post-op progress: $e");
      return Response(requestOptions: RequestOptions(path: ''), data: null);
    });

    Future.wait([preOpFuture, postOpFuture]).then((results) {
      _computeStageStats(
        preOpApiData: results[0].data,
        postOpApiData: results[1].data,
      );
      isComparisonLoading = false;
      notifyListeners();
    }).catchError((e) {
      debugPrint("Error computing stage stats: $e");
      isComparisonLoading = false;
      notifyListeners();
    });

    // 4. Fetch History independently (Assigned & Watched Video History card)
    final histCat = selectedHistoryCategory.toLowerCase();
    _apiService.getUserHistory(
      patient.id,
      category: histCat == 'all' ? null : histCat,
    ).then((historyRes) {
      if (historyRes.data != null) {
        _parseHistoryData(historyRes.data);
      } else {
        videoHistory = [];
      }
      isHistoryLoading = false;
      notifyListeners();
    }).catchError((e) {
      debugPrint("Error fetching user history: $e");
      videoHistory = [];
      isHistoryLoading = false;
      notifyListeners();
    });
  }

  void _computeStageStats({
    dynamic preOpApiData,
    dynamic postOpApiData,
  }) {
    // 1. Calculate from local videoHistory
    final preOpVideos = videoHistory.where((v) {
      final cat = (v['category'] ?? v['stage'] ?? '').toString().toLowerCase();
      return !cat.contains('post') && (cat.contains('pre') || cat.isEmpty);
    }).toList();

    final postOpVideos = videoHistory.where((v) {
      final cat = (v['category'] ?? v['stage'] ?? '').toString().toLowerCase();
      return cat.contains('post');
    }).toList();

    int preAssigned = preOpVideos.length;
    int preCompleted = preOpVideos.where((v) =>
        v['isCompleted'] == true ||
        v['completed'] == true ||
        v['status'] == 'completed' ||
        v['progress'] == 100).length;
    int preInProgress = preOpVideos.where((v) {
      final prog = _parseInt(v['progress']) ?? 0;
      final isComp = v['isCompleted'] == true || v['completed'] == true;
      return !isComp && prog > 0;
    }).length;
    int preNotStarted = (preAssigned - preCompleted - preInProgress).clamp(0, preAssigned);
    int preRate = preAssigned > 0 ? ((preCompleted / preAssigned) * 100).round() : 0;

    int postAssigned = postOpVideos.length;
    int postCompleted = postOpVideos.where((v) =>
        v['isCompleted'] == true ||
        v['completed'] == true ||
        v['status'] == 'completed' ||
        v['progress'] == 100).length;
    int postInProgress = postOpVideos.where((v) {
      final prog = _parseInt(v['progress']) ?? 0;
      final isComp = v['isCompleted'] == true || v['completed'] == true;
      return !isComp && prog > 0;
    }).length;
    int postNotStarted = (postAssigned - postCompleted - postInProgress).clamp(0, postAssigned);
    int postRate = postAssigned > 0 ? ((postCompleted / postAssigned) * 100).round() : 0;

    // 2. Overlay API progress response values if present
    final preApiParsed = _extractStatsMap(preOpApiData);
    if (preApiParsed != null) {
      final apiTotal = _parseInt(preApiParsed['totalAssigned'] ?? preApiParsed['totalVideos'] ?? preApiParsed['total_assigned'] ?? preApiParsed['total_videos']);
      final apiComp = _parseInt(preApiParsed['totalCompleted'] ?? preApiParsed['completedVideos'] ?? preApiParsed['total_completed'] ?? preApiParsed['completed_videos']);
      final apiRate = _parseInt(preApiParsed['progressRate'] ?? preApiParsed['progress_rate'] ?? preApiParsed['overallProgress'] ?? preApiParsed['completionRate']);

      if (apiTotal != null && apiTotal > 0) preAssigned = apiTotal;
      if (apiComp != null) preCompleted = apiComp;
      if (apiRate != null) {
        preRate = apiRate;
      } else if (preAssigned > 0) {
        preRate = ((preCompleted / preAssigned) * 100).round();
      }
      preNotStarted = (preAssigned - preCompleted - preInProgress).clamp(0, preAssigned);
    }

    final postApiParsed = _extractStatsMap(postOpApiData);
    if (postApiParsed != null) {
      final apiTotal = _parseInt(postApiParsed['totalAssigned'] ?? postApiParsed['totalVideos'] ?? postApiParsed['total_assigned'] ?? postApiParsed['total_videos']);
      final apiComp = _parseInt(postApiParsed['totalCompleted'] ?? postApiParsed['completedVideos'] ?? postApiParsed['total_completed'] ?? postApiParsed['completed_videos']);
      final apiRate = _parseInt(postApiParsed['progressRate'] ?? postApiParsed['progress_rate'] ?? postApiParsed['overallProgress'] ?? postApiParsed['completionRate']);

      if (apiTotal != null && apiTotal > 0) postAssigned = apiTotal;
      if (apiComp != null) postCompleted = apiComp;
      if (apiRate != null) {
        postRate = apiRate;
      } else if (postAssigned > 0) {
        postRate = ((postCompleted / postAssigned) * 100).round();
      }
      postNotStarted = (postAssigned - postCompleted - postInProgress).clamp(0, postAssigned);
    }

    preOpStats = StagePerformanceStats(
      stageName: "Pre-op",
      totalAssigned: preAssigned,
      totalCompleted: preCompleted,
      inProgress: preInProgress,
      notStarted: preNotStarted,
      progressRate: preRate,
    );

    postOpStats = StagePerformanceStats(
      stageName: "Post-op",
      totalAssigned: postAssigned,
      totalCompleted: postCompleted,
      inProgress: postInProgress,
      notStarted: postNotStarted,
      progressRate: postRate,
    );
  }

  Map<String, dynamic>? _extractStatsMap(dynamic rawData) {
    if (rawData == null) return null;
    if (rawData is Map) {
      if (rawData['data'] is Map) {
        final d = Map<String, dynamic>.from(rawData['data'] as Map);
        if (d['progress'] is Map) return Map<String, dynamic>.from(d['progress'] as Map);
        if (d['overview'] is Map) return Map<String, dynamic>.from(d['overview'] as Map);
        if (d['stats'] is Map) return Map<String, dynamic>.from(d['stats'] as Map);
        if (d['engagement'] is Map) return Map<String, dynamic>.from(d['engagement'] as Map);
        return d;
      }
      if (rawData['progress'] is Map) return Map<String, dynamic>.from(rawData['progress'] as Map);
      if (rawData['overview'] is Map) return Map<String, dynamic>.from(rawData['overview'] as Map);
      if (rawData['stats'] is Map) return Map<String, dynamic>.from(rawData['stats'] as Map);
      if (rawData['engagement'] is Map) return Map<String, dynamic>.from(rawData['engagement'] as Map);
      return Map<String, dynamic>.from(rawData);
    }
    return null;
  }

  void _parseProgressData(dynamic rawData) {
    if (rawData == null) return;
    final progressData = _extractStatsMap(rawData) ?? {};

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
