import 'package:flutter/material.dart';
import 'package:habit_tracker/core/theme/app_colors.dart';

/// Full-screen gradient used behind scaffold body. Use as first child of a [Stack].
class GradientScaffoldBackground extends StatelessWidget {
  const GradientScaffoldBackground({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.darkGradientStart,
                    AppColors.darkBackground,
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
    );
  }
}
