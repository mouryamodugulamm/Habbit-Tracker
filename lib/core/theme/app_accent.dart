import 'package:flutter/material.dart';

/// Accent option for app theme (gradient accent). Index 0–3.
class AppAccent {
  const AppAccent({
    required this.name,
    required this.lightPrimary,
    required this.lightPrimaryContainer,
    required this.lightGradientStart,
    required this.lightGradientEnd,
    required this.darkPrimary,
    required this.darkPrimaryContainer,
    required this.darkGradientStart,
    required this.darkGradientEnd,
  });

  final String name;
  final Color lightPrimary;
  final Color lightPrimaryContainer;
  final Color lightGradientStart;
  final Color lightGradientEnd;
  final Color darkPrimary;
  final Color darkPrimaryContainer;
  final Color darkGradientStart;
  final Color darkGradientEnd;
}

/// Preset accents. Index matches [SettingsService.accentIndex].
const List<AppAccent> appAccents = [
  AppAccent(
    name: 'Violet',
    lightPrimary: Color(0xFF7C3AED),
    lightPrimaryContainer: Color(0xFFEDE9FE),
    lightGradientStart: Color(0xFFE6DFFA),
    lightGradientEnd: Color(0xFFDCEFF0),
    darkPrimary: Color(0xFFA78BFA),
    darkPrimaryContainer: Color(0xFF5B21B6),
    darkGradientStart: Color(0xFF2E1065),
    darkGradientEnd: Color(0xFF0C0A09),
  ),
  AppAccent(
    name: 'Teal',
    lightPrimary: Color(0xFF0D9488),
    lightPrimaryContainer: Color(0xFFCCFBF1),
    lightGradientStart: Color(0xFFCCFBF1),
    lightGradientEnd: Color(0xFFE0F2FE),
    darkPrimary: Color(0xFF2DD4BF),
    darkPrimaryContainer: Color(0xFF134E4A),
    darkGradientStart: Color(0xFF042F2E),
    darkGradientEnd: Color(0xFF0C0A09),
  ),
  AppAccent(
    name: 'Amber',
    lightPrimary: Color(0xFFD97706),
    lightPrimaryContainer: Color(0xFFFEF3C7),
    lightGradientStart: Color(0xFFFEF3C7),
    lightGradientEnd: Color(0xFFFEE2E2),
    darkPrimary: Color(0xFFFBBF24),
    darkPrimaryContainer: Color(0xFF78350F),
    darkGradientStart: Color(0xFF422006),
    darkGradientEnd: Color(0xFF0C0A09),
  ),
  AppAccent(
    name: 'Rose',
    lightPrimary: Color(0xFFE11D48),
    lightPrimaryContainer: Color(0xFFFFE4E6),
    lightGradientStart: Color(0xFFFFE4E6),
    lightGradientEnd: Color(0xFFFCE7F3),
    darkPrimary: Color(0xFFFB7185),
    darkPrimaryContainer: Color(0xFF881337),
    darkGradientStart: Color(0xFF4C0519),
    darkGradientEnd: Color(0xFF0C0A09),
  ),
];
