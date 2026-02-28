import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale using Plus Jakarta Sans. Use with [BuildContext] or pass [Color] for on-surface variants.
abstract final class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base([
    double size = 14,
    FontWeight? weight,
    double? height,
  ]) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight ?? FontWeight.w400,
      height: height,
    );
  }

  // Display
  static TextStyle displayLarge([Color? color]) =>
      _base(32, FontWeight.w700, 1.2).copyWith(color: color);
  static TextStyle displayMedium([Color? color]) =>
      _base(28, FontWeight.w600, 1.25).copyWith(color: color);
  static TextStyle displaySmall([Color? color]) =>
      _base(24, FontWeight.w600, 1.3).copyWith(color: color);

  // Headline
  static TextStyle headlineLarge([Color? color]) =>
      _base(22, FontWeight.w600, 1.3).copyWith(color: color);
  static TextStyle headlineMedium([Color? color]) =>
      _base(20, FontWeight.w600, 1.35).copyWith(color: color);
  static TextStyle headlineSmall([Color? color]) =>
      _base(18, FontWeight.w600, 1.4).copyWith(color: color);

  // Title
  static TextStyle titleLarge([Color? color]) =>
      _base(18, FontWeight.w500, 1.4).copyWith(color: color);
  static TextStyle titleMedium([Color? color]) =>
      _base(16, FontWeight.w500, 1.45).copyWith(color: color);
  static TextStyle titleSmall([Color? color]) =>
      _base(14, FontWeight.w500, 1.45).copyWith(color: color);

  // Body
  static TextStyle bodyLarge([Color? color]) =>
      _base(16, FontWeight.w400, 1.5).copyWith(color: color);
  static TextStyle bodyMedium([Color? color]) =>
      _base(14, FontWeight.w400, 1.5).copyWith(color: color);
  static TextStyle bodySmall([Color? color]) =>
      _base(12, FontWeight.w400, 1.45).copyWith(color: color);

  // Label
  static TextStyle labelLarge([Color? color]) =>
      _base(14, FontWeight.w500, 1.4).copyWith(color: color);
  static TextStyle labelMedium([Color? color]) =>
      _base(12, FontWeight.w500, 1.4).copyWith(color: color);
  static TextStyle labelSmall([Color? color]) =>
      _base(11, FontWeight.w500, 1.35).copyWith(color: color);
}
