import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/tutorial/app_tour_controller.dart';

/// An elegant tooltip and guidance card for interactive tutorial steps.
class TourGuideCard extends StatefulWidget {
  final String stepText;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onAction;
  final String? actionLabel;
  final bool showSkip;
  final bool pointingDown;

  const TourGuideCard({
    super.key,
    required this.stepText,
    required this.title,
    required this.description,
    this.icon = Icons.touch_app_rounded,
    this.accentColor = AppColors.primary,
    this.onAction,
    this.actionLabel,
    this.showSkip = true,
    this.pointingDown = false,
  });

  @override
  State<TourGuideCard> createState() => _TourGuideCardState();
}

class _TourGuideCardState extends State<TourGuideCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 211, 216, 230),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withValues(alpha: 0.28),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Step Pill + Skip
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Icon(
                          widget.icon,
                          size: 14,
                          color: widget.accentColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.stepText,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: widget.accentColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.showSkip)
                  TextButton(
                    onPressed: () => AppTourController.instance.skipTour(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Skip Tour',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 1, 9, 21),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Body Content: Title & Description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color.fromARGB(255, 12, 0, 0),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color.fromARGB(255, 0, 4, 8),
                    height: 1.35,
                  ),
                ),
                if (widget.onAction != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        widget.actionLabel ?? 'Next',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A pulsing border highlight wrapper for widgets that need to draw immediate attention.
class TourHighlightTarget extends StatefulWidget {
  final Widget child;
  final bool isHighlighted;
  final Color highlightColor;
  final double borderRadius;

  const TourHighlightTarget({
    super.key,
    required this.child,
    required this.isHighlighted,
    this.highlightColor = AppColors.primary,
    this.borderRadius = 22,
  });

  @override
  State<TourHighlightTarget> createState() => _TourHighlightTargetState();
}

class _TourHighlightTargetState extends State<TourHighlightTarget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _glowAnimation = Tween<double>(
      begin: 3.0,
      end: 12.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isHighlighted) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant TourHighlightTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isHighlighted && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isHighlighted) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: widget.highlightColor.withValues(alpha: 0.55),
                blurRadius: _glowAnimation.value * 2,
                spreadRadius: _glowAnimation.value / 2,
              ),
            ],
            border: Border.all(color: Colors.white, width: 2.5),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
