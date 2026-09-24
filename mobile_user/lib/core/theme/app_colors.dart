import 'package:flutter/material.dart';

/// Centralized, modern design tokens and color palette for the app.
class AppColors {
  // Brand & Primary
  static const Color primary = Color(
    0xFF2563EB,
  ); // Modern Sapphire / Royal Blue
  static const Color primaryLight = Color(0xFFEFF6FF); // Soft blue surface tint
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color accent = Color(0xFF3B82F6);

  // Backgrounds & Surfaces
  static const Color background = Color(
    0xFFF8FAFC,
  ); // Clean neutral slate canvas
  static const Color surface = Colors.white;
  static const Color surfaceSecondary = Color(0xFFF1F5F9);
  static const Color surfaceMuted = Color(0xFFF8FAFC);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFEEF2F6);

  // Typography / Slate Scale
  static const Color textPrimary = Color(
    0xFF0F172A,
  ); // Slate 900 - Headings & Titles
  static const Color textSecondary = Color(
    0xFF475569,
  ); // Slate 600 - Subtitles & Labels
  static const Color textMuted = Color(
    0xFF94A3B8,
  ); // Slate 400 - Captions & Inactive icons
  static const Color textLight = Color(0xFFCBD5E1); // Slate 300
  static const Color textWhite = Colors.white;

  // Status & Semantics
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color successLight = Color(0xFFECFDF5);
  static const Color inProgress = Color(0xFF2563EB);
  static const Color inProgressLight = Color(0xFFEFF6FF);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEF2F2);

  // Tutorial Action & Attention Highlights
  static const Color tutorialHighlight = Color.fromARGB(
    255,
    39,
    85,
    234,
  ); // High-contrast Electric Amber
  static const Color tutorialHighlightLight = Color(0xFFFFF7ED);

  // Categories (Hero Cards & Highlights)
  static const Color preOpAccent = Color(0xFF4F46E5);
  static const Color preOpBadgeBg = Color(0xFFEEF2FF);
  static const List<Color> preOpGradient = [
    Color(0xFF4F46E5),
    Color(0xFF6366F1),
    Color(0xFF7C3AED),
  ];

  static const Color postOpAccent = Color(0xFF0D9488);
  static const Color postOpBadgeBg = Color(0xFFF0FDF4);
  static const List<Color> postOpGradient = [
    Color(0xFF0D9488),
    Color(0xFF059669),
    Color(0xFF10B981),
  ];

  // Elevation & Shadows
  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get hoverShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}
