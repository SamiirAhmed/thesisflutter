import 'package:flutter/material.dart';

/// Central color palette for the University Portal app.
class AppColors {
  AppColors._();

  // ── Brand blues ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0D47A1);
  static const Color primaryDark = Color(0xFF1A237E);
  static const Color primaryLight = Color(0xFFE3F2FD);

  // ── Accent / status colors ────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFC62828);
  static const Color teacherBadge = Color(0xFF6A1B9A);

  // ── Neutrals (Light Mode) ─────────────────────────────────────────────────
  static const Color background = Color(0xFFF0F2F5);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1B3131);
  static const Color textSecondary = Color(0xFF6E6E6E);
  static const Color divider = Color(0xFFE0E0E0);

  // ── Neutrals (Dark Mode) ──────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0F0F0F);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color dividerDark = Color(0xFF333333);

  // ── Module card icon colors ──────────────────────────────────────────────
  static const Map<String, Color> moduleColors = {
    'appeals': Color(0xFF1565C0),
    'complaints': Color(0xFFC62828),
    'results': Color(0xFF283593),
    'finance': Color(0xFFE65100),
    'classes': Color(0xFF00695C),
    'attendance': Color(0xFF6A1B9A),
    'research': Color(0xFFBF360C),
    'schedule': Color(0xFF0277BD),
    'grading': Color(0xFF558B2F),
    'course_appeal': Color(0xFF3949AB),
    'notifications': Color(0xFF00897B),
    'coursework_notifications': Color(0xFF00897B),
    'notification': Color(0xFF00897B),
    'report': Color(0xFF5E35B1),
    'reports': Color(0xFF5E35B1),
  };

  static Color moduleColor(String key) =>
      moduleColors[key.toLowerCase()] ?? primary;

  // ── Theme Generation ─────────────────────────────────────────────────────

  static ThemeData getTheme(bool isDark) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primary,
        surface: isDark ? surfaceDark : surface,
        background: isDark ? backgroundDark : background,
      ),
      scaffoldBackgroundColor: isDark ? backgroundDark : background,
      fontFamily: 'Roboto',
      dividerColor: isDark ? dividerDark : divider,
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: isDark ? textPrimaryDark : textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? surfaceDark : primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: isDark ? surfaceDark : surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
