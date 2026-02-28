import 'dart:async';

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:habit_tracker/core/core.dart';
import 'package:habit_tracker/core/widgets/gradient_scaffold_background.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/presentation/providers/goal_providers.dart';
import 'package:habit_tracker/presentation/providers/habit_providers.dart';
import 'package:habit_tracker/presentation/providers/settings_provider.dart';
import 'package:habit_tracker/core/router/app_router.dart';
import 'package:habit_tracker/presentation/widgets/empty_state_habits.dart';
import 'package:habit_tracker/presentation/widgets/habit_card.dart';

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
            style: AppTextStyles.headlineSmall(Colors.white).copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
        titleSpacing: AppSpacing.lg,
        actions: [
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
            ),
            icon: const Icon(Icons.flag_rounded, size: 22),
            onPressed: () => AppRouter.toGoals(context),
            tooltip: 'Goals',
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
              ),
              icon: const Icon(Icons.person_rounded, size: 22),
              onPressed: () => AppRouter.toProfile(context),
              tooltip: 'Profile & settings',
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GradientScaffoldBackground(isDark: isDark),
          habitsValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Something went wrong',
                      style: AppTextStyles.titleMedium(colorScheme.onSurface),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      error.toString(),
                      style: AppTextStyles.bodySmall(colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    FilledButton(
                      onPressed: () => ref.read(habitNotifierProvider.notifier).loadHabits(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (habits) {
          if (habits.isEmpty) {
            return EmptyStateHabits(onAddTap: _openAddHabit);
          }
          // Hide the habit that is pending delete so Undo can "bring it back"
          final visibleHabits = habits.where((h) => h.id != _pendingDeleteId).toList();
          if (visibleHabits.isEmpty) {
            return EmptyStateHabits(onAddTap: _openAddHabit);
          }
          final completedToday = visibleHabits.where((h) => h.isCompletedToday).length;
          final total = visibleHabits.length;
          final progress = total > 0 ? completedToday / total : 0.0;

          return CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
                  child: Text(
                    greeting,
                    style: AppTextStyles.labelLarge(colorScheme.onSurfaceVariant),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 280.ms)
                    .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
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
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your habits',
                        style: AppTextStyles.titleMedium(colorScheme.onSurface),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: isDark ? 0.5 : 1),
                          borderRadius: AppDecorations.cardBorderRadiusSmall,
                        ),
                        child: Text(
                          '$total ${total == 1 ? 'habit' : 'habits'}',
                          style: AppTextStyles.labelSmall(colorScheme.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 280.ms, delay: 120.ms)
                    .slideX(begin: 0.03, end: 0, curve: Curves.easeOut),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  MediaQuery.paddingOf(context).bottom + 72,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final habit = visibleHabits[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Slidable(
                          key: ValueKey(habit.id),
                          startActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            extentRatio: 0.25,
                            children: [
                              SlidableAction(
                                onPressed: (context) => _scheduleDelete(habit),
                                backgroundColor: colorScheme.error,
                                foregroundColor: colorScheme.onError,
                                icon: Icons.delete_rounded,
                                label: 'Delete',
                              ),
                            ],
                          ),
                          endActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            extentRatio: 0.25,
                            children: [
                              SlidableAction(
                                onPressed: (context) => AppRouter.toEditHabit(context, habit),
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                icon: Icons.edit_rounded,
                                label: 'Edit',
                              ),
                            ],
                          ),
                          child: HabitCard(
                            habit: habit,
                            onTap: () => AppRouter.toHabitDetail(context, habit.id),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: (160 + index * 50).ms)
                          .slideX(begin: 0.05, end: 0, curve: Curves.easeOut);
                    },
                    childCount: visibleHabits.length,
                  ),
                ),
              ),
            ],
          );
        },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddHabit,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: Text(
          'Add habit',
          style: AppTextStyles.labelLarge(colorScheme.onPrimary),
        ),
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
    final progressColor = _progressColor(colorScheme);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: AppDecorations.cardBorderRadiusLarge,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colorScheme.surfaceContainerHighest,
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                ]
              : [
                  colorScheme.surface,
                  colorScheme.surfaceContainerLowest.withValues(alpha: 0.5),
                ],
        ),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: isDark ? 0.1 : 0.08),
              offset: const Offset(0, 4),
              blurRadius: 16,
              spreadRadius: 0,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
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
                    style: AppTextStyles.labelSmall(colorScheme.onSurfaceVariant)
                        .copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$percentage',
                        style: AppTextStyles.displaySmall(progressColor)
                            .copyWith(fontWeight: FontWeight.w700, height: 1.1),
                      ),
                      Text(
                        '%',
                        style: AppTextStyles.titleLarge(progressColor)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$completedToday of $total habits completed',
                    style: AppTextStyles.bodySmall(colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: isDark ? 0.35 : 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  progress >= 1 ? Icons.check_circle_rounded : Icons.trending_up_rounded,
                  size: 28,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}
