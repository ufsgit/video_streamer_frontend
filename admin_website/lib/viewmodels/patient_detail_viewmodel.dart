import 'dart:convert';
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

  double get completionFraction => totalAssigned > 0
      ? (totalCompleted / totalAssigned).clamp(0.0, 1.0)
      : 0.0;
}

class PatientDetailViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  UserModel patient;

  bool isLoading = false;
  bool isAccountLoading = true;
  bool isEngagementLoading = true;
  bool isComparisonLoading = true;
  bool isHistoryLoading = true;
  bool isUserReportLoading = false;
  String? errorMessage;

  Map<String, dynamic>? userReportData;
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

  int? _apiPreOpSecondsWatched;
  int? _apiPostOpSecondsWatched;
  int? _apiPreOpTotalDurationSeconds;
  int? _apiPostOpTotalDurationSeconds;
  double? _apiPreOpEffortShare;
  double? _apiPostOpEffortShare;
  double? _apiStageAdherenceRatio;

  int get totalStageCompleted =>
      preOpStats.totalCompleted + postOpStats.totalCompleted;

  double get preOpEffortShare =>
      _apiPreOpEffortShare ??
      (totalStageCompleted > 0
          ? (preOpStats.totalCompleted / totalStageCompleted) * 100
          : 0.0);

  double get postOpEffortShare =>
      _apiPostOpEffortShare ??
      (totalStageCompleted > 0
          ? (postOpStats.totalCompleted / totalStageCompleted) * 100
          : 0.0);

  double get stageAdherenceRatio =>
      _apiStageAdherenceRatio ??
      (preOpStats.progressRate > 0
          ? (postOpStats.progressRate / preOpStats.progressRate)
          : 0.0);

  int get preOpSecondsWatched {
    if (_apiPreOpSecondsWatched != null) return _apiPreOpSecondsWatched!;
    return videoHistory
        .where(
          (v) => !(v['category'] ?? v['stage'] ?? '')
              .toString()
              .toLowerCase()
              .contains('post'),
        )
        .fold(
          0,
          (sum, v) =>
              sum +
              (_parseInt(
                    v['current_timestamp_seconds'] ??
                        v['currentTimestampSeconds'] ??
                        v['progress_seconds'],
                  ) ??
                  0),
        );
  }

  int get postOpSecondsWatched {
    if (_apiPostOpSecondsWatched != null) return _apiPostOpSecondsWatched!;
    return videoHistory
        .where(
          (v) => (v['category'] ?? v['stage'] ?? '')
              .toString()
              .toLowerCase()
              .contains('post'),
        )
        .fold(
          0,
          (sum, v) =>
              sum +
              (_parseInt(
                    v['current_timestamp_seconds'] ??
                        v['currentTimestampSeconds'] ??
                        v['progress_seconds'],
                  ) ??
                  0),
        );
  }

  int get preOpTotalDurationSeconds {
    if (_apiPreOpTotalDurationSeconds != null) {
      return _apiPreOpTotalDurationSeconds!;
    }
    return videoHistory
        .where(
          (v) => !(v['category'] ?? v['stage'] ?? '')
              .toString()
              .toLowerCase()
              .contains('post'),
        )
        .fold(
          0,
          (sum, v) =>
              sum +
              (_parseInt(
                    v['total_video_duration'] ??
                        v['totalVideoDuration'] ??
                        v['duration_seconds'],
                  ) ??
                  0),
        );
  }

  int get postOpTotalDurationSeconds {
    if (_apiPostOpTotalDurationSeconds != null) {
      return _apiPostOpTotalDurationSeconds!;
    }
    return videoHistory
        .where(
          (v) => (v['category'] ?? v['stage'] ?? '')
              .toString()
              .toLowerCase()
              .contains('post'),
        )
        .fold(
          0,
          (sum, v) =>
              sum +
              (_parseInt(
                    v['total_video_duration'] ??
                        v['totalVideoDuration'] ??
                        v['duration_seconds'],
                  ) ??
                  0),
        );
  }

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
        category: category.toLowerCase() == 'all'
            ? null
            : category.toLowerCase(),
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
      final cat = category.toLowerCase() == 'all'
          ? null
          : category.toLowerCase();
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
    _apiService
        .getUserById(patient.id)
        .then((userRes) {
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
        })
        .catchError((e) {
          debugPrint("Error fetching user profile: $e");
          isAccountLoading = false;
          notifyListeners();
        });

    // 2. Fetch Active Stage Engagement Progress independently (Engagement Overview card)
    final cat = activeCategory.toLowerCase();
    _apiService
        .getUserProgress(patient.id, category: cat == 'all' ? null : cat)
        .then((progressRes) {
          if (progressRes.data != null) {
            _parseProgressData(progressRes.data);
          }
          isEngagementLoading = false;
          notifyListeners();
        })
        .catchError((e) {
          debugPrint("Error fetching active stage progress: $e");
          isEngagementLoading = false;
          notifyListeners();
        });

    // 3. Fetch Pre-Op and Post-Op Stage Comparison
    _fetchStageComparison();

    // 4. Fetch History independently (Assigned & Watched Video History card)
    final histCat = selectedHistoryCategory.toLowerCase();
    _apiService
        .getUserHistory(patient.id, category: histCat == 'all' ? null : histCat)
        .then((historyRes) {
          if (historyRes.data != null) {
            _parseHistoryData(historyRes.data);
          } else {
            videoHistory = [];
          }
          isHistoryLoading = false;
          notifyListeners();
        })
        .catchError((e) {
          debugPrint("Error fetching user history: $e");
          videoHistory = [];
          isHistoryLoading = false;
          notifyListeners();
        });

    // 5. Fetch User Report Data (Self-Initiated vs Reminder-Prompted Views)
    fetchUserReportData();
  }

  void _extractReportFromData(dynamic raw) {
    if (raw == null) return;
    dynamic data = raw;
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {}
    }
    if (data is Map && data['data'] != null) {
      data = data['data'];
    }
    if (data is List && data.isNotEmpty) {
      final match = data.firstWhere(
        (item) =>
            item is Map &&
            (item['Patient ID']?.toString() == patient.id ||
                item['patient_id']?.toString() == patient.id ||
                item['id']?.toString() == patient.id),
        orElse: () => data.first,
      );
      if (match is Map) {
        userReportData = Map<String, dynamic>.from(match);
      }
    } else if (data is Map) {
      userReportData = Map<String, dynamic>.from(data);
    }
  }

  Future<void> fetchUserReportData() async {
    isUserReportLoading = true;
    notifyListeners();
    try {
      debugPrint(
        "Fetching report from /api/admin/users/report for patient ${patient.id}",
      );
      final res = await _apiService.getComparisonData(patient.id);
      if (res.data != null) {
        _extractReportFromData(res.data);
      }
    } catch (e) {
      debugPrint("Error fetching comparison data from report API: $e");
      if (userReportData == null) {
        try {
          final compRes = await _apiService.getUserStageComparison(patient.id);
          if (compRes.data != null) {
            _extractReportFromData(compRes.data);
          }
        } catch (e2) {
          debugPrint("Fallback getUserStageComparison error: $e2");
        }
      }
    } finally {
      isUserReportLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchStageComparison() async {
    isComparisonLoading = true;
    notifyListeners();
    try {
      final compRes = await _apiService.getUserStageComparison(patient.id);
      if (compRes.data != null) {
        if (userReportData == null) {
          _extractReportFromData(compRes.data);
        }
        _parseStageComparisonData(compRes.data);
        isComparisonLoading = false;
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint(
        "getUserStageComparison API error (will fallback to progress): $e",
      );
    }

    // Fallback: Fetch Pre-Op and Post-Op Progress in parallel
    try {
      final results = await Future.wait([
        _apiService.getUserProgress(patient.id, category: 'pre-op').catchError((
          e,
        ) {
          debugPrint("Error fetching pre-op progress: $e");
          return Response(requestOptions: RequestOptions(path: ''), data: null);
        }),
        _apiService.getUserProgress(patient.id, category: 'post-op').catchError(
          (e) {
            debugPrint("Error fetching post-op progress: $e");
            return Response(
              requestOptions: RequestOptions(path: ''),
              data: null,
            );
          },
        ),
      ]);
      _computeStageStats(
        preOpApiData: results[0].data,
        postOpApiData: results[1].data,
      );
    } catch (e) {
      debugPrint("Error in stage comparison fallback: $e");
    } finally {
      isComparisonLoading = false;
      notifyListeners();
    }
  }

  void _computeStageStats({dynamic preOpApiData, dynamic postOpApiData}) {
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
    int preCompleted = preOpVideos
        .where(
          (v) =>
              v['isCompleted'] == true ||
              v['completed'] == true ||
              v['status'] == 'completed' ||
              v['progress'] == 100,
        )
        .length;
    int preInProgress = preOpVideos.where((v) {
      final prog = _parseInt(v['progress']) ?? 0;
      final isComp = v['isCompleted'] == true || v['completed'] == true;
      return !isComp && prog > 0;
    }).length;
    int preNotStarted = (preAssigned - preCompleted - preInProgress).clamp(
      0,
      preAssigned,
    );
    int preRate = preAssigned > 0
        ? ((preCompleted / preAssigned) * 100).round()
        : 0;

    int postAssigned = postOpVideos.length;
    int postCompleted = postOpVideos
        .where(
          (v) =>
              v['isCompleted'] == true ||
              v['completed'] == true ||
              v['status'] == 'completed' ||
              v['progress'] == 100,
        )
        .length;
    int postInProgress = postOpVideos.where((v) {
      final prog = _parseInt(v['progress']) ?? 0;
      final isComp = v['isCompleted'] == true || v['completed'] == true;
      return !isComp && prog > 0;
    }).length;
    int postNotStarted = (postAssigned - postCompleted - postInProgress).clamp(
      0,
      postAssigned,
    );
    int postRate = postAssigned > 0
        ? ((postCompleted / postAssigned) * 100).round()
        : 0;

    // 2. Overlay API progress response values if present
    final preApiParsed = _extractStatsMap(preOpApiData);
    if (preApiParsed != null) {
      final apiTotal = _parseInt(
        preApiParsed['totalAssigned'] ??
            preApiParsed['totalVideos'] ??
            preApiParsed['total_assigned'] ??
            preApiParsed['total_videos'],
      );
      final apiComp = _parseInt(
        preApiParsed['totalCompleted'] ??
            preApiParsed['completedVideos'] ??
            preApiParsed['total_completed'] ??
            preApiParsed['completed_videos'],
      );
      final apiRate = _parseInt(
        preApiParsed['progressRate'] ??
            preApiParsed['progress_rate'] ??
            preApiParsed['overallProgress'] ??
            preApiParsed['completionRate'],
      );
      final apiWatched = _parseInt(
        preApiParsed['seconds_watched'] ??
            preApiParsed['secondsWatched'] ??
            preApiParsed['watched_seconds'] ??
            preApiParsed['watchedSeconds'] ??
            preApiParsed['total_watched_seconds'],
      );
      final apiDuration = _parseInt(
        preApiParsed['total_duration_seconds'] ??
            preApiParsed['totalDurationSeconds'] ??
            preApiParsed['total_duration'] ??
            preApiParsed['totalDuration'] ??
            preApiParsed['duration_seconds'],
      );

      if (apiTotal != null && apiTotal > 0) preAssigned = apiTotal;
      if (apiComp != null) preCompleted = apiComp;
      if (apiRate != null) {
        preRate = apiRate;
      } else if (preAssigned > 0) {
        preRate = ((preCompleted / preAssigned) * 100).round();
      }
      if (apiWatched != null) _apiPreOpSecondsWatched = apiWatched;
      if (apiDuration != null) _apiPreOpTotalDurationSeconds = apiDuration;
      preNotStarted = (preAssigned - preCompleted - preInProgress).clamp(
        0,
        preAssigned,
      );
    }

    final postApiParsed = _extractStatsMap(postOpApiData);
    if (postApiParsed != null) {
      final apiTotal = _parseInt(
        postApiParsed['totalAssigned'] ??
            postApiParsed['totalVideos'] ??
            postApiParsed['total_assigned'] ??
            postApiParsed['total_videos'],
      );
      final apiComp = _parseInt(
        postApiParsed['totalCompleted'] ??
            postApiParsed['completedVideos'] ??
            postApiParsed['total_completed'] ??
            postApiParsed['completed_videos'],
      );
      final apiRate = _parseInt(
        postApiParsed['progressRate'] ??
            postApiParsed['progress_rate'] ??
            postApiParsed['overallProgress'] ??
            postApiParsed['completionRate'],
      );
      final apiWatched = _parseInt(
        postApiParsed['seconds_watched'] ??
            postApiParsed['secondsWatched'] ??
            postApiParsed['watched_seconds'] ??
            postApiParsed['watchedSeconds'] ??
            postApiParsed['total_watched_seconds'],
      );
      final apiDuration = _parseInt(
        postApiParsed['total_duration_seconds'] ??
            postApiParsed['totalDurationSeconds'] ??
            postApiParsed['total_duration'] ??
            postApiParsed['totalDuration'] ??
            postApiParsed['duration_seconds'],
      );

      if (apiTotal != null && apiTotal > 0) postAssigned = apiTotal;
      if (apiComp != null) postCompleted = apiComp;
      if (apiRate != null) {
        postRate = apiRate;
      } else if (postAssigned > 0) {
        postRate = ((postCompleted / postAssigned) * 100).round();
      }
      if (apiWatched != null) _apiPostOpSecondsWatched = apiWatched;
      if (apiDuration != null) _apiPostOpTotalDurationSeconds = apiDuration;
      postNotStarted = (postAssigned - postCompleted - postInProgress).clamp(
        0,
        postAssigned,
      );
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
        if (d['progress'] is Map) {
          return Map<String, dynamic>.from(d['progress'] as Map);
        }
        if (d['overview'] is Map) {
          return Map<String, dynamic>.from(d['overview'] as Map);
        }
        if (d['stats'] is Map) {
          return Map<String, dynamic>.from(d['stats'] as Map);
        }
        if (d['engagement'] is Map) {
          return Map<String, dynamic>.from(d['engagement'] as Map);
        }
        return d;
      }
      if (rawData['progress'] is Map) {
        return Map<String, dynamic>.from(rawData['progress'] as Map);
      }
      if (rawData['overview'] is Map) {
        return Map<String, dynamic>.from(rawData['overview'] as Map);
      }
      if (rawData['stats'] is Map) {
        return Map<String, dynamic>.from(rawData['stats'] as Map);
      }
      if (rawData['engagement'] is Map) {
        return Map<String, dynamic>.from(rawData['engagement'] as Map);
      }
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

  void _parseStageComparisonData(dynamic rawData) {
    if (rawData == null) return;
    debugPrint("Parsing stage-comparison data: $rawData");

    Map<String, dynamic> compMap = {};
    if (rawData is Map) {
      if (rawData['data'] is Map) {
        compMap = Map<String, dynamic>.from(rawData['data'] as Map);
      } else if (rawData['comparison'] is Map) {
        compMap = Map<String, dynamic>.from(rawData['comparison'] as Map);
      } else {
        compMap = Map<String, dynamic>.from(rawData);
      }
    }

    Map<String, dynamic>? preMap;
    Map<String, dynamic>? postMap;

    if (compMap.containsKey('pre_op') && compMap['pre_op'] is Map) {
      preMap = Map<String, dynamic>.from(compMap['pre_op'] as Map);
    } else if (compMap.containsKey('preOp') && compMap['preOp'] is Map) {
      preMap = Map<String, dynamic>.from(compMap['preOp'] as Map);
    } else if (compMap.containsKey('pre') && compMap['pre'] is Map) {
      preMap = Map<String, dynamic>.from(compMap['pre'] as Map);
    }

    if (compMap.containsKey('post_op') && compMap['post_op'] is Map) {
      postMap = Map<String, dynamic>.from(compMap['post_op'] as Map);
    } else if (compMap.containsKey('postOp') && compMap['postOp'] is Map) {
      postMap = Map<String, dynamic>.from(compMap['postOp'] as Map);
    } else if (compMap.containsKey('post') && compMap['post'] is Map) {
      postMap = Map<String, dynamic>.from(compMap['post'] as Map);
    }

    if (rawData is List || (compMap['stages'] is List)) {
      final list = (rawData is List ? rawData : compMap['stages']) as List;
      for (final item in list) {
        if (item is Map) {
          final sName =
              (item['stage'] ?? item['category'] ?? item['name'] ?? '')
                  .toString()
                  .toLowerCase();
          if (sName.contains('post')) {
            postMap = Map<String, dynamic>.from(item);
          } else if (sName.contains('pre')) {
            preMap = Map<String, dynamic>.from(item);
          }
        }
      }
    }

    if (preMap != null) {
      final total = _parseInt(
        preMap['total_videos'] ??
            preMap['totalVideos'] ??
            preMap['total_assigned'] ??
            preMap['totalAssigned'] ??
            preMap['count'] ??
            preMap['total'],
      );
      final completed = _parseInt(
        preMap['completed_videos'] ??
            preMap['completedVideos'] ??
            preMap['total_completed'] ??
            preMap['totalCompleted'] ??
            preMap['completed'],
      );
      final inProg = _parseInt(
        preMap['in_progress_videos'] ??
            preMap['inProgressVideos'] ??
            preMap['in_progress'] ??
            preMap['inProgress'],
      );
      final notStarted = _parseInt(
        preMap['not_started_videos'] ??
            preMap['notStartedVideos'] ??
            preMap['not_started'] ??
            preMap['notStarted'],
      );
      final rate = _parseInt(
        preMap['progress_rate'] ??
            preMap['progressRate'] ??
            preMap['completion_rate'] ??
            preMap['completionRate'] ??
            preMap['percentage'] ??
            preMap['progress'],
      );

      final watchedSec = _parseInt(
        preMap['seconds_watched'] ??
            preMap['secondsWatched'] ??
            preMap['watched_seconds'] ??
            preMap['watchedSeconds'] ??
            preMap['total_watched_seconds'] ??
            preMap['time_watched'],
      );
      final durSec = _parseInt(
        preMap['total_duration_seconds'] ??
            preMap['totalDurationSeconds'] ??
            preMap['total_duration'] ??
            preMap['totalDuration'] ??
            preMap['total_time_seconds'] ??
            preMap['duration_seconds'],
      );
      final effort = _parseDouble(
        preMap['effort_share'] ?? preMap['effortShare'] ?? preMap['share'],
      );

      if (watchedSec != null) _apiPreOpSecondsWatched = watchedSec;
      if (durSec != null) _apiPreOpTotalDurationSeconds = durSec;
      if (effort != null) _apiPreOpEffortShare = effort;

      int t = total ?? preOpStats.totalAssigned;
      int c = completed ?? preOpStats.totalCompleted;
      int ip = inProg ?? preOpStats.inProgress;
      int ns = notStarted ?? (t - c - ip).clamp(0, t);
      int r = rate ?? (t > 0 ? ((c / t) * 100).round() : 0);

      preOpStats = StagePerformanceStats(
        stageName: "Pre-op",
        totalAssigned: t,
        totalCompleted: c,
        inProgress: ip,
        notStarted: ns,
        progressRate: r,
      );
    }

    if (postMap != null) {
      final total = _parseInt(
        postMap['total_videos'] ??
            postMap['totalVideos'] ??
            postMap['total_assigned'] ??
            postMap['totalAssigned'] ??
            postMap['count'] ??
            postMap['total'],
      );
      final completed = _parseInt(
        postMap['completed_videos'] ??
            postMap['completedVideos'] ??
            postMap['total_completed'] ??
            postMap['totalCompleted'] ??
            postMap['completed'],
      );
      final inProg = _parseInt(
        postMap['in_progress_videos'] ??
            postMap['inProgressVideos'] ??
            postMap['in_progress'] ??
            postMap['inProgress'],
      );
      final notStarted = _parseInt(
        postMap['not_started_videos'] ??
            postMap['notStartedVideos'] ??
            postMap['not_started'] ??
            postMap['notStarted'],
      );
      final rate = _parseInt(
        postMap['progress_rate'] ??
            postMap['progressRate'] ??
            postMap['completion_rate'] ??
            postMap['completionRate'] ??
            postMap['percentage'] ??
            postMap['progress'],
      );

      final watchedSec = _parseInt(
        postMap['seconds_watched'] ??
            postMap['secondsWatched'] ??
            postMap['watched_seconds'] ??
            postMap['watchedSeconds'] ??
            postMap['total_watched_seconds'] ??
            postMap['time_watched'],
      );
      final durSec = _parseInt(
        postMap['total_duration_seconds'] ??
            postMap['totalDurationSeconds'] ??
            postMap['total_duration'] ??
            postMap['totalDuration'] ??
            postMap['total_time_seconds'] ??
            postMap['duration_seconds'],
      );
      final effort = _parseDouble(
        postMap['effort_share'] ?? postMap['effortShare'] ?? postMap['share'],
      );

      if (watchedSec != null) _apiPostOpSecondsWatched = watchedSec;
      if (durSec != null) _apiPostOpTotalDurationSeconds = durSec;
      if (effort != null) _apiPostOpEffortShare = effort;

      int t = total ?? postOpStats.totalAssigned;
      int c = completed ?? postOpStats.totalCompleted;
      int ip = inProg ?? postOpStats.inProgress;
      int ns = notStarted ?? (t - c - ip).clamp(0, t);
      int r = rate ?? (t > 0 ? ((c / t) * 100).round() : 0);

      postOpStats = StagePerformanceStats(
        stageName: "Post-op",
        totalAssigned: t,
        totalCompleted: c,
        inProgress: ip,
        notStarted: ns,
        progressRate: r,
      );
    }

    final rootRatio = _parseDouble(
      compMap['adherence_ratio'] ??
          compMap['adherenceRatio'] ??
          compMap['stage_adherence_ratio'] ??
          compMap['relative_adherence'],
    );
    if (rootRatio != null) _apiStageAdherenceRatio = rootRatio;

    final rootPreEffort = _parseDouble(
      compMap['pre_op_effort_share'] ?? compMap['preOpEffortShare'],
    );
    if (rootPreEffort != null) _apiPreOpEffortShare = rootPreEffort;

    final rootPostEffort = _parseDouble(
      compMap['post_op_effort_share'] ?? compMap['postOpEffortShare'],
    );
    if (rootPostEffort != null) _apiPostOpEffortShare = rootPostEffort;
  }

  double? _parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) {
      final cleaned = val.replaceAll('%', '').replaceAll('x', '').trim();
      return double.tryParse(cleaned);
    }
    return null;
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
