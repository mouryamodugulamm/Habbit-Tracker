import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/constants/app_constants.dart';
import 'package:habit_tracker/core/constants/habit_icons.dart';
import 'package:habit_tracker/core/core.dart';
import 'package:habit_tracker/core/widgets/gradient_scaffold_background.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/presentation/providers/habit_providers.dart';
import 'package:table_calendar/table_calendar.dart';

/// Habit detail: calendar with completed dates, weekly bar chart, streak and completion stats.
/// Takes [habitId]; resolves habit from list. Tapping a day toggles completion.
class HabitDetailScreen extends ConsumerStatefulWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final String habitId;

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final habitsValue = ref.watch(habitsListProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return habitsValue.when(
      loading: () => _buildShell(
        context,
        colorScheme: colorScheme,
        isDark: isDark,
        title: 'Detail',
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => _buildShell(
        context,
        colorScheme: colorScheme,
        isDark: isDark,
        title: 'Detail',
        body: Center(
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
      ),
      data: (habits) {
        final habit = habits.where((h) => h.id == widget.habitId).firstOrNull;
        if (habit == null) {
          return _buildShell(
            context,
            colorScheme: colorScheme,
            isDark: isDark,
            title: 'Detail',
            body: Center(
              child: Text('Habit not found', style: AppTextStyles.bodyMedium(colorScheme.onSurface)),
            ),
          );
        }
        return _buildContent(context, ref, habit, colorScheme, isDark);
      },
    );
  }

  Widget _buildShell(
    BuildContext context, {
    required ColorScheme colorScheme,
    required bool isDark,
    required String title,
    required Widget body,
  }) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Text(
          title,
          style: AppTextStyles.titleLarge(colorScheme.onSurface).copyWith(fontWeight: FontWeight.w700),
        ),
        titleSpacing: 0,
      ),
      body: Stack(
        children: [
          GradientScaffoldBackground(isDark: isDark),
          body,
        ],
      ),
    );
  }

  static IconData _iconForHabit(Habit habit) {
    final idx = habit.iconIndex;
    if (idx != null && idx >= 0 && idx < habitIcons.length) return habitIcons[idx];
    return habitIcons[habit.id.hashCode.abs() % habitIcons.length];
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final streak = ref.watch(streakForHabitProvider(habit.id));
    final completedSet = habit.completedDates.map(Habit.toDate).toSet();
    final completionPct = habit.completionPercentageLastDays(AppConstants.completionPercentageDays);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        titleSpacing: 0,
      ),
      body: Stack(
        children: [
          GradientScaffoldBackground(isDark: isDark),
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HabitHeroCard(habit: habit, colorScheme: colorScheme, isDark: isDark, icon: _iconForHabit(habit)),
                const SizedBox(height: AppSpacing.xl),
                _StatsRow(
                  currentStreak: streak?.currentStreak ?? 0,
                  longestStreak: streak?.longestStreak ?? 0,
                  completionPercent: completionPct,
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xxl),
                _SectionHeader(title: 'Calendar', colorScheme: colorScheme),
                const SizedBox(height: AppSpacing.sm),
                _CalendarCard(
                  habit: habit,
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  completedSet: completedSet,
                  colorScheme: colorScheme,
                  isDark: isDark,
                  onDaySelected: (day) {
                    ref.read(habitNotifierProvider.notifier).toggleCompletion(habit.id, day);
                  },
                  onPageChanged: (day) => setState(() => _focusedDay = day),
                  onFormatChanged: (format) => setState(() => _calendarFormat = format),
                ),
                const SizedBox(height: AppSpacing.xxl),
                _SectionHeader(title: 'This week', colorScheme: colorScheme),
                const SizedBox(height: AppSpacing.sm),
                _ThisWeekRow(habit: habit, colorScheme: colorScheme, isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitHeroCard extends StatelessWidget {
  const _HabitHeroCard({
    required this.habit,
    required this.colorScheme,
    required this.isDark,
    required this.icon,
  });

  final Habit habit;
  final ColorScheme colorScheme;
  final bool isDark;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: isDark ? 0.35 : 0.18),
            colorScheme.secondary.withValues(alpha: isDark ? 0.25 : 0.12),
          ],
        ),
        borderRadius: AppDecorations.cardBorderRadius,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.onPrimary.withValues(alpha: 0.2),
              borderRadius: AppDecorations.cardBorderRadiusSmall,
            ),
            child: Icon(icon, size: 32, color: colorScheme.onPrimary),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              habit.name,
              style: AppTextStyles.titleLarge(colorScheme.onPrimary).copyWith(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.colorScheme});

  final String title;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: AppTextStyles.labelLarge(colorScheme.onSurface).copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.currentStreak,
    required this.longestStreak,
    required this.completionPercent,
    required this.colorScheme,
    required this.isDark,
  });

  final int currentStreak;
  final int longestStreak;
  final double completionPercent;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            label: 'Current streak',
            value: '$currentStreak',
            icon: Icons.local_fire_department_rounded,
            accentColor: colorScheme.tertiary,
            colorScheme: colorScheme,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatChip(
            label: 'Longest streak',
            value: '$longestStreak',
            icon: Icons.emoji_events_rounded,
            accentColor: colorScheme.secondary,
            colorScheme: colorScheme,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatChip(
            label: '30-day',
            value: '${(completionPercent * 100).round()}%',
            icon: Icons.trending_up_rounded,
            accentColor: colorScheme.primary,
            colorScheme: colorScheme,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.colorScheme,
    required this.isDark,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark
        ? colorScheme.surfaceContainerHighest
        : accentColor.withValues(alpha: 0.12);
    final borderColor = isDark ? colorScheme.outline.withValues(alpha: 0.5) : accentColor.withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppDecorations.cardBorderRadiusSmall,
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.08),
                  offset: const Offset(0, 2),
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
              ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: accentColor),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.titleMedium(colorScheme.onSurface).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.labelSmall(colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.habit,
    required this.focusedDay,
    required this.calendarFormat,
    required this.completedSet,
    required this.colorScheme,
    required this.isDark,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.onFormatChanged,
  });

  final Habit habit;
  final DateTime focusedDay;
  final CalendarFormat calendarFormat;
  final Set<DateTime> completedSet;
  final ColorScheme colorScheme;
  final bool isDark;
  final void Function(DateTime day) onDaySelected;
  final void Function(DateTime day) onPageChanged;
  final void Function(CalendarFormat format) onFormatChanged;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return Container(
      decoration: isDark
          ? AppDecorations.cardDark(color: colorScheme.surfaceContainerHighest)
          : AppDecorations.cardLight(color: colorScheme.surface),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: focusedDay,
        calendarFormat: calendarFormat,
        currentDay: today,
        rowHeight: 44,
        daysOfWeekHeight: 28,
        availableCalendarFormats: const {
          CalendarFormat.month: 'Month',
          CalendarFormat.twoWeeks: '2 weeks',
          CalendarFormat.week: 'Week',
        },
        eventLoader: (day) {
          final d = Habit.toDate(day);
          return completedSet.contains(d) ? [day] : [];
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return null;
            return Positioned(
              bottom: 2,
              child: Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: colorScheme.primary,
              ),
            );
          },
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: AppTextStyles.labelSmall(colorScheme.onSurfaceVariant).copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          weekendStyle: AppTextStyles.labelSmall(colorScheme.onSurfaceVariant).copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        calendarStyle: CalendarStyle(
          cellMargin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          cellPadding: const EdgeInsets.symmetric(vertical: 8),
          defaultTextStyle: AppTextStyles.bodyMedium(colorScheme.onSurface),
          weekendTextStyle: AppTextStyles.bodyMedium(colorScheme.onSurfaceVariant),
          outsideTextStyle: AppTextStyles.bodySmall(colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          selectedTextStyle: AppTextStyles.bodyMedium(colorScheme.onPrimary).copyWith(fontWeight: FontWeight.w600),
          todayTextStyle: AppTextStyles.bodyMedium(colorScheme.primary).copyWith(fontWeight: FontWeight.w700),
          selectedDecoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          todayDecoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.6), width: 1.5),
          ),
          markerDecoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          leftChevronPadding: EdgeInsets.zero,
          rightChevronPadding: EdgeInsets.zero,
          headerPadding: const EdgeInsets.symmetric(vertical: 12),
          formatButtonPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          formatButtonDecoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: isDark ? 0.4 : 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
          ),
          formatButtonTextStyle: AppTextStyles.labelMedium(colorScheme.onPrimaryContainer).copyWith(
            fontWeight: FontWeight.w600,
          ),
          titleTextStyle: AppTextStyles.titleMedium(colorScheme.onSurface).copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          titleTextFormatter: (date, locale) {
            const months = ['January', 'February', 'March', 'April', 'May', 'June',
              'July', 'August', 'September', 'October', 'November', 'December'];
            return '${months[date.month - 1]} ${date.year}';
          },
          leftChevronIcon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chevron_left_rounded, size: 22, color: colorScheme.onSurface),
          ),
          rightChevronIcon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chevron_right_rounded, size: 22, color: colorScheme.onSurface),
          ),
        ),
        onDaySelected: (selected, focused) {
          onDaySelected(selected);
          onPageChanged(focused);
        },
        onPageChanged: onPageChanged,
        onFormatChanged: onFormatChanged,
      ),
    );
  }
}

class _ThisWeekRow extends StatelessWidget {
  const _ThisWeekRow({
    required this.habit,
    required this.colorScheme,
    required this.isDark,
  });

  final Habit habit;
  final ColorScheme colorScheme;
  final bool isDark;

  static const _weekLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = Habit.toDate(now);
    final completedSet = habit.completedDates.map(Habit.toDate).toSet();
    final weekDays = List.generate(7, (i) {
      final day = DateTime.utc(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
      return (day, completedSet.contains(day));
    });

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
      decoration: isDark
          ? AppDecorations.cardDark(color: colorScheme.surfaceContainerHighest)
          : AppDecorations.cardLight(color: colorScheme.surface),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final day = weekDays[i].$1;
          final completed = weekDays[i].$2;
          final isToday = Habit.toDate(day) == today;
          final dayLabel = _weekLabels[day.weekday - 1];
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dayLabel,
                  style: AppTextStyles.labelSmall(colorScheme.onSurfaceVariant),
                ),
                Text(
                  '${day.day}',
                  style: AppTextStyles.labelSmall(colorScheme.onSurface).copyWith(
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed
                        ? colorScheme.primary
                        : colorScheme.error.withValues(alpha: isDark ? 0.5 : 0.35),
                  ),
                  child: completed
                      ? Icon(Icons.check_rounded, size: 18, color: colorScheme.onPrimary)
                      : null,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
