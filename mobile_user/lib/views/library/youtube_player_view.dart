import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../core/storage/video_progress_manager.dart';
import '../../services/api_service.dart';

class YoutubePlayerView extends StatefulWidget {
  final String videoUrl;
  final String title;
  final dynamic videoId;

  const YoutubePlayerView({
    super.key,
    required this.videoUrl,
    required this.title,
    this.videoId,
  });

  @override
  State<YoutubePlayerView> createState() => _YoutubePlayerViewState();
}

class _YoutubePlayerViewState extends State<YoutubePlayerView> {
  late YoutubePlayerController _controller;
  StreamSubscription? _subscription;

  double _currentPosition = 0.0;
  double _totalDuration = 0.0;
  double _savedResumePosition = 0.0;
  bool _isCompleted = false;
  PlayerState _lastPlayerState = PlayerState.unknown;
  bool _hasSeekedToResume = false;
  bool _resumeEstablished = false;

  @override
  void initState() {
    super.initState();
    final videoId =
        YoutubePlayerController.convertUrlToId(widget.videoUrl) ?? '';

    // Load initial saved progress from Hive
    final saved = VideoProgressManager.getProgress(widget.videoUrl);
    _savedResumePosition = saved.currentPosition;
    _currentPosition = saved.currentPosition;
    _totalDuration = saved.totalDuration;
    // Calculate if completed: total watch time equals or exceeds total full duration
    _isCompleted = _totalDuration > 0 && _currentPosition >= _totalDuration;

    final double resumeSecs = (_savedResumePosition > 0 && !_isCompleted) ? _savedResumePosition : 0.0;
    if (resumeSecs <= 0) {
      _resumeEstablished = true;
    }

    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      startSeconds: resumeSecs > 0 ? resumeSecs : null,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );

    // Fallback: unlock position updates after 3 seconds in case player never sends matching timestamp
    if (resumeSecs > 0) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && !_resumeEstablished) {
          setState(() {
            _resumeEstablished = true;
          });
        }
      });
    }

    // Track playback stream & player states
    _subscription = _controller.listen((value) async {
      if (!mounted) return;

      final double dur = await _controller.duration;
      final double pos = await _controller.currentTime;

      if (dur > 0) _totalDuration = dur;

      // When resuming, ensure we seek to the saved timestamp once the player starts
      if (!_hasSeekedToResume && _savedResumePosition > 0 && !_isCompleted) {
        if (value.playerState == PlayerState.playing ||
            value.playerState == PlayerState.buffering ||
            value.playerState == PlayerState.cued) {
          _hasSeekedToResume = true;
          await _controller.seekTo(seconds: _savedResumePosition, allowSeekAhead: true);
          _currentPosition = _savedResumePosition;
        }
      }

      // Safeguard: ignore initial 0s ticks before player seeks to saved resume position
      if (_resumeEstablished) {
        if (pos > 0) {
          _currentPosition = pos;
        }
      } else {
        if (pos >= (_savedResumePosition - 1.5)) {
          _resumeEstablished = true;
          _currentPosition = pos;
        }
      }

      final PlayerState currentState = value.playerState;
      final bool ended = currentState == PlayerState.ended;
      final bool isDone = ended || (_totalDuration > 0 && _currentPosition >= _totalDuration);

      // Send to API and update UI/Hive immediately ONLY when user pauses
      if (currentState == PlayerState.paused && _lastPlayerState != PlayerState.paused) {
        if (pos > 0) {
          _currentPosition = pos;
        }
        if (mounted) {
          setState(() {
            _isCompleted = isDone;
          });
        }
        _saveToHiveAndApi(
          current: _currentPosition,
          total: _totalDuration,
          isCompleted: isDone,
        );
      }

      // Send to API and update UI/Hive when video finishes/ends
      if (ended && _lastPlayerState != PlayerState.ended) {
        if (mounted) {
          setState(() {
            _isCompleted = true;
          });
        }
        _saveToHiveAndApi(
          current: _totalDuration > 0 ? _totalDuration : _currentPosition,
          total: _totalDuration,
          isCompleted: true,
        );
      }

      _lastPlayerState = currentState;
    });
  }

  /// Saves progress to Hive and sends payload to API
  void _saveToHiveAndApi({
    required double current,
    required double total,
    required bool isCompleted,
  }) {
    final bool completed = isCompleted || (total > 0 && current >= total);

    VideoProgressManager.saveProgress(
      idOrUrl: widget.videoUrl,
      currentPosition: current,
      totalDuration: total,
      isCompleted: completed,
      videoId: widget.videoId,
    );

    final dynamic effectiveId = widget.videoId ??
        (int.tryParse(widget.videoUrl) ??
            VideoProgressManager.getProgress(widget.videoUrl).videoId ??
            0);

    ApiService().updateVideoProgress(
      videoId: effectiveId,
      currentTimestampSeconds: current,
      totalWatchTimeSeconds: total,
      isCompleted: completed,
    );
  }

  /// Triggered when user goes back or leaves the screen
  void _onExitScreen() {
    final bool completed = _isCompleted || (_totalDuration > 0 && _currentPosition >= _totalDuration);
    _saveToHiveAndApi(
      current: _currentPosition,
      total: _totalDuration,
      isCompleted: completed,
    );
  }

  @override
  void dispose() {
    _onExitScreen();
    _subscription?.cancel();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double fraction = _totalDuration > 0
        ? (_currentPosition / _totalDuration).clamp(0.0, 1.0)
        : (_isCompleted ? 1.0 : 0.0);
    final int percent = _isCompleted ? 100 : (fraction * 100).round();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _onExitScreen();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: Text(
            widget.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            // YouTube Player Container
            Container(
              color: Colors.black,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: YoutubePlayer(controller: _controller),
              ),
            ),

            // Live Progress & Complete Status Card
            Expanded(
              child: Container(
                color: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Progress Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Watch Progress',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              if (_isCompleted)
                                const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF12B76A),
                                      size: 18,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Completed',
                                      style: TextStyle(
                                        color: Color(0xFF12B76A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  '$percent% completed',
                                  style: const TextStyle(
                                    color: Color(0xFF0052CC),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _isCompleted ? 1.0 : fraction,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _isCompleted
                                    ? const Color(0xFF12B76A)
                                    : const Color(0xFF0052CC),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
