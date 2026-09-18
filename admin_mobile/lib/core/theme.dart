import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ==========================================
  // Brand & Primary Colors
  // ==========================================
  static const Color primary = Color(0xFF0052CC);
  static const Color primaryBlue = Color(0xFF0052CC);
  static const Color primaryDark = Color(0xFF0747A6);
  static const Color primaryLight = Color(0xFF2684FF);

  // ==========================================
  // Neutrals, Surfaces & Borders
  // ==========================================
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color cardBg = Colors.white;
  static const Color cardHover = Color(0xFFFAFBFD);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFF1F5F9);
  static const Color borderMedium = Color(0xFFCBD5E1);

  // ==========================================
  // Typography
  // ==========================================
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFFCBD5E1);

  // ==========================================
  // Subtle Blue Palette (Total / Assigned / Info)
  // ==========================================
  static const Color blue = Color(0xFF2563EB);
  static const Color blueBg = Color(0xFFEFF6FF);
  static const Color blueBorder = Color(0xFFDBEAFE);
  static const Color blueText = Color(0xFF1D4ED8);
  static const Color blueCardBg = Color(0xFFF0F7FF);
  static const Color secondaryBlue = Color(0xFFEFF6FF);

  // ==========================================
  // Subtle Purple / Violet Palette (Avg / Engagement)
  // ==========================================
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleBg = Color(0xFFF5F3FF);
  static const Color purpleBorder = Color(0xFFE9D5FF);
  static const Color purpleText = Color(0xFF6D28D9);
  static const Color purpleCardBg = Color(0xFFFAF5FF);

  // ==========================================
  // Subtle Emerald / Green Palette (Completed / Success / Live)
  // ==========================================
  static const Color emerald = Color(0xFF059669);
  static const Color emeraldBg = Color(0xFFECFDF5);
  static const Color emeraldBorder = Color(0xFFBBF7D0);
  static const Color emeraldText = Color(0xFF047857);
  static const Color emeraldCardBg = Color(0xFFF0FDF4);
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFECFDF5);

  // ==========================================
  // Subtle Amber / Orange Palette (In-Progress / Warning)
  // ==========================================
  static const Color amber = Color(0xFFD97706);
  static const Color amberBg = Color(0xFFFFFBEB);
  static const Color amberBorder = Color(0xFFFDE68A);
  static const Color amberText = Color(0xFF92400E);
  static const Color warning = Color(0xFFD97706);

  // ==========================================
  // Subtle Red / Rose Palette (Danger / Delete / Inactive)
  // ==========================================
  static const Color red = Color(0xFFDC2626);
  static const Color redBg = Color(0xFFFEF2F2);
  static const Color redBorder = Color(0xFFFECACA);
  static const Color redText = Color(0xFFB91C1C);
  static const Color error = Color(0xFFDC2626);

  // ==========================================
  // Subtle Teal / Cyan Palette
  // ==========================================
  static const Color teal = Color(0xFF0D9488);
  static const Color tealBg = Color(0xFFF0FDFA);
  static const Color tealBorder = Color(0xFFCCFBF1);
  static const Color tealText = Color(0xFF0F766E);
  static const Color accent = Color(0xFF38BDF8);

  static const Color categorySelectorColor = Color(0xFF0B192C);

  // ==========================================
  // Dynamic Pastel Avatar Color Palettes
  // ==========================================
  static const List<Map<String, Color>> avatarPalettes = [
    {'bg': Color(0xFFEFF6FF), 'fg': Color(0xFF2563EB), 'border': Color(0xFFBFDBFE)}, // Blue
    {'bg': Color(0xFFF5F3FF), 'fg': Color(0xFF7C3AED), 'border': Color(0xFFDDD6FE)}, // Purple
    {'bg': Color(0xFFECFDF5), 'fg': Color(0xFF059669), 'border': Color(0xFFA7F3D0)}, // Emerald
    {'bg': Color(0xFFFFF7ED), 'fg': Color(0xFFEA580C), 'border': Color(0xFFFED7AA)}, // Orange
    {'bg': Color(0xFFFDF2F8), 'fg': Color(0xFFDB2777), 'border': Color(0xFFFBCFE8)}, // Pink
    {'bg': Color(0xFFF0FDFA), 'fg': Color(0xFF0D9488), 'border': Color(0xFF99F6E4)}, // Teal
  ];

  static Map<String, Color> getAvatarPalette(String name) {
    if (name.isEmpty) return avatarPalettes[0];
    final code = name.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
    return avatarPalettes[code % avatarPalettes.length];
  }

  // ==========================================
  // Theme Data Configuration
  // ==========================================
  static ThemeData get theme => lightTheme;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: blueBg,
        surface: surface,
        error: error,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: border),
        ),
      ),
    );
  }
}

