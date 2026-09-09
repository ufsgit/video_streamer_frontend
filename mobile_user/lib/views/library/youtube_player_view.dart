import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../core/storage/video_progress_manager.dart';

class YoutubePlayerView extends StatefulWidget {
  final String videoUrl;
  final String title;

  const YoutubePlayerView({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<YoutubePlayerView> createState() => _YoutubePlayerViewState();
}

class _YoutubePlayerViewState extends State<YoutubePlayerView> {
  late YoutubePlayerController _controller;
  StreamSubscription? _subscription;

  double _currentPosition = 0.0;
  double _totalDuration = 0.0;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayerController.convertUrlToId(widget.videoUrl) ?? '';

    // Load initial saved progress
    final saved = VideoProgressManager.getProgress(widget.videoUrl);
    _currentPosition = saved.currentPosition;
    _totalDuration = saved.totalDuration;
    _isCompleted = saved.isCompleted;

    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );

    if (!_isCompleted && _currentPosition > 5) {
      _controller.seekTo(seconds: _currentPosition, allowSeekAhead: true);
    }

    // Track playback stream & player states
    _subscription = _controller.listen((value) async {
      if (!mounted) return;

      final double dur = await _controller.duration;
      final double pos = await _controller.currentTime;

      if (dur > 0) {
        _totalDuration = dur;
      }
      if (pos > 0) {
        _currentPosition = pos;
      }

      final bool ended = value.playerState == PlayerState.ended;
      final bool completed = ended || _isCompleted || (_totalDuration > 0 && _currentPosition >= (_totalDuration * 0.92));

      if (completed != _isCompleted) {
        setState(() {
          _isCompleted = completed;
        });
      }

      // Save progress to Hive
      if (_totalDuration > 0 || _currentPosition > 0) {
        VideoProgressManager.saveProgress(
          idOrUrl: widget.videoUrl,
          currentPosition: _currentPosition,
          totalDuration: _totalDuration,
          isCompleted: _isCompleted,
        );
      }
    });
  }

  @override
  void dispose() {
    // Save final state before exiting
    if (_totalDuration > 0) {
      VideoProgressManager.saveProgress(
        idOrUrl: widget.videoUrl,
        currentPosition: _currentPosition,
        totalDuration: _totalDuration,
        isCompleted: _isCompleted,
      );
    }
    _subscription?.cancel();
    _controller.close();
    super.dispose();
  }

  void _toggleManualComplete() async {
    setState(() {
      _isCompleted = !_isCompleted;
    });

    if (_isCompleted) {
      await VideoProgressManager.markCompleted(
        widget.videoUrl,
        totalDuration: _totalDuration,
      );
    } else {
      await VideoProgressManager.saveProgress(
        idOrUrl: widget.videoUrl,
        currentPosition: _currentPosition,
        totalDuration: _totalDuration,
        isCompleted: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double fraction = _totalDuration > 0
        ? (_currentPosition / _totalDuration).clamp(0.0, 1.0)
        : (_isCompleted ? 1.0 : 0.0);
    final int percent = _isCompleted ? 100 : (fraction * 100).round();

    return Scaffold(
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
              child: YoutubePlayer(
                controller: _controller,
              ),
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
                  // Title
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

                  // Mark as Completed Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _toggleManualComplete,
                      icon: Icon(
                        _isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 20,
                      ),
                      label: Text(
                        _isCompleted ? 'Mark as Incomplete' : 'Mark as Completed',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCompleted
                            ? const Color(0xFF12B76A)
                            : const Color(0xFF0052CC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
