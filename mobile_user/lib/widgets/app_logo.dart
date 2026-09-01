import 'package:flutter/material.dart';

/// Stethoscope logo icon widget without using external images.
/// Uses custom container styling and Flutter vector icons.
class AppLogo extends StatelessWidget {
  final double size;
  final double iconSize;

  const AppLogo({
    super.key,
    this.size = 90.0,
    this.iconSize = 46.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF5B61F6).withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: size * 0.72,
          height: size * 0.72,
          decoration: const BoxDecoration(
            color: Color(0xFF5B61F6),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.medical_services_rounded,
            size: iconSize * 0.7,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
