import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/core.dart';
import 'package:habit_tracker/core/router/app_router.dart';
import 'package:habit_tracker/core/widgets/gradient_scaffold_background.dart';
import 'package:habit_tracker/core/widgets/glass_card.dart';
import 'package:habit_tracker/presentation/providers/backup_providers.dart';
import 'package:habit_tracker/presentation/providers/settings_provider.dart';

/// Profile & settings: sleek, grouped layout with profile, appearance, and data sections.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  late ThemeMode _themeMode;
  late Locale? _locale;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsNotifierProvider);
    _nameController = TextEditingController(text: settings.userName ?? '');
    _themeMode = settings.themeMode;
    _locale = settings.locale;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _applySettings() async {
    final notifier = ref.read(settingsNotifierProvider.notifier);
    await notifier.setUserName(
      _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
    );
    await notifier.setThemeMode(_themeMode);
    await notifier.setLocale(_locale);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Settings saved'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _exportBackup(WidgetRef ref, ColorScheme colorScheme) async {
    final error = await exportBackup(ref);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $error'),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Backup ready to share or save'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _restoreBackup(WidgetRef ref, ColorScheme colorScheme) async {
    final result = await restoreBackup(ref);
    if (!mounted) return;
    switch (result) {
      case RestoreSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Backup restored'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      case RestoreError(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $message'),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      case RestoreCancelled():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          style: IconButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
          ),
        ),
        title: Text(
          'Profile & settings',
          style: AppTextStyles.titleLarge(colorScheme.onSurface).copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: Stack(
        children: [
          GradientScaffoldBackground(isDark: isDark),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.screen),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildProfileSection(colorScheme, isDark),
                    const SizedBox(height: AppSpacing.xl),
                    _buildAppearanceSection(colorScheme, isDark),
                    const SizedBox(height: AppSpacing.xl),
                    _buildDataSection(colorScheme, isDark),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildApplyButton(colorScheme),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(ColorScheme colorScheme, bool isDark) {
    final initial = (_nameController.text.trim().isNotEmpty
            ? _nameController.text.trim().substring(0, 1).toUpperCase()
            : '?')
        .toUpperCase();

    return GlassCard(
      isDark: isDark,
      useBlur: isDark,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                  color: isDark ? null : colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? AppColors.glassGradientEnd : colorScheme.primary).withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: AppTextStyles.headlineMedium(
                    isDark ? Colors.white : colorScheme.onPrimaryContainer,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Display name',
                      style: AppTextStyles.labelSmall(colorScheme.onSurfaceVariant)
                          .copyWith(letterSpacing: 0.5),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextField(
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Your name',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: colorScheme.primary, width: 2),
                        ),
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                      ),
                      style: AppTextStyles.titleMedium(colorScheme.onSurface).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(ColorScheme colorScheme, bool isDark) {
    return GlassCard(
      isDark: isDark,
      useBlur: isDark,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
            child: Text(
              'APPEARANCE',
              style: AppTextStyles.labelSmall(colorScheme.onSurfaceVariant).copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Theme',
              style: AppTextStyles.labelMedium(colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SegmentedButton<ThemeMode>(
              style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                visualDensity: VisualDensity.compact,
                selectedBackgroundColor: colorScheme.primary,
                selectedForegroundColor: colorScheme.onPrimary,
              ),
              segments: const [
                ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded, size: 20), label: Text('System')),
                ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded, size: 20), label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded, size: 20), label: Text('Dark')),
              ],
              selected: {_themeMode},
              onSelectionChanged: (Set<ThemeMode> selected) => setState(() => _themeMode = selected.first),
            ),
          ),
          Divider(height: AppSpacing.xl, color: colorScheme.outline.withValues(alpha: 0.4)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Language',
              style: AppTextStyles.labelMedium(colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _LanguageOption(
            label: 'English',
            selected: _locale?.languageCode == 'en',
            onTap: () => setState(() => _locale = const Locale('en')),
            colorScheme: colorScheme,
          ),
          _LanguageOption(
            label: 'Español',
            selected: _locale?.languageCode == 'es',
            onTap: () => setState(() => _locale = const Locale('es')),
            colorScheme: colorScheme,
          ),
          _LanguageOption(
            label: 'Français',
            selected: _locale?.languageCode == 'fr',
            onTap: () => setState(() => _locale = const Locale('fr')),
            colorScheme: colorScheme,
          ),
          _LanguageOption(
            label: 'System default',
            selected: _locale == null,
            onTap: () => setState(() => _locale = null),
            colorScheme: colorScheme,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(ColorScheme colorScheme, bool isDark) {
    return GlassCard(
      isDark: isDark,
      useBlur: isDark,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
            child: Text(
              'DATA',
              style: AppTextStyles.labelSmall(colorScheme.onSurfaceVariant).copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Export or restore your habits and completions as a JSON file.',
              style: AppTextStyles.bodySmall(colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _exportBackup(ref, colorScheme),
                    icon: const Icon(Icons.upload_rounded, size: 20),
                    label: const Text('Export'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _restoreBackup(ref, colorScheme),
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: const Text('Restore'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: AppSpacing.xl, color: colorScheme.outline.withValues(alpha: 0.4)),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => AppRouter.toDataPrivacy(context),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppDecorations.cardRadius)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 22, color: colorScheme.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data & privacy',
                            style: AppTextStyles.titleSmall(colorScheme.onSurface).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'What we store · Delete all data',
                            style: AppTextStyles.bodySmall(colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant, size: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton(ColorScheme colorScheme) {
    return FilledButton(
      onPressed: _applySettings,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_rounded, size: 22, color: colorScheme.onPrimary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Save changes',
            style: AppTextStyles.labelLarge(colorScheme.onPrimary).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colorScheme,
    this.isLast = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.sm,
            bottom: isLast ? AppSpacing.lg : AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyLarge(colorScheme.onSurface),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, size: 22, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
