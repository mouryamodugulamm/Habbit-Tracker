import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:habit_tracker/core/theme/app_colors.dart';
import 'package:habit_tracker/core/theme/app_decorations.dart';

/// Frosted glass-style card: semi-transparent surface, optional blur, rounded corners, subtle border and shadow.
/// Theme-aware: uses dark glass in dark mode and light glass in light mode. Use on top of scaffold background.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.blurSigma = 12,
    this.useBlur,
    this.isDark,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double blurSigma;
  /// If null, blur is used only in dark mode. Set false to disable (e.g. in lists for performance).
  final bool? useBlur;
  /// If null, derived from [Theme.of(context).brightness].
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? AppDecorations.cardBorderRadiusLarge;
    final surfaceColor = dark ? AppColors.glassSurface : AppColors.lightGlassSurface;
    final borderColor = dark ? AppColors.glassSurfaceBorder : AppColors.lightGlassSurfaceBorder;
    final enableBlur = useBlur ?? dark;

    final content = Container(
      padding: padding ?? const EdgeInsets.all(0),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: dark
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.lightGlassSurfaceTop,
                  AppColors.lightGlassSurface,
                ],
                stops: [0.0, 1.0],
              ),
        color: dark ? surfaceColor : null,
        border: Border.all(
          color: dark ? borderColor : AppColors.lightGlassSurfaceBorder,
          width: dark ? 1 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: dark ? Colors.black.withValues(alpha: 0.25) : AppColors.lightGlassShadow,
            offset: Offset(0, dark ? 4 : 4),
            blurRadius: dark ? 20 : 20,
            spreadRadius: 0,
          ),
          if (dark)
            BoxShadow(
              color: AppColors.glassGradientStart.withValues(alpha: 0.1),
              offset: const Offset(0, 2),
              blurRadius: 14,
              spreadRadius: 0,
            ),
          if (!dark)
            BoxShadow(
              color: AppColors.lightGlassShadowAccent,
              offset: const Offset(0, 2),
              blurRadius: 12,
              spreadRadius: 0,
            ),
        ],
      ),
      child: dark
          ? child
          : Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: radius,
                    child: CustomPaint(
                      painter: _LightCardPatternPainter(),
                    ),
                  ),
                ),
                child,
              ],
            ),
    );

    if (!enableBlur) return content;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: content,
      ),
    );
  }
}

/// Very subtle dot pattern for light-theme cards only.
class _LightCardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotColor = AppColors.lightGlassPatternDot;
    const spacing = 20.0;
    const radius = 0.8;
    for (var x = 0.0; x < size.width + spacing; x += spacing) {
      for (var y = 0.0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, Paint()..color = dotColor);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
