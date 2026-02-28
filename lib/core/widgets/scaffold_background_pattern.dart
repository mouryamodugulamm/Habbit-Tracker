import 'package:flutter/material.dart';
import 'package:habit_tracker/core/theme/app_colors.dart';

/// Subtle decorative pattern overlay for scaffold backgrounds (dots + soft orbs).
/// Place after [GradientScaffoldBackground] in a [Stack] for a more polished look.
class ScaffoldBackgroundPattern extends StatelessWidget {
  const ScaffoldBackgroundPattern({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _PatternPainter(isDark: isDark),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  _PatternPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (isDark) {
      final dotColor = Colors.white.withValues(alpha: 0.08);
      const spacing = 28.0;
      const radius = 1.5;
      for (var x = 0.0; x < size.width + spacing; x += spacing) {
        for (var y = 0.0; y < size.height + spacing; y += spacing) {
          canvas.drawCircle(Offset(x, y), radius, Paint()..color = dotColor);
        }
      }
      final orbColor = AppColors.glassGradientEnd.withValues(alpha: 0.14);
      final orbRadius = size.shortestSide * 0.4;
      _drawOrbs(canvas, size, orbColor, orbRadius);
    }
    // Light theme: visible dot grid + gradient orbs + diagonal stripe
    if (!isDark) {
      final dotColor = AppColors.lightPrimary.withValues(alpha: 0.12);
      const spacing = 24.0;
      const radius = 1.2;
      for (var x = 0.0; x < size.width + spacing; x += spacing) {
        for (var y = 0.0; y < size.height + spacing; y += spacing) {
          canvas.drawCircle(Offset(x, y), radius, Paint()..color = dotColor);
        }
      }
      final violetOrb = AppColors.lightPrimary.withValues(alpha: 0.14);
      final tealOrb = AppColors.lightSecondary.withValues(alpha: 0.12);
      final orbRadius = size.shortestSide * 0.42;
      _drawOrbs(canvas, size, violetOrb, orbRadius);
      _drawOrbsLightTeal(canvas, size, tealOrb, orbRadius * 0.95);
      _drawLightDiagonalStripes(canvas, size);
    }
  }

  void _drawLightDiagonalStripes(Canvas canvas, Size size) {
    final stripeColor = AppColors.lightPrimary.withValues(alpha: 0.03);
    const step = 48.0;
    final paint = Paint()
      ..color = stripeColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (var i = -size.height; i < size.width + size.height; i += step) {
      canvas.drawLine(Offset(i.toDouble(), -20), Offset(i + size.height, size.height + 20), paint);
    }
  }

  void _drawOrbs(Canvas canvas, Size size, Color orbColor, double orbRadius) {
    final topRight = Offset(size.width + orbRadius * 0.3, -orbRadius * 0.4);
    final bottomLeft = Offset(-orbRadius * 0.4, size.height + orbRadius * 0.3);
    for (final center in [topRight, bottomLeft]) {
      final rect = Rect.fromCircle(center: center, radius: orbRadius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [orbColor, orbColor.withValues(alpha: 0.0)],
          stops: const [0.0, 1.0],
        ).createShader(rect);
      canvas.drawCircle(center, orbRadius, paint);
    }
  }

  void _drawOrbsLightTeal(Canvas canvas, Size size, Color orbColor, double orbRadius) {
    final topLeft = Offset(-orbRadius * 0.3, -orbRadius * 0.2);
    final bottomRight = Offset(size.width + orbRadius * 0.2, size.height + orbRadius * 0.25);
    for (final center in [topLeft, bottomRight]) {
      final rect = Rect.fromCircle(center: center, radius: orbRadius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [orbColor, orbColor.withValues(alpha: 0.0)],
          stops: const [0.0, 1.0],
        ).createShader(rect);
      canvas.drawCircle(center, orbRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
