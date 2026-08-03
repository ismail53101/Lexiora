import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/constants/app_constants.dart';
import 'package:lexiora/core/widgets/app_bottom_nav.dart';
import 'package:lexiora/features/library/domain/entities/library_document.dart';
import 'package:lexiora/features/library/presentation/providers/library_providers.dart';
import 'package:lexiora/features/notes/domain/entities/note.dart';
import 'package:lexiora/features/notes/presentation/pages/all_notes_page.dart';

/// The Profile tab — a personal snapshot (real library stats, not
/// placeholders) plus quick links to Settings and About. Sapiora has no
/// account system, so this is simply *your* copy of the app.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final int docCount = ref
        .watch(allDocumentsProvider)
        .maybeWhen(data: (List<LibraryDocument> d) => d.length, orElse: () => 0);
    final int favoriteCount = ref
        .watch(favoriteDocumentsProvider)
        .maybeWhen(data: (List<LibraryDocument> d) => d.length, orElse: () => 0);
    final int noteCount = ref
        .watch(allNotesProvider)
        .maybeWhen(data: (List<Note> n) => n.length, orElse: () => 0);

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: <Widget>[
          Center(
            child: Column(
              children: <Widget>[
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[scheme.primary, scheme.tertiary],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    AppConstants.userDisplayName.substring(0, 1),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  AppConstants.userDisplayName,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppConstants.appName} · v${AppConstants.appVersion}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: <Widget>[
              Expanded(
                  child:
                      _StatCard(icon: Icons.folder_open_outlined, value: docCount, label: 'Documents')),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatCard(
                      icon: Icons.star_outline, value: favoriteCount, label: 'Favorites')),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatCard(
                      icon: Icons.sticky_note_2_outlined, value: noteCount, label: 'Notes')),
            ],
          ),
          const SizedBox(height: 28),
          _MenuTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Theme, translation language, reading preferences',
            onTap: () => context.push(AppRoutes.settings),
          ),
          const SizedBox(height: 10),
          _MenuTile(
            icon: Icons.folder_open_outlined,
            title: 'Library',
            subtitle: 'All your documents',
            onTap: () => context.push(AppRoutes.library),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.value, required this.label});
  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: scheme.primary, size: 22),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
