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
    this.accentColor = AppColors.tutorialHighlight,
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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
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
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.85),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withValues(alpha: 0.35),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
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
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.55),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Icon(
                          widget.icon,
                          size: 15,
                          color: widget.accentColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.stepText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
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
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Body Content: Title & Description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFCBD5E1),
                    height: 1.4,
                  ),
                ),
                if (widget.onAction != null) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: widget.accentColor.withValues(alpha: 0.5),
                      ),
                      child: Text(
                        widget.actionLabel ?? 'Next',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
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
    this.highlightColor = AppColors.tutorialHighlight,
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
      duration: const Duration(milliseconds: 1000),
    );
    _glowAnimation = Tween<double>(
      begin: 4.0,
      end: 14.0,
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
                color: widget.highlightColor.withValues(alpha: 0.7),
                blurRadius: _glowAnimation.value * 2.2,
                spreadRadius: _glowAnimation.value * 0.8,
              ),
              BoxShadow(
                color: widget.highlightColor.withValues(alpha: 0.35),
                blurRadius: _glowAnimation.value * 3.5,
                spreadRadius: _glowAnimation.value * 1.5,
              ),
            ],
            border: Border.all(
              color: widget.highlightColor,
              width: 3.2,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
