import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_constants.dart';

class FindTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.accent,
        surface: Colors.white,
        error: AppColors.danger,
      ),
    );
    return _withSharedStyle(base, Brightness.light);
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: const Color(0xFF80D7DA),
        secondary: const Color(0xFF7FE2B3),
        tertiary: const Color(0xFFF5C978),
        surface: const Color(0xFF18211F),
        error: const Color(0xFFFF9DA3),
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
    );
    return _withSharedStyle(base, Brightness.dark);
  }

  static ThemeData _withSharedStyle(ThemeData base, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textTheme = GoogleFonts.notoKufiArabicTextTheme(base.textTheme).apply(
      bodyColor: isDark ? Colors.white : AppColors.ink,
      displayColor: isDark ? Colors.white : AppColors.ink,
    );

    return base.copyWith(
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.background,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.background,
        foregroundColor: isDark ? Colors.white : AppColors.ink,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 10,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        color: isDark ? const Color(0xFF18211F) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : const Color(0xFFE1E9E6),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1A2523) : Colors.white,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFDDE8E4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFDDE8E4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? const Color(0xFF80D7DA) : AppColors.primary,
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : const Color(0xFFD6E4DF),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF18211F) : Colors.white,
        selectedItemColor: isDark ? const Color(0xFF80D7DA) : AppColors.primary,
        unselectedItemColor: AppColors.muted,
        selectedLabelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: textTheme.labelMedium,
        type: BottomNavigationBarType.fixed,
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: isDark ? const Color(0xFF80D7DA) : AppColors.primary,
        textTheme: CupertinoTextThemeData(
          textStyle: textTheme.bodyMedium,
          navTitleTextStyle: textTheme.titleLarge,
        ),
      ),
    );
  }
}
