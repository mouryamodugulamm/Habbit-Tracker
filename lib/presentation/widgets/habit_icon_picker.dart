import 'package:flutter/material.dart';
import 'package:habit_tracker/core/constants/habit_icons.dart';
import 'package:habit_tracker/core/theme/app_decorations.dart';
import 'package:habit_tracker/core/theme/app_spacing.dart';

/// Grid of [habitIcons]. [selectedIndex] is highlighted; tap updates selection (0-based).
class HabitIconPicker extends StatelessWidget {
  const HabitIconPicker({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.colorScheme,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: List.generate(habitIcons.length, (index) {
        final selected = index == selectedIndex;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelected(index),
            borderRadius: AppDecorations.cardBorderRadiusSmall,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: AppDecorations.cardBorderRadiusSmall,
                border: Border.all(
                  color: selected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.3),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Icon(
                habitIcons[index],
                size: 26,
                color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }),
    );
  }
}
