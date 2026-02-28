import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:habit_tracker/core/core.dart';
import 'package:habit_tracker/core/widgets/glass_card.dart';
import 'package:habit_tracker/core/widgets/gradient_scaffold_background.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/presentation/providers/goal_providers.dart';
import 'package:habit_tracker/presentation/providers/habit_providers.dart';
import 'package:habit_tracker/presentation/providers/settings_provider.dart';
import 'package:habit_tracker/core/router/app_router.dart';
import 'package:habit_tracker/presentation/widgets/empty_state_habits.dart';
import 'package:habit_tracker/presentation/widgets/habit_card.dart';
import 'package:habit_tracker/presentation/widgets/home_bottom_bar.dart';

/// Home screen: today's progress, habit list (or empty state), FAB to add. Swipe left = edit, swipe right = delete (undo 3s).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _deleteTimer;
  Timer? _snackBarHideTimer;
  String? _pendingDeleteId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(habitNotifierProvider.notifier).loadHabits();
      ref.read(goalNotifierProvider.notifier).loadGoals();
    });
  }

  @override
  void dispose() {
    _deleteTimer?.cancel();
    _snackBarHideTimer?.cancel();
    super.dispose();
  }

  void _openAddHabit() {
    AppRouter.toAddHabit(context);
  }

  void _scheduleDelete(Habit habit) {
    _deleteTimer?.cancel();
    _snackBarHideTimer?.cancel();
    _pendingDeleteId = habit.id;
    _deleteTimer = Timer(const Duration(seconds: 3), () {
      if (_pendingDeleteId != null) {
        ref.read(habitNotifierProvider.notifier).deleteHabit(_pendingDeleteId!);
        if (mounted) setState(() => _pendingDeleteId = null);
      }
      _deleteTimer = null;
    });
    setState(() {});
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text("'${habit.name}' deleted"),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            _snackBarHideTimer?.cancel();
            messenger.hideCurrentSnackBar();
            _deleteTimer?.cancel();
            _pendingDeleteId = null;
            setState(() {});
          },
        ),
      ),
    );
    _snackBarHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) messenger.hideCurrentSnackBar();
      _snackBarHideTimer = null;
    });
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final habitsValue = ref.watch(habitsListProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userName = ref.watch(userNameProvider);
    final greeting = userName != null && userName.isNotEmpty
        ? '${_greeting()}, ${userName.split(' ').first}'
        : _greeting();

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
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: headerGradient),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: isDark
                ? [colorScheme.primary, colorScheme.tertiary]
                : [colorScheme.primary, colorScheme.tertiary],
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Text(
            'Habbit',
            style: AppTextStyles.headlineSmall(
              Colors.white,
            ).copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
        ),
        titleSpacing: AppSpacing.lg,
      ),
      body: Stack(
        children: [
          GradientScaffoldBackground(isDark: isDark),
          Padding(
            padding: EdgeInsets.only(bottom: homeBottomBarTotalHeight(context)),
            child: habitsValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: GlassCard(
                  isDark: isDark,
                  useBlur: isDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.xxl,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Something went wrong',
                        style: AppTextStyles.titleMedium(colorScheme.onSurface),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        error.toString(),
                        style: AppTextStyles.bodySmall(
                          colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      FilledButton(
                        onPressed: () =>
                            ref.read(habitNotifierProvider.notifier).loadHabits(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            data: (habits) {
              if (habits.isEmpty) {
                return EmptyStateHabits(onAddTap: _openAddHabit);
              }
              // Hide the habit that is pending delete so Undo can "bring it back"
              final visibleHabits = habits
                  .where((h) => h.id != _pendingDeleteId)
                  .toList();
              if (visibleHabits.isEmpty) {
                return EmptyStateHabits(onAddTap: _openAddHabit);
              }
              final completedToday = visibleHabits
                  .where((h) => h.isCompletedToday)
                  .length;
              final total = visibleHabits.length;
              final progress = total > 0 ? completedToday / total : 0.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: Text(
                      greeting,
                      style: AppTextStyles.labelLarge(
                        colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 280.ms)
                      .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: _ProgressCard(
                      completedToday: completedToday,
                      total: total,
                      progress: progress,
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 320.ms, delay: 80.ms)
                      .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your habits',
                          style: AppTextStyles.titleMedium(
                            colorScheme.onSurface,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer
                                .withValues(alpha: isDark ? 0.5 : 1),
                            borderRadius:
                                AppDecorations.cardBorderRadiusSmall,
                          ),
                          child: Text(
                            '$total ${total == 1 ? 'habit' : 'habits'}',
                            style: AppTextStyles.labelSmall(
                              colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 280.ms, delay: 120.ms)
                      .slideX(begin: 0.03, end: 0, curve: Curves.easeOut),
                  Expanded(
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: const [
                          Color(0x00000000),
                          Color(0xFF000000),
                          Color(0xFF000000),
                          Color(0x00000000),
                        ],
                        stops: const [0.0, 0.06, 0.94, 1.0],
                      ).createShader(bounds),
                      child: ListView.builder(
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          homeBottomBarTotalHeight(context),
                        ),
                        itemCount: visibleHabits.length,
                        itemBuilder: (context, index) {
                        final habit = visibleHabits[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.md,
                          ),
                          child: Slidable(
                            key: ValueKey(habit.id),
                            useTextDirection: false,
                            startActionPane: ActionPane(
                              motion: const DrawerMotion(),
                              extentRatio: 0.28,
                              children: [
                                _ThemedDeleteAction(
                                  onPressed: () => _scheduleDelete(habit),
                                ),
                              ],
                            ),
                            endActionPane: ActionPane(
                              motion: const DrawerMotion(),
                              extentRatio: 0.28,
                              children: [
                                _ThemedEditAction(
                                  onPressed: () =>
                                      AppRouter.toEditHabit(context, habit),
                                ),
                              ],
                            ),
                            child: HabitCard(
                              habit: habit,
                              onTap: () => AppRouter.toHabitDetail(
                                context,
                                habit.id,
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(
                              duration: 300.ms,
                              delay: (160 + index * 50).ms,
                            )
                            .slideX(begin: 0.05, end: 0, curve: Curves.easeOut);
                      },
                      ),
                    ),
                  ),
                ],
              );
            },
            ),
          ),
          HomeBottomBar(
            onAddHabit: _openAddHabit,
            onGoals: () => AppRouter.toGoals(context),
            onProfile: () => AppRouter.toProfile(context),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.completedToday,
    required this.total,
    required this.progress,
    required this.colorScheme,
    required this.isDark,
  });

  final int completedToday;
  final int total;
  final double progress;
  final ColorScheme colorScheme;
  final bool isDark;

  /// Progress bar and accent color by severity: low = error, mid = tertiary/primary, high = primary.
  Color _progressColor(ColorScheme scheme) {
    if (progress <= 0.25) return scheme.error;
    if (progress <= 0.5) return scheme.tertiary;
    if (progress <= 0.75) return scheme.primary;
    return scheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (progress * 100).round() : 0;
    final progressColor = isDark
        ? AppColors.glassGradientEnd
        : _progressColor(colorScheme);
    final progressBarBackground = isDark
        ? AppColors.glassSurfaceBorder
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.8);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TODAY'S PROGRESS",
                  style: AppTextStyles.labelSmall(
                    colorScheme.onSurfaceVariant,
                  ).copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$percentage',
                      style: AppTextStyles.displaySmall(
                        progressColor,
                      ).copyWith(fontWeight: FontWeight.w700, height: 1.1),
                    ),
                    Text(
                      '%',
                      style: AppTextStyles.titleLarge(
                        progressColor,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$completedToday of $total habits completed',
                  style: AppTextStyles.bodySmall(
                    colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.glassGradientStart,
                          AppColors.glassGradientEnd,
                        ],
                      )
                    : null,
                color: isDark ? null : progressColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                progress >= 1
                    ? Icons.check_circle_rounded
                    : Icons.trending_up_rounded,
                size: 28,
                color: isDark ? Colors.white : progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: isDark
              ? _GradientProgressBar(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: progressBarBackground,
                )
              : LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: progressBarBackground,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
        ),
      ],
    );

    return GlassCard(
      isDark: isDark,
      useBlur: isDark,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: content,
    );
  }
}

/// Custom progress bar that draws a blue–purple gradient for the filled portion.
class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({
    required this.value,
    required this.backgroundColor,
  });

  final double value;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = 10.0;
        return Stack(
          children: [
            Container(
              height: height,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              height: height,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height / 2),
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.glassGradientStart,
                      AppColors.glassGradientEnd,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Sizes its child to a fraction of the parent's width (and optional height).
class FractionallySizedBox extends StatelessWidget {
  const FractionallySizedBox({
    super.key,
    required this.widthFactor,
    required this.child,
    this.height,
  });

  final double widthFactor;
  final double? height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth * widthFactor;
        return SizedBox(width: w, height: height, child: child);
      },
    );
  }
}

/// Themed delete swipe action: gradient background, rounded left corners, icon + label.
class _ThemedDeleteAction extends StatelessWidget {
  const _ThemedDeleteAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final radius = AppDecorations.cardBorderRadius;

    final decoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: isDark
            ? [
                colorScheme.error.withValues(alpha: 0.9),
                colorScheme.error,
              ]
            : [
                colorScheme.error,
                Color.lerp(colorScheme.error, Colors.black, 0.15)!,
              ],
      ),
      borderRadius: BorderRadius.only(
        topLeft: radius.topLeft,
        bottomLeft: radius.bottomLeft,
      ),
      boxShadow: [
        BoxShadow(
          color: colorScheme.error.withValues(alpha: 0.25),
          offset: const Offset(-1, 0),
          blurRadius: 6,
          spreadRadius: 0,
        ),
      ],
    );

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.only(
            topLeft: radius.topLeft,
            bottomLeft: radius.bottomLeft,
          ),
          child: Container(
            decoration: decoration,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.delete_rounded,
                  size: 24,
                  color: colorScheme.onError,
                ),
                const SizedBox(height: 4),
                Text(
                  'Delete',
                  style: AppTextStyles.labelMedium(colorScheme.onError)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Themed edit swipe action: gradient background, rounded right corners, icon + label.
class _ThemedEditAction extends StatelessWidget {
  const _ThemedEditAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final radius = AppDecorations.cardBorderRadius;

    final decoration = BoxDecoration(
      gradient: isDark
          ? const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.glassGradientStart,
                AppColors.glassGradientEnd,
              ],
            )
          : LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                colorScheme.primary,
                Color.lerp(colorScheme.primary, colorScheme.primaryContainer, 0.3)!,
              ],
            ),
      borderRadius: BorderRadius.only(
        topRight: radius.topRight,
        bottomRight: radius.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: (isDark ? AppColors.glassGradientEnd : colorScheme.primary)
              .withValues(alpha: 0.3),
          offset: const Offset(1, 0),
          blurRadius: 8,
          spreadRadius: 0,
        ),
      ],
    );

    final onPrimary = isDark ? Colors.white : colorScheme.onPrimary;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.only(
            topRight: radius.topRight,
            bottomRight: radius.bottomRight,
          ),
          child: Container(
            decoration: decoration,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.edit_rounded,
                  size: 24,
                  color: onPrimary,
                ),
                const SizedBox(height: 4),
                Text(
                  'Edit',
                  style: AppTextStyles.labelMedium(onPrimary)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
