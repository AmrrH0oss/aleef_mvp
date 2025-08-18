import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6F2D8F);
  static const Color primaryVariant = Color(0xFF56226F);
  static const Color secondary = Color(0xFF22C55E);
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFFF9800);
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w700),
      displayMedium: GoogleFonts.inter(fontWeight: FontWeight.w700),
      displaySmall: GoogleFonts.inter(fontWeight: FontWeight.w700),
      headlineLarge: GoogleFonts.inter(fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.inter(fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600),
      titleSmall: GoogleFonts.inter(fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.inter(),
      bodyMedium: GoogleFonts.inter(),
      bodySmall: GoogleFonts.inter(),
      labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w600),
      labelMedium: GoogleFonts.inter(fontWeight: FontWeight.w600),
      labelSmall: GoogleFonts.inter(fontWeight: FontWeight.w600),
    );

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryVariant,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      dividerColor: AppColors.divider,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 900;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  static double getResponsiveWidth(
    BuildContext context, {
    double mobile = 1.0,
    double tablet = 0.8,
    double desktop = 0.6,
  }) {
    if (isMobile(context)) return MediaQuery.of(context).size.width * mobile;
    if (isTablet(context)) return MediaQuery.of(context).size.width * tablet;
    return MediaQuery.of(context).size.width * desktop;
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) return const EdgeInsets.all(16);
    if (isTablet(context)) return const EdgeInsets.all(24);
    return const EdgeInsets.all(32);
  }
}
