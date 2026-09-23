import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/storage/video_progress_manager.dart';
import '../core/theme/app_colors.dart';

class VideoProgressBar extends StatefulWidget {
  final String? videoKey;
  final dynamic videoId;
  final Color activeColor;
  final Color completedColor;
  final Color backgroundColor;

  const VideoProgressBar({
    super.key,
    required this.videoKey,
    this.videoId,
    this.activeColor = AppColors.primary,
    this.completedColor = AppColors.success,
    this.backgroundColor = AppColors.border,
  });

  @override
  State<VideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends State<VideoProgressBar> {
  @override
  void initState() {
    super.initState();
    _syncServerProgress();
  }

  @override
  void didUpdateWidget(covariant VideoProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId || oldWidget.videoKey != widget.videoKey) {
      _syncServerProgress();
    }
  }

  void _syncServerProgress() {
    if (widget.videoId != null) {
      VideoProgressManager.fetchAndSyncProgressFromApi(
        videoId: widget.videoId,
        idOrUrl: widget.videoKey,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoKey == null || widget.videoKey!.isEmpty) {
      return const SizedBox.shrink();
    }

    final normalized = VideoProgressManager.normalizeKey(widget.videoKey);

    return ValueListenableBuilder<Box>(
      valueListenable: VideoProgressManager.listenable(keys: [normalized]),
      builder: (context, box, _) {
        final progress = VideoProgressManager.getProgress(normalized);
        final bool isCompleted = progress.isActuallyCompleted;
        final double fraction = progress.progressFraction;
        final int percent = progress.percentInt;

        final Color barColor = isCompleted ? widget.completedColor : widget.activeColor;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 5,
                backgroundColor: widget.backgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 6),

            // Progress text / Tick row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isCompleted)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: widget.completedColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: widget.completedColor,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        fraction > 0
                            ? Icons.timelapse_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        percent > 0 ? '$percent% completed' : 'Not started',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                if (progress.totalDuration > 0)
                  Text(
                    _formatTime(progress.currentPosition, progress.totalDuration),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _formatTime(double current, double total) {
    String fmt(double secs) {
      final d = Duration(seconds: secs.toInt());
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$m:$s';
    }

    return '${fmt(current)} / ${fmt(total)}';
  }
}
