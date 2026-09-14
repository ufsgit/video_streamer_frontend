import 'package:flutter/material.dart';

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
            return Icon(
              Icons.health_and_safety_rounded,
              color: Colors.blue.shade600,
              size: innerSize,
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
                    color: Colors.black.withValues(alpha: 0.08),
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
