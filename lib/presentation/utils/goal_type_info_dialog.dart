import 'package:flutter/material.dart';
import 'package:habit_tracker/core/core.dart';

/// Shows a simple popup explaining the two goal types.
void showGoalTypeInfoDialog(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Goal types'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total days',
            style: AppTextStyles.labelLarge(colorScheme.onSurface)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Reach that many days total. You can miss days in between — your count keeps going up.',
            style: AppTextStyles.bodySmall(colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Streak',
            style: AppTextStyles.labelLarge(colorScheme.onSurface)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'That many days in a row. If you miss a day, the streak resets to zero.',
            style: AppTextStyles.bodySmall(colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Only the days you chose (e.g. weekdays) count.',
            style: AppTextStyles.bodySmall(colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}
