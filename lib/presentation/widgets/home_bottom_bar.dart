import 'package:flutter/material.dart';
import 'package:habit_tracker/core/theme/app_colors.dart';
import 'package:habit_tracker/core/theme/app_decorations.dart';
import 'package:habit_tracker/core/theme/app_text_styles.dart';

/// Height of the bar (excluding the raised center button).
const double kHomeBottomBarHeight = 70;

/// Diameter of the center "Add habit" button.
const double kHomeBottomBarCenterButtonSize = 56;

/// Total height to reserve below content so the list never goes under the bar or center button.
double homeBottomBarTotalHeight(BuildContext context) {
  final safeBottom = MediaQuery.paddingOf(context).bottom;
  final barHeight = kHomeBottomBarHeight;
  final raisedButtonHeight = kHomeBottomBarCenterButtonSize / 2;
  const gap = 16.0;
  return safeBottom + barHeight + raisedButtonHeight + gap;
}

/// Custom bottom bar: notch in the center cradling a raised Add-habit button;
/// Goals on the left (icon + text), Profile on the right.
class HomeBottomBar extends StatelessWidget {
  const HomeBottomBar({
    super.key,
    required this.onAddHabit,
    required this.onGoals,
    required this.onProfile,
  });

  final VoidCallback onAddHabit;
  final VoidCallback onGoals;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final barColor = isDark
        ? AppColors.glassSurface
        : AppColors.lightGlassSurface;
    final borderColor = isDark
        ? AppColors.glassSurfaceBorder
        : AppColors.lightGlassSurfaceBorder;
    final centerButtonColor = isDark
        ? null
        : colorScheme.primary;
    final centerButtonGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.glassGradientStart,
              AppColors.glassGradientEnd,
            ],
          )
        : null;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: CustomPaint(
          painter: _NotchedBarPainter(
            barColor: barColor,
            borderColor: borderColor,
            notchRadius: kHomeBottomBarCenterButtonSize / 2 + 4,
          ),
          child: SizedBox(
            height: kHomeBottomBarHeight,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _BarItem(
                        icon: Icons.flag_rounded,
                        label: 'Goals',
                        color: colorScheme.onSurface,
                        onTap: onGoals,
                      ),
                    ),
                    SizedBox(width: kHomeBottomBarCenterButtonSize + 24),
                    Expanded(
                      child: _BarItem(
                        icon: Icons.person_rounded,
                        label: 'Profile',
                        color: colorScheme.onSurface,
                        onTap: onProfile,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: -kHomeBottomBarCenterButtonSize / 2,
                  child: _CenterAddButton(
                    size: kHomeBottomBarCenterButtonSize,
                    backgroundColor: centerButtonColor,
                    gradient: centerButtonGradient,
                    onPressed: onAddHabit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotchedBarPainter extends CustomPainter {
  _NotchedBarPainter({
    required this.barColor,
    required this.borderColor,
    required this.notchRadius,
  });

  final Color barColor;
  final Color borderColor;
  final double notchRadius;

  @override
  void paint(Canvas canvas, Size size) {
    const cornerRadius = 24.0;
    final centerX = size.width / 2;

    final notchWidth = notchRadius + 8;
    final path = Path()
      ..moveTo(0, cornerRadius)
      ..quadraticBezierTo(0, 0, cornerRadius, 0)
      ..lineTo(centerX - notchWidth, 0)
      ..arcToPoint(
        Offset(centerX + notchWidth, 0),
        radius: Radius.circular(notchWidth),
        clockwise: false,
      )
      ..lineTo(size.width - cornerRadius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, cornerRadius)
      ..lineTo(size.width, size.height - cornerRadius)
      ..quadraticBezierTo(size.width, size.height, size.width - cornerRadius, size.height)
      ..lineTo(cornerRadius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - cornerRadius)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = barColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDecorations.cardBorderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.labelSmall(color).copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterAddButton extends StatelessWidget {
  const _CenterAddButton({
    required this.size,
    required this.backgroundColor,
    required this.gradient,
    required this.onPressed,
  });

  final double size;
  final Color? backgroundColor;
  final Gradient? gradient;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 8,
      shadowColor: (gradient != null ? AppColors.glassGradientEnd : backgroundColor)!.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      color: Colors.transparent,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient,
          color: gradient == null ? backgroundColor : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              offset: const Offset(0, 4),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Icon(
              Icons.add_rounded,
              size: 32,
              color: colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
