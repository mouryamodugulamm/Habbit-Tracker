import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:habit_tracker/core/theme/app_colors.dart';
import 'package:habit_tracker/core/theme/app_decorations.dart';
import 'package:habit_tracker/core/theme/app_text_styles.dart';

/// Design system: light and dark themes using [AppColors], [AppTextStyles], and rounded card style.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: AppColors.lightPrimary,
      onPrimary: AppColors.lightOnPrimary,
      primaryContainer: AppColors.lightPrimaryContainer,
      onPrimaryContainer: AppColors.lightOnPrimaryContainer,
      secondary: AppColors.lightSecondary,
      onSecondary: AppColors.lightOnSecondary,
      secondaryContainer: AppColors.lightSecondaryContainer,
      onSecondaryContainer: AppColors.lightOnSecondaryContainer,
      tertiary: AppColors.lightTertiary,
      onTertiary: AppColors.lightOnTertiary,
      tertiaryContainer: AppColors.lightTertiaryContainer,
      onTertiaryContainer: AppColors.lightOnTertiaryContainer,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightOnSurface,
      surfaceContainerHighest: AppColors.lightSurfaceVariant,
      onSurfaceVariant: AppColors.lightOnSurfaceVariant,
      outline: AppColors.lightOutline,
      outlineVariant: AppColors.lightOutlineVariant,
      error: AppColors.lightError,
      onError: AppColors.lightOnError,
      surfaceContainerLowest: AppColors.lightBackground,
    );

    final textTheme = TextTheme(
      displayLarge: AppTextStyles.displayLarge(AppColors.lightOnSurface),
      displayMedium: AppTextStyles.displayMedium(AppColors.lightOnSurface),
      displaySmall: AppTextStyles.displaySmall(AppColors.lightOnSurface),
      headlineLarge: AppTextStyles.headlineLarge(AppColors.lightOnSurface),
      headlineMedium: AppTextStyles.headlineMedium(AppColors.lightOnSurface),
      headlineSmall: AppTextStyles.headlineSmall(AppColors.lightOnSurface),
      titleLarge: AppTextStyles.titleLarge(AppColors.lightOnSurface),
      titleMedium: AppTextStyles.titleMedium(AppColors.lightOnSurface),
      titleSmall: AppTextStyles.titleSmall(AppColors.lightOnSurface),
      bodyLarge: AppTextStyles.bodyLarge(AppColors.lightOnSurface),
      bodyMedium: AppTextStyles.bodyMedium(AppColors.lightOnSurface),
      bodySmall: AppTextStyles.bodySmall(AppColors.lightOnSurface),
      labelLarge: AppTextStyles.labelLarge(AppColors.lightOnSurface),
      labelMedium: AppTextStyles.labelMedium(AppColors.lightOnSurface),
      labelSmall: AppTextStyles.labelSmall(AppColors.lightOnSurface),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.lightOnSurface,
        titleTextStyle: AppTextStyles.titleLarge(
          AppColors.lightOnSurface,
        ).copyWith(fontWeight: FontWeight.w700),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: AppDecorations.cardBorderRadius,
          side: BorderSide(
            color: AppColors.lightOutline.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.lightOnPrimary,
          elevation: 2,
          shadowColor: AppColors.lightPrimary.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppDecorations.cardBorderRadiusSmall,
          ),
          textStyle: AppTextStyles.labelLarge(
            AppColors.lightOnPrimary,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.lightOnPrimary,
          elevation: 2,
          shadowColor: AppColors.lightPrimary.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppDecorations.cardBorderRadiusSmall,
          ),
          textStyle: AppTextStyles.labelLarge(
            AppColors.lightOnPrimary,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: AppDecorations.cardBorderRadiusSmall,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDecorations.cardBorderRadiusSmall,
          borderSide: const BorderSide(color: AppColors.lightOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDecorations.cardBorderRadiusSmall,
          borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: AppTextStyles.bodyMedium(AppColors.lightOnSurfaceVariant),
      ),
      scaffoldBackgroundColor: AppColors.lightGradientMid,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: AppColors.lightOnPrimary,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkOnPrimary,
      primaryContainer: AppColors.darkPrimaryContainer,
      onPrimaryContainer: AppColors.darkOnPrimaryContainer,
      secondary: AppColors.darkSecondary,
      onSecondary: AppColors.darkOnSecondary,
      secondaryContainer: AppColors.darkSecondaryContainer,
      onSecondaryContainer: AppColors.darkOnSecondaryContainer,
      tertiary: AppColors.darkTertiary,
      onTertiary: AppColors.darkOnTertiary,
      tertiaryContainer: AppColors.darkTertiaryContainer,
      onTertiaryContainer: AppColors.darkOnTertiaryContainer,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      onSurfaceVariant: AppColors.darkOnSurfaceVariant,
      outline: AppColors.darkOutline,
      outlineVariant: AppColors.darkOutlineVariant,
      error: AppColors.darkError,
      onError: AppColors.darkOnError,
      surfaceContainerLowest: AppColors.darkBackground,
    );

    final textTheme = TextTheme(
      displayLarge: AppTextStyles.displayLarge(AppColors.darkOnSurface),
      displayMedium: AppTextStyles.displayMedium(AppColors.darkOnSurface),
      displaySmall: AppTextStyles.displaySmall(AppColors.darkOnSurface),
      headlineLarge: AppTextStyles.headlineLarge(AppColors.darkOnSurface),
      headlineMedium: AppTextStyles.headlineMedium(AppColors.darkOnSurface),
      headlineSmall: AppTextStyles.headlineSmall(AppColors.darkOnSurface),
      titleLarge: AppTextStyles.titleLarge(AppColors.darkOnSurface),
      titleMedium: AppTextStyles.titleMedium(AppColors.darkOnSurface),
      titleSmall: AppTextStyles.titleSmall(AppColors.darkOnSurface),
      bodyLarge: AppTextStyles.bodyLarge(AppColors.darkOnSurface),
      bodyMedium: AppTextStyles.bodyMedium(AppColors.darkOnSurface),
      bodySmall: AppTextStyles.bodySmall(AppColors.darkOnSurface),
      labelLarge: AppTextStyles.labelLarge(AppColors.darkOnSurface),
      labelMedium: AppTextStyles.labelMedium(AppColors.darkOnSurface),
      labelSmall: AppTextStyles.labelSmall(AppColors.darkOnSurface),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.darkOnSurface,
        titleTextStyle: AppTextStyles.titleLarge(
          AppColors.darkOnSurface,
        ).copyWith(fontWeight: FontWeight.w700),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurfaceVariant,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: AppDecorations.cardBorderRadius,
          side: BorderSide(
            color: AppColors.darkOutline.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkOnPrimary,
          elevation: 2,
          shadowColor: AppColors.darkPrimary.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppDecorations.cardBorderRadiusSmall,
          ),
          textStyle: AppTextStyles.labelLarge(
            AppColors.darkOnPrimary,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkOnPrimary,
          elevation: 2,
          shadowColor: AppColors.darkPrimary.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppDecorations.cardBorderRadiusSmall,
          ),
          textStyle: AppTextStyles.labelLarge(
            AppColors.darkOnPrimary,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: AppDecorations.cardBorderRadiusSmall,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDecorations.cardBorderRadiusSmall,
          borderSide: const BorderSide(color: AppColors.darkOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDecorations.cardBorderRadiusSmall,
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: AppTextStyles.bodyMedium(AppColors.darkOnSurfaceVariant),
      ),
      scaffoldBackgroundColor: AppColors.glassBackground,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.darkOnPrimary,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
      ),
    );
  }
}
