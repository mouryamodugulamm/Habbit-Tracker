import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/theme/app_colors.dart';
import 'package:habit_tracker/core/theme/app_decorations.dart';
import 'package:habit_tracker/core/theme/app_spacing.dart';
import 'package:habit_tracker/core/theme/app_text_styles.dart';
import 'package:habit_tracker/core/constants/habit_icons.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/presentation/providers/habit_providers.dart';

/// A single habit card: icon, name, streak badge, completion toggle. [onTap] opens habit detail.
/// When [viewDate] is set, completion state and toggle use that date (e.g. for home date picker).
class HabitCard extends ConsumerWidget {
  const HabitCard({super.key, required this.habit, this.onTap, this.viewDate});

  final Habit habit;
  final VoidCallback? onTap;
  /// When non-null, completion is shown/toggled for this date.
  final DateTime? viewDate;

  static IconData _iconForHabit(Habit habit) {
    final idx = habit.iconIndex;
    if (idx != null && idx >= 0 && idx < habitIcons.length) {
      return habitIcons[idx];
    }
    return habitIcons[habit.id.hashCode.abs() % habitIcons.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final streak = ref.watch(streakForHabitProvider(habit.id));
    final date = viewDate ?? DateTime.now();
    final completedToday = habit.isCompletedOn(date);
    final icon = _iconForHabit(habit);
    final useGlass = isDark;
    final accentColor = completedToday
        ? colorScheme.primary
        : colorScheme.primary.withValues(alpha: 0.5);
    final iconColor = useGlass && completedToday ? Colors.white : accentColor;

    final content = Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: useGlass && completedToday
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.glassGradientStart,
                      AppColors.glassGradientEnd,
                    ],
                  )
                : null,
            color: useGlass && !completedToday
                ? AppColors.glassSurfaceBorder
                : accentColor.withValues(alpha: isDark ? 0.35 : 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: useGlass && completedToday
                  ? AppColors.glassGradientEnd.withValues(alpha: 0.5)
                  : accentColor.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 26, color: iconColor),
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
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 14,
                      color: completedToday
                          ? Colors.amber
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${streak.currentStreak} day streak',
                      style: AppTextStyles.labelMedium(
                        completedToday
                            ? Colors.amber
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              if (habit.effectiveTargetPerDay > 1) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Logged ${habit.completedCountOn(date)}/${habit.effectiveTargetPerDay} times',
                  style: AppTextStyles.labelSmall(colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (habit.effectiveTargetPerDay <= 1)
          SizedBox(
            width: 44,
            height: 44,
            child: Checkbox(
              value: completedToday,
              onChanged: (_) {
                ref
                    .read(habitNotifierProvider.notifier)
                    .toggleCompletion(habit.id, date);
              },
              activeColor: useGlass
                  ? AppColors.glassGradientEnd
                  : colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: AppDecorations.cardBorderRadiusSmall,
              ),
            ),
          )
        else
          _CounterCheckbox(
            count: habit.completedCountOn(date),
            target: habit.effectiveTargetPerDay,
            isDark: useGlass,
            colorScheme: colorScheme,
            onTap: () {
              final notifier = ref.read(habitNotifierProvider.notifier);
              if (habit.completedCountOn(date) >= habit.effectiveTargetPerDay) {
                notifier.resetCompletionsForDate(habit.id, date);
              } else {
                notifier.addCompletion(habit.id);
              }
            },
            onLongPress: () {
              if (habit.completedCountOn(date) > 0) {
                ref.read(habitNotifierProvider.notifier).toggleCompletion(habit.id, date);
              }
            },
          ),
      ],
    );

    final isLight = !isDark;
    final container = Container(
      decoration: BoxDecoration(
        gradient: useGlass
            ? null
            : (isLight
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.lightGlassSurfaceTop,
                        AppColors.lightGlassSurface,
                      ],
                    )
                  : null),
        color: useGlass
            ? AppColors.glassSurface
            : (isLight ? null : colorScheme.surfaceContainerHighest),
        borderRadius: AppDecorations.cardBorderRadius,
        border: Border.all(
          color: useGlass
              ? AppColors.glassSurfaceBorder
              : (isLight
                    ? AppColors.lightGlassSurfaceBorder
                    : colorScheme.outline.withValues(alpha: 0.35)),
          width: 1,
        ),
        boxShadow: [
          if (completedToday && useGlass)
            BoxShadow(
              color: AppColors.glassGradientEnd.withValues(alpha: 0.15),
              offset: const Offset(0, 2),
              blurRadius: 12,
              spreadRadius: 0,
            )
          else if (completedToday)
            BoxShadow(
              color: colorScheme.primary.withValues(
                alpha: isDark ? 0.12 : 0.08,
              ),
              offset: const Offset(0, 2),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          BoxShadow(
            color: isLight
                ? AppColors.lightGlassShadow
                : Colors.black.withValues(alpha: 0.2),
            offset: Offset(0, isLight ? 3 : 2),
            blurRadius: isLight ? 16 : 8,
            spreadRadius: 0,
          ),
          if (isLight)
            BoxShadow(
              color: AppColors.lightGlassShadowAccent,
              offset: const Offset(0, 1),
              blurRadius: 8,
              spreadRadius: 0,
            ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
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

/// Rounded checkbox for multi-target habits: shows count until goal, then green check.
/// Tap to add one, long-press to remove one.
class _CounterCheckbox extends StatelessWidget {
  const _CounterCheckbox({
    required this.count,
    required this.target,
    required this.isDark,
    required this.colorScheme,
    required this.onTap,
    required this.onLongPress,
  });

  final int count;
  final int target;
  final bool isDark;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final reached = count >= target;
    final fillColor = reached
        ? (isDark ? AppColors.glassGradientEnd : colorScheme.primary)
        : colorScheme.surfaceContainerHighest;
    final borderColor = reached
        ? (isDark ? AppColors.glassGradientEnd : colorScheme.primary)
        : colorScheme.outline.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: onTap,
      onLongPress: count > 0 ? onLongPress : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        alignment: Alignment.center,
        child: reached
            ? Icon(
                Icons.check_rounded,
                size: 26,
                color: isDark ? Colors.white : colorScheme.onPrimary,
              )
            : Text(
                '$count',
                style: AppTextStyles.titleMedium(colorScheme.onSurfaceVariant)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
