import 'package:flutter/material.dart';
import 'package:habit_tracker/core/theme/app_colors.dart';
import 'package:habit_tracker/core/widgets/scaffold_background_pattern.dart';

/// Full-screen gradient + subtle pattern used behind scaffold body. Use as first child of a [Stack].
class GradientScaffoldBackground extends StatelessWidget {
  const GradientScaffoldBackground({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.glassBackgroundGradientEnd,
                        AppColors.glassBackground,
                        AppColors.darkGradientEnd,
                      ]
                    : [
                        AppColors.lightGradientStart,
                        AppColors.lightGradientMid,
                        AppColors.lightGradientEnd,
                      ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          ScaffoldBackgroundPattern(isDark: isDark),
        ],
      ),
    );
  }
}
