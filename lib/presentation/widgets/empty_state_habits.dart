import 'package:flutter/material.dart';
import 'package:habit_tracker/core/theme/app_spacing.dart';
import 'package:habit_tracker/core/theme/app_text_styles.dart';

/// Empty state when there are no habits. Design system only; tap action is passed in.
class EmptyStateHabits extends StatelessWidget {
  const EmptyStateHabits({
    super.key,
    required this.onAddTap,
  });

  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.track_changes_rounded,
              size: 80,
              color: colorScheme.outline,
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
    );
  }
}
