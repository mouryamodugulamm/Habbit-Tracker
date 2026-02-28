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
  late int _selectedIconIndex;
  late TimeOfDay? _reminderTime;
  String? _nameError;
  bool _isSaving = false;
  bool _goalEnabled = false;
  GoalTargetType _goalTargetType = GoalTargetType.totalDays;
  int _goalTargetValue = 30;
  Goal? _existingGoal;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit.name);
    final idx = widget.habit.iconIndex;
    _selectedIconIndex = (idx != null && idx >= 0 && idx < habitIcons.length) ? idx : 0;
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
    final name = _nameController.text.trim();
    final error = _validateName(name);
    setState(() => _nameError = error);
    if (error != null) return;

    setState(() => _isSaving = true);
    try {
      final reminderMinutes = _reminderTime != null
          ? _reminderTime!.hour * 60 + _reminderTime!.minute
          : null;
      final updated = widget.habit.copyWith(
        name: name,
        clearReminder: reminderMinutes == null,
        reminderMinutesSinceMidnight: reminderMinutes,
        iconIndex: _selectedIconIndex,
      );
      await ref.read(habitNotifierProvider.notifier).updateHabit(updated);
      final goalNotifier = ref.read(goalNotifierProvider.notifier);
      if (_goalEnabled && _goalTargetValue > 0) {
        if (_existingGoal != null && _existingGoal!.isActive) {
          await goalNotifier.updateGoal(_existingGoal!.copyWith(
            targetType: _goalTargetType,
            targetValue: _goalTargetValue,
          ));
        } else {
          await goalNotifier.deleteGoalsForHabit(widget.habit.id);
          await goalNotifier.addGoal(Goal(
            id: const Uuid().v4(),
            habitId: widget.habit.id,
            targetType: _goalTargetType,
            targetValue: _goalTargetValue,
          ));
        }
      } else if (_existingGoal != null) {
        await goalNotifier.deleteGoalsForHabit(widget.habit.id);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
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
        title: Text('Edit habit', style: AppTextStyles.titleLarge(colorScheme.onSurface)),
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
                  if (_nameError != null) setState(() => _nameError = _validateName(_nameController.text));
                },
                onSubmitted: (_) => _save(),
              ),
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
                  onChanged: (v) => setState(() => _goalTargetType = v ?? GoalTargetType.totalDays),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  initialValue: _goalTargetValue.toString(),
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
                    if (v != null) setState(() => _goalTargetValue = v);
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
