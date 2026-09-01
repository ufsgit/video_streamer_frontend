import 'package:flutter/material.dart';

/// Stylized video preview container without using image assets/network images.
/// Used for non-library screens (Home screen) according to instructions.
class VideoContainerNoImage extends StatelessWidget {
  final double height;
  final String? badgeText;
  final bool showCheckmark;
  final Gradient? customGradient;

  const VideoContainerNoImage({
    super.key,
    required this.height,
    this.badgeText,
    this.showCheckmark = false,
    this.customGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        gradient: customGradient ??
            const LinearGradient(
              colors: [
                Color(0xFF2C3E50),
                Color(0xFF4CA1AF),
                Color(0xFF34495E),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      ),
      child: Stack(
        children: [
          // Background abstract medical icon/pattern opacity
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.fitness_center_rounded,
              size: 140,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            left: -10,
            top: -10,
            child: Icon(
              Icons.play_circle_fill_rounded,
              size: 100,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          // Center Play Button
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),
          // Badge at bottom right (e.g. "12 min left")
          if (badgeText != null)
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          // Checkmark at top right if completed
          if (showCheckmark)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF12B76A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
