import 'package:flutter/material.dart';
import 'package:habit_tracker/core/theme/app_spacing.dart';
import 'package:habit_tracker/core/theme/app_text_styles.dart';
import 'package:habit_tracker/core/widgets/glass_card.dart';

/// Empty state when there are no habits. Glass card layout; tap action is passed in.
class EmptyStateHabits extends StatelessWidget {
  const EmptyStateHabits({
    super.key,
    required this.onAddTap,
  });

  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        child: GlassCard(
          useBlur: isDark,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.xxl + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(
                    alpha: isDark ? 0.35 : 0.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.track_changes_rounded,
                  size: 56,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'No habits yet',
                style: AppTextStyles.headlineSmall(colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Add your first habit and start building streaks.',
                style: AppTextStyles.bodyMedium(colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              FilledButton.icon(
                onPressed: onAddTap,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add habit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
