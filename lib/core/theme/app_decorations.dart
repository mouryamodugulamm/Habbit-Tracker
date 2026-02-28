import 'package:flutter/material.dart';
import 'package:habit_tracker/core/theme/app_colors.dart';

/// Shared decoration and shape constants (cards, chips, inputs).
abstract final class AppDecorations {
  AppDecorations._();

  /// Default radius for cards and surfaces. Use with [Light] / [Dark] colors.
  static const double cardRadius = 16;
  static const double cardRadiusSmall = 12;
  static const double cardRadiusLarge = 20;

  static const BorderRadius cardBorderRadius = BorderRadius.all(Radius.circular(cardRadius));
  static const BorderRadius cardBorderRadiusSmall = BorderRadius.all(Radius.circular(cardRadiusSmall));
  static const BorderRadius cardBorderRadiusLarge = BorderRadius.all(Radius.circular(cardRadiusLarge));

  /// Rounded card style for light theme.
  static BoxDecoration cardLight({
    Color? color,
    Border? border,
    List<BoxShadow>? shadow,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.lightSurface,
      borderRadius: cardBorderRadius,
      border: border ?? Border.all(color: AppColors.lightOutline, width: 1),
      boxShadow: shadow ??
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
    );
  }

  /// Rounded card style for dark theme.
  static BoxDecoration cardDark({
    Color? color,
    Border? border,
    List<BoxShadow>? shadow,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.darkSurfaceVariant,
      borderRadius: cardBorderRadius,
      border: border ?? Border.all(color: AppColors.darkOutline, width: 1),
      boxShadow: shadow ??
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
    );
  }
}
