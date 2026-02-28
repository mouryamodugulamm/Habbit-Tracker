import 'package:flutter/material.dart';

/// Rich multi-color palette: violet primary, teal secondary, amber accent; warm and cool neutrals.
abstract final class AppColors {
  AppColors._();

  // -------------------------------------------------------------------------
  // Light theme
  // -------------------------------------------------------------------------

  /// Primary – violet
  static const Color lightPrimary = Color(0xFF7C3AED);
  static const Color lightPrimaryContainer = Color(0xFFEDE9FE);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightOnPrimaryContainer = Color(0xFF4C1D95);

  /// Secondary – teal
  static const Color lightSecondary = Color(0xFF0D9488);
  static const Color lightSecondaryContainer = Color(0xFFCCFBF1);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightOnSecondaryContainer = Color(0xFF134E4A);

  /// Tertiary – amber (streaks, highlights)
  static const Color lightTertiary = Color(0xFFD97706);
  static const Color lightTertiaryContainer = Color(0xFFFEF3C7);
  static const Color lightOnTertiary = Color(0xFFFFFFFF);
  static const Color lightOnTertiaryContainer = Color(0xFF78350F);

  static const Color lightSurface = Color(0xFFFAF8FC);
  static const Color lightSurfaceVariant = Color(0xFFF5F3FF);
  static const Color lightOnSurface = Color(0xFF1C1917);
  static const Color lightOnSurfaceVariant = Color(0xFF57534E);
  static const Color lightOutline = Color(0xFFE7E5E4);
  static const Color lightOutlineVariant = Color(0xFFF5F3FF);

  /// Warm cream-tinted background
  static const Color lightBackground = Color(0xFFFEFDFB);
  static const Color lightError = Color(0xFFDC2626);
  static const Color lightOnError = Color(0xFFFFFFFF);

  static const Color lightGradientStart = Color(0xFFEDE9FE);
  static const Color lightGradientMid = Color(0xFFF5F3FF);
  static const Color lightGradientEnd = Color(0xFFECFDF5);

  // -------------------------------------------------------------------------
  // Dark theme
  // -------------------------------------------------------------------------

  static const Color darkPrimary = Color(0xFFA78BFA);
  static const Color darkPrimaryContainer = Color(0xFF5B21B6);
  static const Color darkOnPrimary = Color(0xFF2E1065);
  static const Color darkOnPrimaryContainer = Color(0xFFEDE9FE);

  static const Color darkSecondary = Color(0xFF2DD4BF);
  static const Color darkSecondaryContainer = Color(0xFF134E4A);
  static const Color darkOnSecondary = Color(0xFF042F2E);
  static const Color darkOnSecondaryContainer = Color(0xFF99F6E4);

  static const Color darkTertiary = Color(0xFFFBBF24);
  static const Color darkTertiaryContainer = Color(0xFF78350F);
  static const Color darkOnTertiary = Color(0xFF422006);
  static const Color darkOnTertiaryContainer = Color(0xFFFEF3C7);

  static const Color darkSurface = Color(0xFF1C1917);
  static const Color darkSurfaceVariant = Color(0xFF292524);
  static const Color darkOnSurface = Color(0xFFFAFAF9);
  static const Color darkOnSurfaceVariant = Color(0xFFA8A29E);
  static const Color darkOutline = Color(0xFF44403C);
  static const Color darkOutlineVariant = Color(0xFF292524);

  static const Color darkBackground = Color(0xFF0C0A09);
  static const Color darkError = Color(0xFFF87171);
  static const Color darkOnError = Color(0xFF450A0A);

  static const Color darkGradientStart = Color(0xFF2E1065);
  static const Color darkGradientEnd = Color(0xFF0C0A09);
}
