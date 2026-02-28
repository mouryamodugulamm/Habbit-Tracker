import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/core.dart';
import 'package:habit_tracker/presentation/providers/settings_provider.dart';

/// Profile & settings: user name, theme (light/dark/system), language.
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
      const SnackBar(content: Text('Settings applied')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile & settings', style: AppTextStyles.titleLarge(colorScheme.onSurface)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _SectionHeader(icon: Icons.person_outline_rounded, label: 'Profile', colorScheme: colorScheme),
          const SizedBox(height: AppSpacing.sm),
          _ProfileCard(
            isDark: isDark,
            colorScheme: colorScheme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Display name', style: AppTextStyles.labelMedium(colorScheme.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Your name',
                    border: OutlineInputBorder(borderRadius: AppDecorations.cardBorderRadiusSmall),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                  style: AppTextStyles.bodyLarge(colorScheme.onSurface),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _SectionHeader(icon: Icons.palette_outlined, label: 'Theme', colorScheme: colorScheme),
          const SizedBox(height: AppSpacing.sm),
          _ProfileCard(
            isDark: isDark,
            colorScheme: colorScheme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('App appearance', style: AppTextStyles.labelMedium(colorScheme.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<ThemeMode>(
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: colorScheme.primary,
                    selectedForegroundColor: colorScheme.onPrimary,
                  ),
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded), label: Text('System')),
                    ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded), label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded), label: Text('Dark')),
                  ],
                  selected: {_themeMode},
                  onSelectionChanged: (Set<ThemeMode> selected) {
                    setState(() => _themeMode = selected.first);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _SectionHeader(icon: Icons.language_rounded, label: 'Language', colorScheme: colorScheme),
          const SizedBox(height: AppSpacing.sm),
          _ProfileCard(
            isDark: isDark,
            colorScheme: colorScheme,
            child: _LanguageTile(
              languageCode: 'en',
              label: 'English',
              selected: _locale?.languageCode == 'en',
              onTap: () => setState(() => _locale = const Locale('en')),
              colorScheme: colorScheme,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _ProfileCard(
            isDark: isDark,
            colorScheme: colorScheme,
            child: _LanguageTile(
              languageCode: 'es',
              label: 'Español',
              selected: _locale?.languageCode == 'es',
              onTap: () => setState(() => _locale = const Locale('es')),
              colorScheme: colorScheme,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _ProfileCard(
            isDark: isDark,
            colorScheme: colorScheme,
            child: _LanguageTile(
              languageCode: 'fr',
              label: 'Français',
              selected: _locale?.languageCode == 'fr',
              onTap: () => setState(() => _locale = const Locale('fr')),
              colorScheme: colorScheme,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _ProfileCard(
            isDark: isDark,
            colorScheme: colorScheme,
            child: _LanguageTile(
              languageCode: null,
              label: 'System default',
              selected: _locale == null,
              onTap: () => setState(() => _locale = null),
              colorScheme: colorScheme,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          FilledButton.icon(
            onPressed: _applySettings,
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Apply settings'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTextStyles.titleSmall(colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.isDark,
    required this.colorScheme,
    required this.child,
  });

  final bool isDark;
  final ColorScheme colorScheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.6) : colorScheme.surface,
        borderRadius: AppDecorations.cardBorderRadius,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.languageCode,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colorScheme,
  });

  final String? languageCode;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppDecorations.cardBorderRadiusSmall,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.bodyLarge(colorScheme.onSurface))),
            if (selected)
              Icon(Icons.check_circle_rounded, size: 22, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
