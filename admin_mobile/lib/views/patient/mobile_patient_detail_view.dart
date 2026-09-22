import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:admin_mobile/core/theme.dart';
import 'package:admin_mobile/models/user_model.dart';
import 'package:admin_mobile/services/api_service.dart';
import 'package:admin_mobile/viewmodels/library_viewmodel.dart';
import 'package:admin_mobile/viewmodels/patient_detail_viewmodel.dart';
import 'package:admin_mobile/widgets/app_logo.dart';
import 'mobile_create_patient_view.dart';

class MobilePatientDetailView extends StatefulWidget {
  final UserModel patient;
  final bool autoFetch;
  final List<Map<String, dynamic>>? initialVideos;

  const MobilePatientDetailView({
    super.key,
    required this.patient,
    this.autoFetch = true,
    this.initialVideos,
  });

  @override
  State<MobilePatientDetailView> createState() =>
      _MobilePatientDetailViewState();
}

class _MobilePatientDetailViewState extends State<MobilePatientDetailView> {
  final ApiService _apiService = ApiService();
  late UserModel _patient;

  bool _isLoading = true;
  bool _isStageLoading = false;
  bool _isHistoryLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _videoHistory = [];
  int _totalVideos = 0;
  int _completedVideos = 0;
  int _progressRate = 0;
  String _selectedOpStage = "Pre-op";
  String _selectedHistoryCategory = "All";

  StagePerformanceStats _preOpStats = const StagePerformanceStats(
    stageName: "Pre-op",
    totalAssigned: 0,
    totalCompleted: 0,
    progressRate: 0,
  );

  StagePerformanceStats _postOpStats = const StagePerformanceStats(
    stageName: "Post-op",
    totalAssigned: 0,
    totalCompleted: 0,
    progressRate: 0,
  );

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    if (widget.initialVideos != null) {
      _videoHistory = widget.initialVideos!;
      _totalVideos = _videoHistory.length;
      _completedVideos = _videoHistory
          .where((v) => v['isCompleted'] == true || v['progress'] == 100)
          .length;
      _progressRate = _totalVideos > 0
          ? ((_completedVideos / _totalVideos) * 100).round()
          : 0;
      _isLoading = false;
    } else if (!widget.autoFetch) {
      _isLoading = false;
    } else {
      _fetchPatientDetails();
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

  Future<void> _onStageChanged(String stage) async {
    if (_selectedOpStage == stage && !_isStageLoading) return;
    setState(() {
      _selectedOpStage = stage;
      _isStageLoading = true;
      if (stage == "Pre-op" && _preOpStats.totalAssigned > 0) {
        _totalVideos = _preOpStats.totalAssigned;
        _completedVideos = _preOpStats.totalCompleted;
        _progressRate = _preOpStats.progressRate;
      } else if (stage == "Post-op" && _postOpStats.totalAssigned > 0) {
        _totalVideos = _postOpStats.totalAssigned;
        _completedVideos = _postOpStats.totalCompleted;
        _progressRate = _postOpStats.progressRate;
      }
    });

    try {
      final progressRes = await _apiService.getUserProgress(
        _patient.id,
        category: stage == 'All' ? null : stage.toLowerCase(),
      );
      if (progressRes.data != null && mounted) {
        setState(() {
          _parseProgressData(progressRes.data);
        });
      }
    } catch (e) {
      debugPrint("Error fetching progress for $stage: $e");
    } finally {
      if (mounted) setState(() => _isStageLoading = false);
    }
  }

  Future<void> _onHistoryCategoryChanged(String category) async {
    if (_selectedHistoryCategory == category && !_isHistoryLoading) return;
    setState(() {
      _selectedHistoryCategory = category;
      _isHistoryLoading = true;
    });

    try {
      final res = await _apiService.getUserHistory(
        _patient.id,
        category: category.toLowerCase() == 'all' ? null : category.toLowerCase(),
      );
      if (res.data != null && mounted) {
        setState(() {
          _parseHistoryData(res.data);
        });
      }
    } catch (e) {
      debugPrint("Error fetching history for $category: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isHistoryLoading = false;
        });
      }
    }
  }

  void _parseHistoryData(dynamic hData, {List<Map<String, dynamic>>? fallbackVideos}) {
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
      }
    }
    if (rawHistory.isNotEmpty) {
      _videoHistory = rawHistory
          .whereType<Map>()
          .map((v) => Map<String, dynamic>.from(v))
          .toList();
    } else if (fallbackVideos != null && fallbackVideos.isNotEmpty && _selectedHistoryCategory == "All") {
      _videoHistory = fallbackVideos;
    } else {
      _videoHistory = [];
    }
  }

  Future<void> _fetchPatientDetails({String? category}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final activeCategory = category ?? _selectedOpStage;

    try {
      final userRes = await _apiService.getUserById(_patient.id);

      final preOpFuture = _apiService.getUserProgress(
        _patient.id,
        category: 'pre-op',
      ).catchError((e) {
        debugPrint("Error fetching pre-op progress: $e");
        return Response(requestOptions: RequestOptions(path: ''), data: null);
      });

      final postOpFuture = _apiService.getUserProgress(
        _patient.id,
        category: 'post-op',
      ).catchError((e) {
        debugPrint("Error fetching post-op progress: $e");
        return Response(requestOptions: RequestOptions(path: ''), data: null);
      });

      final historyFuture = _apiService.getUserHistory(
        _patient.id, 
        category: _selectedHistoryCategory.toLowerCase() == 'all' ? null : _selectedHistoryCategory.toLowerCase(),
      ).catchError((e) {
        debugPrint("Error fetching user history logs: $e");
        return Response(requestOptions: RequestOptions(path: ''), data: null);
      });

      final results = await Future.wait([preOpFuture, postOpFuture, historyFuture]);

      final preOpProgressRes = results[0];
      final postOpProgressRes = results[1];
      final historyRes = results[2];

      Response? activeProgressRes;
      final cat = activeCategory.toLowerCase();
      if (cat == 'pre-op') {
        activeProgressRes = preOpProgressRes;
      } else if (cat == 'post-op') {
        activeProgressRes = postOpProgressRes;
      } else {
        activeProgressRes = await _apiService.getUserProgress(
          _patient.id,
          category: cat == 'all' ? null : cat,
        ).catchError((e) {
          debugPrint("Error fetching user progress for $activeCategory: $e");
          return Response(requestOptions: RequestOptions(path: ''), data: null);
        });
      }
      final resData = userRes.data;

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
        _patient = UserModel.fromJson(userData);

        final List<dynamic> rawVideos =
            userData['assigned_videos'] ??
            userData['assignedVideos'] ??
            userData['videos'] ??
            userData['history'] ??
            userData['watched_videos'] ??
            [];

        _videoHistory = rawVideos
            .map((v) => Map<String, dynamic>.from(v as Map))
            .toList();

        // If history API returned data, use or supplement it
        if (historyRes.data != null) {
          _parseHistoryData(
            historyRes.data,
            fallbackVideos: List<Map<String, dynamic>>.from(_videoHistory),
          );
        }

        _totalVideos =
            _parseInt(
              userData['total_videos'] ??
                  userData['totalVideos'] ??
                  userData['total_assigned'] ??
                  userData['total_watched'],
            ) ??
            _videoHistory.length;

        _completedVideos =
            _parseInt(
              userData['total_completed'] ??
                  userData['completed_videos'] ??
                  userData['completedCount'],
            ) ??
            _videoHistory
                .where(
                  (v) =>
                      v['isCompleted'] == true ||
                      v['completed'] == true ||
                      v['status'] == 'completed' ||
                      v['progress'] == 100,
                )
                .length;

        if (_totalVideos > 0) {
          _progressRate = ((_completedVideos / _totalVideos) * 100).round();
        } else if (userData['progress'] != null) {
          _progressRate = _parseInt(userData['progress']) ?? 0;
        } else {
          _progressRate = 0;
        }
      }

      if (activeProgressRes.data != null) {
        _parseProgressData(activeProgressRes.data);
      }

      _computeStageStats(
        preOpApiData: preOpProgressRes.data,
        postOpApiData: postOpProgressRes.data,
      );
    } catch (e) {
      debugPrint("Error fetching patient details: $e");
      _errorMessage = "Failed to load patient profile.";
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? _extractStatsMap(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) {
      if (raw['data'] is Map) {
        final d = raw['data'] as Map;
        if (d['engagement'] is Map) {
          return Map<String, dynamic>.from(d['engagement'] as Map);
        }
        if (d['overview'] is Map) {
          return Map<String, dynamic>.from(d['overview'] as Map);
        }
        if (d['stats'] is Map) {
          return Map<String, dynamic>.from(d['stats'] as Map);
        }
        return Map<String, dynamic>.from(d);
      }
      if (raw['engagement'] is Map) {
        return Map<String, dynamic>.from(raw['engagement'] as Map);
      }
      if (raw['overview'] is Map) {
        return Map<String, dynamic>.from(raw['overview'] as Map);
      }
      if (raw['stats'] is Map) {
        return Map<String, dynamic>.from(raw['stats'] as Map);
      }
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  void _parseProgressData(dynamic raw) {
    final stats = _extractStatsMap(raw);
    if (stats == null || stats.isEmpty) return;

    final parsedTotal = _parseInt(
      stats['totalAssigned'] ??
          stats['total_assigned'] ??
          stats['totalVideos'] ??
          stats['total_videos'] ??
          stats['assignedVideos'] ??
          stats['assigned_videos'] ??
          stats['assigned'] ??
          stats['total'] ??
          stats['count'],
    );
    if (parsedTotal != null) _totalVideos = parsedTotal;

    final parsedCompleted = _parseInt(
      stats['totalCompleted'] ??
          stats['total_completed'] ??
          stats['completedVideos'] ??
          stats['completed_videos'] ??
          stats['completedCount'] ??
          stats['completed_count'] ??
          stats['completed'] ??
          stats['watchedVideos'] ??
          stats['watched_videos'] ??
          stats['videosWatched'] ??
          stats['videos_watched'],
    );
    if (parsedCompleted != null) _completedVideos = parsedCompleted;

    final parsedRate = _parseInt(
      stats['progressRate'] ??
          stats['progress_rate'] ??
          stats['overallProgress'] ??
          stats['overall_progress'] ??
          stats['completionRate'] ??
          stats['completion_rate'] ??
          stats['progressPercentage'] ??
          stats['progress_percentage'] ??
          stats['progress'] ??
          stats['rate'] ??
          stats['percentage'],
    );
    if (parsedRate != null) {
      _progressRate = parsedRate;
    } else if (_totalVideos > 0) {
      _progressRate = ((_completedVideos / _totalVideos) * 100).round();
    }

    if (stats['video_history'] is List ||
        stats['videoHistory'] is List ||
        stats['videos'] is List ||
        stats['history'] is List ||
        stats['assigned_videos'] is List) {
      final List list =
          (stats['video_history'] ??
                  stats['videoHistory'] ??
                  stats['videos'] ??
                  stats['history'] ??
                  stats['assigned_videos'])
              as List;
      if (list.isNotEmpty) {
        _videoHistory = list
            .map((v) => Map<String, dynamic>.from(v as Map))
            .toList();
      }
    }
  }

  void _computeStageStats({dynamic preOpApiData, dynamic postOpApiData}) {
    final preOpVideos = _videoHistory.where((v) {
      final cat = (v['category'] ?? v['stage'] ?? '').toString().toLowerCase();
      return !cat.contains('post') && (cat.contains('pre') || cat.isEmpty);
    }).toList();

    final postOpVideos = _videoHistory.where((v) {
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

      if (apiTotal != null && apiTotal > 0) preAssigned = apiTotal;
      if (apiComp != null) preCompleted = apiComp;
      if (apiRate != null) {
        preRate = apiRate;
      } else if (preAssigned > 0) {
        preRate = ((preCompleted / preAssigned) * 100).round();
      }
      preInProgress = (preAssigned - preCompleted).clamp(0, preAssigned);
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

      if (apiTotal != null && apiTotal > 0) postAssigned = apiTotal;
      if (apiComp != null) postCompleted = apiComp;
      if (apiRate != null) {
        postRate = apiRate;
      } else if (postAssigned > 0) {
        postRate = ((postCompleted / postAssigned) * 100).round();
      }
      postInProgress = (postAssigned - postCompleted).clamp(0, postAssigned);
      postNotStarted = (postAssigned - postCompleted - postInProgress).clamp(
        0,
        postAssigned,
      );
    }

    _preOpStats = StagePerformanceStats(
      stageName: "Pre-op",
      totalAssigned: preAssigned,
      totalCompleted: preCompleted,
      inProgress: preInProgress,
      notStarted: preNotStarted,
      progressRate: preRate,
    );

    _postOpStats = StagePerformanceStats(
      stageName: "Post-op",
      totalAssigned: postAssigned,
      totalCompleted: postCompleted,
      inProgress: postInProgress,
      notStarted: postNotStarted,
      progressRate: postRate,
    );
  }

  Future<void> _unassignVideo(Map<String, dynamic> video) async {
    final title = video['title'] ?? 'this video';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Unassign Video"),
        content: Text(
          "Are you sure you want to remove '$title' from ${_patient.name}'s assigned list?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Remove", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final updatedList = _videoHistory.where((v) {
          final vId = v['id'] ?? v['_id'];
          final targetId = video['id'] ?? video['_id'];
          if (vId != null && targetId != null) return vId != targetId;
          return v['title'] != video['title'];
        }).toList();

        await _apiService.editUser(_patient.id, {
          'assigned_videos': updatedList,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Video removed from patient assignment"),
              backgroundColor: AppTheme.success,
            ),
          );
          _fetchPatientDetails();
        }
      } catch (e) {
        debugPrint("Error unassigning video: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to remove video"),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showVideoPreviewDialog(Map<String, dynamic> video) {
    final url =
        (video['youtubeUrl'] ?? video['video_url'] ?? video['url'] ?? '')
            .toString()
            .trim();
    final ytId = VideoLibraryViewModel.extractYoutubeId(url);

    showDialog(
      context: context,
      builder: (context) {
        YoutubePlayerController? controller;
        if (ytId != null && ytId.isNotEmpty) {
          controller = YoutubePlayerController.fromVideoId(
            videoId: ytId,
            autoPlay: true,
            params: const YoutubePlayerParams(
              showControls: true,
              showFullscreenButton: true,
              mute: false,
            ),
          );
        }

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        video['title'] ?? 'Video Preview',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        controller?.close();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Player
              if (controller != null)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: YoutubePlayer(
                    controller: controller,
                    aspectRatio: 16 / 9,
                  ),
                )
              else
                Container(
                  height: 200,
                  color: Colors.black87,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_circle_outline,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          url.isNotEmpty ? url : "No video stream link",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${video['duration'] ?? 'Stream'} • ${video['category'] ?? 'General'}",
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        controller?.close();
                        Navigator.of(context).pop();
                      },
                      child: const Text("Close"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Patient"),
        content: Text(
          "Are you sure you want to permanently delete ${_patient.name}? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _apiService.deleteUser(_patient.id);
      if (success.statusCode == 200 || success.statusCode == 204) {
        if (!mounted) return;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Patient deleted successfully"),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive =
        _patient.status.toLowerCase() == "active" || _patient.status.isEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          _patient.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _isLoading ? null : _fetchPatientDetails,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MobileCreatePatientView(patientToEdit: _patient),
                ),
              );
              if (result == true) {
                _fetchPatientDetails();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: _confirmDelete,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading && _videoHistory.isEmpty
          ? const Center(
              child: AppLogoLoader(
                size: 52,
                message: "Loading patient details...",
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchPatientDetails,
              color: AppTheme.primaryBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppTheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppTheme.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Patient Profile Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildAvatar(),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _patient.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? AppTheme.emeraldBg
                                                : AppTheme.background,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: isActive
                                                  ? AppTheme.emeraldBorder
                                                  : AppTheme.border,
                                            ),
                                          ),
                                          child: Text(
                                            isActive
                                                ? "Active"
                                                : _patient.status,
                                            style: TextStyle(
                                              color: isActive
                                                  ? AppTheme.emeraldText
                                                  : AppTheme.textSecondary,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${_patient.age > 0 ? '${_patient.age} yrs' : 'Age N/A'} • ${_patient.gender}",
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "ID: P${_patient.id.length > 6 ? _patient.id.substring(0, 6) : _patient.id}",
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // Contact Info List
                          _buildInfoRow(
                            Icons.phone_outlined,
                            "Phone",
                            _patient.phone,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.email_outlined,
                            "Email",
                            _patient.email,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.cake_outlined,
                            "DOB",
                            _patient.dob.isNotEmpty ? _patient.dob : "N/A",
                          ),
                          if (_patient.language.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.language_outlined,
                              "Language",
                              _patient.language,
                            ),
                          ],
                          if (_patient.note.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.notes,
                              "Clinical Notes",
                              _patient.note,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Engagement Stats Card with Stage Switcher
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Educational Engagement",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),

                              // PRE-OP OR POST-OP SELECTION BOX
                              Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.borderMedium,
                                  ),
                                ),
                                child: _isStageLoading
                                    ? const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        child: SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      )
                                    : PopupMenuButton<String>(
                                        tooltip: "Select Stage",
                                        offset: const Offset(0, 36),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          side: const BorderSide(
                                            color: AppTheme.border,
                                          ),
                                        ),
                                        color: Colors.white,
                                        elevation: 4,
                                        onSelected: _onStageChanged,
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: "Pre-op",
                                            height: 36,
                                            child: Text(
                                              "Pre-op",
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                    _selectedOpStage == "Pre-op"
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                color:
                                                    _selectedOpStage == "Pre-op"
                                                    ? AppTheme.primary
                                                    : AppTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: "Post-op",
                                            height: 36,
                                            child: Text(
                                              "Post-op",
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                    _selectedOpStage ==
                                                        "Post-op"
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                color:
                                                    _selectedOpStage ==
                                                        "Post-op"
                                                    ? AppTheme.primary
                                                    : AppTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: "All",
                                            height: 36,
                                            child: Text(
                                              "All",
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                    _selectedOpStage == "All"
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                color: _selectedOpStage == "All"
                                                    ? AppTheme.primary
                                                    : AppTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _selectedOpStage,
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons
                                                    .keyboard_arrow_down_rounded,
                                                size: 16,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AnimatedOpacity(
                            opacity: _isStageLoading ? 0.6 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatTile(
                                        "Assigned",
                                        "$_totalVideos",
                                        Icons.video_library_outlined,
                                        AppTheme.blue,
                                        AppTheme.blueBg,
                                        AppTheme.blueBorder,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildStatTile(
                                        "Completed",
                                        "$_completedVideos",
                                        Icons.check_circle_outline,
                                        AppTheme.emerald,
                                        AppTheme.emeraldBg,
                                        AppTheme.emeraldBorder,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildStatTile(
                                        "Progress",
                                        "$_progressRate%",
                                        Icons.trending_up,
                                        AppTheme.purple,
                                        AppTheme.purpleBg,
                                        AppTheme.purpleBorder,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _totalVideos > 0
                                        ? (_completedVideos / _totalVideos)
                                              .clamp(0.0, 1.0)
                                        : 0.0,
                                    minHeight: 6,
                                    backgroundColor: AppTheme.borderSubtle,
                                    color: _progressRate == 100
                                        ? AppTheme.emerald
                                        : AppTheme.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stage Performance Comparison Card (Pre-Op vs Post-Op)
                    _buildStagePerformanceComparisonCard(),
                    const SizedBox(height: 16),

                    _buildAssignedAndWatchedCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAssignedAndWatchedCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.blueBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: AppTheme.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Assigned & Watched Video History",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              // Category filter dropdown
              Container(
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderMedium),
                ),
                child: PopupMenuButton<String>(
                  tooltip: "Select Category",
                  offset: const Offset(0, 34),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  color: Colors.white,
                  elevation: 4,
                  onSelected: _onHistoryCategoryChanged,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: "All",
                      height: 32,
                      child: Text(
                        "All",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: _selectedHistoryCategory == "All"
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: _selectedHistoryCategory == "All"
                              ? AppTheme.primary
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: "Pre-op",
                      height: 32,
                      child: Text(
                        "Pre-op",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: _selectedHistoryCategory == "Pre-op"
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: _selectedHistoryCategory == "Pre-op"
                              ? AppTheme.primary
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: "Post-op",
                      height: 32,
                      child: Text(
                        "Post-op",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: _selectedHistoryCategory == "Post-op"
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: _selectedHistoryCategory == "Post-op"
                              ? AppTheme.primary
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedHistoryCategory,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 15,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Count Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  "${_videoHistory.length} ${_videoHistory.length == 1 ? 'Video' : 'Videos'}",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isHistoryLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.primary,
                ),
              ),
            )
          else if (_videoHistory.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.video_library_outlined,
                    size: 36,
                    color: AppTheme.textLight,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "No assigned or watched videos found for this patient.",
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _videoHistory.length,
              separatorBuilder: (context, index) => const Divider(
                height: 16,
                color: AppTheme.borderSubtle,
              ),
              itemBuilder: (context, index) {
                final v = _videoHistory[index];
                final isCompleted =
                    v['isCompleted'] == true ||
                    v['completed'] == true ||
                    v['progress'] == 100;
                final title = v['title']?.toString() ??
                    v['name']?.toString() ??
                    'Video #${index + 1}';
                final duration = v['duration']?.toString() ?? '10:00';
                final category = v['category']?.toString() ?? 'General';
                final isPostOp = category.toLowerCase().contains('post');

                return InkWell(
                  onTap: () => _showVideoPreviewDialog(v),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppTheme.emeraldBg
                                : AppTheme.blueBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCompleted
                                  ? AppTheme.emeraldBorder
                                  : AppTheme.blueBorder,
                            ),
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check_circle
                                : Icons.play_circle_outline,
                            color: isCompleted
                                ? AppTheme.emeraldText
                                : AppTheme.blueText,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Text(
                                    duration,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isPostOp
                                          ? AppTheme.purpleBg
                                          : AppTheme.blueBg,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isPostOp
                                            ? AppTheme.purpleBorder
                                            : AppTheme.blueBorder,
                                      ),
                                    ),
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        color: isPostOp
                                            ? AppTheme.purpleText
                                            : AppTheme.blueText,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppTheme.emeraldBg
                                : AppTheme.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isCompleted
                                  ? AppTheme.emeraldBorder
                                  : AppTheme.border,
                            ),
                          ),
                          child: Text(
                            isCompleted ? "Completed" : "Assigned",
                            style: TextStyle(
                              color: isCompleted
                                  ? AppTheme.emeraldText
                                  : AppTheme.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            size: 18,
                            color: Colors.grey,
                          ),
                          padding: EdgeInsets.zero,
                          onSelected: (action) {
                            if (action == 'play') {
                              _showVideoPreviewDialog(v);
                            } else if (action == 'unassign') {
                              _unassignVideo(v);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'play',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.play_circle_outline,
                                    size: 18,
                                    color: AppTheme.blue,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Play Video',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'unassign',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.remove_circle_outline,
                                    size: 18,
                                    color: AppTheme.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Unassign Video',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final palette = AppTheme.getAvatarPalette(_patient.name);
    if (_patient.imageUrl.isNotEmpty) {
      return FutureBuilder<Uint8List?>(
        future: _apiService.fetchImageBytes(_patient.imageUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.data != null &&
              snapshot.data!.isNotEmpty) {
            return CircleAvatar(
              radius: 26,
              backgroundImage: MemoryImage(snapshot.data!),
            );
          }
          return CircleAvatar(
            radius: 26,
            backgroundColor: palette['bg'],
            child: Text(
              _patient.name.isNotEmpty ? _patient.name[0].toUpperCase() : 'P',
              style: TextStyle(
                color: palette['fg'],
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          );
        },
      );
    }

    return CircleAvatar(
      radius: 26,
      backgroundColor: palette['bg'],
      child: Text(
        _patient.name.isNotEmpty ? _patient.name[0].toUpperCase() : 'P',
        style: TextStyle(
          color: palette['fg'],
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildStagePerformanceComparisonCard() {
    final preOp = _preOpStats;
    final postOp = _postOpStats;
    final delta = postOp.progressRate - preOp.progressRate;

    String deltaLabel;
    Color deltaTextColor;
    Color deltaBg;
    Color deltaBorder;
    IconData deltaIcon;

    if (delta > 0) {
      deltaLabel = "Post-Op +${delta.abs()}%";
      deltaTextColor = AppTheme.emeraldText;
      deltaBg = AppTheme.emeraldBg;
      deltaBorder = AppTheme.emeraldBorder;
      deltaIcon = Icons.trending_up_rounded;
    } else if (delta < 0) {
      deltaLabel = "Pre-Op +${delta.abs()}%";
      deltaTextColor = AppTheme.blueText;
      deltaBg = AppTheme.blueBg;
      deltaBorder = AppTheme.blueBorder;
      deltaIcon = Icons.trending_up_rounded;
    } else {
      deltaLabel = "Compare";
      deltaTextColor = AppTheme.textSecondary;
      deltaBg = AppTheme.borderSubtle;
      deltaBorder = AppTheme.borderMedium;
      deltaIcon = Icons.horizontal_rule_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.purpleBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.compare_arrows_rounded,
                      color: AppTheme.purple,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Pre-Op & Post-Op",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: deltaBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: deltaBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(deltaIcon, size: 12, color: deltaTextColor),
                    const SizedBox(width: 4),
                    Text(
                      deltaLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: deltaTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Pre-Op and Post-Op visual cards
          Row(
            children: [
              Expanded(
                child: _buildStageDetailBox(
                  stageTitle: "PRE-OP",
                  icon: Icons.assignment_outlined,
                  stats: preOp,
                  accentColor: AppTheme.blue,
                  cardBg: AppTheme.blueCardBg,
                  borderColor: AppTheme.blueBorder,
                  textColor: AppTheme.blueText,
                  badgeBg: AppTheme.blueBg,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStageDetailBox(
                  stageTitle: "POST-OP",
                  icon: Icons.healing_outlined,
                  stats: postOp,
                  accentColor: AppTheme.emerald,
                  cardBg: AppTheme.emeraldCardBg,
                  borderColor: AppTheme.emeraldBorder,
                  textColor: AppTheme.emeraldText,
                  badgeBg: AppTheme.emeraldBg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStageDetailBox({
    required String stageTitle,
    required IconData icon,
    required StagePerformanceStats stats,
    required Color accentColor,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color badgeBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stageTitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 12, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "${stats.progressRate}%",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "${stats.totalCompleted} / ${stats.totalAssigned} done",
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(
            fontSize: 12.5,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : "N/A",
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    IconData icon,
    Color fg,
    Color bg,
    Color border,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: fg,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
