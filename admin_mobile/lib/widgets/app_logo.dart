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

/// Animated Loading Indicator featuring the branded logo with pulsing glow and circular ring
class AppLogoLoader extends StatefulWidget {
  final double size;
  final String? message;
  final bool isFullScreen;

  const AppLogoLoader({
    super.key,
    this.size = 56.0,
    this.message,
    this.isFullScreen = false,
  });

  @override
  State<AppLogoLoader> createState() => _AppLogoLoaderState();
}

class _AppLogoLoaderState extends State<AppLogoLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loaderContent = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Spinning Progress Ring
              SizedBox(
                width: widget.size + 24,
                height: widget.size + 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF0F3D81).withValues(alpha: 0.85),
                  ),
                ),
              ),
              // Pulsing Branded Logo
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: AppLogo(
                        size: widget.size,
                        backgroundColor: Colors.white,
                        hasShadow: true,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          if (widget.message != null && widget.message!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ],
      ),
    );

    if (widget.isFullScreen) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        body: loaderContent,
      );
    }

    return loaderContent;
  }
}

