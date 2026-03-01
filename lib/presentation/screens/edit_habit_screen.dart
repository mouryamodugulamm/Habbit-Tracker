import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/constants/habit_icons.dart';
import 'package:habit_tracker/core/core.dart';
import 'package:habit_tracker/core/widgets/gradient_scaffold_background.dart';
import 'package:habit_tracker/core/widgets/glass_card.dart';
import 'package:habit_tracker/domain/entities/goal.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/presentation/providers/goal_providers.dart';
import 'package:habit_tracker/presentation/providers/habit_providers.dart';
import 'package:habit_tracker/presentation/widgets/habit_icon_picker.dart';
import 'package:uuid/uuid.dart';

/// Edit existing habit: name and reminder. Preserves id and completed dates.
class EditHabitScreen extends ConsumerStatefulWidget {
  const EditHabitScreen({super.key, required this.habit});

  final Habit habit;

  @override
  ConsumerState<EditHabitScreen> createState() => _EditHabitScreenState();
}

class _EditHabitScreenState extends ConsumerState<EditHabitScreen> {
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late int _selectedIconIndex;
  late TimeOfDay? _reminderTime;
  String? _nameError;
  bool _isSaving = false;
  bool _goalEnabled = false;
  GoalTargetType _goalTargetType = GoalTargetType.totalDays;
  int _goalTargetValue = 30;
  Goal? _existingGoal;
  late HabitFrequency _frequency;
  late List<int> _customWeekdays;
  late int _targetCountPerDay;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit.name);
    _categoryController = TextEditingController(text: widget.habit.category ?? '');
    _frequency = widget.habit.frequency;
    _customWeekdays = List.from(widget.habit.customWeekdays);
    _targetCountPerDay = widget.habit.targetCountPerDay ?? 1;
    if (_targetCountPerDay < 1) _targetCountPerDay = 1;
    if (_targetCountPerDay > 99) _targetCountPerDay = 99;
    if (_frequency == HabitFrequency.custom && _customWeekdays.isEmpty) {
      _customWeekdays = [1];
    }
    final idx = widget.habit.iconIndex;
    _selectedIconIndex = (idx != null && idx >= 0 && idx < habitIcons.length)
        ? idx
        : 0;
    _reminderTime = widget.habit.reminderMinutesSinceMidnight != null
        ? TimeOfDay(
            hour: widget.habit.reminderMinutesSinceMidnight! ~/ 60,
            minute: widget.habit.reminderMinutesSinceMidnight! % 60,
          )
        : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final goal = ref.read(goalForHabitProvider(widget.habit.id));
      if (goal != null && mounted) {
        setState(() {
          _existingGoal = goal;
          _goalEnabled = goal.isActive;
          _goalTargetType = goal.targetType;
          _goalTargetValue = goal.targetValue;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter a habit name';
    if (trimmed.length > AppConstants.maxHabitNameLength) {
      return 'Max ${AppConstants.maxHabitNameLength} characters';
    }
    return null;
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    if (picked != null && mounted) setState(() => _reminderTime = picked);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final error = _validateName(name);
    setState(() => _nameError = error);
    if (error != null) return;

    setState(() => _isSaving = true);
    try {
      final reminderMinutes = _reminderTime != null
          ? _reminderTime!.hour * 60 + _reminderTime!.minute
          : null;
      final categoryTrimmed = _categoryController.text.trim();
      final updated = widget.habit.copyWith(
        name: name,
        clearReminder: reminderMinutes == null,
        reminderMinutesSinceMidnight: reminderMinutes,
        iconIndex: _selectedIconIndex,
        category: categoryTrimmed.isEmpty ? null : categoryTrimmed,
        clearCategory: categoryTrimmed.isEmpty,
        frequency: _frequency,
        customWeekdays: _frequency == HabitFrequency.custom ? _customWeekdays : null,
        targetCountPerDay: _targetCountPerDay == 1 ? null : _targetCountPerDay,
      );
      await ref.read(habitNotifierProvider.notifier).updateHabit(updated);
      final goalNotifier = ref.read(goalNotifierProvider.notifier);
      if (_goalEnabled && _goalTargetValue > 0) {
        if (_existingGoal != null && _existingGoal!.isActive) {
          await goalNotifier.updateGoal(
            _existingGoal!.copyWith(
              targetType: _goalTargetType,
              targetValue: _goalTargetValue,
            ),
          );
        } else {
          await goalNotifier.deleteGoalsForHabit(widget.habit.id);
          await goalNotifier.addGoal(
            Goal(
              id: const Uuid().v4(),
              habitId: widget.habit.id,
              targetType: _goalTargetType,
              targetValue: _goalTargetValue,
            ),
          );
        }
      } else if (_existingGoal != null) {
        await goalNotifier.deleteGoalsForHabit(widget.habit.id);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit habit',
          style: AppTextStyles.titleLarge(colorScheme.onSurface),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          GradientScaffoldBackground(isDark: isDark),
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: GlassCard(
                isDark: isDark,
                useBlur: isDark,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Habit name',
                        hintText: 'e.g. Morning run',
                        errorText: _nameError,
                        counterText: '',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: AppConstants.maxHabitNameLength,
                      onChanged: (_) {
                        if (_nameError != null) {
                          setState(
                            () => _nameError = _validateName(
                              _nameController.text,
                            ),
                          );
                        }
                      },
                      onSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category (optional)',
                        hintText: 'e.g. Health, Work, Learning',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Target per day',
                      style: AppTextStyles.labelLarge(
                        colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      initialValue: _targetCountPerDay.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Completions per day',
                        hintText: 'e.g. 3 for "Drink 3 glasses of water"',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (s) {
                        final v = int.tryParse(s);
                        setState(() => _targetCountPerDay = (v == null || v < 1) ? 1 : (v > 99 ? 99 : v));
                      },
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '1 = once per day. Use 2+ for habits you do multiple times.',
                      style: AppTextStyles.bodySmall(colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Frequency',
                      style: AppTextStyles.labelLarge(
                        colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<HabitFrequency>(
                      segments: const [
                        ButtonSegment(value: HabitFrequency.daily, label: Text('Every day')),
                        ButtonSegment(value: HabitFrequency.weekdays, label: Text('Weekdays')),
                        ButtonSegment(value: HabitFrequency.custom, label: Text('Custom')),
                      ],
                      selected: {_frequency},
                      onSelectionChanged: (s) => setState(() => _frequency = s.first),
                    ),
                    if (_frequency == HabitFrequency.custom) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        children: [1, 2, 3, 4, 5, 6, 7].map((w) {
                          const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          final selected = _customWeekdays.contains(w);
                          return FilterChip(
                            label: Text(labels[w - 1]),
                            selected: selected,
                            onSelected: (v) {
                              setState(() {
                                if (v) {
                                  _customWeekdays = [..._customWeekdays, w]..sort();
                                } else {
                                  _customWeekdays = _customWeekdays.where((d) => d != w).toList();
                                }
                                if (_customWeekdays.isEmpty) _customWeekdays = [1];
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Choose icon',
                      style: AppTextStyles.labelLarge(
                        colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    HabitIconPicker(
                      selectedIndex: _selectedIconIndex,
                      onSelected: (index) =>
                          setState(() => _selectedIconIndex = index),
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Row(
                      children: [
                        Text(
                          'Goal (optional)',
                          style: AppTextStyles.labelLarge(
                            colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Switch(
                          value: _goalEnabled,
                          onChanged: (v) => setState(() => _goalEnabled = v),
                        ),
                      ],
                    ),
                    if (_goalEnabled) ...[
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<GoalTargetType>(
                        initialValue: _goalTargetType,
                        decoration: const InputDecoration(
                          labelText: 'Goal type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: GoalTargetType.totalDays,
                            child: Text('Complete this many times (any days)'),
                          ),
                          DropdownMenuItem(
                            value: GoalTargetType.streak,
                            child: Text('Do it this many days in a row'),
                          ),
                        ],
                        onChanged: (v) => setState(
                          () => _goalTargetType = v ?? GoalTargetType.totalDays,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        initialValue: _goalTargetValue.toString(),
                        decoration: InputDecoration(
                          labelText: _goalTargetType == GoalTargetType.streak
                              ? 'How many days in a row?'
                              : 'How many times to complete?',
                          hintText: _goalTargetType == GoalTargetType.streak
                              ? 'e.g. 7'
                              : 'e.g. 30',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (s) {
                          final v = int.tryParse(s);
                          if (v != null) setState(() => _goalTargetValue = v);
                        },
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _goalTargetType == GoalTargetType.streak
                            ? 'Aim for a streak of consecutive days.'
                            : 'Aim for this many completions (any days count).',
                        style: AppTextStyles.bodySmall(
                          colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Reminder (optional)',
                      style: AppTextStyles.labelLarge(
                        colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    InkWell(
                      onTap: _pickReminderTime,
                      borderRadius: AppDecorations.cardBorderRadiusSmall,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: AppDecorations.cardBorderRadiusSmall,
                          border: Border.all(color: colorScheme.outline),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              color: colorScheme.onSurfaceVariant,
                              size: 22,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              _reminderTime != null
                                  ? _reminderTime!.format(context)
                                  : 'Set time',
                              style: AppTextStyles.bodyMedium(
                                colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            if (_reminderTime != null)
                              TextButton(
                                onPressed: () =>
                                    setState(() => _reminderTime = null),
                                child: Text(
                                  'Clear',
                                  style: AppTextStyles.labelMedium(
                                    colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),
                    FilledButton(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppDecorations.cardBorderRadiusSmall,
                        ),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Text('Save'),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: TextButton(
                        onPressed: _isSaving
                            ? null
                            : () => _archiveOrRestore(context, colorScheme),
                        child: Text(
                          widget.habit.isArchived
                              ? 'Restore habit'
                              : 'Archive habit',
                          style: AppTextStyles.labelMedium(
                            widget.habit.isArchived
                                ? colorScheme.primary
                                : colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _archiveOrRestore(
    BuildContext context,
    ColorScheme colorScheme,
  ) async {
    final isArchived = widget.habit.isArchived;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArchived ? 'Restore habit?' : 'Archive habit?'),
        content: Text(
          isArchived
              ? 'This habit will show again in your main list.'
              : 'Archived habits are hidden from the main list. You can restore them from the Archived filter.',
          style: AppTextStyles.bodyMedium(colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isArchived ? 'Restore' : 'Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(habitNotifierProvider.notifier).updateHabit(
            widget.habit.copyWith(isArchived: !isArchived),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
