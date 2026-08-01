import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/config/build_flags.dart';
import 'package:lexiora/core/constants/app_constants.dart';
import 'package:lexiora/core/constants/translation_languages.dart';
import 'package:lexiora/core/reader_engine/reader_models.dart';
import 'package:lexiora/core/services/permission_service.dart';
import 'package:lexiora/features/settings/domain/entities/app_settings.dart';
import 'package:lexiora/features/settings/presentation/providers/settings_providers.dart';

/// The Settings screen. Reads the reactive [settingsProvider] and mutates
/// through the [settingsControllerProvider]; every change persists immediately.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppSettings> async = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(child: Text('Could not load settings: $e')),
        data: (AppSettings s) => _SettingsBody(settings: s),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsController controller = ref.read(settingsControllerProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _SectionCard(
          title: 'Appearance',
          children: [
            const _Label('Theme'),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (Set<ThemeMode> v) =>
                  controller.setThemeMode(v.first),
            ),
            const SizedBox(height: 20),
            _Label('Font size  (${(settings.fontScale * 100).round()}%)'),
            Slider(
              value: settings.fontScale,
              min: 0.8,
              max: 1.6,
              divisions: 8,
              label: '${(settings.fontScale * 100).round()}%',
              onChanged: (double v) => controller.setFontScale(v),
            ),
            Text(
              'The quick brown fox jumps over the lazy dog.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        _SectionCard(
          title: 'Reading',
          children: [
            const _Label('Reading direction'),
            SegmentedButton<ReaderScrollAxis>(
              segments: const [
                ButtonSegment(
                  value: ReaderScrollAxis.vertical,
                  label: Text('Vertical'),
                  icon: Icon(Icons.swap_vert),
                ),
                ButtonSegment(
                  value: ReaderScrollAxis.horizontal,
                  label: Text('Horizontal'),
                  icon: Icon(Icons.swap_horiz),
                ),
              ],
              selected: {settings.readingScrollAxis},
              onSelectionChanged: (Set<ReaderScrollAxis> v) =>
                  controller.setScrollAxis(v.first),
            ),
            const SizedBox(height: 20),
            const _Label('Reading mode'),
            SegmentedButton<ReaderColorMode>(
              segments: const [
                ButtonSegment(value: ReaderColorMode.day, label: Text('Day')),
                ButtonSegment(value: ReaderColorMode.sepia, label: Text('Sepia')),
                ButtonSegment(value: ReaderColorMode.night, label: Text('Night')),
              ],
              selected: {settings.readerColorMode},
              onSelectionChanged: (Set<ReaderColorMode> v) =>
                  controller.setColorMode(v.first),
            ),
            const SizedBox(height: 20),
            const _Label('Default highlight color'),
            const SizedBox(height: 8),
            _ColorRow(
              colors: settings.highlightColors,
              selected: settings.defaultHighlightColor,
              onSelected: controller.setDefaultHighlightColor,
            ),
          ],
        ),
        _SectionCard(
          title: 'Reading behaviour',
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Keep screen awake'),
              subtitle: const Text('Stop the screen dimming while reading'),
              value: settings.keepScreenAwake,
              onChanged: controller.setKeepScreenAwake,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto-resume'),
              subtitle: const Text('Reopen documents on your last read page'),
              value: settings.autoResume,
              onChanged: controller.setAutoResume,
            ),
          ],
        ),
        _SectionCard(
          title: 'Translation',
          children: [
            const _Label('Translate words into'),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue:
                  translationLanguageByCode(settings.translationLanguage).code,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: kTranslationLanguages
                  .map(
                    (TranslationLanguage l) => DropdownMenuItem<String>(
                      value: l.code,
                      child: Text(l.label),
                    ),
                  )
                  .toList(),
              onChanged: (String? code) {
                if (code != null) controller.setTranslationLanguage(code);
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Used by the reader’s “Translate” action when you select a word. '
              'Translation data is offline.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        _SectionCard(
          title: 'Data',
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Back up library'),
              subtitle: const Text('Local backup — coming in a future update'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _comingSoon(context, 'Backup'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restore_outlined),
              title: const Text('Restore library'),
              subtitle: const Text('Restore from a backup — coming soon'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _comingSoon(context, 'Restore'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('App permissions'),
              subtitle:
                  const Text('Manage the storage access used to find your PDFs'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => sl<PermissionService>().openSystemSettings(),
            ),
          ],
        ),
        if (BuildFlags.enableAdmin)
          _SectionCard(
            title: 'Admin',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Admin Panel'),
                subtitle: const Text('Manage curated PDFs, links & notes'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.admin),
              ),
            ],
          ),
        const _SectionCard(
          title: 'About',
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.info_outline),
              title: Text(AppConstants.appName),
              subtitle: Text('Version ${AppConstants.appVersion}'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.school_outlined),
              title: Text(AppConstants.appTagline),
              subtitle: Text('Offline-first · No account required'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.favorite_outline),
              title: Text('Developed by Ismail Lashari'),
            ),
          ],
        ),
      ],
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$feature will arrive in a future update.')),
      );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      );
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.colors,
    required this.selected,
    required this.onSelected,
  });

  final List<int> colors;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((int value) {
        final bool isSelected = value == selected;
        return InkWell(
          onTap: () => onSelected(value),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(value),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.transparent,
                width: 3,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 20, color: Colors.black87)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
