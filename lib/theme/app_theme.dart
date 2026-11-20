import 'package:flutter/material.dart';

/// Centralized brand colors and design tokens for ACLC Student Violations.
class AppColors {
  // Brand colors
  static const navy = Color(0xFF0F136E);
  static const navyLight = Color(0xFF1E258F);
  static const navyDark = Color(0xFF090C47);
  static const navySurface = Color(0xFFEEF1FA);

  static const red = Color(0xFFFD070C);
  static const redLight = Color(0xFFFF4D50);
  static const redDark = Color(0xFFB80004);
  static const redSurface = Color(0xFFFEECEE);

  // Status Colors
  static const safeGreen = Color(0xFF16A34A);
  static const safeGreenBg = Color(0xFFEAF8EF);
  static const warningAmber = Color(0xFFD97706);
  static const warningAmberBg = Color(0xFFFEF3C7);
  static const dangerRed = Color(0xFFDC2626);
  static const dangerRedBg = Color(0xFFFEE2E2);
  static const darkBackground = Color(0xFF202124);
  static const darkSurface = Color(0xFF292A2D);
  static const darkBorder = Color(0xFF3C4043);
  static const darkAccentSurface = Color(0xFF394457);

  // Neutral Colors
  static const background = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);

  // Helper for Warning / Severity level color
  static Color forWarning(String? level) {
    switch (level?.toLowerCase()) {
      case 'green':
      case 'safe':
        return safeGreen;
      case 'yellow':
      case 'warning':
        return warningAmber;
      case 'red':
      case 'critical':
      case 'danger':
        return dangerRed;
      default:
        return textSecondary;
    }
  }

  static Color forWarningBg(String? level) {
    switch (level?.toLowerCase()) {
      case 'green':
      case 'safe':
        return safeGreenBg;
      case 'yellow':
      case 'warning':
        return warningAmberBg;
      case 'red':
      case 'critical':
      case 'danger':
        return dangerRedBg;
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  static Color forSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'minor':
        return warningAmber;
      case 'major':
        return const Color(0xFFEA580C);
      case 'critical':
        return dangerRed;
      default:
        return navy;
    }
  }

  static Color forStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return safeGreen;
      case 'rejected':
      case 'dismissed':
        return dangerRed;
      case 'pending':
        return warningAmber;
      default:
        return textSecondary;
    }
  }

  /// Returns an icon paired with severity level for a11y color+icon differentiation
  static IconData iconForSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return Icons.dangerous_rounded;
      case 'major':
        return Icons.warning_rounded;
      case 'minor':
        return Icons.info_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

/// Centralized Material 3 Theme Configuration
class AppTheme {
  static Color portalSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColors.darkSurface
      : AppColors.surface;

  static Color portalCardSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColors.darkSurface
      : AppColors.surface;

  static Color portalTextPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFE8EAED)
      : AppColors.textPrimary;

  static Color portalTextSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFBDC1C6)
      : AppColors.textSecondary;

  static Color portalTextMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF9AA0A6)
      : AppColors.textMuted;

  static Color portalAccent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF8AB4F8)
      : AppColors.navy;

  static Color portalBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColors.darkBorder
      : AppColors.border;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        primary: AppColors.navy,
        secondary: AppColors.red,
        error: AppColors.red,
        surface: AppColors.surface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: null,

      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        color: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.navy.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.navy, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.navy,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        prefixIconColor: AppColors.navy,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navy, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 4,
        indicatorColor: AppColors.navySurface,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.navy : AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: isSelected ? AppColors.navy : AppColors.textSecondary,
          );
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navy,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
          height: 1.35,
        ),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.textMuted),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF8AB4F8),
      onPrimary: Color(0xFF202124),
      secondary: Color(0xFFF28B82),
      onSecondary: Color(0xFF202124),
      error: Color(0xFFF28B82),
      onError: Color(0xFF202124),
      surface: AppColors.darkSurface,
      onSurface: Color(0xFFE8EAED),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: Color(0xFFE8EAED),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkSurface,
        surfaceTintColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.darkAccentSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF8AB4F8),
          side: const BorderSide(color: Color(0xFF8AB4F8), width: 1.5),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF8AB4F8),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        labelStyle: const TextStyle(color: Color(0xFFBDC1C6)),
        hintStyle: const TextStyle(color: Color(0xFF9AA0A6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      textTheme: lightTheme.textTheme.apply(
        bodyColor: const Color(0xFFBDC1C6),
        displayColor: const Color(0xFFE8EAED),
      ),
      dividerColor: AppColors.darkBorder,
    );
  }
}
