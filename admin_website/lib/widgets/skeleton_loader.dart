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

/// Skeleton loader for Patient Activity Logs table (Desktop & Mobile responsive).
class ActivityLogsSkeleton extends StatelessWidget {
  final int rowCount;
  final bool isMobile;

  const ActivityLogsSkeleton({
    super.key,
    this.rowCount = 6,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final narrow = isMobile || screenWidth < 600;

    return SkeletonPulse(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rowCount,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: AppTheme.borderSubtle),
        itemBuilder: (context, index) {
          if (narrow) {
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
          }

          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            color: index % 2 == 0 ? Colors.white : AppTheme.cardHover,
            child: Row(
              children: [
                // Patient
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      const SkeletonBox(
                        width: 28,
                        height: 28,
                        shape: BoxShape.circle,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(
                              width: index % 2 == 0 ? 130 : 100,
                              height: 13,
                              borderRadius: 4,
                            ),
                            const SizedBox(height: 4),
                            const SkeletonBox(
                              width: 70,
                              height: 10,
                              borderRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Last Activity
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(
                        width: 85,
                        height: 12,
                        borderRadius: 3,
                      ),
                      SizedBox(height: 4),
                      SkeletonBox(
                        width: 55,
                        height: 10,
                        borderRadius: 3,
                      ),
                    ],
                  ),
                ),
                // Progress
                Expanded(
                  flex: 2,
                  child: Row(
                    children: const [
                      SkeletonBox(
                        width: 60,
                        height: 7,
                        borderRadius: 4,
                      ),
                      SizedBox(width: 8),
                      SkeletonBox(
                        width: 28,
                        height: 12,
                        borderRadius: 3,
                      ),
                    ],
                  ),
                ),
                // Pre-Op
                const Expanded(
                  flex: 2,
                  child: SkeletonBox(
                    width: 70,
                    height: 13,
                    borderRadius: 3,
                  ),
                ),
                // Post-Op
                const Expanded(
                  flex: 2,
                  child: SkeletonBox(
                    width: 70,
                    height: 13,
                    borderRadius: 3,
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

/// Skeleton loader for Video Library Grid.
class VideoGridSkeleton extends StatelessWidget {
  final int itemCount;

  const VideoGridSkeleton({
    super.key,
    this.itemCount = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 8),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.15,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail Skeleton
                const Expanded(
                  flex: 6,
                  child: SkeletonBox(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 0,
                  ),
                ),
                // Details Skeleton
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SkeletonBox(
                          width: index.isEven ? 160 : 120,
                          height: 13,
                          borderRadius: 4,
                        ),
                        Row(
                          children: const [
                            SkeletonBox(
                              width: 48,
                              height: 16,
                              borderRadius: 10,
                            ),
                            SizedBox(width: 6),
                            SkeletonBox(
                              width: 36,
                              height: 12,
                              borderRadius: 3,
                            ),
                          ],
                        ),
                      ],
                    ),
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

/// Skeleton loader for Patients List Grid.
class PatientsGridSkeleton extends StatelessWidget {
  final int itemCount;

  const PatientsGridSkeleton({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 4;
          if (constraints.maxWidth < 600) {
            crossAxisCount = 1;
          } else if (constraints.maxWidth < 950) {
            crossAxisCount = 2;
          } else if (constraints.maxWidth < 1350) {
            crossAxisCount = 3;
          } else if (constraints.maxWidth < 1750) {
            crossAxisCount = 4;
          } else {
            crossAxisCount = 5;
          }

          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: 168,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Avatar & Name Skeleton
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SkeletonBox(
                            width: 34,
                            height: 34,
                            shape: BoxShape.circle,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonBox(
                                  width: index.isEven ? 130 : 100,
                                  height: 14,
                                  borderRadius: 4,
                                ),
                                const SizedBox(height: 6),
                                const SkeletonBox(
                                  width: 80,
                                  height: 11,
                                  borderRadius: 3,
                                ),
                              ],
                            ),
                          ),
                          const SkeletonBox(
                            width: 50,
                            height: 18,
                            borderRadius: 10,
                          ),
                        ],
                      ),
                      // Middle Details
                      Row(
                        children: const [
                          SkeletonBox(
                            width: 14,
                            height: 14,
                            shape: BoxShape.circle,
                          ),
                          SizedBox(width: 6),
                          SkeletonBox(
                            width: 95,
                            height: 11,
                            borderRadius: 3,
                          ),
                        ],
                      ),
                      // Bottom Details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          SkeletonBox(
                            width: 75,
                            height: 12,
                            borderRadius: 3,
                          ),
                          SkeletonBox(
                            width: 55,
                            height: 20,
                            borderRadius: 6,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
