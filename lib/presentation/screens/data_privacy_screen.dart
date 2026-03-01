import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/core.dart';
import 'package:habit_tracker/core/widgets/gradient_scaffold_background.dart';
import 'package:habit_tracker/presentation/providers/goal_providers.dart';
import 'package:habit_tracker/presentation/providers/habit_providers.dart';

/// Explains what data is stored locally and offers "Delete all data".
class DataPrivacyScreen extends ConsumerStatefulWidget {
  const DataPrivacyScreen({super.key});

  @override
  ConsumerState<DataPrivacyScreen> createState() => _DataPrivacyScreenState();
}

class _DataPrivacyScreenState extends ConsumerState<DataPrivacyScreen> {
  bool _isDeleting = false;

  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text(
          'This will permanently remove all your habits, completions, and goals from this device. '
          'This cannot be undone. Restore from a backup later if you have one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isDeleting = true);
    try {
      final habitRepo = ref.read(habitRepositoryProvider);
      final goalRepo = ref.read(goalRepositoryProvider);
      await habitRepo.clearAll();
      await goalRepo.clearAll();
      await ref.read(habitNotifierProvider.notifier).loadHabits();
      await ref.read(goalNotifierProvider.notifier).loadGoals();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data deleted')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Data & privacy',
          style: AppTextStyles.titleLarge(colorScheme.onSurface),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          GradientScaffoldBackground(isDark: isDark),
          ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                'What we store (on your device only)',
                style: AppTextStyles.titleMedium(colorScheme.onSurface)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'All data stays on your phone or tablet. We do not send it to any server.',
                style: AppTextStyles.bodyMedium(colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              _BulletItem(
                colorScheme: colorScheme,
                title: 'Habits',
                body: 'Names, icons, reminders, schedule (frequency), and how many times per day.',
              ),
              _BulletItem(
                colorScheme: colorScheme,
                title: 'Completions',
                body: 'When you logged each habit (date and time, and optional notes).',
              ),
              _BulletItem(
                colorScheme: colorScheme,
                title: 'Goals',
                body: 'Goals you set (e.g. 30 days total or 7-day streak) and their progress.',
              ),
              _BulletItem(
                colorScheme: colorScheme,
                title: 'Settings',
                body: 'Display name, theme (light/dark), and language. Stored in app preferences.',
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Delete all data',
                style: AppTextStyles.titleMedium(colorScheme.onSurface)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Remove all habits, completions, goals, and reset the app. Use this before uninstalling or to start fresh. Export a backup first if you want to restore later.',
                style: AppTextStyles.bodyMedium(colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _isDeleting ? null : _deleteAllData,
                icon: _isDeleting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Icon(Icons.delete_forever_rounded, color: colorScheme.onError),
                label: Text(_isDeleting ? 'Deleting…' : 'Delete all data'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({
    required this.colorScheme,
    required this.title,
    required this.body,
  });

  final ColorScheme colorScheme;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: AppTextStyles.bodyLarge(colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMedium(colorScheme.onSurface)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: AppTextStyles.bodySmall(colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
