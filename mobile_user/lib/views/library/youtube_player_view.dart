import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../core/storage/video_progress_manager.dart';
import '../../services/api_service.dart';

class YoutubePlayerView extends StatefulWidget {
  final String videoUrl;
  final String title;
  final dynamic videoId;
  final Widget? customPlayerWidget;
  final YoutubePlayerController? controller;
  final bool enableApiSync;

  const YoutubePlayerView({
    super.key,
    required this.videoUrl,
    required this.title,
    this.videoId,
    this.customPlayerWidget,
    this.controller,
    this.enableApiSync = true,
  });

  @override
  State<YoutubePlayerView> createState() => _YoutubePlayerViewState();
}

class _YoutubePlayerViewState extends State<YoutubePlayerView> {
  YoutubePlayerController? _controller;
  StreamSubscription? _subscription;
  Timer? _fallbackTimer;

  // ===========================================================================
  // PLAYBACK & PROGRESS TRACKING STATE
  // ===========================================================================
  String _extractedVideoId = '';
  double _currentPosition = 0.0;
  double _lastPosition = 0.0;
  double _maxWatchedPosition = 0.0;
  double _videoDuration = 0.0;
  bool _isSeekingBack = false;

  double _savedResumePosition = 0.0;
  bool _isCompleted = false;
  PlayerState _lastPlayerState = PlayerState.unknown;
  bool _hasSeekedToResume = false;
  bool _resumeEstablished = false;

  bool _isPlaying = false;
  double _currentPlaybackRate = 1.0;

  // Tolerance threshold (in seconds) for normal playback updates
  static const double _normalPlaybackToleranceSecs = 3.0;

  String get _thumbnailUrl => _extractedVideoId.isNotEmpty
      ? 'https://img.youtube.com/vi/$_extractedVideoId/hqdefault.jpg'
      : '';

  @override
  void initState() {
    super.initState();
    _extractedVideoId =
        YoutubePlayerController.convertUrlToId(widget.videoUrl) ?? '';

    // Load initial saved progress from Hive storage
    final saved = VideoProgressManager.getProgress(widget.videoUrl);
    _savedResumePosition = saved.currentPosition;
    _currentPosition = saved.currentPosition;
    _lastPosition = saved.currentPosition;
    _maxWatchedPosition = saved.currentPosition;
    _videoDuration = saved.totalDuration;

    // Video is completed if marked in storage or watched to the end
    _isCompleted = saved.isCompleted ||
        (_videoDuration > 0 && _currentPosition >= (_videoDuration - 1.0));

    final double resumeSecs = (_savedResumePosition > 0 && !_isCompleted)
        ? _savedResumePosition
        : 0.0;
    if (resumeSecs <= 0) {
      _resumeEstablished = true;
    }

    if (widget.controller != null) {
      _controller = widget.controller;
    } else if (widget.customPlayerWidget == null) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: _extractedVideoId,
        autoPlay: true,
        startSeconds: resumeSecs > 0 ? resumeSecs : null,
        params: const YoutubePlayerParams(
          showControls: false, // Hides native YouTube controls & red progress bar
          showFullscreenButton: false,
          strictRelatedVideos: true,
          showVideoAnnotations: false,
          enableCaption: false,
        ),
      );
    }

    // Fallback: unlock position updates after 3 seconds in case player never sends matching timestamp
    if (resumeSecs > 0 && widget.customPlayerWidget == null) {
      _fallbackTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && !_resumeEstablished) {
          setState(() {
            _resumeEstablished = true;
          });
        }
      });
    }

    // Track playback stream & player states
    if (_controller != null) {
      _subscription = _controller!.listen((value) async {
        if (!mounted) return;

        final double dur = await _controller!.duration;
        final double pos = await _controller!.currentTime;

        if (dur > 0 && _videoDuration != dur) {
          setState(() {
            _videoDuration = dur;
          });
        }

        // When resuming, seek to the saved timestamp once the player starts
        if (!_hasSeekedToResume && _savedResumePosition > 0 && !_isCompleted) {
          if (value.playerState == PlayerState.playing ||
              value.playerState == PlayerState.buffering ||
              value.playerState == PlayerState.cued) {
            _hasSeekedToResume = true;
            _isSeekingBack = true;
            await _controller!.seekTo(
              seconds: _savedResumePosition,
              allowSeekAhead: true,
            );
            _currentPosition = _savedResumePosition;
            _lastPosition = _savedResumePosition;
            _maxWatchedPosition =
                _maxWatchedPosition > _savedResumePosition
                    ? _maxWatchedPosition
                    : _savedResumePosition;
            _isSeekingBack = false;
            return;
          }
        }

        // Safeguard: ignore initial 0s ticks before player seeks to saved resume position
        if (!_resumeEstablished) {
          if (pos >= (_savedResumePosition - 1.5)) {
            _resumeEstablished = true;
            _currentPosition = pos;
            _lastPosition = pos;
            _maxWatchedPosition =
                _maxWatchedPosition > pos ? _maxWatchedPosition : pos;
          }
          return;
        }

        // Forward-seek detection & enforcement
        if (_isSeekingBack) {
          if (pos <= _maxWatchedPosition + 0.5) {
            _isSeekingBack = false;
            _currentPosition = pos;
            _lastPosition = pos;
          }
          return;
        }

        if (!_isCompleted && pos > 0) {
          if (pos <= _maxWatchedPosition) {
            _currentPosition = pos;
            _lastPosition = pos;
          } else {
            final double forwardJumpFromLast = pos - _lastPosition;
            final double forwardJumpFromMax = pos - _maxWatchedPosition;

            final bool isNormalProgression =
                forwardJumpFromLast >= 0 &&
                forwardJumpFromLast <= _normalPlaybackToleranceSecs &&
                forwardJumpFromMax <= _normalPlaybackToleranceSecs;

            if (isNormalProgression) {
              _currentPosition = pos;
              _lastPosition = pos;
              _maxWatchedPosition = pos;
            } else {
              _isSeekingBack = true;
              await _controller!.seekTo(
                seconds: _maxWatchedPosition,
                allowSeekAhead: true,
              );
              _currentPosition = _maxWatchedPosition;
              _lastPosition = _maxWatchedPosition;
              _isSeekingBack = false;
              return;
            }
          }
        } else if (_isCompleted && pos > 0) {
          _currentPosition = pos;
          _lastPosition = pos;
          _maxWatchedPosition =
              _videoDuration > 0 ? _videoDuration : _maxWatchedPosition;
        }

        final PlayerState currentState = value.playerState;
        final bool isCurrentlyPlaying = currentState == PlayerState.playing;
        final bool ended = currentState == PlayerState.ended;
        final bool isDone = ended ||
            (_videoDuration > 0 &&
                _maxWatchedPosition >= (_videoDuration - 1.0));

        if (_isPlaying != isCurrentlyPlaying || _isCompleted != isDone) {
          setState(() {
            _isPlaying = isCurrentlyPlaying;
            if (isDone) {
              _isCompleted = true;
              _maxWatchedPosition =
                  _videoDuration > 0 ? _videoDuration : _maxWatchedPosition;
            }
          });
        } else {
          setState(() {});
        }

        // Send to API and update Hive on pause
        if (currentState == PlayerState.paused &&
            _lastPlayerState != PlayerState.paused) {
          _saveToHiveAndApi(
            current: _maxWatchedPosition,
            total: _videoDuration,
            isCompleted: _isCompleted,
          );
        }

        // Send to API and update Hive on finish
        if (ended && _lastPlayerState != PlayerState.ended) {
          _saveToHiveAndApi(
            current: _videoDuration > 0 ? _videoDuration : _maxWatchedPosition,
            total: _videoDuration,
            isCompleted: true,
          );
        }

        _lastPlayerState = currentState;
      });
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _controller?.pauseVideo();
    } else {
      _controller?.playVideo();
    }
  }

  void _changePlaybackRate(double rate) {
    _controller?.setPlaybackRate(rate);
    setState(() {
      _currentPlaybackRate = rate;
    });
  }

  /// Saves progress to Hive first, then reads from Hive to send the payload to API
  Future<void> _saveToHiveAndApi({
    required double current,
    required double total,
    required bool isCompleted,
  }) async {
    final bool completed =
        isCompleted || (total > 0 && current >= (total - 1.0));

    // 1. Persist to Hive storage
    await VideoProgressManager.saveProgress(
      idOrUrl: widget.videoUrl,
      currentPosition: current,
      totalDuration: total,
      isCompleted: completed,
      videoId: widget.videoId,
    );

    // 2. Read the authoritative values directly from Hive
    final saved = VideoProgressManager.getProgress(widget.videoUrl);

    final dynamic effectiveId =
        saved.videoId ??
        widget.videoId ??
        (int.tryParse(widget.videoUrl) ?? 0);

    // 3. Send to API using values from Hive
    if (widget.enableApiSync) {
      ApiService().updateVideoProgress(
        videoId: effectiveId,
        currentTimestampSeconds: saved.currentPosition,
        totalWatchTimeSeconds: saved.totalDuration,
        isCompleted: saved.isCompleted,
      );
    }
  }

  /// Triggered when user goes back or leaves the screen
  void _onExitScreen() {
    final bool completed =
        _isCompleted ||
        (_videoDuration > 0 && _maxWatchedPosition >= (_videoDuration - 1.0));
    _saveToHiveAndApi(
      current: _maxWatchedPosition,
      total: _videoDuration,
      isCompleted: completed,
    );
  }

  String _formatDuration(double seconds) {
    if (seconds.isNaN || seconds.isInfinite || seconds <= 0) return '00:00';
    final dur = Duration(seconds: seconds.round());
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = dur.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$secs';
    }
    return '$minutes:$secs';
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _onExitScreen();
    _subscription?.cancel();
    _controller?.close();
    super.dispose();
  }

  Widget _buildVideoPlayerWithOverlay(Widget playerWidget) {
    final bool showPausedCover = !_isPlaying &&
        (_lastPlayerState == PlayerState.paused ||
            _lastPlayerState == PlayerState.ended ||
            _isCompleted);

    return Container(
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          children: [
            playerWidget,

            // Paused / Ended Cover Overlay that completely hides YouTube's suggested video cards popup
            if (showPausedCover)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _togglePlayPause,
                  child: Container(
                    color: const Color(0xFF0F172A),
                    child: Stack(
                      alignment: Alignment.center,
                      fit: StackFit.expand,
                      children: [
                        // Video Thumbnail Poster
                        if (_thumbnailUrl.isNotEmpty)
                          Image.network(
                            _thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: const Color(0xFF0F172A)),
                          ),

                        // Dark Gradient Scrim to hide any iframe artifacts underneath
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.45),
                                Colors.black.withValues(alpha: 0.75),
                              ],
                            ),
                          ),
                        ),

                        // Status Badge at top-left
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isCompleted || _lastPlayerState == PlayerState.ended
                                      ? Icons.check_circle_rounded
                                      : Icons.pause_circle_filled_rounded,
                                  color: _isCompleted || _lastPlayerState == PlayerState.ended
                                      ? const Color(0xFF12B76A)
                                      : const Color(0xFF38BDF8),
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _isCompleted || _lastPlayerState == PlayerState.ended
                                      ? 'Finished'
                                      : 'Paused',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Transparent Gesture Overlay to intercept clicks while playing
            if (!showPausedCover)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _togglePlayPause,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomControlsBar() {
    final double fraction = _videoDuration > 0
        ? (_currentPosition / _videoDuration).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Non-skippable Progress Line and Timestamps
          Row(
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 4,
                    backgroundColor: const Color(0xFF334155),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatDuration(_videoDuration),
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Row 2: Control Buttons (Play/Pause, Speed, Fullscreen)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Play / Pause Button
              Material(
                color: const Color(0xFF2563EB),
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _togglePlayPause,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),

              // Right Group: Playback Speed & Fullscreen Button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<double>(
                    tooltip: 'Playback Speed',
                    initialValue: _currentPlaybackRate,
                    onSelected: _changePlaybackRate,
                    color: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Color(0xFF334155)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF334155),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${_currentPlaybackRate == 1.0 ? '1.0' : _currentPlaybackRate}x',
                        style: const TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    itemBuilder: (context) => [
                      0.75,
                      1.0,
                      1.25,
                      1.5,
                      2.0,
                    ].map((rate) {
                      return PopupMenuItem<double>(
                        value: rate,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${rate}x',
                              style: TextStyle(
                                color: _currentPlaybackRate == rate
                                    ? const Color(0xFF38BDF8)
                                    : Colors.white,
                                fontWeight: _currentPlaybackRate == rate
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (_currentPlaybackRate == rate)
                              const Icon(
                                Icons.check_rounded,
                                color: Color(0xFF38BDF8),
                                size: 16,
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.fullscreen_rounded,
                      color: Color(0xFFCBD5E1),
                      size: 26,
                    ),
                    tooltip: 'Fullscreen',
                    splashRadius: 20,
                    onPressed: () {
                      _controller?.toggleFullScreen();
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double fraction = _videoDuration > 0
        ? (_maxWatchedPosition / _videoDuration).clamp(0.0, 1.0)
        : (_isCompleted ? 1.0 : 0.0);
    final int percent = _isCompleted ? 100 : (fraction * 100).round();

    final playerWidget = widget.customPlayerWidget ??
        (_controller != null
            ? YoutubePlayer(controller: _controller!)
            : const SizedBox.shrink());

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
            // YouTube Player Container with Tap/Gesture Interceptor & Paused Cover
            _buildVideoPlayerWithOverlay(playerWidget),

            // Custom Control Bar below video (No skippable/rewind progress bar)
            _buildCustomControlsBar(),

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
