import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/theme/app_decorations.dart';
import 'package:habit_tracker/core/theme/app_spacing.dart';
import 'package:habit_tracker/core/theme/app_text_styles.dart';
import 'package:habit_tracker/core/constants/habit_icons.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/presentation/providers/habit_providers.dart';

/// A single habit card: icon, name, streak badge, completion toggle. [onTap] opens habit detail.
class HabitCard extends ConsumerWidget {
  const HabitCard({super.key, required this.habit, this.onTap});

  final Habit habit;
  final VoidCallback? onTap;

  static IconData _iconForHabit(Habit habit) {
    final idx = habit.iconIndex;
    if (idx != null && idx >= 0 && idx < habitIcons.length) return habitIcons[idx];
    return habitIcons[habit.id.hashCode.abs() % habitIcons.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final streak = ref.watch(streakForHabitProvider(habit.id));
    final completedToday = habit.isCompletedToday;
    final icon = _iconForHabit(habit);
    final accentColor = completedToday
        ? colorScheme.primary
        : colorScheme.primary.withValues(alpha: 0.5);

    final content = Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: isDark ? 0.35 : 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 26, color: accentColor),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                habit.name,
                style: AppTextStyles.titleMedium(colorScheme.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (streak != null && streak.currentStreak > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded, size: 14, color: colorScheme.tertiary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${streak.currentStreak} day streak',
                      style: AppTextStyles.labelMedium(colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 44,
          height: 44,
          child: Checkbox(
            value: completedToday,
            onChanged: (_) {
              ref.read(habitNotifierProvider.notifier).toggleCompletion(habit.id, DateTime.now());
            },
            activeColor: colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: AppDecorations.cardBorderRadiusSmall),
          ),
        ),
      ],
    );

    final container = Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surface,
        borderRadius: AppDecorations.cardBorderRadius,
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.18),
          width: 1,
        ),
        boxShadow: [
          if (completedToday)
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.08),
              offset: const Offset(0, 2),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: content,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDecorations.cardBorderRadius,
          child: container,
        ),
      );
    }
    return container;
  }
}
