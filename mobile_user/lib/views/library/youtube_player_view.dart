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

class _YoutubePlayerViewState extends State<YoutubePlayerView> with WidgetsBindingObserver {
  YoutubePlayerController? _controller;
  StreamSubscription? _subscription;

  // ===========================================================================
  // PLAYBACK & PROGRESS TRACKING STATE
  // ===========================================================================
  String _extractedVideoId = '';
  double _currentPosition = 0.0;
  double _maxWatchedPosition = 0.0;
  double _videoDuration = 0.0;
  Timer? _playbackTicker;

  double _savedResumePosition = 0.0;
  double _lastSavedPositionToHive = 0.0;
  bool _isCompleted = false;
  PlayerState _lastPlayerState = PlayerState.unknown;
  bool _hasSeekedToResume = false;

  bool _isPlaying = false;

  String get _thumbnailUrl => _extractedVideoId.isNotEmpty
      ? 'https://img.youtube.com/vi/$_extractedVideoId/hqdefault.jpg'
      : '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _extractedVideoId =
        YoutubePlayerController.convertUrlToId(widget.videoUrl) ?? '';

    // Load initial saved progress from Hive storage
    final saved = VideoProgressManager.getProgress(widget.videoUrl);
    _savedResumePosition = saved.currentPosition;
    _currentPosition = saved.currentPosition;
    _maxWatchedPosition = saved.currentPosition;
    _videoDuration = saved.totalDuration;

    // Video is completed if marked in storage or watched to the end
    _isCompleted = saved.isCompleted ||
        (_videoDuration > 0 && _currentPosition >= (_videoDuration - 1.0));

    // Ensure first_opened_at is set on first open in IST
    final nowIst = VideoProgressManager.nowInIstIso();
    if (saved.firstOpenedAt == null || saved.firstOpenedAt!.isEmpty) {
      VideoProgressManager.saveProgress(
        idOrUrl: widget.videoUrl,
        currentPosition: saved.currentPosition,
        totalDuration: saved.totalDuration,
        isCompleted: _isCompleted,
        videoId: widget.videoId,
        firstOpenedAt: nowIst,
        lastWatchedAt: nowIst,
        completedAt: saved.completedAt,
      );
    }

    final double resumeSecs = (_savedResumePosition > 0 && !_isCompleted)
        ? _savedResumePosition
        : 0.0;

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

    // Track playback stream & player states
    if (_controller != null) {
      _subscription = _controller!.listen((value) async {
        if (!mounted) return;

        final PlayerState currentState = value.playerState;
        final bool isCurrentlyPlaying = currentState == PlayerState.playing;
        final bool ended = currentState == PlayerState.ended;
        final bool isDone = ended ||
            (_videoDuration > 0 &&
                _maxWatchedPosition >= (_videoDuration - 1.0));

        if (isCurrentlyPlaying) {
          if (!_isPlaying) {
            _isPlaying = true;
            _startPlaybackTicker();
          }
        } else {
          if (_isPlaying) {
            _isPlaying = false;
            _stopPlaybackTicker();
          }
        }

        // When resuming on initial start, seek once to saved timestamp
        if (!_hasSeekedToResume && _savedResumePosition > 0 && !_isCompleted) {
          if (currentState == PlayerState.playing ||
              currentState == PlayerState.buffering ||
              currentState == PlayerState.cued) {
            _hasSeekedToResume = true;
            try {
              await _controller!.seekTo(
                seconds: _savedResumePosition,
                allowSeekAhead: true,
              );
            } catch (_) {}
          }
        }

        if (isDone) {
          _isCompleted = true;
          _maxWatchedPosition =
              _videoDuration > 0 ? _videoDuration : _maxWatchedPosition;
        }

        setState(() {});

        // Send to API and update Hive on pause
        if (currentState == PlayerState.paused &&
            _lastPlayerState != PlayerState.paused) {
          _lastSavedPositionToHive = _maxWatchedPosition;
          _saveToHiveAndApi(
            current: _maxWatchedPosition,
            total: _videoDuration,
            isCompleted: _isCompleted,
          );
        }

        // Send to API and update Hive on finish
        if (ended && _lastPlayerState != PlayerState.ended) {
          _lastSavedPositionToHive =
              _videoDuration > 0 ? _videoDuration : _maxWatchedPosition;
          _saveToHiveAndApi(
            current:
                _videoDuration > 0 ? _videoDuration : _maxWatchedPosition,
            total: _videoDuration,
            isCompleted: true,
          );
        }

        _lastPlayerState = currentState;
      });
    }
  }

  void _startPlaybackTicker() {
    _playbackTicker?.cancel();
    _playbackTicker = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!mounted || _controller == null || !_isPlaying) return;
      try {
        final double pos = await _controller!.currentTime;
        final double dur = await _controller!.duration;

        if (!mounted) return;

        if (dur > 0 && _videoDuration != dur) {
          setState(() {
            _videoDuration = dur;
          });
        }

        if (pos > 0) {
          // Anti-skip protection: If user jumped > 5s ahead of max watched
          if (!_isCompleted &&
              _maxWatchedPosition > 0 &&
              pos > (_maxWatchedPosition + 5.0)) {
            await _controller!.seekTo(
              seconds: _maxWatchedPosition,
              allowSeekAhead: true,
            );
          } else {
            _currentPosition = pos;
            if (pos > _maxWatchedPosition) {
              _maxWatchedPosition = pos;
            }

            // Continuously persist to Hive every ~2 seconds
            if ((_maxWatchedPosition - _lastSavedPositionToHive).abs() >= 2.0) {
              _lastSavedPositionToHive = _maxWatchedPosition;
              VideoProgressManager.saveProgress(
                idOrUrl: widget.videoUrl,
                currentPosition: _maxWatchedPosition,
                totalDuration: _videoDuration,
                isCompleted: _isCompleted,
                videoId: widget.videoId,
              );
            }
          }
          setState(() {});
        }
      } catch (_) {}
    });
  }

  void _stopPlaybackTicker() {
    _playbackTicker?.cancel();
    _playbackTicker = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _onExitScreen();
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _controller?.pauseVideo();
      _stopPlaybackTicker();
      _saveToHiveAndApi(
        current: _maxWatchedPosition,
        total: _videoDuration,
        isCompleted: _isCompleted,
      );
    } else {
      _controller?.playVideo();
      _startPlaybackTicker();
    }
  }

  /// Saves progress to Hive first, then reads from Hive to send the payload to API
  Future<void> _saveToHiveAndApi({
    required double current,
    required double total,
    required bool isCompleted,
  }) async {
    final bool completed =
        isCompleted || (total > 0 && current >= (total - 1.0));
    final nowIst = VideoProgressManager.nowInIstIso();

    // 1. Persist to Hive storage
    await VideoProgressManager.saveProgress(
      idOrUrl: widget.videoUrl,
      currentPosition: current,
      totalDuration: total,
      isCompleted: completed,
      videoId: widget.videoId,
      lastWatchedAt: nowIst,
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
        firstOpenedAt: saved.firstOpenedAt,
        lastWatchedAt: saved.lastWatchedAt ?? nowIst,
        completedAt: saved.completedAt,
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
    WidgetsBinding.instance.removeObserver(this);
    _stopPlaybackTicker();
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
      padding: const EdgeInsets.fromLTRB(16, 2, 8, 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(
              Icons.fullscreen_rounded,
              color: Color(0xFFCBD5E1),
              size: 24,
            ),
            tooltip: 'Fullscreen',
            splashRadius: 20,
            onPressed: () {
              _controller?.toggleFullScreen();
            },
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
