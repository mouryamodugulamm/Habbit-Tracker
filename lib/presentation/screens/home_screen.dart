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
import 'package:habit_tracker/presentation/providers/home_providers.dart';
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

  Widget _buildHabitTile(
    BuildContext context,
    Habit habit,
    DateTime selectedDate,
    ColorScheme colorScheme,
    bool isDark,
    int animationDelay,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Slidable(
        key: ValueKey(habit.id),
        useTextDirection: false,
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.28,
          children: [
            _ThemedDeleteAction(onPressed: () => _scheduleDelete(habit)),
          ],
        ),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.28,
          children: [
            _ThemedEditAction(
              onPressed: () => AppRouter.toEditHabit(context, habit),
            ),
          ],
        ),
        child: HabitCard(
          habit: habit,
          viewDate: selectedDate,
          onTap: () => AppRouter.toHabitDetail(context, habit.id),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: (160 + animationDelay * 50).ms)
        .slideX(begin: 0.05, end: 0, curve: Curves.easeOut);
  }

  Widget _buildHabitsList(
    BuildContext context,
    List<Habit> habits,
    DateTime selectedDate,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        homeBottomBarTotalHeight(context),
      ),
      itemCount: habits.length,
      itemBuilder: (context, index) => _buildHabitTile(
        context,
        habits[index],
        selectedDate,
        colorScheme,
        isDark,
        index,
      ),
    );
  }

  Widget _buildHabitsListBySections(
    BuildContext context,
    List<Habit> habits,
    DateTime selectedDate,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    const uncategorizedLabel = 'Uncategorized';
    final grouped = <String, List<Habit>>{};
    for (final h in habits) {
      final key = (h.category?.trim().isEmpty ?? true) ? uncategorizedLabel : h.category!;
      grouped.putIfAbsent(key, () => []).add(h);
    }
    final sectionOrder = grouped.keys.toList()
      ..sort((a, b) {
        if (a == uncategorizedLabel) return -1;
        if (b == uncategorizedLabel) return 1;
        return a.compareTo(b);
      });
    int delay = 0;
    final children = <Widget>[];
    for (final sectionName in sectionOrder) {
      final sectionHabits = grouped[sectionName]!;
      children.add(
        Padding(
          padding: EdgeInsets.only(
            top: sectionOrder.indexOf(sectionName) > 0 ? AppSpacing.lg : 0,
          ),
          child: _SectionHeader(
            title: sectionName,
            count: sectionHabits.length,
            colorScheme: colorScheme,
          ),
        ),
      );
      children.add(const SizedBox(height: AppSpacing.sm));
      for (final habit in sectionHabits) {
        children.add(_buildHabitTile(
          context,
          habit,
          selectedDate,
          colorScheme,
          isDark,
          delay++,
        ));
      }
    }
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        homeBottomBarTotalHeight(context),
      ),
      children: children,
    );
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

    ref.listen<List<Habit>>(homeVisibleHabitsProvider, (prev, next) {
      final habits = ref.read(habitsListProvider).valueOrNull ?? [];
      if (habits.isNotEmpty && next.isEmpty && prev != null && prev.isNotEmpty && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No items found')),
        );
      }
    });

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
                          style: AppTextStyles.titleMedium(
                            colorScheme.onSurface,
                          ),
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
                          onPressed: () => ref
                              .read(habitNotifierProvider.notifier)
                              .loadHabits(),
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
                final baseList = ref.watch(homeVisibleHabitsProvider);
                final visibleHabits = baseList
                    .where((h) => h.id != _pendingDeleteId)
                    .toList();
                final selectedDate = ref.watch(homeSelectedDateProvider);
                // Micro-completions: sum actual completions (capped at target per habit) and total possible
                int actualCompletions = 0;
                int totalPossible = 0;
                for (final h in visibleHabits) {
                  final target = h.effectiveTargetPerDay;
                  totalPossible += target;
                  actualCompletions += h.completedCountOn(selectedDate).clamp(0, target);
                }
                final progress = totalPossible > 0 ? actualCompletions / totalPossible : 0.0;
                final habitCount = visibleHabits.length;
                final filter = ref.watch(homeFilterProvider);
                final sort = ref.watch(homeSortProvider);
                final categoryFilter = ref.watch(homeCategoryFilterProvider);
                final distinctCategories = habits
                    .map((h) => h.category)
                    .whereType<String>()
                    .where((s) => s.trim().isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();

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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  greeting,
                                  style: AppTextStyles.labelLarge(
                                    colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              _DateChip(
                                selectedDate: selectedDate,
                                onTap: () async {
                                  final now = DateTime.now();
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate.isAfter(now) ? now : selectedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: now,
                                  );
                                  if (picked != null && mounted) {
                                    ref.read(homeSelectedDateProvider.notifier).state = picked;
                                  }
                                },
                                onResetToToday: () {
                                  ref.read(homeSelectedDateProvider.notifier).state = DateTime.now();
                                },
                                colorScheme: colorScheme,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 280.ms)
                        .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),
                    Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.sm,
                            AppSpacing.lg,
                            AppSpacing.lg,
                          ),
                          child: _ProgressCard(
                            completedToday: actualCompletions,
                            total: totalPossible,
                            progress: progress,
                            colorScheme: colorScheme,
                            isDark: isDark,
                            selectedDate: selectedDate,
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: isDark
                            ? BoxDecoration(
                                color: AppColors.glassSurface,
                                borderRadius: AppDecorations.cardBorderRadiusSmall,
                                border: Border.all(
                                  color: AppColors.glassSurfaceBorder,
                                  width: 1,
                                ),
                              )
                            : BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                borderRadius: AppDecorations.cardBorderRadiusSmall,
                                border: Border.all(
                                  color: colorScheme.outline.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.06),
                                    offset: const Offset(0, 2),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _SleekDropdownRow<String>(
                                label: 'Category',
                                value: categoryFilter ?? '',
                                valueLabel: (categoryFilter == null || categoryFilter.isEmpty) ? 'All' : categoryFilter,
                                colorScheme: colorScheme,
                                isDark: isDark,
                                items: [
                                  ('', 'All'),
                                  ...distinctCategories.map((c) => (c, c)),
                                ],
                                onSelected: (v) => ref.read(homeCategoryFilterProvider.notifier).state =
                                    (v.isEmpty ? null : v),
                              ),
                            ),
                            _FilterBarDivider(colorScheme: colorScheme, isDark: isDark),
                            Expanded(
                              child: _SleekDropdownRow<HomeFilter>(
                                label: 'Filter',
                                value: filter,
                                valueLabel: _filterLabel(filter),
                                colorScheme: colorScheme,
                                isDark: isDark,
                                items: const [
                                  (HomeFilter.all, 'All'),
                                  (HomeFilter.completedToday, 'Completed today'),
                                  (HomeFilter.notDone, 'Not done'),
                                  (HomeFilter.archived, 'Archived'),
                                ],
                                onSelected: (v) => ref.read(homeFilterProvider.notifier).state = v,
                              ),
                            ),
                            _FilterBarDivider(colorScheme: colorScheme, isDark: isDark),
                            Expanded(
                              child: _SleekDropdownRow<HomeSort>(
                                label: 'Sort',
                                value: sort,
                                valueLabel: _sortLabel(sort),
                                colorScheme: colorScheme,
                                isDark: isDark,
                                items: const [
                                  (HomeSort.name, 'Name'),
                                  (HomeSort.streak, 'Streak'),
                                  (HomeSort.needsAttention, 'Needs attention'),
                                ],
                                onSelected: (v) => ref.read(homeSortProvider.notifier).state = v,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                                  '$habitCount ${habitCount == 1 ? 'habit' : 'habits'}',
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
                        child: categoryFilter != null
                            ? _buildHabitsList(
                                context,
                                visibleHabits,
                                selectedDate,
                                colorScheme,
                                isDark,
                              )
                            : _buildHabitsListBySections(
                                context,
                                visibleHabits,
                                selectedDate,
                                colorScheme,
                                isDark,
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

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.selectedDate,
    required this.onTap,
    required this.onResetToToday,
    required this.colorScheme,
    required this.isDark,
  });

  final DateTime selectedDate;
  final VoidCallback onTap;
  final VoidCallback onResetToToday;
  final ColorScheme colorScheme;
  final bool isDark;

  static bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  static String _weekday(int w) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[w - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(selectedDate);
    final label = isToday
        ? 'Today'
        : '${_weekday(selectedDate.weekday)}, ${selectedDate.month}/${selectedDate.day}';
    return Row(
      children: [
        Material(
          color: colorScheme.primaryContainer.withValues(alpha: isDark ? 0.5 : 0.9),
          borderRadius: AppDecorations.cardBorderRadiusSmall,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppDecorations.cardBorderRadiusSmall,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    label,
                    style: AppTextStyles.labelMedium(colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isToday) ...[
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onResetToToday,
            child: Text(
              'Back to today',
              style: AppTextStyles.labelSmall(colorScheme.primary),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.colorScheme,
  });

  final String title;
  final int count;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTextStyles.titleSmall(colorScheme.onSurfaceVariant)
              .copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: AppDecorations.cardBorderRadiusSmall,
          ),
          child: Text(
            '$count',
            style: AppTextStyles.labelSmall(colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

String _filterLabel(HomeFilter f) {
  switch (f) {
    case HomeFilter.all:
      return 'All';
    case HomeFilter.completedToday:
      return 'Completed today';
    case HomeFilter.notDone:
      return 'Not done';
    case HomeFilter.archived:
      return 'Archived';
  }
}

String _sortLabel(HomeSort s) {
  switch (s) {
    case HomeSort.name:
      return 'Name';
    case HomeSort.streak:
      return 'Streak';
    case HomeSort.needsAttention:
      return 'Needs attention';
  }
}

/// Subtle vertical divider between filter bar sections.
class _FilterBarDivider extends StatelessWidget {
  const _FilterBarDivider({required this.colorScheme, required this.isDark});

  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.outline.withValues(alpha: 0.25)
            : colorScheme.outline.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

/// One row: label + sleek dropdown (pill-style trigger, opens menu on tap).
class _SleekDropdownRow<T> extends StatelessWidget {
  const _SleekDropdownRow({
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.items,
    required this.onSelected,
    required this.colorScheme,
    required this.isDark,
  });

  final String label;
  final T value;
  final String valueLabel;
  final List<(T, String)> items;
  final void Function(T) onSelected;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final triggerBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.8);
    final triggerBorder = isDark
        ? colorScheme.outline.withValues(alpha: 0.2)
        : colorScheme.outline.withValues(alpha: 0.12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.labelSmall(colorScheme.onSurfaceVariant).copyWith(
            fontSize: 10,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        PopupMenuButton<T>(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40),
          offset: const Offset(0, 8),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: AppDecorations.cardBorderRadiusSmall,
          ),
          color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
          onSelected: onSelected,
          itemBuilder: (context) => items
              .map((e) => PopupMenuItem<T>(
                    value: e.$1,
                    child: Text(
                      e.$2,
                      style: AppTextStyles.bodyMedium(colorScheme.onSurface),
                    ),
                  ))
              .toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: triggerBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: triggerBorder, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    valueLabel,
                    style: AppTextStyles.bodyMedium(colorScheme.onSurface).copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: colorScheme.primary.withValues(alpha: isDark ? 0.9 : 0.8),
                ),
              ],
            ),
          ),
        ),
      ],
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
    required this.selectedDate,
  });

  final int completedToday;
  final int total;
  final double progress;
  final ColorScheme colorScheme;
  final bool isDark;
  final DateTime selectedDate;

  static bool _isProgressToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  static String _shortDate(DateTime d) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[d.weekday - 1]}, ${d.month}/${d.day}';
  }

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
                  _isProgressToday(selectedDate)
                      ? "TODAY'S PROGRESS"
                      : 'PROGRESS FOR ${selectedDate.month}/${selectedDate.day}',
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
                  _isProgressToday(selectedDate)
                      ? '$completedToday of $total completions'
                      : '$completedToday of $total completions on ${_shortDate(selectedDate)}',
                  style: AppTextStyles.bodySmall(colorScheme.onSurfaceVariant),
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
            ? [colorScheme.error.withValues(alpha: 0.9), colorScheme.error]
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
                  style: AppTextStyles.labelMedium(
                    colorScheme.onError,
                  ).copyWith(fontWeight: FontWeight.w600),
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
                Color.lerp(
                  colorScheme.primary,
                  colorScheme.primaryContainer,
                  0.3,
                )!,
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
                Icon(Icons.edit_rounded, size: 24, color: onPrimary),
                const SizedBox(height: 4),
                Text(
                  'Edit',
                  style: AppTextStyles.labelMedium(
                    onPrimary,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
