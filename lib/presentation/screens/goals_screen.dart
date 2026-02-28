import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/constants/habit_icons.dart';
import 'package:habit_tracker/core/core.dart';
import 'package:habit_tracker/core/widgets/glass_card.dart';
import 'package:habit_tracker/core/widgets/gradient_scaffold_background.dart';
import 'package:habit_tracker/domain/entities/goal.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/entities/streak_result.dart';
import 'package:habit_tracker/presentation/providers/goal_providers.dart';
import 'package:habit_tracker/presentation/providers/habit_providers.dart';
import 'package:habit_tracker/core/router/app_router.dart';

IconData _iconForHabit(Habit? habit) {
  if (habit == null) return Icons.flag_rounded;
  final idx = habit.iconIndex;
  if (idx != null && idx >= 0 && idx < habitIcons.length) return habitIcons[idx];
  return habitIcons[habit.id.hashCode.abs() % habitIcons.length];
}

/// Goals section: list active goals with progress; Mark done / Close.
class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(goalNotifierProvider.notifier).loadGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeGoalsValue = ref.watch(activeGoalsListProvider);
    final habitsValue = ref.watch(habitsListProvider);

    final headerGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [
              colorScheme.primary.withValues(alpha: 0.35),
              colorScheme.primary.withValues(alpha: 0.12),
              Colors.transparent,
            ]
          : [
              colorScheme.primary.withValues(alpha: 0.22),
              colorScheme.primary.withValues(alpha: 0.08),
              Colors.transparent,
            ],
      stops: const [0.0, 0.5, 1.0],
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: headerGradient)),
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs),
          child: IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 22),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
        ),
        title: Text(
          'Goals',
          style: AppTextStyles.titleLarge(colorScheme.onSurface).copyWith(fontWeight: FontWeight.w700),
        ),
        titleSpacing: 0,
      ),
      body: Stack(
        children: [
          GradientScaffoldBackground(isDark: isDark),
          activeGoalsValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
                    const SizedBox(height: AppSpacing.lg),
                    Text(err.toString(), style: AppTextStyles.bodyMedium(colorScheme.error), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            data: (activeGoals) {
              if (activeGoals.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.screen),
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
                              color: (isDark ? AppColors.glassGradientEnd : colorScheme.primary).withValues(alpha: isDark ? 0.2 : 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.flag_rounded,
                              size: 56,
                              color: isDark ? AppColors.glassGradientEnd : colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            'No active goals',
                            style: AppTextStyles.titleLarge(colorScheme.onSurface),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Add a goal when creating or editing a habit to track long-term progress.',
                            style: AppTextStyles.bodyMedium(colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          FilledButton.icon(
                            onPressed: () => AppRouter.toAddHabit(context),
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text('Add habit with goal'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              final habits = habitsValue.valueOrNull ?? [];
              return ListView.builder(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
                itemCount: activeGoals.length,
                itemBuilder: (context, index) {
                  final goal = activeGoals[index];
                  final habit = habits.where((h) => h.id == goal.habitId).firstOrNull;
                  return _GoalCard(
                    goal: goal,
                    habit: habit,
                    colorScheme: colorScheme,
                    isDark: isDark,
                    onMarkDone: () => ref.read(goalNotifierProvider.notifier).markGoalCompleted(goal),
                    onClose: () => ref.read(goalNotifierProvider.notifier).markGoalClosed(goal),
                    onTapHabit: habit != null ? () => AppRouter.toHabitDetail(context, habit.id) : null,
                    streak: habit != null ? ref.watch(streakForHabitProvider(habit.id)) : null,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.habit,
    required this.colorScheme,
    required this.isDark,
    required this.onMarkDone,
    required this.onClose,
    this.onTapHabit,
    this.streak,
  });

  final Goal goal;
  final Habit? habit;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onMarkDone;
  final VoidCallback onClose;
  final VoidCallback? onTapHabit;
  final StreakResult? streak;

  @override
  Widget build(BuildContext context) {
    final habitName = habit?.name ?? 'Unknown habit';
    final currentProgress = goal.targetType == GoalTargetType.totalDays
        ? (habit?.completedDates.length ?? 0)
        : (streak?.currentStreak ?? 0);
    final targetLabel = goal.targetType == GoalTargetType.totalDays ? 'days' : 'day streak';
    final progressLabel = '$currentProgress / ${goal.targetValue} $targetLabel';
    final isReached = currentProgress >= goal.targetValue;

    final useGlass = isDark;
    final progressColor = useGlass && isReached
        ? AppColors.glassGradientEnd
        : (isReached ? colorScheme.primary : colorScheme.tertiary);
    final iconColor = useGlass ? AppColors.glassGradientEnd : colorScheme.primary;

    final cardContent = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _iconForHabit(habit),
                color: iconColor,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  habitName,
                  style: AppTextStyles.titleMedium(colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            progressLabel,
            style: AppTextStyles.bodyMedium(colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: (goal.targetValue > 0) ? (currentProgress / goal.targetValue).clamp(0.0, 1.0) : 0,
            backgroundColor: useGlass ? AppColors.glassSurfaceBorder : colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onClose,
                child: Text('Close goal', style: AppTextStyles.labelMedium(colorScheme.onSurfaceVariant)),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: onMarkDone,
                child: const Text('Mark done'),
              ),
            ],
          ),
        ],
      ),
    );

    if (useGlass) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: GlassCard(
          useBlur: true,
          child: InkWell(
            onTap: onTapHabit,
            borderRadius: AppDecorations.cardBorderRadiusLarge,
            child: cardContent,
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTapHabit,
        borderRadius: AppDecorations.cardBorderRadius,
        child: cardContent,
      ),
    );
  }
}
