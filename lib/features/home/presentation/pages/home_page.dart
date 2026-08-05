import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/navigation/home_destination.dart';
import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/result.dart';
import 'package:lexiora/core/widgets/app_bottom_nav.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/features/library/domain/entities/library_document.dart';
import 'package:lexiora/features/library/domain/usecases/library_usecases.dart';
import 'package:lexiora/features/library/presentation/providers/library_providers.dart';
import 'package:lexiora/features/library/presentation/widgets/document_card.dart';
import 'package:lexiora/features/settings/domain/entities/app_settings.dart';
import 'package:lexiora/features/settings/presentation/providers/settings_providers.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_goal.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';

/// The Home dashboard: a personal greeting, quick search, at-a-glance stats,
/// Continue reading / Recent documents, Explore module grid, Today's Goal,
/// and Import PDF — the app's landing tab.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LibraryDocument>> all =
        ref.watch(allDocumentsProvider);
    final AsyncValue<List<LibraryEntry>> continueReading =
        ref.watch(continueReadingProvider);
    final AsyncValue<List<LibraryDocument>> recent =
        ref.watch(recentDocumentsProvider);
    final AsyncValue<List<LibraryDocument>> favorites =
        ref.watch(favoriteDocumentsProvider);
    final List<HomeDestination> destinations =
        sl<HomeDestinationRegistry>().destinations;
    final String displayName = ref.watch(settingsProvider).maybeWhen(
        data: (AppSettings s) => s.displayName, orElse: () => '');

    final bool isEmpty = all.maybeWhen(
      data: (List<LibraryDocument> d) => d.isEmpty,
      orElse: () => false,
    );

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      floatingActionButton: null,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: _GreetingRow(
                  displayName: displayName,
                  onSearchTap: () => context.push(AppRoutes.library),
                  onThemeTap: () => _toggleTheme(context, ref),
                ),
              ),
            ),
            if (isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.auto_stories_outlined,
                  title: 'Welcome to Sapiora',
                  message:
                      'Sapiora automatically finds the PDF files already on '
                      'your device — or import your own with the Import PDF '
                      'button. Everything stays on your device.',
                  action: FilledButton.icon(
                    onPressed: () => context.push(AppRoutes.library),
                    icon: const Icon(Icons.folder_open_outlined),
                    label: const Text('Open library'),
                  ),
                ),
              )
            else ...[
              const SliverToBoxAdapter(child: _StatsRow()),
              _continueAndRecentSection(context, continueReading, recent),
              _docStrip(context, 'Favorites', favorites),
            ],
            SliverToBoxAdapter(
              child: _ExploreSection(destinations: destinations),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: _GoalAndImportRow(
                  onImport: () => _import(context, ref),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _HomeFooter()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Result<ImportOutcome> result =
        await ref.read(importPdfsProvider).call(const NoParams());
    result.fold(
      (failure) => messenger.showSnackBar(
        SnackBar(content: Text('Import failed: ${failure.message}')),
      ),
      (ImportOutcome o) {
        if (o.picked == 0) return; // cancelled
        final String msg = o.added > 0
            ? 'Imported ${o.added} PDF${o.added == 1 ? '' : 's'}'
                '${o.duplicates > 0 ? ' · skipped ${o.duplicates} already added' : ''}'
            : (o.duplicates == 1
                ? 'That PDF is already in your library'
                : 'Those PDFs are already in your library');
        messenger.showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  /// Flips between Light and Dark (from whichever is currently in effect —
  /// including when following System) so the header button always has a
  /// clear, single next state to switch to.
  void _toggleTheme(BuildContext context, WidgetRef ref) {
    final Brightness current = Theme.of(context).brightness;
    final ThemeMode next =
        current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    ref.read(settingsControllerProvider).setThemeMode(next);
  }

  /// "Continue reading" (left) and "Recent documents" (right) side by side —
  /// falls back to a stacked column on very narrow widths so nothing gets
  /// cramped on small screens, and simply grows wider on large/desktop
  /// windows since both columns are flex-based.
  Widget _continueAndRecentSection(
    BuildContext context,
    AsyncValue<List<LibraryEntry>> continueAsync,
    AsyncValue<List<LibraryDocument>> recentAsync,
  ) {
    final List<LibraryEntry> continueEntries = continueAsync.maybeWhen(
        data: (List<LibraryEntry> e) => e, orElse: () => const <LibraryEntry>[]);
    final List<LibraryDocument> recentDocs = recentAsync.maybeWhen(
      data: (List<LibraryDocument> d) => d,
      orElse: () => const <LibraryDocument>[],
    );

    if (continueEntries.isEmpty && recentDocs.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final Widget? left = continueEntries.isEmpty
                ? null
                : _ContinueReadingColumn(entries: continueEntries);
            final Widget? right = recentDocs.isEmpty
                ? null
                : _RecentDocumentsColumn(documents: recentDocs);

            if (left != null && right != null) {
              if (constraints.maxWidth < 300) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    left,
                    const SizedBox(height: 20),
                    right,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: left),
                  const SizedBox(width: 14),
                  Expanded(child: right),
                ],
              );
            }
            return left ?? right ?? const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _docStrip(
    BuildContext context,
    String title,
    AsyncValue<List<LibraryDocument>> async, {
    bool showViewAll = false,
  }) {
    final List<LibraryDocument> docs = async.maybeWhen(
      data: (List<LibraryDocument> d) => d,
      orElse: () => const [],
    );
    if (docs.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: _Section(
        title: title,
        onViewAll:
            showViewAll ? () => context.push(AppRoutes.library) : null,
        child: _HorizontalList(
          itemCount: docs.length,
          itemBuilder: (BuildContext context, int i) => DocumentCard(
            document: docs[i],
            onOpen: () => context.push(AppRoutes.reader(docs[i].id)),
          ),
        ),
      ),
    );
  }
}

/// "Good Evening, Ismail 👋" (or just "Good Evening 👋" until a name is set)
/// + subtitle, with the circular search and theme-toggle buttons.
class _GreetingRow extends StatelessWidget {
  const _GreetingRow({
    required this.displayName,
    required this.onSearchTap,
    required this.onThemeTap,
  });

  final String displayName;
  final VoidCallback onSearchTap;
  final VoidCallback onThemeTap;

  String get _greeting {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text.rich(
                TextSpan(
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                  children: <InlineSpan>[
                    TextSpan(text: displayName.isEmpty
                        ? _greeting
                        : '$_greeting, '),
                    if (displayName.isNotEmpty)
                      TextSpan(
                        text: displayName,
                        style: TextStyle(color: scheme.primary),
                      ),
                    const TextSpan(text: ' 👋'),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Keep learning, keep growing.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _GlowIconButton(
          icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          onTap: onThemeTap,
        ),
        const SizedBox(width: 10),
        _GlowIconButton(icon: Icons.search_rounded, onTap: onSearchTap),
      ],
    ).animate().fadeIn(duration: 320.ms).slideY(begin: -0.08, end: 0);
  }
}

/// A circular, softly-glowing icon button — used for the header search entry.
class _GlowIconButton extends StatefulWidget {
  const _GlowIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_GlowIconButton> createState() => _GlowIconButtonState();
}

class _GlowIconButtonState extends State<_GlowIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[scheme.primary, scheme.tertiary],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.38),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(widget.icon, color: scheme.onPrimary),
        ),
      ),
    );
  }
}

/// The "24 PDFs / study time today / today's goal" glance row.
class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final int docCount = ref.watch(allDocumentsProvider).maybeWhen(
        data: (List<LibraryDocument> d) => d.length, orElse: () => 0);

    final int studyMinutes = ref.watch(studyMinutesTodayProvider).maybeWhen(
        data: (int m) => m, orElse: () => 0);

    final List<StudyGoal> goals = ref.watch(studyGoalsProvider).maybeWhen(
        data: (List<StudyGoal> g) => g, orElse: () => const <StudyGoal>[]);
    final int goalTotal = goals.length;
    final int goalDone = goals.where((StudyGoal g) => g.achieved).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _StatTile(
              icon: Icons.description_outlined,
              value: '$docCount',
              label: 'PDFs',
              subLabel: 'In library',
              color: scheme.primary,
              onTap: () => context.push(AppRoutes.library),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: Icons.schedule_rounded,
              value: formatDuration(studyMinutes),
              label: 'Study time',
              subLabel: 'Today',
              color: const Color(0xFF38BDF8),
              onTap: () => context.push(AppRoutes.studyHub),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: Icons.track_changes_rounded,
              value: goalTotal == 0 ? '—' : '$goalDone / $goalTotal',
              label: 'Goal',
              subLabel: goalTotal == 0
                  ? 'Set a goal'
                  : (goalDone >= goalTotal ? 'Completed' : 'In progress'),
              color: scheme.primary,
              onTap: () => context.push(AppRoutes.studyHub),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.subLabel,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final String subLabel;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                subLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.onViewAll});
  final String title;
  final Widget child;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('View all'),
                  ),
              ],
            ),
          ),
          child,
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0);
  }
}

class _HorizontalList extends StatelessWidget {
  const _HorizontalList({required this.itemCount, required this.itemBuilder});
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 244,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (BuildContext context, int i) => SizedBox(
          width: 152,
          child: _ElevatedCard(
            child: itemBuilder(context, i),
          ),
        ),
      ),
    );
  }
}

/// Wraps a document card with a soft, premium drop shadow — the card's own
/// internal styling is untouched, this only affects how it sits on the page.
class _ElevatedCard extends StatelessWidget {
  const _ElevatedCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Left column of the two-column row: the in-progress document(s), styled as
/// one large cover card (matching the target dashboard layout). Scrolls
/// horizontally only when there's more than one in-progress document.
class _ContinueReadingColumn extends StatelessWidget {
  const _ContinueReadingColumn({required this.entries});
  final List<LibraryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Continue reading',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        SizedBox(
          height: 244,
          child: entries.length == 1
              ? _ElevatedCard(
                  child: DocumentCard(
                    document: entries.first.document,
                    progress: entries.first.percent,
                    onOpen: () =>
                        context.push(AppRoutes.reader(entries.first.document.id)),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (BuildContext context, int i) {
                    final LibraryEntry e = entries[i];
                    return SizedBox(
                      width: 152,
                      child: _ElevatedCard(
                        child: DocumentCard(
                          document: e.document,
                          progress: e.percent,
                          onOpen: () =>
                              context.push(AppRoutes.reader(e.document.id)),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0);
  }
}

/// Right column of the two-column row: a compact vertical list of the most
/// recent documents, each as a thumbnail + title + metadata row.
class _RecentDocumentsColumn extends StatelessWidget {
  const _RecentDocumentsColumn({required this.documents});
  final List<LibraryDocument> documents;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<LibraryDocument> shown = documents.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Recent documents',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => context.push(AppRoutes.library),
                child: const Text('View all'),
              ),
            ],
          ),
        ),
        for (int i = 0; i < shown.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == shown.length - 1 ? 0 : 10),
            child: _RecentDocRow(
              document: shown[i],
              onOpen: () => context.push(AppRoutes.reader(shown[i].id)),
            ),
          ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0);
  }
}

/// A compact document row: small cover thumbnail, a "PDF" pill, title, and
/// size · recency line — used in the Recent documents column.
class _RecentDocRow extends StatelessWidget {
  const _RecentDocRow({required this.document, required this.onOpen});
  final LibraryDocument document;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 46,
                  height: 58,
                  child: _RecentDocThumb(document: document),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'PDF',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      document.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${document.readableSize} · '
                      '${_relativeDayLabel(document.lastOpenedAt ?? document.importedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_vert, size: 18, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// The recent-doc row's thumbnail: the real cover when one exists, otherwise
/// a small placeholder icon — never shows a broken-image glyph.
class _RecentDocThumb extends StatelessWidget {
  const _RecentDocThumb({required this.document});
  final LibraryDocument document;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String? path = document.coverPath;
    if (path != null && path.isNotEmpty) {
      return ColoredBox(
        color: const Color(0xFFF3F1EC),
        child: Image.file(
          File(path),
          fit: BoxFit.contain,
          errorBuilder: (BuildContext context, Object error, StackTrace? _) =>
              _RecentDocThumbPlaceholder(scheme: scheme),
        ),
      );
    }
    return _RecentDocThumbPlaceholder(scheme: scheme);
  }
}

class _RecentDocThumbPlaceholder extends StatelessWidget {
  const _RecentDocThumbPlaceholder({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(
        Icons.picture_as_pdf_outlined,
        color: scheme.onSurfaceVariant,
        size: 20,
      ),
    );
  }
}

/// A short "Today" / "Yesterday" / "N days ago" label for a document's
/// recency, used only by the Recent documents row.
String _relativeDayLabel(DateTime dt) {
  final DateTime now = DateTime.now();
  final DateTime day = DateTime(dt.year, dt.month, dt.day);
  final DateTime today = DateTime(now.year, now.month, now.day);
  final int diff = today.difference(day).inDays;
  if (diff <= 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return '$diff days ago';
  if (diff < 30) return '${(diff / 7).floor()}w ago';
  if (diff < 365) return '${(diff / 30).floor()}mo ago';
  return '${(diff / 365).floor()}y ago';
}

class _HomeFooter extends StatelessWidget {
  const _HomeFooter();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.primary.withValues(alpha: 0.16),
                scheme.tertiary.withValues(alpha: 0.16),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite, size: 14, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Developed by Ismail Lashari',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Explore module grid — a responsive wrap of square tiles (icon, label,
/// subtitle), one per [HomeDestination]. The column count adapts to the
/// available width, so this looks right from a narrow phone up to a wide
/// desktop/Windows window without ever overflowing.
class _ExploreSection extends StatelessWidget {
  const _ExploreSection({required this.destinations});
  final List<HomeDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final List<HomeDestination> visible =
        destinations.where((HomeDestination d) => d.enabled).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(
              'Explore',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                const double spacing = 12;
                // ~78 logical px per tile keeps labels/subtitles readable on
                // a typical phone width and scales up cleanly on wider/
                // desktop windows, without ever needing to cut words off.
                final int columns =
                    (constraints.maxWidth / 78).floor().clamp(3, 6);
                final double tileWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) /
                        columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: <Widget>[
                    for (int i = 0; i < visible.length; i++)
                      SizedBox(
                        width: tileWidth,
                        child: _ExploreTile(destination: visible[i], index: i),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({required this.destination, required this.index});
  final HomeDestination destination;
  final int index;

  /// Purely presentational per-module accent colors so the grid reads as
  /// distinct modules at a glance. Unknown/future ids fall back to the
  /// theme's primary color, so no destination is ever left uncolored.
  static const Map<String, Color> _accentColors = <String, Color>{
    'library': Color(0xFF8B7CF6),
    'study_hub': Color(0xFF8B7CF6),
    'dictionary': Color(0xFF2DD4BF),
    'grammar': Color(0xFFFACC15),
    'vocabulary': Color(0xFFF472B6),
    'flashcards': Color(0xFF22D3EE),
    'quiz': Color(0xFFFB923C),
    'ai_assistant': Color(0xFF8B7CF6),
    'cloud_sync': Color(0xFF2DD4BF),
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color accent = _accentColors[destination.id] ?? scheme.primary;

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        splashColor: accent.withValues(alpha: 0.10),
        highlightColor: accent.withValues(alpha: 0.06),
        onTap: () {
          if (destination.comingSoon) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text('${destination.label} is coming soon.')),
              );
          } else {
            context.push(destination.routePath);
          }
        },
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(destination.icon, color: accent, size: 26),
                  const SizedBox(height: 8),
                  Text(
                    destination.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w700, height: 1.15),
                  ),
                  if (destination.subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      destination.subtitle!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant, height: 1.2),
                    ),
                  ],
                ],
              ),
            ),
            if (destination.comingSoon)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Soon',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    )
        .animate(delay: (30 * index).ms)
        .fadeIn(duration: 240.ms)
        .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1));
  }
}

/// Today's Goal (real data from Study Hub's daily goals) side-by-side with
/// the Import PDF action.
class _GoalAndImportRow extends ConsumerWidget {
  const _GoalAndImportRow({required this.onImport});
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Expanded(flex: 6, child: _TodaysGoalCard()),
          const SizedBox(width: 12),
          Expanded(flex: 5, child: _ImportPdfButton(onTap: onImport)),
        ],
      ),
    );
  }
}

class _TodaysGoalCard extends ConsumerWidget {
  const _TodaysGoalCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AsyncValue<List<StudyGoal>> goalsAsync =
        ref.watch(studyGoalsProvider);
    final List<StudyGoal> goals = goalsAsync.maybeWhen(
        data: (List<StudyGoal> g) => g, orElse: () => const <StudyGoal>[]);

    final int total = goals.length;
    final int done = goals.where((StudyGoal g) => g.achieved).length;
    final double fraction = total == 0 ? 0 : done / total;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push(AppRoutes.studyHub),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: fraction),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (BuildContext context, double value, _) =>
                        CircularProgressIndicator(
                      value: value,
                      strokeWidth: 6,
                      backgroundColor:
                          scheme.outlineVariant.withValues(alpha: 0.4),
                      valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                    ),
                  ),
                  Text(
                    total == 0 ? '—' : '${(fraction * 100).round()}%',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    "Today's Goal",
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    total == 0 ? 'Set a goal' : '$done / $total Topics',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportPdfButton extends StatefulWidget {
  const _ImportPdfButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_ImportPdfButton> createState() => _ImportPdfButtonState();
}

class _ImportPdfButtonState extends State<_ImportPdfButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[scheme.primary, scheme.tertiary],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.upload_rounded, color: scheme.onPrimary, size: 26),
              const SizedBox(height: 10),
              Text(
                'Import PDF',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Add and study anywhere',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onPrimary.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
