import 'package:flutter/material.dart';

/// App logo mark: rounded square with checkmark. Use for app bar, splash, or branding.
/// [size] controls the total width/height; [primaryColor] and [onPrimaryColor] for theme.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 40,
    this.primaryColor,
    this.onPrimaryColor,
    this.showStreakDot = true,
  });

  final double size;
  final Color? primaryColor;
  final Color? onPrimaryColor;
  final bool showStreakDot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = primaryColor ?? scheme.primary;
    final onPrimary = onPrimaryColor ?? scheme.onPrimary;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AppLogoPainter(
          primary: primary,
          onPrimary: onPrimary,
          showStreakDot: showStreakDot,
        ),
      ),
    );
  }
}

class _AppLogoPainter extends CustomPainter {
  _AppLogoPainter({
    required this.primary,
    required this.onPrimary,
    required this.showStreakDot,
  });

  final Color primary;
  final Color onPrimary;
  final bool showStreakDot;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w * 0.22; // corner radius

    // Background: rounded square
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(r),
    );
    canvas.drawRRect(bgRect, Paint()..color = primary);

    // Checkmark path (bold, centered)
    final checkPath = Path()
      ..moveTo(w * 0.22, h * 0.50)
      ..lineTo(w * 0.42, h * 0.70)
      ..lineTo(w * 0.78, h * 0.28);
    canvas.drawPath(
      checkPath,
      Paint()
        ..color = onPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.14
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Optional small "streak" dot (top-right)
    if (showStreakDot) {
      canvas.drawCircle(
        Offset(w * 0.82, h * 0.18),
        w * 0.08,
        Paint()..color = onPrimary.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AppLogoPainter old) =>
      primary != old.primary || onPrimary != old.onPrimary || showStreakDot != old.showStreakDot;
}
