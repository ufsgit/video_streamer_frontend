import 'package:flutter/material.dart';

/// Health Shield & Care Cross custom vector painter (Primary App Emblem)
class HealthShieldPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const HealthShieldPainter({
    this.color = Colors.white,
    this.strokeWidth = 2.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final outlinePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 1. Draw Protective Shield Contour
    final shieldPath = Path();
    shieldPath.moveTo(w * 0.16, h * 0.18);
    shieldPath.quadraticBezierTo(w * 0.5, h * 0.12, w * 0.84, h * 0.18);
    shieldPath.lineTo(w * 0.84, h * 0.52);
    shieldPath.cubicTo(
      w * 0.84,
      h * 0.76,
      w * 0.55,
      h * 0.90,
      w * 0.5,
      h * 0.94,
    );
    shieldPath.cubicTo(
      w * 0.45,
      h * 0.90,
      w * 0.16,
      h * 0.76,
      w * 0.16,
      h * 0.52,
    );
    shieldPath.close();

    canvas.drawPath(shieldPath, outlinePaint);

    // 2. Draw Inner Medical Cross with Rounded Edges
    final crossVertical = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.48),
        width: w * 0.15,
        height: h * 0.40,
      ),
      Radius.circular(w * 0.075),
    );

    final crossHorizontal = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.48),
        width: w * 0.40,
        height: h * 0.15,
      ),
      Radius.circular(w * 0.075),
    );

    canvas.drawRRect(crossVertical, fillPaint);
    canvas.drawRRect(crossHorizontal, fillPaint);
  }

  @override
  bool shouldRepaint(covariant HealthShieldPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Stethoscope vector painter for medical categorization
class StethoscopePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const StethoscopePainter({
    this.color = Colors.white,
    this.strokeWidth = 2.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Earpieces tips
    canvas.drawCircle(Offset(w * 0.22, h * 0.2), strokeWidth * 0.7, fillPaint);
    canvas.drawCircle(Offset(w * 0.62, h * 0.2), strokeWidth * 0.7, fillPaint);

    // Binaural tube (U-shape)
    final path = Path();
    path.moveTo(w * 0.22, h * 0.22);
    path.lineTo(w * 0.22, h * 0.42);
    path.arcToPoint(
      Offset(w * 0.62, h * 0.42),
      radius: Radius.circular(w * 0.2),
      clockwise: false,
    );
    path.lineTo(w * 0.62, h * 0.22);
    canvas.drawPath(path, paint);

    // Tubing down to chestpiece
    final tubePath = Path();
    tubePath.moveTo(w * 0.42, h * 0.58);
    tubePath.cubicTo(
      w * 0.42,
      h * 0.85,
      w * 0.78,
      h * 0.88,
      w * 0.78,
      h * 0.68,
    );
    canvas.drawPath(tubePath, paint);

    // Chestpiece
    canvas.drawCircle(Offset(w * 0.78, h * 0.6), strokeWidth * 1.5, fillPaint);
    canvas.drawCircle(Offset(w * 0.78, h * 0.6), strokeWidth * 2.2, paint);
  }

  @override
  bool shouldRepaint(covariant StethoscopePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// App Logo widget rendering the official logo asset with optional container styling
class AppLogo extends StatelessWidget {
  final double size;
  final double? iconSize;
  final bool isSquircle;
  final Color? backgroundColor;
  final bool hasShadow;
  final EdgeInsetsGeometry? padding;

  const AppLogo({
    super.key,
    this.size = 44.0,
    this.iconSize,
    this.isSquircle = true,
    this.backgroundColor,
    this.hasShadow = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final double innerSize = iconSize ?? size;

    Widget imageWidget = Image.asset(
      'assets/images/logo_transparent.png',
      width: innerSize,
      height: innerSize,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/logo.png',
          width: innerSize,
          height: innerSize,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return CustomPaint(
              size: Size(innerSize, innerSize),
              painter: HealthShieldPainter(
                color: Colors.blue.shade600,
                strokeWidth: innerSize * 0.09,
              ),
            );
          },
        );
      },
    );

    if (backgroundColor != null || hasShadow || padding != null) {
      return Container(
        width: size,
        height: size,
        padding: padding ?? EdgeInsets.all(size * 0.08),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: isSquircle ? BorderRadius.circular(size * 0.28) : null,
          shape: isSquircle ? BoxShape.rectangle : BoxShape.circle,
          boxShadow: hasShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(child: imageWidget),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Center(child: imageWidget),
    );
  }
}
