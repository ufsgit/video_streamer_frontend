import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Reusable pulsating animation wrapper for skeleton widgets.
class SkeletonPulse extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const SkeletonPulse({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.35,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}

/// Standalone skeleton placeholder box.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
    this.margin,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFE2E8F0),
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(borderRadius)
            : null,
      ),
    );
  }
}

/// Skeleton loader for Top Watched Videos leaderboard.
class TopVideosSkeleton extends StatelessWidget {
  final int itemCount;

  const TopVideosSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: itemCount,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: AppTheme.borderSubtle),
        itemBuilder: (context, index) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            child: Row(
              children: [
                // Rank Circle
                const SkeletonBox(
                  width: 22,
                  height: 22,
                  shape: BoxShape.circle,
                ),
                const SizedBox(width: 10),

                // Video Thumbnail
                const SkeletonBox(
                  width: 36,
                  height: 36,
                  borderRadius: 7,
                ),
                const SizedBox(width: 10),

                // Title and Category lines
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(
                        width: index.isEven ? 160 : 125,
                        height: 13,
                        borderRadius: 4,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: const [
                          SkeletonBox(
                            width: 52,
                            height: 13,
                            borderRadius: 4,
                          ),
                          SizedBox(width: 6),
                          SkeletonBox(
                            width: 34,
                            height: 11,
                            borderRadius: 3,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Watch Count Badge
                const SkeletonBox(
                  width: 44,
                  height: 22,
                  borderRadius: 14,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Skeleton loader for Patient Activity Logs (Mobile view).
class ActivityLogsSkeleton extends StatelessWidget {
  final int rowCount;
  final bool isMobile;

  const ActivityLogsSkeleton({
    super.key,
    this.rowCount = 6,
    this.isMobile = true,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rowCount,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: AppTheme.borderSubtle),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 11.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(
                  width: 32,
                  height: 32,
                  shape: BoxShape.circle,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(
                        width: index % 2 == 0 ? 140 : 110,
                        height: 14,
                        borderRadius: 4,
                      ),
                      const SizedBox(height: 5),
                      const SkeletonBox(
                        width: 85,
                        height: 11,
                        borderRadius: 3,
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: const [
                          SkeletonBox(
                            width: 68,
                            height: 18,
                            borderRadius: 4,
                          ),
                          SizedBox(width: 8),
                          SkeletonBox(
                            width: 90,
                            height: 11,
                            borderRadius: 3,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
