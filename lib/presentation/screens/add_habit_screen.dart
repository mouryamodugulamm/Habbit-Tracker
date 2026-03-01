import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/core.dart';
import 'package:habit_tracker/core/widgets/gradient_scaffold_background.dart';
import 'package:habit_tracker/core/widgets/glass_card.dart';
import 'package:habit_tracker/domain/entities/goal.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/presentation/providers/goal_providers.dart';
import 'package:habit_tracker/presentation/providers/habit_providers.dart';
import 'package:habit_tracker/presentation/widgets/habit_icon_picker.dart';
import 'package:uuid/uuid.dart';

/// New habit form: name (required), optional reminder time, save. Logic in notifier; UI only.
class AddHabitScreen extends ConsumerStatefulWidget {
  const AddHabitScreen({super.key});

  @override
  ConsumerState<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends ConsumerState<AddHabitScreen> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();

  int _selectedIconIndex = 0;
  TimeOfDay? _reminderTime;
  String? _category;
  HabitFrequency _frequency = HabitFrequency.daily;
  List<int> _customWeekdays = [1, 2, 3, 4, 5];
  String? _nameError;
  bool _isSaving = false;
  int _targetCountPerDay = 1;
  GoalTargetType? _goalTargetType = GoalTargetType.totalDays;
  int? _goalTargetValue;
  bool _goalEnabled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter a habit name';
    if (trimmed.length > AppConstants.maxHabitNameLength) return 'Max ${AppConstants.maxHabitNameLength} characters';
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
    _nameFocusNode.unfocus();
    final name = _nameController.text.trim();
    final error = _validateName(name);
    setState(() => _nameError = error);
    if (error != null) return;

    setState(() => _isSaving = true);
    try {
      final habitId = const Uuid().v4();
      final habitNotifier = ref.read(habitNotifierProvider.notifier);
      final reminderMinutes = _reminderTime != null
          ? _reminderTime!.hour * 60 + _reminderTime!.minute
          : null;
      final categoryTrimmed = _category?.trim();
      await habitNotifier.addHabit(
        habitId,
        name,
        skipReload: true,
        reminderMinutesSinceMidnight: reminderMinutes,
        iconIndex: _selectedIconIndex,
        category: categoryTrimmed?.isEmpty ?? true ? null : categoryTrimmed,
        frequency: _frequency,
        customWeekdays: _frequency == HabitFrequency.custom ? _customWeekdays : null,
        targetCountPerDay: _targetCountPerDay == 1 ? null : _targetCountPerDay,
      );
      if (_goalEnabled && _goalTargetType != null && _goalTargetValue != null && _goalTargetValue! > 0) {
        await ref.read(goalNotifierProvider.notifier).addGoal(
              Goal(
                id: const Uuid().v4(),
                habitId: habitId,
                targetType: _goalTargetType!,
                targetValue: _goalTargetValue!,
              ),
            );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        habitNotifier.loadHabits();
        ref.read(goalNotifierProvider.notifier).loadGoals();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Theme.of(context).colorScheme.error),
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
        title: Text('New habit', style: AppTextStyles.titleLarge(colorScheme.onSurface)),
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
                focusNode: _nameFocusNode,
                decoration: InputDecoration(
                  labelText: 'Habit name',
                  hintText: 'e.g. Morning run',
                  errorText: _nameError,
                  counterText: '',
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLength: AppConstants.maxHabitNameLength,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = _validateName(_nameController.text));
                },
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                onChanged: (v) => setState(() => _category = v),
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
                style: AppTextStyles.labelLarge(colorScheme.onSurfaceVariant),
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
                '1 = once per day. Use 2+ for habits you do multiple times (e.g. glasses of water).',
                style: AppTextStyles.bodySmall(colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Frequency',
                style: AppTextStyles.labelLarge(colorScheme.onSurfaceVariant),
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
                style: AppTextStyles.labelLarge(colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.sm),
              HabitIconPicker(
                selectedIndex: _selectedIconIndex,
                onSelected: (index) => setState(() => _selectedIconIndex = index),
                colorScheme: colorScheme,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Text(
                    'Goal (optional)',
                    style: AppTextStyles.labelLarge(colorScheme.onSurfaceVariant),
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
                  initialValue: _goalTargetType ?? GoalTargetType.totalDays,
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
                  onChanged: (v) => setState(() => _goalTargetType = v ?? GoalTargetType.totalDays),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  initialValue: _goalTargetValue?.toString() ?? '',
                  decoration: InputDecoration(
                    labelText: _goalTargetType == GoalTargetType.streak
                        ? 'How many days in a row?'
                        : 'How many times to complete?',
                    hintText: _goalTargetType == GoalTargetType.streak ? 'e.g. 7' : 'e.g. 30',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (s) {
                    final v = int.tryParse(s);
                    setState(() => _goalTargetValue = v);
                  },
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _goalTargetType == GoalTargetType.streak
                      ? 'Aim for a streak of consecutive days.'
                      : 'Aim for this many completions (any days count).',
                  style: AppTextStyles.bodySmall(colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Reminder (optional)',
                style: AppTextStyles.labelLarge(colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.sm),
              InkWell(
                onTap: _pickReminderTime,
                borderRadius: AppDecorations.cardBorderRadiusSmall,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: AppDecorations.cardBorderRadiusSmall,
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule_rounded, color: colorScheme.onSurfaceVariant, size: 22),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        _reminderTime != null
                            ? _reminderTime!.format(context)
                            : 'Set time',
                        style: AppTextStyles.bodyMedium(colorScheme.onSurface),
                      ),
                      const Spacer(),
                      if (_reminderTime != null)
                        TextButton(
                          onPressed: () => setState(() => _reminderTime = null),
                          child: Text('Clear', style: AppTextStyles.labelMedium(colorScheme.primary)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  shape: RoundedRectangleBorder(borderRadius: AppDecorations.cardBorderRadiusSmall),
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
                ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
